import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../providers/api_providers.dart';
import '../../../providers/auth_providers.dart';
import '../../../providers/transport_realtime_provider.dart';

/// Écran chauffeur : transitions de statut + envoi GPS toutes les 3 s après EN_ROUTE.
class DriverActiveRideScreen extends ConsumerStatefulWidget {
  const DriverActiveRideScreen({super.key, required this.rideId});

  final String rideId;

  @override
  ConsumerState<DriverActiveRideScreen> createState() => _DriverActiveRideScreenState();
}

class _DriverActiveRideScreenState extends ConsumerState<DriverActiveRideScreen> {
  bool _isLoading = false;

  static const Map<String, Map<String, String>> _transitions = {
    'ACCEPTEE': {'statut': 'EN_ROUTE', 'label': 'Démarrer le trajet'},
    'EN_ROUTE': {'statut': 'ARRIVEE', 'label': 'Je suis arrivé'},
    'ARRIVEE': {'statut': 'EN_COURS', 'label': 'Passager monté — Démarrer'},
    'EN_COURS': {'statut': 'TERMINEE', 'label': 'Terminer la course'},
  };

  Future<void> _startTracking(String rideId) async {
    final token = await ref.read(tokenStorageProvider).getToken() ?? '';
    final socket = ref.read(transportSocketProvider);

    socket.connect(AppConfig.baseUrl, token);
    socket.joinRide(rideId);

    ref.read(locationTimerProvider.notifier).state?.cancel();
    final timer = Timer.periodic(const Duration(seconds: 3), (_) async {
      try {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        socket.sendDriverLocation(rideId, pos.latitude, pos.longitude);
        await ref.read(userRepositoryProvider).updateLocation(
              pos.latitude,
              pos.longitude,
            );
      } catch (e) {
        debugPrint('[Driver] Erreur position : $e');
      }
    });
    ref.read(locationTimerProvider.notifier).state = timer;
  }

  void _stopTracking() {
    ref.read(locationTimerProvider.notifier).state?.cancel();
    ref.read(locationTimerProvider.notifier).state = null;
    ref.read(transportSocketProvider).disconnect();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final t = await ref.read(transportRepositoryProvider).findById(widget.rideId);
        if (t.statut != null) {
          ref.read(rideStatusProvider.notifier).state = t.statut!;
        }
      } catch (e) {
        debugPrint('[Driver] Chargement course : $e');
      }
    });
  }

  @override
  void dispose() {
    _stopTracking();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Course en cours'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Course ${widget.rideId}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 24),
            Consumer(
              builder: (context, ref, _) {
                final statut = ref.watch(rideStatusProvider);
                final transition = _transitions[statut];
                if (transition == null) {
                  return Text(
                    'Statut : $statut',
                    textAlign: TextAlign.center,
                  );
                }

                return Semantics(
                  label: transition['label']!,
                  button: true,
                  child: ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () async {
                            setState(() => _isLoading = true);
                            try {
                              await ref.read(transportRepositoryProvider).updateStatut(
                                    widget.rideId,
                                    transition['statut']!,
                                  );
                              ref.read(rideStatusProvider.notifier).state =
                                  transition['statut']!;
                              HapticFeedback.mediumImpact();

                              if (transition['statut'] == 'EN_ROUTE') {
                                await _startTracking(widget.rideId);
                              }
                              if (transition['statut'] == 'TERMINEE') {
                                _stopTracking();
                                if (context.mounted) context.go('/transport/history');
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(e.toString())),
                                );
                              }
                            } finally {
                              if (mounted) setState(() => _isLoading = false);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                      backgroundColor: const Color(0xFF7F77DD),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            transition['label']!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
