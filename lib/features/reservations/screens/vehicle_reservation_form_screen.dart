import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/utils/geolocation_utils.dart';
import '../../../core/widgets/address_search_field.dart';
import '../../../core/widgets/ma3ak_map_widget.dart';
import '../../map/screens/map_picker_screen.dart';
import '../../../data/models/map/geocode_result.dart';
import '../../../data/models/map/route_result.dart';
import '../../../data/models/vehicle.dart';
import '../../../data/models/vehicle_reservation.dart';
import '../../../data/models/vehicle_reservation_statut.dart';
import '../../../providers/auth_providers.dart';
import '../../../providers/api_providers.dart';
import '../../../providers/vehicle_reservation_providers.dart';
import '../../../providers/vehicle_providers.dart';

/// Formulaire de création de réservation (bénéficiaire ou accompagnant).
class VehicleReservationFormScreen extends ConsumerStatefulWidget {
  const VehicleReservationFormScreen({
    super.key,
    this.vehicleId,
  });

  final String? vehicleId;

  @override
  ConsumerState<VehicleReservationFormScreen> createState() =>
      _VehicleReservationFormScreenState();
}

class _VehicleReservationFormScreenState
    extends ConsumerState<VehicleReservationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final _heureController = TextEditingController();
  final _lieuDepartController = TextEditingController();
  final _lieuDestinationController = TextEditingController();
  final _besoinsController = TextEditingController();
  bool _isLoading = false;
  double? _originLat;
  double? _originLon;
  double? _destLat;
  double? _destLon;
  RouteResult? _routeResult;
  bool _routeLoading = false;
  bool _gettingCurrentLocation = false;
  static const Color _primaryBlue = Color(0xFF1976D2);
  static const LatLng _tunisCenter = LatLng(36.8065, 10.1815);

  @override
  void dispose() {
    _heureController.dispose();
    _lieuDepartController.dispose();
    _lieuDestinationController.dispose();
    _besoinsController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) setState(() => _selectedDate = date);
  }

  Future<void> _pickTime(BuildContext context) async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (time != null) {
      setState(() {
        _selectedTime = time;
        _heureController.text = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _calculateRoute() async {
    final departureText = _lieuDepartController.text.trim();
    final destinationText = _lieuDestinationController.text.trim();
    if (departureText.isEmpty || destinationText.isEmpty) return;

    setState(() => _routeLoading = true);
    try {
      final repo = ref.read(mapRepositoryProvider);
      double originLat = _originLat ?? 0, originLon = _originLon ?? 0;
      double destLat = _destLat ?? 0, destLon = _destLon ?? 0;

      if (_originLat == null || _originLon == null) {
        final list = await repo.geocode(query: departureText, countrycodes: 'TN', limit: 1);
        if (list.isEmpty) throw Exception('Adresse de départ introuvable');
        originLat = list.first.lat;
        originLon = list.first.lon;
        if (mounted) setState(() { _originLat = originLat; _originLon = originLon; });
      }
      if (_destLat == null || _destLon == null) {
        final list = await repo.geocode(query: destinationText, countrycodes: 'TN', limit: 1);
        if (list.isEmpty) throw Exception('Adresse de destination introuvable');
        destLat = list.first.lat;
        destLon = list.first.lon;
        if (mounted) setState(() { _destLat = destLat; _destLon = destLon; });
      }

      final result = await repo.route(
        originLat: originLat,
        originLon: originLon,
        destinationLat: destLat,
        destinationLon: destLon,
      );
      if (mounted) setState(() { _routeResult = result; _routeLoading = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _routeLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final vehicleId = widget.vehicleId;
    if (vehicleId == null || vehicleId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppStrings.fr().vehicleNotAvailableForDate,
          ),
        ),
      );
      return;
    }

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppStrings.fromPreferredLanguage(
              ref.read(authStateProvider).valueOrNull?.preferredLanguage?.name,
            ).dateRequired,
          ),
        ),
      );
      return;
    }

    final heure = _heureController.text.trim();
    if (heure.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppStrings.fromPreferredLanguage(
              ref.read(authStateProvider).valueOrNull?.preferredLanguage?.name,
            ).timeRequired,
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = ref.read(authStateProvider).valueOrNull;
      if (user == null) throw Exception('Non connecté');

      final repo = ref.read(vehicleReservationRepositoryProvider);
      final reservation = VehicleReservation(
        id: '',
        userId: user.id,
        vehicleId: vehicleId,
        date: _selectedDate!,
        heure: heure,
        lieuDepart: _lieuDepartController.text.trim().isEmpty
            ? null
            : _lieuDepartController.text.trim(),
        lieuDestination: _lieuDestinationController.text.trim().isEmpty
            ? null
            : _lieuDestinationController.text.trim(),
        besoinsSpecifiques: _besoinsController.text.trim().isEmpty
            ? null
            : _besoinsController.text.trim(),
        statut: VehicleReservationStatut.enAttente,
      );

      final created = await repo.create(reservation);

      if (mounted) {
        ref.invalidate(myVehicleReservationsProvider);
        ref.read(transportUiRefreshProvider.notifier).state++;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppStrings.fromPreferredLanguage(user.preferredLanguage?.name)
                  .reservationCreated,
            ),
          ),
        );
        context.go('/vehicle-reservations/${created.id}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;
    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final strings = AppStrings.fromPreferredLanguage(user.preferredLanguage?.name);
    final theme = Theme.of(context);
    final vehicleId = widget.vehicleId;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.grey.shade700),
          onPressed: () => context.pop(),
        ),
        title: Text(
          strings.createReservation,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Section VÉHICULE CHOISI
              if (vehicleId != null)
                ref.watch(vehicleProvider(vehicleId)).when(
                      data: (vehicle) => _buildVehicleCard(vehicle, strings, theme),
                      loading: () => Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      ),
                      error: (_, __) => Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        color: Colors.red.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, color: Colors.red),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Erreur lors du chargement du véhicule',
                                  style: TextStyle(color: Colors.red.shade700),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
              if (vehicleId == null) ...[
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  color: Colors.orange.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            strings.isAr
                                ? 'اختر مركبة من الكتالوج ثم انقر على "حجز"'
                                : 'Choisissez un véhicule depuis le catalogue puis cliquez sur "Réserver".',
                            style: TextStyle(color: Colors.orange.shade900),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              const SizedBox(height: 20),
              // Date
              _buildDateField(strings, theme),
              const SizedBox(height: 16),
              // Heure
              _buildTimeField(strings, theme),
              const SizedBox(height: 16),
              // Lieu de départ
              _buildDepartureField(strings, theme),
              const SizedBox(height: 16),
              // Lieu de destination
              _buildDestinationField(strings, theme),
              const SizedBox(height: 16),
              // Carte : isolée avec ListenableBuilder (évite de reconstruire tout l’écran à chaque frappe → ANR).
              ListenableBuilder(
                listenable: Listenable.merge([
                  _lieuDepartController,
                  _lieuDestinationController,
                ]),
                builder: (context, _) => _buildRouteMapCard(strings, theme),
              ),
              const SizedBox(height: 16),
              // Besoins spécifiques
              _buildSpecificNeedsField(strings, theme),
              const SizedBox(height: 16),
              // Boîte d'information
              _buildInfoBox(strings, theme),
              const SizedBox(height: 24),
              // Bouton Enregistrer
              _buildSubmitButton(strings, theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVehicleCard(Vehicle vehicle, AppStrings strings, ThemeData theme) {
    final hasRamp = vehicle.accessibilite.rampeAcces;
    return Card(
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: EdgeInsets.zero,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image du véhicule
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: vehicle.photos.isNotEmpty
                  ? Image.network(
                      vehicle.photos.first,
                      width: 110,
                      height: 90,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          width: 110,
                          height: 90,
                          color: Colors.grey.shade200,
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                              strokeWidth: 2,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 110,
                        height: 90,
                        color: Colors.grey.shade200,
                        child: Icon(Icons.directions_car, color: Colors.grey.shade400, size: 40),
                      ),
                    )
                  : Container(
                      width: 110,
                      height: 90,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.directions_car, color: Colors.grey.shade400, size: 40),
                    ),
            ),
            const SizedBox(width: 16),
            // Informations du véhicule
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'VÉHICULE CHOISI',
                    style: TextStyle(
                      color: _primaryBlue,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    vehicle.displayName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (hasRamp)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle, color: Colors.green.shade700, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'Accès fauteuil roulant',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Text(
                          'Tarif estimé : 15.000 DT/km',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          context.push('/home?tab=2');
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Modifier',
                          style: TextStyle(
                            color: _primaryBlue,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateField(AppStrings strings, ThemeData theme) {
    return InkWell(
      onTap: () => _pickDate(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: _primaryBlue, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Date *',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _selectedDate != null
                        ? '${_selectedDate!.day.toString().padLeft(2, '0')}/${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.year}'
                        : 'mm/dd/yyyy',
                    style: TextStyle(
                      fontSize: 16,
                      color: _selectedDate != null ? Colors.black87 : Colors.grey.shade400,
                      fontWeight: _selectedDate != null ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.calendar_today, color: Colors.grey.shade400, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeField(AppStrings strings, ThemeData theme) {
    return InkWell(
      onTap: () => _pickTime(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(Icons.access_time, color: _primaryBlue, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Heure *',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _heureController.text.isNotEmpty ? _heureController.text : '--:--',
                    style: TextStyle(
                      fontSize: 16,
                      color: _heureController.text.isNotEmpty ? Colors.black87 : Colors.grey.shade400,
                      fontWeight: _heureController.text.isNotEmpty ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.access_time, color: Colors.grey.shade400, size: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _setDepartureToCurrentLocation(AppStrings strings) async {
    setState(() => _gettingCurrentLocation = true);
    try {
      final user = ref.read(authStateProvider).valueOrNull;
      late final double lat;
      late final double lon;
      String? infoSnack;

      try {
        final position = await resolveUserPosition();
        final gLat = position.latitude;
        final gLon = position.longitude;
        final adj = preferTunisiaProfileWhenGpsMismatch(
          gpsLat: gLat,
          gpsLon: gLon,
          profileLat: user?.latitude,
          profileLon: user?.longitude,
        );
        lat = adj.lat;
        lon = adj.lon;
        if (adj.lat != gLat || adj.lon != gLon) {
          infoSnack = strings.usedProfileLocationInsteadOfGps;
        }
      } on GeolocationError catch (e) {
        if (!mounted) return;
        if (e == GeolocationError.permissionDenied) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'L\'accès à la position est nécessaire. Activez-la dans les paramètres.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
        final fb = profileCoordinatesFallback(user?.latitude, user?.longitude);
        if (fb != null &&
            (e == GeolocationError.timeout ||
                e == GeolocationError.serviceDisabled)) {
          lat = fb.lat;
          lon = fb.lon;
          infoSnack = strings.usedSavedCoordinatesWhenGpsUnavailable;
        } else {
          final msg = switch (e) {
            GeolocationError.serviceDisabled =>
              'Activez la localisation (GPS) et réessayez.',
            GeolocationError.timeout =>
              'Délai dépassé. Réessayez ou choisissez l\'adresse sur la carte.',
            GeolocationError.permissionDenied => '',
          };
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg), backgroundColor: Colors.orange),
          );
          return;
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().contains('disabled')
                  ? 'Activez le GPS et réessayez.'
                  : 'Impossible d\'obtenir la position.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final repo = ref.read(mapRepositoryProvider);
      final result = await repo.reverseGeocodeGet(lat: lat, lon: lon);
      if (!mounted) return;
      if (result != null) {
        _lieuDepartController.text = result.displayName;
        setState(() {
          _originLat = result.lat;
          _originLon = result.lon;
          _routeResult = null;
        });
      }
      if (infoSnack != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(infoSnack),
            backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().contains('disabled')
                ? 'Activez le GPS et réessayez.'
                : 'Impossible de récupérer l\'adresse pour cette position.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
    } finally {
      if (mounted) setState(() => _gettingCurrentLocation = false);
    }
  }

  Future<void> _pickPlaceOnMap(BuildContext context, bool isDeparture, AppStrings strings) async {
    final result = await Navigator.of(context).push<GeocodeResult>(
      MaterialPageRoute(
        builder: (_) => MapPickerScreen(
          title: isDeparture ? strings.departurePlace : strings.destinationPlace,
        ),
      ),
    );
    if (result == null || !mounted) return;
    if (isDeparture) {
      _lieuDepartController.text = result.displayName;
      setState(() {
        _originLat = result.lat;
        _originLon = result.lon;
        _routeResult = null;
      });
    } else {
      _lieuDestinationController.text = result.displayName;
      setState(() {
        _destLat = result.lat;
        _destLon = result.lon;
        _routeResult = null;
      });
    }
  }

  Widget _buildDepartureField(AppStrings strings, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AddressSearchField(
          controller: _lieuDepartController,
          label: strings.departurePlace,
          hint: strings.enterDepartureAddress,
          countrycodes: 'TN',
          limit: 5,
          onSelected: (r) {
            if (r != null) {
              setState(() {
                _originLat = r.lat;
                _originLon = r.lon;
                _routeResult = null;
              });
            } else {
              setState(() { _originLat = null; _originLon = null; _routeResult = null; });
            }
          },
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _gettingCurrentLocation ? null : () => _setDepartureToCurrentLocation(strings),
                icon: _gettingCurrentLocation
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(Icons.my_location, size: 20, color: _primaryBlue),
                label: Text(
                  strings.myCurrentLocation,
                  style: TextStyle(color: _primaryBlue, fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _primaryBlue,
                  side: BorderSide(color: _primaryBlue),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: () => _pickPlaceOnMap(context, true, strings),
              icon: Icon(Icons.map_outlined, size: 20, color: _primaryBlue),
              label: Text(strings.chooseOnMap, style: TextStyle(color: _primaryBlue, fontWeight: FontWeight.w500)),
              style: OutlinedButton.styleFrom(
                foregroundColor: _primaryBlue,
                side: BorderSide(color: _primaryBlue),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDestinationField(AppStrings strings, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AddressSearchField(
          controller: _lieuDestinationController,
          label: strings.destinationPlace,
          hint: strings.whereAreYouGoing,
          countrycodes: 'TN',
          limit: 5,
          onSelected: (r) {
            if (r != null) {
              setState(() {
                _destLat = r.lat;
                _destLon = r.lon;
                _routeResult = null;
              });
            } else {
              setState(() { _destLat = null; _destLon = null; _routeResult = null; });
            }
          },
        ),
        const SizedBox(height: 6),
        TextButton.icon(
          onPressed: () => _pickPlaceOnMap(context, false, strings),
          icon: Icon(Icons.map_outlined, size: 20, color: _primaryBlue),
          label: Text(strings.chooseOnMap, style: TextStyle(color: _primaryBlue, fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }

  Widget _buildRouteMapCard(AppStrings strings, ThemeData theme) {
    final hasDeparture = _lieuDepartController.text.isNotEmpty;
    final hasDestination = _lieuDestinationController.text.isNotEmpty;
    final canCalculate = hasDeparture && hasDestination;
    final origin = (_originLat != null && _originLon != null)
        ? LatLng(_originLat!, _originLon!)
        : null;
    final destination = (_destLat != null && _destLon != null)
        ? LatLng(_destLat!, _destLon!)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.blue.shade200, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                Ma3akMapWidget(
                  initialCenter: origin ?? destination ?? _tunisCenter,
                  initialZoom: 12,
                  origin: origin,
                  destination: destination,
                  routeResult: _routeResult,
                  height: 220,
                ),
                if (_routeLoading)
                  Positioned.fill(
                    child: Container(
                      color: Colors.white.withValues(alpha: 0.85),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 12,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                strings.calculatingRoute,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (_routeResult != null) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildRouteInfoChip(
                icon: Icons.straighten,
                label: '${strings.routeDistance} : ${_routeResult!.distanceFormatted}',
              ),
              _buildRouteInfoChip(
                icon: Icons.schedule,
                label: '${strings.routeDuration} : ${_routeResult!.durationFormatted}',
              ),
            ],
          ),
        ],
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: canCalculate && !_routeLoading ? _calculateRoute : null,
            icon: _routeLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Icon(
                    Icons.route,
                    color: canCalculate ? Colors.white : Colors.grey.shade400,
                    size: 20,
                  ),
            label: Text(
              _routeLoading
                  ? (strings.isAr ? 'جاري الحساب...' : 'Calcul en cours...')
                  : (canCalculate ? strings.calculateRoute : strings.fillAddressesFirst),
              style: TextStyle(
                color: canCalculate ? Colors.white : Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              disabledBackgroundColor: Colors.grey.shade200,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRouteInfoChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _primaryBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _primaryBlue.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: _primaryBlue),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade800)),
        ],
      ),
    );
  }

  Widget _buildSpecificNeedsField(AppStrings strings, ThemeData theme) {
    return TextFormField(
      controller: _besoinsController,
      maxLines: 4,
      decoration: InputDecoration(
        labelText: strings.specificNeeds,
        labelStyle: TextStyle(
          color: Colors.grey.shade600,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        hintText: 'Ex: aide pour le transfert, espace pour chien guide, oxygène...',
        hintStyle: TextStyle(color: Colors.grey.shade400),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _primaryBlue, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        alignLabelWithHint: true,
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildInfoBox(AppStrings strings, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: _primaryBlue, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Les réservations doivent être effectuées au moins 2 heures à l\'avance pour garantir la disponibilité du chauffeur accompagnateur.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(AppStrings strings, ThemeData theme) {
    final isEnabled = !_isLoading && widget.vehicleId != null;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: isEnabled ? _submit : null,
        icon: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.arrow_forward, color: Colors.white, size: 22),
        label: Text(
          _isLoading ? 'Enregistrement...' : 'Enregistrer la réservation',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
            letterSpacing: 0.5,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryBlue,
          padding: const EdgeInsets.symmetric(vertical: 18),
          elevation: 2,
          shadowColor: _primaryBlue.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          disabledBackgroundColor: Colors.grey.shade300,
          disabledForegroundColor: Colors.grey.shade600,
        ),
      ),
    );
  }
}
