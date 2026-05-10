import 'package:equatable/equatable.dart';

/// Résultat d'un géocodage (adresse → coordonnées) ou géocodage inverse.
class GeocodeResult extends Equatable {
  const GeocodeResult({
    required this.lat,
    required this.lon,
    required this.displayName,
    required this.type,
    this.address,
  });

  factory GeocodeResult.fromJson(Map<String, dynamic> json) {
    final addressRaw = json['address'];
    Map<String, String>? addressMap;
    if (addressRaw is Map) {
      addressMap = addressRaw.map((k, v) =>
          MapEntry(k.toString(), v?.toString() ?? ''));
    }
    final lat = json['lat'];
    final lon = json['lon'];
    return GeocodeResult(
      lat: lat is num ? lat.toDouble() : double.tryParse(lat?.toString() ?? '') ?? 0.0,
      lon: lon is num ? lon.toDouble() : double.tryParse(lon?.toString() ?? '') ?? 0.0,
      displayName: json['displayName']?.toString() ?? json['display_name']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      address: addressMap,
    );
  }

  final double lat;
  final double lon;
  final String displayName;
  final String type;
  final Map<String, String>? address;

  @override
  List<Object?> get props => [lat, lon, displayName, type];
}
