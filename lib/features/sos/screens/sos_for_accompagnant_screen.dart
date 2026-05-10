import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/sos_providers.dart';

class SosForAccompagnantScreen extends ConsumerWidget {
  const SosForAccompagnantScreen({super.key});

  String _fmtDate(DateTime? dt) {
    if (dt == null) return 'Date inconnue';
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$d/$m/$y - $hh:$mm';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(sosAlertsForAccompagnantProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('SOS recus (accompagnant)'),
        actions: [
          IconButton(
            tooltip: 'Actualiser',
            onPressed: () =>
                ref.invalidate(sosAlertsForAccompagnantProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: alertsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 44),
                const SizedBox(height: 12),
                Text(
                  error.toString().replaceFirst('Exception: ', ''),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => ref.invalidate(sosAlertsForAccompagnantProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reessayer'),
                ),
              ],
            ),
          ),
        ),
        data: (alerts) {
          if (alerts.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Aucune alerte SOS recue pour le moment.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(sosAlertsForAccompagnantProvider);
              await ref.read(sosAlertsForAccompagnantProvider.future);
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemBuilder: (_, i) {
                final a = alerts[i];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.emergency, color: Colors.red),
                    title: Text(
                      '${a.latitude.toStringAsFixed(5)}, ${a.longitude.toStringAsFixed(5)}',
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 4),
                        Text('Statut: ${a.statut ?? 'EN_ATTENTE'}'),
                        if (a.alertSource != null && a.alertSource!.isNotEmpty)
                          Text('Source: ${a.alertSource}'),
                        if (a.voiceLabelFr != null && a.voiceLabelFr!.isNotEmpty)
                          Text(
                            'Voix: ${a.voiceLabelFr} (${a.voiceScore?.toStringAsFixed(0) ?? '-'}%)',
                          ),
                        Text('Cree le: ${_fmtDate(a.createdAt)}'),
                      ],
                    ),
                    isThreeLine: true,
                  ),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemCount: alerts.length,
            ),
          );
        },
      ),
    );
  }
}
