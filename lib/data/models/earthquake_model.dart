import 'package:earthquake_alert/core/utils/date_formatter.dart';

class Earthquake {
  final String id;
  final DateTime date; // UTC (parseQuakeDate ile normalize)
  final double latitude;
  final double longitude;
  final double depth; // km
  final double magnitude;
  final String location; // başlık/yer adı
  final String? city;
  final String? district;

  Earthquake({
    required this.id,
    required this.date,
    required this.latitude,
    required this.longitude,
    required this.depth,
    required this.magnitude,
    required this.location,
    this.city,
    this.district,
  });

  factory Earthquake.fromJson(Map<String, dynamic> json) {
    // --- Tarih ---
    // Orhan Aydoğdu (Kandilli) tipik tarih alanı: "date": "2025.08.27 14:12:36"
    final rawDate = (json['date'] ??
            json['datetime'] ??
            json['eventDate'] ??
            json['time'] ??
            json['date_time'])
        ?.toString();

    final dt = parseQuakeDate(rawDate ?? '');

    // --- Koordinatlar ---
    // Bazı API'lar 'lng' yerine 'lon' kullanır, GeoJSON için coordinates[lon, lat]
    final dynamic latRaw = json['lat'] ??
        json['latitude'] ??
        (json['geojson']?['coordinates']?[1]);
    final dynamic lonRaw = json['lng'] ??
        json['lon'] ??
        json['longitude'] ??
        (json['geojson']?['coordinates']?[0]);

    final lat = _asDouble(latRaw);
    final lon = _asDouble(lonRaw);

    // --- Derinlik & Büyüklük ---
    final depth = _asDouble(json['depth'] ?? json['depth_km']);
    final mag = _asDouble(json['mag'] ?? json['magnitude']);

    // --- Konum/başlık ---
    final title =
        (json['title'] ?? json['place'] ?? json['location'] ?? '').toString();

    // --- Şehir/ilçe (opsiyonel) ---
    final city = json['city']?.toString();
    final district = json['district']?.toString();

    // --- ID ---
    final String id = (json['earthquake_id'] ??
            json['id'] ??
            '${dt.millisecondsSinceEpoch}_${lat}_$lon')
        .toString();

    return Earthquake(
      id: id,
      date: dt,
      latitude: lat,
      longitude: lon,
      depth: depth,
      magnitude: mag,
      location: title,
      city: city,
      district: district,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'earthquake_id': id,
      'date': date.toIso8601String(), // UTC ISO
      'lat': latitude,
      'lng': longitude,
      'depth': depth,
      'mag': magnitude,
      'title': location,
      'city': city,
      'district': district,
    };
  }
}

/// String/num → double güvenli dönüştürme
double _asDouble(dynamic v, {double fallback = 0.0}) {
  if (v == null) return fallback;
  if (v is num) return v.toDouble();
  final s = v.toString().trim();
  if (s.isEmpty) return fallback;
  // virgül ile gelen büyüklük/değerler için
  final normalized = s.replaceAll(',', '.');
  return double.tryParse(normalized) ?? fallback;
}
