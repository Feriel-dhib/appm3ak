import 'dart:io';

import 'package:dio/dio.dart';

import '../api/api_client.dart';
import '../api/endpoints.dart';
import '../models/user_model.dart';
import '../../core/config/app_config.dart';
import '../../core/utils/profile_photo_rules.dart';

class UserRepository {
  UserRepository({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  /// Inscription (CreateUserDto) : nom, prenom, email, password, telephone, role + optionnels.
  Future<UserModel> register({
    required String nom,
    required String prenom,
    required String email,
    required String password,
    required String telephone,
    required String role,
    String? typeHandicap,
    String? besoinSpecifique,
    bool animalAssistance = false,
    String? typeAccompagnant,
    String? specialisation,
    String? langue,
  }) async {
    final body = <String, dynamic>{
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'password': password,
      'telephone': telephone,
      'role': role,
    };
    if (typeHandicap != null && typeHandicap.isNotEmpty) body['typeHandicap'] = typeHandicap;
    if (besoinSpecifique != null && besoinSpecifique.isNotEmpty) body['besoinSpecifique'] = besoinSpecifique;
    body['animalAssistance'] = animalAssistance;
    if (typeAccompagnant != null && typeAccompagnant.isNotEmpty) body['typeAccompagnant'] = typeAccompagnant;
    if (specialisation != null && specialisation.isNotEmpty) body['specialisation'] = specialisation;
    if (langue != null && langue.isNotEmpty) body['langue'] = langue;

    final response = await _api.dio.post(Endpoints.userRegister, data: body);
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Profil de l'utilisateur connecté.
  Future<UserModel> getMe() async {
    final response = await _api.dio.get(Endpoints.userMe);
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Dernière position connue (chauffeur / livetracking).
  Future<void> updateLocation(double latitude, double longitude) async {
    await _api.dio.patch(
      Endpoints.userMeLocation,
      data: {'latitude': latitude, 'longitude': longitude},
    );
  }

  /// Mise à jour du profil.
  Future<UserModel> updateMe({
    String? nom,
    String? prenom,
    String? telephone,
    String? typeHandicap,
    String? besoinSpecifique,
    bool? animalAssistance,
    String? typeAccompagnant,
    String? specialisation,
    bool? disponible,
    String? langue,
    /// URL absolue ou chemin `uploads/...` (sans multipart). Pour retirer la photo, préférer [deleteProfilePhoto].
    String? photoProfil,
  }) async {
    final body = <String, dynamic>{};
    if (nom != null) body['nom'] = nom;
    if (prenom != null) body['prenom'] = prenom;
    if (telephone != null) body['telephone'] = telephone;
    if (typeHandicap != null) body['typeHandicap'] = typeHandicap;
    if (besoinSpecifique != null) body['besoinSpecifique'] = besoinSpecifique;
    if (animalAssistance != null) body['animalAssistance'] = animalAssistance;
    if (typeAccompagnant != null) body['typeAccompagnant'] = typeAccompagnant;
    if (specialisation != null) body['specialisation'] = specialisation;
    if (disponible != null) body['disponible'] = disponible;
    if (langue != null) body['langue'] = langue;
    if (photoProfil != null) body['photoProfil'] = photoProfil;

    final response = await _api.dio.patch(Endpoints.userMe, data: body);
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Suppression du compte.
  Future<void> deleteMe() async {
    await _api.dio.delete(Endpoints.userMe);
  }

  /// Upload photo de profil (PATCH /user/me/photo, champ fichier `image`).
  Future<UserModel> updateProfilePhoto(File image) async {
    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(image.path),
    });
    final response = await _api.dio.patch(
      Endpoints.userMePhoto,
      data: formData,
    );
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Supprime la photo de profil (DELETE /user/me/photo).
  Future<UserModel> deleteProfilePhoto() async {
    final response = await _api.dio.delete(Endpoints.userMePhoto);
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return UserModel.fromJson(data);
    }
    return getMe();
  }

  /// URL d’affichage pour [UserModel.photoProfil] : http(s) tel quel, sinon `BASE_URL/uploads/...`.
  static String photoUrl(String? photoProfil) =>
      resolveProfilePhotoDisplayUrl(photoProfil, AppConfig.apiBaseUrl);
}
