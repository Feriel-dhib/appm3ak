import 'dart:typed_data';

import 'package:tflite_flutter/tflite_flutter.dart';

/// Resultat de prediction d'un caractere.
class PredictionResult {
  const PredictionResult({
    required this.label,
    required this.confidence,
    required this.index,
  });

  final String label;
  final double confidence;
  final int index;
}

/// Charge et execute le modele TFLite de reconnaissance air writing.
class AirWritingPredictor {
  AirWritingPredictor({
    this.modelAssetPath = 'assets/models/air_writing.tflite',
    this.confidenceThreshold = 0.40,
  });

  final String modelAssetPath;
  final double confidenceThreshold;

  Interpreter? _interpreter;

  static const List<String> _labels = <String>[
    '0',
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
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

  Future<void> load() async {
    if (_interpreter != null) {
      return;
    }
    final InterpreterOptions options = InterpreterOptions()..threads = 2;
    _interpreter = await Interpreter.fromAsset(modelAssetPath, options: options);
  }

  Future<void> dispose() async {
    _interpreter?.close();
    _interpreter = null;
  }

  /// Execute l'inference et filtre les predictions peu confiantes.
  PredictionResult? predict(Float32List input784) {
    final Interpreter? interpreter = _interpreter;
    if (interpreter == null || input784.length != 28 * 28) {
      return null;
    }

    final List<List<List<List<double>>>> input = <List<List<List<double>>>>[
      List<List<List<double>>>.generate(
        28,
        (int y) => List<List<double>>.generate(
          28,
          (int x) => <double>[input784[(y * 28) + x]],
        ),
      ),
    ];

    final List<List<double>> output = <List<double>>[
      List<double>.filled(_labels.length, 0.0),
    ];

    interpreter.run(input, output);

    final List<double> probs = output.first;
    int bestIndex = 0;
    double bestScore = probs.first;
    for (int i = 1; i < probs.length; i++) {
      if (probs[i] > bestScore) {
        bestScore = probs[i];
        bestIndex = i;
      }
    }
    if (bestScore < confidenceThreshold) {
      return null;
    }
    return PredictionResult(
      label: _labels[bestIndex],
      confidence: bestScore,
      index: bestIndex,
    );
  }

  /// Expose les labels pour debug/telemetrie.
  List<String> get labels => List<String>.unmodifiable(_labels);
}
