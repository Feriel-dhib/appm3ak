class TtsResponse {
  const TtsResponse({required this.message});

  factory TtsResponse.fromJson(Map<String, dynamic> json) {
    return TtsResponse(message: json['message']?.toString() ?? '');
  }

  final String message;
}
