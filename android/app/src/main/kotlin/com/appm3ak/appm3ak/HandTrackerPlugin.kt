package com.appm3ak.appm3ak

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.ImageFormat
import android.graphics.Matrix
import android.graphics.Rect
import android.graphics.YuvImage
import com.google.mediapipe.framework.image.BitmapImageBuilder
import com.google.mediapipe.tasks.core.BaseOptions
import com.google.mediapipe.tasks.vision.core.RunningMode
import com.google.mediapipe.tasks.vision.handlandmarker.HandLandmarker
import com.google.mediapipe.tasks.vision.handlandmarker.HandLandmarkerResult
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.ByteArrayOutputStream
import java.nio.ByteBuffer
import java.io.File
import java.io.FileOutputStream
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicLong

/**
 * MediaPipe Hand Landmarker (mode VIDEO) pour les frames [CameraImage] envoyées depuis Dart.
 * Même canal que iOS : [ma3ak/air_writing_hand_tracker].
 */
class HandTrackerPlugin : FlutterPlugin, MethodCallHandler {
    private var channel: MethodChannel? = null
    private var applicationContext: android.content.Context? = null
    private var handLandmarker: HandLandmarker? = null
    private val inFlight = AtomicBoolean(false)
    private val frameMs = AtomicLong(0)

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        applicationContext = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, CHANNEL_NAME)
        channel?.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel?.setMethodCallHandler(null)
        channel = null
        applicationContext = null
        handLandmarker?.close()
        handLandmarker = null
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "initialize" -> {
                val ctx = applicationContext ?: run {
                    result.error("no_context", null, null)
                    return
                }
                val args = call.arguments as? Map<*, *>
                val assetPath = args?.get("taskAssetPath") as? String
                    ?: "assets/models/hand_landmarker.task"
                try {
                    ensureLandmarker(ctx, assetPath)
                    result.success(null)
                } catch (e: Exception) {
                    result.error("init_failed", e.message, null)
                }
            }

            "dispose" -> {
                handLandmarker?.close()
                handLandmarker = null
                result.success(null)
            }

            "detectHandLandmarks" -> {
                val landmarker = handLandmarker
                if (landmarker == null) {
                    result.success(null)
                    return
                }
                if (!inFlight.compareAndSet(false, true)) {
                    result.success(null)
                    return
                }
                try {
                    val args = call.arguments as? Map<*, *> ?: run {
                        result.success(null)
                        return
                    }
                    val payload = detect(args, landmarker)
                    result.success(payload)
                } catch (e: Exception) {
                    result.success(null)
                } finally {
                    inFlight.set(false)
                }
            }

            else -> result.notImplemented()
        }
    }

    private fun ensureLandmarker(ctx: android.content.Context, flutterAssetPath: String) {
        if (handLandmarker != null) return
        val taskFile = copyAssetToCache(ctx, flutterAssetPath)
        val baseOptions = BaseOptions.builder()
            .setModelAssetPath(taskFile.absolutePath)
            .build()
        val options = HandLandmarker.HandLandmarkerOptions.builder()
            .setBaseOptions(baseOptions)
            .setNumHands(1)
            // Seuils plus bas que le défaut : selfie / faible lumière / doigt proche.
            .setMinHandDetectionConfidence(0.35f)
            .setMinHandPresenceConfidence(0.35f)
            .setMinTrackingConfidence(0.35f)
            .setRunningMode(RunningMode.VIDEO)
            .build()
        handLandmarker = HandLandmarker.createFromOptions(ctx, options)
    }

    private fun copyAssetToCache(ctx: android.content.Context, flutterAssetPath: String): File {
        val name = flutterAssetPath.substringAfterLast('/')
        val out = File(ctx.filesDir, "air_writing_$name")
        if (out.exists() && out.length() > 0) return out
        val key = "flutter_assets/$flutterAssetPath"
        ctx.assets.open(key).use { input ->
            FileOutputStream(out).use { output -> input.copyTo(output) }
        }
        return out
    }

    private fun detect(args: Map<*, *>, landmarker: HandLandmarker): Map<String, Any>? {
        val width = args["width"] as? Int ?: return null
        val height = args["height"] as? Int ?: return null
        val sensorRotation = (args["sensorRotation"] as? Int) ?: 0
        val deviceOrientationName = args["deviceOrientation"] as? String
        val lensDirection = args["lensDirection"] as? String
        val planes = args["planes"] as? List<*> ?: return null
        if (planes.isEmpty()) return null

        val bitmap = planesToBitmap(width, height, planes) ?: return null
        val deviceDeg = deviceOrientationDegrees(deviceOrientationName)
        val front = lensDirection?.equals("front", ignoreCase = true) == true
        val rotationDeg = computeDisplayRotationDegrees(sensorRotation, deviceDeg, front)
        val rotated = rotateBitmap(bitmap, rotationDeg.toFloat())
        if (rotated != bitmap) {
            bitmap.recycle()
        }

        val mpImage = BitmapImageBuilder(rotated).build()
        val ts = frameMs.addAndGet(33)
        val mpResult: HandLandmarkerResult = landmarker.detectForVideo(mpImage, ts)
        mpImage.close()

        val hands = mpResult.landmarks()
        if (hands.isEmpty()) {
            rotated.recycle()
            return null
        }
        val hand = hands[0]
        val w = rotated.width.toFloat()
        val h = rotated.height.toFloat()
        val landmarks = ArrayList<Map<String, Double>>(21)
        for (i in 0 until 21) {
            if (i < hand.size) {
                val lm = hand[i]
                landmarks.add(
                    mapOf(
                        "x" to (lm.x() * w).toDouble(),
                        "y" to (lm.y() * h).toDouble(),
                        "z" to lm.z().toDouble(),
                    ),
                )
            } else {
                landmarks.add(mapOf("x" to 0.0, "y" to 0.0, "z" to 0.0))
            }
        }
        rotated.recycle()
        return mapOf("landmarks" to landmarks)
    }

    private fun deviceOrientationDegrees(name: String?): Int {
        return when (name) {
            "portraitUp" -> 0
            "landscapeLeft" -> 90
            "portraitDown" -> 180
            "landscapeRight" -> 270
            else -> 0
        }
    }

    /**
     * Même logique que l’orientation JPEG Camera1/Camera2 (compense miroir avant).
     */
    private fun computeDisplayRotationDegrees(
        sensorOrientation: Int,
        deviceDegrees: Int,
        frontFacing: Boolean,
    ): Int {
        val r = if (frontFacing) {
            val t = (sensorOrientation + deviceDegrees) % 360
            (360 - t) % 360
        } else {
            (sensorOrientation - deviceDegrees + 360) % 360
        }
        return (r + 360) % 360
    }

    private fun rotateBitmap(source: Bitmap, rotationDegrees: Float): Bitmap {
        if (rotationDegrees == 0f) return source
        val matrix = Matrix()
        matrix.postRotate(rotationDegrees)
        return Bitmap.createBitmap(source, 0, 0, source.width, source.height, matrix, true)
    }

    private fun planeBytes(plane: Map<*, *>): ByteArray? {
        return when (val raw = plane["bytes"]) {
            is ByteArray -> raw
            is ByteBuffer -> {
                val dup = raw.duplicate()
                val arr = ByteArray(dup.remaining())
                dup.get(arr)
                arr
            }
            else -> {
                try {
                    val f = raw?.javaClass?.getDeclaredField("data")
                    f?.isAccessible = true
                    f?.get(raw) as? ByteArray
                } catch (_: Exception) {
                    null
                }
            }
        }
    }

    private fun planesToBitmap(width: Int, height: Int, planes: List<*>): Bitmap? {
        val p0 = planes[0] as? Map<*, *> ?: return null
        val yBytes = planeBytes(p0) ?: return null
        val yRowStride = (p0["bytesPerRow"] as? Int) ?: width

        if (planes.size >= 3) {
            val p1 = planes[1] as? Map<*, *>
            val p2 = planes[2] as? Map<*, *>
            val uBytes = p1?.let { planeBytes(it) }
            val vBytes = p2?.let { planeBytes(it) }
            if (uBytes != null && vBytes != null) {
                val uRowStride = (p1["bytesPerRow"] as? Int) ?: width
                val vRowStride = (p2["bytesPerRow"] as? Int) ?: width
                val uPixelStride = (p1["bytesPerPixel"] as? Int) ?: 1
                val vPixelStride = (p2["bytesPerPixel"] as? Int) ?: 1
                val nv21 = yuv420ToNv21(
                    yBytes,
                    yRowStride,
                    uBytes,
                    uRowStride,
                    uPixelStride,
                    vBytes,
                    vRowStride,
                    vPixelStride,
                    width,
                    height,
                )
                val yuv = YuvImage(nv21, ImageFormat.NV21, width, height, null)
                val out = ByteArrayOutputStream()
                yuv.compressToJpeg(Rect(0, 0, width, height), 92, out)
                val bytes = out.toByteArray()
                return BitmapFactory.decodeByteArray(bytes, 0, bytes.size)
            }
        }

        // Fallback : luminance Y seule (aperçu dégradé mais évite un crash)
        val argb = IntArray(width * height)
        var output = 0
        for (row in 0 until height) {
            val rowStart = row * yRowStride
            for (col in 0 until width) {
                val yi = (yBytes[rowStart + col].toInt() and 0xff)
                argb[output++] = -0x1000000 or (yi shl 16) or (yi shl 8) or yi
            }
        }
        return Bitmap.createBitmap(argb, width, height, Bitmap.Config.ARGB_8888)
    }

    private fun yuv420ToNv21(
        y: ByteArray,
        yRowStride: Int,
        u: ByteArray,
        uRowStride: Int,
        uPixelStride: Int,
        v: ByteArray,
        vRowStride: Int,
        vPixelStride: Int,
        width: Int,
        height: Int,
    ): ByteArray {
        val ySize = width * height
        val chromaHeight = height / 2
        val chromaWidth = width / 2
        val nv21 = ByteArray(ySize + chromaWidth * chromaHeight * 2)
        // Y
        var pos = 0
        for (row in 0 until height) {
            System.arraycopy(y, row * yRowStride, nv21, pos, width)
            pos += width
        }
        // NV21 : interleave VU
        var uvPos = ySize
        for (row in 0 until chromaHeight) {
            for (col in 0 until chromaWidth) {
                val uIndex = row * uRowStride + col * uPixelStride
                val vIndex = row * vRowStride + col * vPixelStride
                nv21[uvPos++] = v[vIndex]
                nv21[uvPos++] = u[uIndex]
            }
        }
        return nv21
    }

    companion object {
        private const val CHANNEL_NAME = "ma3ak/air_writing_hand_tracker"
    }
}
