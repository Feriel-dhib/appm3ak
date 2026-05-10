import 'dart:typed_data';

import 'package:tflite_flutter/tflite_flutter.dart';

import '../models/prediction_result.dart';

/// Labels alignés sur `predictor.py` (MNIST / EMNIST letters / 36 / balanced 47).
List<String> _labelsForClassCount(int numClasses) {
  const digits = <String>['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
  const letters = <String>[
    'A',
    'B',
    'C',
    'D',
    'E',
    'F',
    'G',
    'H',
    'I',
    'J',
    'K',
    'L',
    'M',
    'N',
    'O',
    'P',
    'Q',
    'R',
    'S',
    'T',
    'U',
    'V',
    'W',
    'X',
    'Y',
    'Z',
  ];
  const emnistBalancedLower = <String>[
    'a',
    'b',
    'd',
    'e',
    'f',
    'g',
    'h',
    'n',
    'q',
    'r',
    't',
  ];
  switch (numClasses) {
    case 10:
      return List<String>.from(digits);
    case 26:
      return List<String>.from(letters);
    case 36:
      return <String>[...digits, ...letters];
    case 47:
      return <String>[...digits, ...letters, ...emnistBalancedLower];
    default:
      return List<String>.generate(numClasses, (i) => '#$i');
  }
}

class TfliteService {
  TfliteService({
    this.modelAssetPath = 'assets/models/air_writing.tflite',
  });

  final String modelAssetPath;
  Interpreter? _interpreter;
  List<String> _labels = const <String>[];

  List<String> get labels => List<String>.unmodifiable(_labels);

  Future<void> load() async {
    if (_interpreter != null) return;

    Object? lastError;
    Interpreter? created;

    Future<void> tryOpen(InterpreterOptions? options) async {
      try {
        created = options != null
            ? await Interpreter.fromAsset(modelAssetPath, options: options)
            : await Interpreter.fromAsset(modelAssetPath);
      } catch (e) {
        lastError = e;
        created = null;
      }
    }

    final opt2 = InterpreterOptions()..threads = 2;
    try {
      await tryOpen(opt2);
    } finally {
      opt2.delete();
    }
    if (created != null) {
      _bindInterpreter(created!);
      return;
    }

    final opt1 = InterpreterOptions()..threads = 1;
    try {
      await tryOpen(opt1);
    } finally {
      opt1.delete();
    }
    if (created != null) {
      _bindInterpreter(created!);
      return;
    }

    await tryOpen(null);
    if (created != null) {
      _bindInterpreter(created!);
      return;
    }

    throw ArgumentError(
      'Modèle TFLite introuvable ou incompatible (interpréteur). '
      'Sur le poste de build : flutter clean && flutter pub get && '
      '(iOS) cd ios && pod install. '
      'Vérifiez que tflite_flutter est en 0.12+ et que $modelAssetPath est bien présent. '
      'Détail : ${lastError ?? "inconnu"}',
    );
  }

  void _bindInterpreter(Interpreter interpreter) {
    final outShape = interpreter.getOutputTensor(0).shape;
    final numClasses = outShape.last;
    _labels = _labelsForClassCount(numClasses);
    _interpreter = interpreter;
  }

  PredictionResult? predict(
    Float32List input784, {
    required double minConfidence,
    int topK = 3,
  }) {
    final interpreter = _interpreter;
    if (interpreter == null || input784.length != 28 * 28) {
      return null;
    }
    if (_labels.isEmpty) return null;

    final input = <List<List<List<double>>>>[
      List<List<List<double>>>.generate(
        28,
        (y) => List<List<double>>.generate(
          28,
          (x) => <double>[input784[(y * 28) + x]],
        ),
      ),
    ];
    final output = <List<double>>[List<double>.filled(_labels.length, 0.0)];
    interpreter.run(input, output);
    final probs = output.first;

    final rankedIndices = List<int>.generate(probs.length, (i) => i)
      ..sort((a, b) => probs[b].compareTo(probs[a]));

    final safeK = topK.clamp(1, probs.length);
    final ranked = rankedIndices
        .take(safeK)
        .map(
          (i) => RankedPrediction(
            label: _labels[i],
            confidence: probs[i],
            index: i,
          ),
        )
        .toList(growable: false);
    final top1 = ranked.first;
    return PredictionResult(
      top1: top1,
      topK: ranked,
      accepted: top1.confidence >= minConfidence,
    );
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _labels = const [];
  }
}
