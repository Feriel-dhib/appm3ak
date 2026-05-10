import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/notification_model.dart';
import '../../../providers/api_providers.dart';

/// Liste des notifications (SOS, risque, médicament, etc.).
class NotificationsListScreen extends ConsumerStatefulWidget {
  const NotificationsListScreen({super.key});

  @override
  ConsumerState<NotificationsListScreen> createState() =>
      _NotificationsListScreenState();
}

class _NotificationsListScreenState extends ConsumerState<NotificationsListScreen> {
  List<NotificationModel> _items = [];
  int _unreadCount = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(notificationsRepositoryProvider);
      final page = await repo.getMine(page: 1, limit: 50);
      if (mounted) {
        setState(() {
          _items = page.data;
          _unreadCount = page.unreadCount;
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _markRead(NotificationModel n) async {
    if (n.lu) return;
    try {
      final repo = ref.read(notificationsRepositoryProvider);
      await repo.markRead(n.id);
      await _load();
    } catch (_) {}
  }

  Future<void> _markAllRead() async {
    try {
      final repo = ref.read(notificationsRepositoryProvider);
      await repo.markAllRead();
      await _load();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllRead,
              child: const Text('Tout marquer lu'),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? Center(
                  child: Text(
                    'Aucune notification',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _items.length,
                    itemBuilder: (_, i) {
                      final n = _items[i];
                      return Card(
                        color: n.lu
                            ? null
                            : theme.colorScheme.surfaceContainerHighest,
                        child: ListTile(
                          leading: Icon(
                            _iconForType(n.type),
                            color: theme.colorScheme.primary,
                          ),
                          title: Text(n.titre ?? 'Notification'),
                          subtitle: n.message != null
                              ? Text(
                                  n.message!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                )
                              : null,
                          trailing: n.lu
                              ? null
                              : IconButton(
                                  icon: const Icon(Icons.check_circle_outline),
                                  onPressed: () => _markRead(n),
                                  tooltip: 'Marquer comme lu',
                                ),
                          onTap: () => _markRead(n),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  IconData _iconForType(String? type) {
    switch (type) {
      case 'SOS_URGENCE':
        return Icons.emergency;
      case 'RISQUE':
        return Icons.warning_amber;
      case 'MEDICATION_ALERT':
        return Icons.medication;
      default:
        return Icons.notifications;
    }
  }
}
