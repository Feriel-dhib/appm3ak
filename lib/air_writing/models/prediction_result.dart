class RankedPrediction {
  const RankedPrediction({
    required this.label,
    required this.confidence,
    required this.index,
  });

  final String label;
  final double confidence;
  final int index;
}

class PredictionResult {
  const PredictionResult({
    required this.top1,
    required this.topK,
    required this.accepted,
  });

  final RankedPrediction top1;
  final List<RankedPrediction> topK;
  final bool accepted;
}
