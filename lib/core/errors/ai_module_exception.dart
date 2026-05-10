import 'package:dio/dio.dart';

enum AiModuleErrorType {
  unauthorized,
  timeout,
  offline,
  badRequest,
  payloadTooLarge,
  server,
  invalidPayload,
  unknown,
}

class AiModuleException implements Exception {
  const AiModuleException({
    required this.type,
    required this.message,
    this.statusCode,
    this.cause,
  });

  final AiModuleErrorType type;
  final String message;
  final int? statusCode;
  final Object? cause;

  factory AiModuleException.fromDio(DioException error) {
    final statusCode = error.response?.statusCode;
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return AiModuleException(
        type: AiModuleErrorType.timeout,
        message: 'Le service AI ne répond pas à temps.',
        statusCode: statusCode,
        cause: error,
      );
    }
    if (error.type == DioExceptionType.connectionError) {
      return AiModuleException(
        type: AiModuleErrorType.offline,
        message: 'Le service AI est indisponible.',
        statusCode: statusCode,
        cause: error,
      );
    }

    final serverMessage = _extractServerMessage(error.response?.data);
    if (statusCode == 400) {
      return AiModuleException(
        type: AiModuleErrorType.badRequest,
        message: serverMessage ?? 'Requête AI invalide.',
        statusCode: statusCode,
        cause: error,
      );
    }
    if (statusCode == 401) {
      return AiModuleException(
        type: AiModuleErrorType.unauthorized,
        message:
            serverMessage ??
            'Authentification AI refusee (401). Verifiez MA3AK_API_KEY et le header X-API-Key.',
        statusCode: statusCode,
        cause: error,
      );
    }
    if (statusCode == 404) {
      return AiModuleException(
        type: AiModuleErrorType.unknown,
        message: serverMessage ?? 'Endpoint ou modele IA introuvable (404).',
        statusCode: statusCode,
        cause: error,
      );
    }
    if (statusCode == 415) {
      return AiModuleException(
        type: AiModuleErrorType.badRequest,
        message:
            serverMessage ?? 'Format de fichier non supporte par le backend IA.',
        statusCode: statusCode,
        cause: error,
      );
    }
    if (statusCode == 413) {
      return AiModuleException(
        type: AiModuleErrorType.payloadTooLarge,
        message: 'Le fichier audio est trop volumineux.',
        statusCode: statusCode,
        cause: error,
      );
    }
    if (statusCode != null && statusCode >= 500) {
      return AiModuleException(
        type: AiModuleErrorType.server,
        message: serverMessage ?? 'Erreur interne du service AI.',
        statusCode: statusCode,
        cause: error,
      );
    }
    return AiModuleException(
      type: AiModuleErrorType.unknown,
      message: serverMessage ?? 'Erreur AI inconnue.',
      statusCode: statusCode,
      cause: error,
    );
  }

  static String? _extractServerMessage(Object? data) {
    if (data is Map<String, dynamic>) {
      return data['error']?.toString() ??
          data['message']?.toString() ??
          data['detail']?.toString();
    }
    return null;
  }

  @override
  String toString() => message;
}
