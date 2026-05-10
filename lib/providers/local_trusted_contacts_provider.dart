import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local_trusted_contacts_store.dart';
import '../data/models/local_trusted_contact.dart';

final localTrustedContactsProvider =
    StateNotifierProvider<LocalTrustedContactsNotifier, List<LocalTrustedContact>>(
  (ref) => LocalTrustedContactsNotifier(),
);

class LocalTrustedContactsNotifier extends StateNotifier<List<LocalTrustedContact>> {
  LocalTrustedContactsNotifier() : super(const []) {
    _load();
  }

  final _store = LocalTrustedContactsStore();

  Future<void> _load() async {
    state = await _store.load();
  }

  Future<void> refresh() => _load();

  Future<void> add({
    required String displayName,
    required String phone,
  }) async {
    final trimmedName = displayName.trim();
    final trimmedPhone = phone.trim().replaceAll(RegExp(r'\s'), '');
    if (trimmedName.isEmpty || trimmedPhone.isEmpty) return;

    final nextPriority = state.isEmpty
        ? 0
        : state.map((e) => e.priority).reduce((a, b) => a > b ? a : b) + 1;

    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final next = [
      ...state,
      LocalTrustedContact(
        id: id,
        displayName: trimmedName,
        phone: trimmedPhone,
        priority: nextPriority,
      ),
    ];
    await _store.save(next);
    state = next;
  }

  Future<void> remove(String id) async {
    final next = state.where((e) => e.id != id).toList();
    await _store.save(next);
    state = next;
  }
}
