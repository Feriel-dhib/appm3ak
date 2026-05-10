import '../../data/models/user_model.dart';
import '../../data/models/vehicle.dart';

/// Permissions de modification d'un véhicule selon le rôle de l'utilisateur.
class VehicleEditPermissions {
  const VehicleEditPermissions({
    required this.canEditAll,
    required this.canEditStatus,
    required this.canEdit,
  });

  final bool canEditAll; // Propriétaire ou Admin : modifier tout
  final bool canEditStatus; // Chauffeur solidaire ou canEditAll : modifier uniquement le statut
  final bool canEdit; // Au moins une permission

  /// Détermine les permissions de modification pour un véhicule donné.
  static VehicleEditPermissions fromUserAndVehicle(UserModel user, Vehicle vehicle) {
    final isOwner = vehicle.ownerId == user.id;
    final isAdmin = user.role == UserRole.admin;
    final isChauffeurSolidaire = user.isChauffeurSolidaire;

    final canEditAll = isOwner || isAdmin;
    final canEditStatus = canEditAll || isChauffeurSolidaire;

    return VehicleEditPermissions(
      canEditAll: canEditAll,
      canEditStatus: canEditStatus,
      canEdit: canEditStatus,
    );
  }

  /// Vérifie si l'utilisateur peut modifier uniquement le statut (sans modifier les autres champs).
  bool get canOnlyEditStatus => canEditStatus && !canEditAll;
}
