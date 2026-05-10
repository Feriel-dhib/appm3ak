class SttResponse {
  const SttResponse({required this.text});

  factory SttResponse.fromJson(Map<String, dynamic> json) {
    return SttResponse(text: json['text']?.toString() ?? '');
  }

  final String text;
}
