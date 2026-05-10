import '../api/api_client.dart';
import '../api/endpoints.dart';
import '../models/relation_model.dart';

class RelationsRepository {
  RelationsRepository({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  /// Créer une demande de liaison.
  /// Si l'utilisateur connecté est HANDICAPE : envoyer [accompagnantId].
  /// Si ACCOMPAGNANT : envoyer [handicapId].
  Future<RelationModel> create({
    String? accompagnantId,
    String? handicapId,
  }) async {
    final Map<String, String> body = {};
    if (accompagnantId != null && accompagnantId.isNotEmpty) {
      body['accompagnantId'] = accompagnantId;
    }
    if (handicapId != null && handicapId.isNotEmpty) {
      body['handicapId'] = handicapId;
    }
    final response = await _api.dio.post(
      Endpoints.relations,
      data: body,
    );
    return RelationModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Accepter une demande de liaison.
  Future<RelationModel> accept(String relationId) async {
    final response = await _api.dio.post(
      Endpoints.relationAccept(relationId),
    );
    return RelationModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Supprimer une liaison.
  Future<void> delete(String relationId) async {
    await _api.dio.delete(Endpoints.relationById(relationId));
  }

  /// Mes relations (toutes ou acceptées uniquement).
  Future<List<RelationModel>> getMyRelations({bool acceptedOnly = false}) async {
    final path = acceptedOnly
        ? '${Endpoints.relationsMe}?acceptedOnly=true'
        : Endpoints.relationsMe;
    final response = await _api.dio.get(path);
    final list = response.data as List<dynamic>? ?? [];
    return list
        .map((e) => RelationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Mes accompagnants (handicapé uniquement). Par défaut : acceptées uniquement.
  Future<List<RelationModel>> getMyAccompagnants({
    bool acceptedOnly = true,
  }) async {
    final path = acceptedOnly
        ? Endpoints.relationsMeAccompagnants
        : '${Endpoints.relationsMeAccompagnants}?acceptedOnly=false';
    final response = await _api.dio.get(path);
    final list = response.data as List<dynamic>? ?? [];
    return list
        .map((e) => RelationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Mes handicapés (accompagnant uniquement). Par défaut : acceptées uniquement.
  Future<List<RelationModel>> getMyHandicapes({
    bool acceptedOnly = true,
  }) async {
    final path = acceptedOnly
        ? Endpoints.relationsMeHandicapes
        : '${Endpoints.relationsMeHandicapes}?acceptedOnly=false';
    final response = await _api.dio.get(path);
    final list = response.data as List<dynamic>? ?? [];
    return list
        .map((e) => RelationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Détail d'une relation (handicapId et accompagnantId populés).
  Future<RelationModel> getById(String relationId) async {
    final response = await _api.dio.get(Endpoints.relationById(relationId));
    return RelationModel.fromJson(response.data as Map<String, dynamic>);
  }
}
