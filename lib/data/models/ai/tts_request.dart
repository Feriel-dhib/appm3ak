class TtsRequest {
  const TtsRequest({required this.text});

  final String text;

  Map<String, dynamic> toJson() => {'text': text};
}
