import 'dart:isolate';
import 'dart:typed_data';

import 'package:tflite_flutter/tflite_flutter.dart';

import '../config/detection_config.dart';
import 'yolo_tflite_runner.dart';

/// Message envoyé au isolate : soit init (bytes du modèle), soit frame (RGB inputWidth×inputHeight).
const int _msgInit = 0;
const int _msgFrame = 1;

/// Point d'entrée de l'isolate de détection. Reçoit le SendPort du main pour renvoyer les résultats.
/// Le main envoie : [ _msgInit, Uint8List ] puis [ _msgFrame, Uint8List ] pour chaque frame.
void detectionIsolateEntry(SendPort mainSendPort) {
  final receivePort = ReceivePort();
  mainSendPort.send(receivePort.sendPort);

  Interpreter? interpreter;
  TensorType? inputType;
  TensorType? outputType;
  int outputElements = 1 * 84 * DetectionConfig.numPredictions;
  List<int> outputShape = const [1, 84, DetectionConfig.numPredictions];

  receivePort.listen((dynamic message) {
    if (message is! List || message.length < 2) return;
    final kind = message[0] as int;
    final data = message[1];

    if (kind == _msgInit && data is Uint8List) {
      try {
        interpreter?.close();
        interpreter = Interpreter.fromBuffer(data);
        final inTensor = interpreter!.getInputTensor(0);
        final outTensor = interpreter!.getOutputTensor(0);
        inputType = inTensor.type;
        outputType = outTensor.type;
        outputElements = outTensor.numElements();
        outputShape = outTensor.shape;
        // Aide diagnostic dans les logs device.
        print(
          '[Detection] inputShape=${inTensor.shape} inputType=${inTensor.type} '
          'outputShape=${outTensor.shape} outputType=${outTensor.type}',
        );
        mainSendPort.send(InferenceOutput(detections: []));
      } catch (e) {
        mainSendPort.send(InferenceOutput(detections: [], error: e.toString()));
      }
      return;
    }

    if (kind == _msgFrame && data is Uint8List && interpreter != null) {
      try {
        final Object input;
        switch (inputType) {
          case TensorType.uint8:
            input = preprocessRgbToUint8_4D(data);
            break;
          case TensorType.int8:
            input = preprocessRgbToInt8_4D(data);
            break;
          case TensorType.float32:
          default:
            input = preprocessRgbToFloat32_4D(data);
            break;
        }

        Object outputBuffer;
        switch (outputType) {
          case TensorType.uint8:
            outputBuffer = _createOutputBufferUint8(outputShape);
            break;
          case TensorType.int8:
            outputBuffer = _createOutputBufferInt8(outputShape);
            break;
          case TensorType.float32:
          default:
            outputBuffer = _createOutputBufferFloat32(outputShape);
            break;
        }

        interpreter!.run(input, outputBuffer);

        final outList = _flattenToDoubleList(outputBuffer);
        final nPreds = outputElements ~/ 84;
        final detections = parseYoloOutput(outList, numPredictions: nPreds);
        mainSendPort.send(InferenceOutput(detections: detections));
      } catch (e) {
        mainSendPort.send(InferenceOutput(detections: [], error: e.toString()));
      }
    }
  });
}

Object _createOutputBufferFloat32(List<int> shape) {
  if (shape.length == 3) {
    return List.generate(
      shape[0],
      (_) => List.generate(
        shape[1],
        (_) => List<double>.filled(shape[2], 0.0),
      ),
    );
  }
  return Float32List(shape.fold(1, (a, b) => a * b));
}

Object _createOutputBufferInt8(List<int> shape) {
  if (shape.length == 3) {
    return List.generate(
      shape[0],
      (_) => List.generate(
        shape[1],
        (_) => List<int>.filled(shape[2], 0),
      ),
    );
  }
  return Int8List(shape.fold(1, (a, b) => a * b));
}

Object _createOutputBufferUint8(List<int> shape) {
  if (shape.length == 3) {
    return List.generate(
      shape[0],
      (_) => List.generate(
        shape[1],
        (_) => List<int>.filled(shape[2], 0),
      ),
    );
  }
  return Uint8List(shape.fold(1, (a, b) => a * b));
}

List<double> _flattenToDoubleList(Object output) {
  final result = <double>[];
  void walk(Object? node) {
    if (node is List) {
      for (final item in node) {
        walk(item);
      }
      return;
    }
    if (node is num) result.add(node.toDouble());
  }

  walk(output);
  return result;
}
