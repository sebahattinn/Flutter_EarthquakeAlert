import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

import '../../data/models/earthquake_model.dart';

class EarthquakeService {
  static const String apiUrl =
      'https://api.orhanaydogdu.com.tr/deprem/kandilli/live'; //kandilli api.

  Future<List<Earthquake>> fetchEarthquakes({int limit = 50}) async {
    try {
      final uri = Uri.parse('$apiUrl?limit=$limit');
      final response = await http.get(uri);

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final decoded = json.decode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Unexpected response shape');
      }

      // API -> genelde { status: true, result: [ ... ] }
      final List<dynamic> rawList = (decoded['result'] ??
          decoded['data'] ??
          decoded['events'] ??
          []) as List<dynamic>;

      final quakes = rawList
          .whereType<Map<String, dynamic>>()
          .map(Earthquake.fromJson)
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date)); // yeni en üstte

      return quakes;
    } catch (e) {
      // Ekranda gösterdiğin hata mesajıyla uyumlu olsun
      throw Exception('Error fetching earthquakes: $e');
    }
  }

  Future<List<Earthquake>> fetchNearbyEarthquakes(
    double lat,
    double lon, {
    double radiusKm = 100,
  }) async {
    final earthquakes = await fetchEarthquakes(limit: 100);

    return earthquakes.where((eq) {
      final distance = _calculateDistance(lat, lon, eq.latitude, eq.longitude);
      return distance <= radiusKm;
    }).toList();
  }

  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // km
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);

    final double a = pow(sin(dLat / 2), 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) * pow(sin(dLon / 2), 2);

    final double c = 2 * asin(sqrt(a));
    return earthRadius * c;
  }

  double _toRadians(double degrees) => degrees * pi / 180;
}
