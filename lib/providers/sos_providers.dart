import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/sos_alert_model.dart';
import 'api_providers.dart';

final sosAlertsForAccompagnantProvider =
    FutureProvider.autoDispose<List<SosAlertModel>>((ref) async {
  final repo = ref.watch(sosRepositoryProvider);
  return repo.getForAccompagnant();
});
