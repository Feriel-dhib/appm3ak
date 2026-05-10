import 'package:dio/dio.dart';

import '../api/api_client.dart';
import '../api/endpoints.dart';
import '../models/auth_response.dart';
import '../../core/services/token_storage_service.dart';

class AuthRepository {
  AuthRepository({
    required ApiClient apiClient,
    required TokenStorageService tokenStorage,
  })  : _api = apiClient,
        _storage = tokenStorage;

  final ApiClient _api;
  final TokenStorageService _storage;

  Future<String?> getStoredToken() => _storage.getToken();

  Future<void> _saveToken(String token) => _storage.saveToken(token);

  Future<void> _clearToken() => _storage.clearToken();

  /// Vérifie si un token est stocké (utilisateur potentiellement connecté).
  Future<bool> hasStoredToken() async {
    final token = await getStoredToken();
    return token != null && token.isNotEmpty;
  }

  /// Login email/password.
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _api.dio.post(
        Endpoints.authLogin,
        data: {'email': email, 'password': password},
      );
      final auth = AuthResponse.fromJson(response.data as Map<String, dynamic>);
      await _saveToken(auth.accessToken);
      return auth;
    } on DioException catch (e) {
      // Extraire le message d'erreur du backend
      String errorMessage = 'Email ou mot de passe incorrect';
      if (e.response != null && e.response!.data is Map) {
        final data = e.response!.data as Map<String, dynamic>;
        errorMessage = data['message']?.toString() ?? errorMessage;
      }
      throw Exception(errorMessage);
    } catch (e) {
      // Si c'est déjà une Exception avec message, la relancer
      if (e is Exception) rethrow;
      throw Exception('Erreur lors de la connexion');
    }
  }

  /// Login Google via id_token.
  Future<AuthResponse> loginWithGoogle({required String idToken}) async {
    final response = await _api.dio.post(
      Endpoints.authGoogle,
      data: {'id_token': idToken},
    );
    final auth = AuthResponse.fromJson(response.data as Map<String, dynamic>);
    await _saveToken(auth.accessToken);
    return auth;
  }

  /// Déconnexion : supprime le token local.
  Future<void> logout() => _clearToken();

  /// Vérifie la configuration backend (JWT, Google).
  Future<Map<String, bool>> checkConfig() async {
    try {
      final response = await _api.dio.get(Endpoints.authConfigTest);
      final data = response.data as Map<String, dynamic>;
      return {
        'jwtSecretConfigured': data['jwtSecretConfigured'] as bool? ?? false,
        'googleClientIdConfigured':
            data['googleClientIdConfigured'] as bool? ?? false,
      };
    } catch (_) {
      return {'jwtSecretConfigured': false, 'googleClientIdConfigured': false};
    }
  }
}
