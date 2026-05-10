import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/token_storage_service.dart';
import '../data/api/api_client.dart';
import '../data/repositories/emergency_contacts_repository.dart';
import '../data/repositories/health_chat_repository.dart';
import '../data/repositories/medical_records_repository.dart';
import '../data/repositories/notifications_repository.dart';
import '../data/repositories/safety_repository.dart';
import '../data/repositories/relations_repository.dart';
import '../data/repositories/sos_repository.dart';
import '../data/repositories/transport_repository.dart';
import '../data/repositories/map_repository.dart';
import '../data/repositories/medical_documents_repository.dart';
import '../data/repositories/vehicle_repository.dart';
import '../data/repositories/vehicle_reservation_repository.dart';
import '../data/local_companion_medical_qr_store.dart';
import '../data/local_medical_documents_store.dart';
import '../data/local_medical_record_store.dart';

final tokenStorageProvider = Provider<TokenStorageService>((ref) {
  return TokenStorageService();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.watch(tokenStorageProvider);
  return ApiClient(getAccessToken: storage.getToken);
});

final emergencyContactsRepositoryProvider =
    Provider<EmergencyContactsRepository>((ref) {
      return EmergencyContactsRepository(
        apiClient: ref.watch(apiClientProvider),
      );
    });

final medicalRecordsRepositoryProvider = Provider<MedicalRecordsRepository>((
  ref,
) {
  return MedicalRecordsRepository(apiClient: ref.watch(apiClientProvider));
});

final healthChatRepositoryProvider = Provider<HealthChatRepository>((ref) {
  return HealthChatRepository(apiClient: ref.watch(apiClientProvider));
});

final safetyRepositoryProvider = Provider<SafetyRepository>((ref) {
  return SafetyRepository(apiClient: ref.watch(apiClientProvider));
});

final relationsRepositoryProvider = Provider<RelationsRepository>((ref) {
  return RelationsRepository(apiClient: ref.watch(apiClientProvider));
});

final sosRepositoryProvider = Provider<SosRepository>((ref) {
  return SosRepository(apiClient: ref.watch(apiClientProvider));
});

final transportRepositoryProvider = Provider<TransportRepository>((ref) {
  return TransportRepository(apiClient: ref.watch(apiClientProvider));
});

/// Incrémenter pour recharger hub transport, demandes chauffeur, etc. après synchro réservation ↔ course.
final transportUiRefreshProvider = StateProvider<int>((ref) => 0);

final vehicleRepositoryProvider = Provider<VehicleRepository>((ref) {
  return VehicleRepository(apiClient: ref.watch(apiClientProvider));
});

final vehicleReservationRepositoryProvider =
    Provider<VehicleReservationRepository>((ref) {
      return VehicleReservationRepository(
        apiClient: ref.watch(apiClientProvider),
      );
    });

final mapRepositoryProvider = Provider<MapRepository>((ref) {
  return MapRepository(apiClient: ref.watch(apiClientProvider));
});

final notificationsRepositoryProvider = Provider<NotificationsRepository>((
  ref,
) {
  return NotificationsRepository(apiClient: ref.watch(apiClientProvider));
});

final localMedicalRecordStoreProvider = Provider<LocalMedicalRecordStore>((
  ref,
) {
  return LocalMedicalRecordStore();
});

final localCompanionMedicalQrStoreProvider =
    Provider<LocalCompanionMedicalQrStore>((ref) {
      return LocalCompanionMedicalQrStore();
    });

final localMedicalDocumentsStoreProvider = Provider<LocalMedicalDocumentsStore>(
  (ref) {
    return LocalMedicalDocumentsStore();
  },
);

final medicalDocumentsRepositoryProvider = Provider<MedicalDocumentsRepository>(
  (ref) {
    return MedicalDocumentsRepository(apiClient: ref.watch(apiClientProvider));
  },
);
