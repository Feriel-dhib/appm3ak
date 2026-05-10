import '../../core/errors/ai_module_exception.dart';
import '../models/ai/adapt_models.dart';
import '../repositories/ai_module_repository.dart';

/// Service applicatif minimal pour consommer le backend AI distant.
class AiModuleService {
  AiModuleService(this._repository);

  final AiModuleRepository _repository;

  Future<bool> getHealth() {
    return _repository.isHealthy();
  }

  /// Exemple demandé: `adaptUserType("blind")`.
  Future<AiInteractionMode> adaptUserType(String userType) async {
    final normalized = userType.trim().toLowerCase();
    final type = AiUserType.fromJson(normalized);
    if (type == null) {
      throw const AiModuleException(
        type: AiModuleErrorType.invalidPayload,
        message: 'user_type invalide. Valeurs attendues: blind, deaf, motor.',
      );
    }
    final response = await _repository.adaptForUserType(type);
    return response.mode;
  }
}
