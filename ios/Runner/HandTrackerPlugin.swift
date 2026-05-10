import Flutter
import UIKit
import Vision
import CoreVideo
import CoreImage
import CoreGraphics
import ImageIO

/// Implémentation native iOS du canal `ma3ak/air_writing_hand_tracker`.
///
/// Utilise `VNDetectHumanHandPoseRequest` (Apple Vision, iOS 14+) pour
/// récupérer 21 landmarks de la main à partir des frames BGRA8888 envoyées
/// par le `camera` plugin Flutter.
///
/// Format de retour: `{ "landmarks": [ {x,y,z}, ... ] }` en coordonnées
/// pixel (origine top-left) — compatible avec le code Dart existant.
class HandTrackerPlugin: NSObject, FlutterPlugin {
  static let channelName = "ma3ak/air_writing_hand_tracker"

  private let request: VNDetectHumanHandPoseRequest = {
    let r = VNDetectHumanHandPoseRequest()
    r.maximumHandCount = 1
    return r
  }()

  private let processingQueue = DispatchQueue(
    label: "ma3ak.hand_tracker.queue",
    qos: .userInitiated
  )
  private var inFlight = false
  private var initialized = false
  private var lastLandmarksPayload: [String: Any]?
  private var lastLandmarksTime: CFTimeInterval = 0

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: HandTrackerPlugin.channelName,
      binaryMessenger: registrar.messenger()
    )
    let instance = HandTrackerPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "initialize":
      initialized = true
      result(nil)
    case "dispose":
      initialized = false
      lastLandmarksPayload = nil
      result(nil)
    case "detectHandLandmarks":
      guard initialized else {
        result(nil)
        return
      }
      guard let args = call.arguments as? [String: Any] else {
        result(nil)
        return
      }
      processingQueue.async { [weak self] in
        guard let self else { return }
        if self.inFlight {
          // Ne pas renvoyer `nil` : Flutter l’interprète comme « aucune main ».
          if let cached = self.lastLandmarksPayload,
             CACurrentMediaTime() - self.lastLandmarksTime < 0.15 {
            DispatchQueue.main.async { result(cached) }
            return
          }
          DispatchQueue.main.async { result(nil) }
          return
        }
        self.inFlight = true
        let payload = self.detect(args: args)
        self.inFlight = false
        if let payload {
          self.lastLandmarksPayload = payload
          self.lastLandmarksTime = CACurrentMediaTime()
        }
        DispatchQueue.main.async { result(payload) }
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  // MARK: - Detection

  private func detect(args: [String: Any]) -> [String: Any]? {
    guard
      let width = args["width"] as? Int,
      let height = args["height"] as? Int,
      let format = args["format"] as? String,
      let planes = args["planes"] as? [[String: Any]],
      !planes.isEmpty
    else {
      return nil
    }

    let deviceOrientation = args["deviceOrientation"] as? String
    let lensFront = (args["lensDirection"] as? String)?.lowercased() == "front"

    guard let cgImage = makeCGImage(
      format: format.lowercased(),
      width: width,
      height: height,
      planes: planes
    ) else {
      return nil
    }

    let visionPack = prepareCgImageForVision(
      cgImage: cgImage,
      originalWidth: width,
      originalHeight: height
    )
    let visionCG = visionPack.image
    let vx = visionPack.visionWidth
    let vy = visionPack.visionHeight
    let sx = visionPack.scaleToOriginalX
    let sy = visionPack.scaleToOriginalY

    let orientation = cgOrientationForVision(
      imageWidth: width,
      imageHeight: height,
      deviceOrientationName: deviceOrientation,
      lensFront: lensFront
    )

    let handler = VNImageRequestHandler(cgImage: visionCG, orientation: orientation)
    do {
      try handler.perform([request])
    } catch {
      return nil
    }

    guard
      let observation = request.results?.first as? VNHumanHandPoseObservation
    else {
      return nil
    }

    // Mapping joint Vision → index MediaPipe (21 landmarks).
    let jointMap: [(VNHumanHandPoseObservation.JointName, Int)] = [
      (.wrist, 0),
      (.thumbCMC, 1), (.thumbMP, 2), (.thumbIP, 3), (.thumbTip, 4),
      (.indexMCP, 5), (.indexPIP, 6), (.indexDIP, 7), (.indexTip, 8),
      (.middleMCP, 9), (.middlePIP, 10), (.middleDIP, 11), (.middleTip, 12),
      (.ringMCP, 13), (.ringPIP, 14), (.ringDIP, 15), (.ringTip, 16),
      (.littleMCP, 17), (.littlePIP, 18), (.littleDIP, 19), (.littleTip, 20),
    ]

    // Prépare une liste de 21 landmarks à zéro pour rester compatible avec
    // le pipeline MediaPipe.
    var landmarks: [[String: Any]] = Array(
      repeating: ["x": 0.0, "y": 0.0, "z": 0.0],
      count: 21
    )
    let confidenceThreshold: VNConfidence = 0.15
    var detectedAny = false

    for (joint, idx) in jointMap {
      guard
        let point = try? observation.recognizedPoint(joint),
        point.confidence >= confidenceThreshold
      else { continue }

      // Vision: coordonnées normalisées [0..1] avec origine bottom-left,
      // relatives à l'image passée au handler (vx × vy), puis reprojection
      // vers les dimensions buffer caméra d'origine.
      let pxVision = Double(point.location.x) * Double(vx)
      let pyVision = (1.0 - Double(point.location.y)) * Double(vy)
      let px = pxVision * sx
      let py = pyVision * sy
      landmarks[idx] = ["x": px, "y": py, "z": 0.0]
      detectedAny = true
    }

    guard detectedAny else { return nil }
    return ["landmarks": landmarks]
  }

  /// Réduit la longueur max côté Vision pour accélérer la pose (latence Flutter).
  private func prepareCgImageForVision(
    cgImage: CGImage,
    originalWidth: Int,
    originalHeight: Int
  ) -> (image: CGImage, visionWidth: Int, visionHeight: Int, scaleToOriginalX: Double, scaleToOriginalY: Double) {
    let maxSide = 720
    let longSide = max(originalWidth, originalHeight)
    guard longSide > maxSide else {
      return (cgImage, originalWidth, originalHeight, 1, 1)
    }
    let scale = Double(maxSide) / Double(longSide)
    let nw = max(1, Int(Double(originalWidth) * scale))
    let nh = max(1, Int(Double(originalHeight) * scale))
    let scaleBackX = Double(originalWidth) / Double(nw)
    let scaleBackY = Double(originalHeight) / Double(nh)

    let colorSpace = CGColorSpaceCreateDeviceRGB()
    guard
      let ctx = CGContext(
        data: nil,
        width: nw,
        height: nh,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
      )
    else {
      return (cgImage, originalWidth, originalHeight, 1, 1)
    }
    ctx.interpolationQuality = .medium
    ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: nw, height: nh))
    guard let scaled = ctx.makeImage() else {
      return (cgImage, originalWidth, originalHeight, 1, 1)
    }
    return (scaled, nw, nh, scaleBackX, scaleBackY)
  }

  /// Orientation buffer → upright affichage (selfie / paysage).
  private func cgOrientationForVision(
    imageWidth: Int,
    imageHeight: Int,
    deviceOrientationName: String?,
    lensFront: Bool
  ) -> CGImagePropertyOrientation {
    let name = deviceOrientationName ?? "portraitUp"
    let portraitFamily: Set<String> = ["portraitUp", "portraitDown"]
    let isPortrait = portraitFamily.contains(name)

    if lensFront {
      if isPortrait {
        return imageWidth > imageHeight ? .leftMirrored : .upMirrored
      }
      return imageHeight > imageWidth ? .upMirrored : .rightMirrored
    }

    if isPortrait {
      return imageWidth > imageHeight ? .right : .up
    }
    return imageHeight > imageWidth ? .up : .left
  }

  // MARK: - Image construction

  private func makeCGImage(
    format: String,
    width: Int,
    height: Int,
    planes: [[String: Any]]
  ) -> CGImage? {
    if format.contains("bgra") {
      return makeCGImageFromBGRA(
        width: width,
        height: height,
        planes: planes
      )
    }
    if format.contains("yuv") {
      return makeCGImageFromYUV420(
        width: width,
        height: height,
        planes: planes
      )
    }
    // Format inconnu: tente BGRA en fallback.
    return makeCGImageFromBGRA(
      width: width,
      height: height,
      planes: planes
    )
  }

  private func makeCGImageFromBGRA(
    width: Int,
    height: Int,
    planes: [[String: Any]]
  ) -> CGImage? {
    guard
      let plane = planes.first,
      let typed = plane["bytes"] as? FlutterStandardTypedData
    else { return nil }
    let bytesPerRow = (plane["bytesPerRow"] as? Int) ?? (width * 4)
    let cfData = typed.data as NSData as CFData
    guard let provider = CGDataProvider(data: cfData) else { return nil }

    let bitmapInfo = CGBitmapInfo(
      rawValue: CGImageAlphaInfo.noneSkipFirst.rawValue
        | CGBitmapInfo.byteOrder32Little.rawValue
    )

    return CGImage(
      width: width,
      height: height,
      bitsPerComponent: 8,
      bitsPerPixel: 32,
      bytesPerRow: bytesPerRow,
      space: CGColorSpaceCreateDeviceRGB(),
      bitmapInfo: bitmapInfo,
      provider: provider,
      decode: nil,
      shouldInterpolate: false,
      intent: .defaultIntent
    )
  }

  /// Conversion YUV420 → CGImage via CVPixelBuffer + CIContext.
  /// Utilisé en fallback (Android style); iOS produit en général du BGRA.
  private func makeCGImageFromYUV420(
    width: Int,
    height: Int,
    planes: [[String: Any]]
  ) -> CGImage? {
    guard planes.count >= 3 else { return nil }
    guard
      let yTyped = planes[0]["bytes"] as? FlutterStandardTypedData,
      let uTyped = planes[1]["bytes"] as? FlutterStandardTypedData,
      let vTyped = planes[2]["bytes"] as? FlutterStandardTypedData
    else { return nil }
    let yRow = (planes[0]["bytesPerRow"] as? Int) ?? width
    let uvRow = (planes[1]["bytesPerRow"] as? Int) ?? width

    var pixelBuffer: CVPixelBuffer?
    let attrs: [String: Any] = [
      kCVPixelBufferIOSurfacePropertiesKey as String: [:]
    ]
    let status = CVPixelBufferCreate(
      kCFAllocatorDefault,
      width,
      height,
      kCVPixelFormatType_420YpCbCr8BiPlanarFullRange,
      attrs as CFDictionary,
      &pixelBuffer
    )
    guard status == kCVReturnSuccess, let pb = pixelBuffer else { return nil }

    CVPixelBufferLockBaseAddress(pb, [])
    defer { CVPixelBufferUnlockBaseAddress(pb, []) }

    if let yDest = CVPixelBufferGetBaseAddressOfPlane(pb, 0) {
      let dstRow = CVPixelBufferGetBytesPerRowOfPlane(pb, 0)
      yTyped.data.withUnsafeBytes { (raw: UnsafeRawBufferPointer) in
        guard let base = raw.baseAddress else { return }
        for r in 0..<height {
          memcpy(
            yDest.advanced(by: r * dstRow),
            base.advanced(by: r * yRow),
            min(dstRow, yRow)
          )
        }
      }
    }
    if let uvDest = CVPixelBufferGetBaseAddressOfPlane(pb, 1) {
      let dstRow = CVPixelBufferGetBytesPerRowOfPlane(pb, 1)
      let halfH = height / 2
      let halfW = width / 2
      uTyped.data.withUnsafeBytes { (uRaw: UnsafeRawBufferPointer) in
        vTyped.data.withUnsafeBytes { (vRaw: UnsafeRawBufferPointer) in
          guard let uBase = uRaw.baseAddress, let vBase = vRaw.baseAddress
          else { return }
          for r in 0..<halfH {
            let dstLine = uvDest
              .advanced(by: r * dstRow)
              .assumingMemoryBound(to: UInt8.self)
            let uLine = uBase
              .advanced(by: r * uvRow)
              .assumingMemoryBound(to: UInt8.self)
            let vLine = vBase
              .advanced(by: r * uvRow)
              .assumingMemoryBound(to: UInt8.self)
            for c in 0..<halfW {
              dstLine[c * 2] = uLine[c]
              dstLine[c * 2 + 1] = vLine[c]
            }
          }
        }
      }
    }

    let ciImage = CIImage(cvPixelBuffer: pb)
    let ciContext = CIContext(options: nil)
    return ciContext.createCGImage(ciImage, from: ciImage.extent)
  }
}
