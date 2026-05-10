import '../api/api_client.dart';
import '../api/endpoints.dart';
import '../models/user_model.dart';

/// Service utilisateur pour le profil « animal d'assistance » (Provider / UI dédiée).
///
/// **Exemple** :
/// ```dart
/// final service = UserService(apiClient: ref.read(apiClientProvider));
/// final me = await service.fetchCurrentUser();
/// await service.updateAnimalAssistance(
///   animalAssistance: true,
///   animalType: 'chien',
///   animalName: 'Rex',
///   animalNotes: 'chien guide',
/// );
/// ```
class UserService {
  UserService({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  /// Profil courant (même source que l’app : `/user/me`).
  Future<UserModel> fetchCurrentUser() async {
    final response = await _api.dio.get(Endpoints.userMe);
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Mise à jour des champs animal d’assistance (`PUT /users/animal`).
  Future<UserModel> updateAnimalAssistance({
    required bool animalAssistance,
    String? animalType,
    String? animalName,
    String? animalNotes,
  }) async {
    final Map<String, dynamic> body;
    if (!animalAssistance) {
      body = {
        'animalAssistance': false,
        'animalType': null,
        'animalName': null,
        'animalNotes': null,
      };
    } else {
      body = {
        'animalAssistance': true,
        'animalType': animalType,
        'animalName': animalName,
        'animalNotes': animalNotes ?? '',
      };
    }
    final response = await _api.dio.put(Endpoints.usersAnimal, data: body);
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return UserModel.fromJson(data);
    }
    return fetchCurrentUser();
  }
}
