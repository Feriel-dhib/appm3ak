class AiHealthResponse {
  const AiHealthResponse({required this.status});

  factory AiHealthResponse.fromJson(Map<String, dynamic> json) {
    return AiHealthResponse(status: json['status']?.toString() ?? '');
  }

  final String status;

  bool get isOk => status.toLowerCase() == 'ok';
}
