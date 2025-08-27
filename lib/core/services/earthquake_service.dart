import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../data/models/earthquake_model.dart';

class EarthquakeService {
  static const String apiUrl =
      'https://api.orhanaydogdu.com.tr/deprem/kandilli/live';

  Future<List<Earthquake>> fetchEarthquakes({int limit = 50}) async {
    try {
      final response = await http.get(
        Uri.parse('$apiUrl?limit=$limit'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> results = data['result'] ?? [];

        return results.map((e) => Earthquake.fromJson(e)).toList();
      } else {
        throw Exception('Failed to load earthquakes');
      }
    } catch (e) {
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

    final double a = (dLat / 2).sin() * (dLat / 2).sin() +
        _toRadians(lat1).cos() *
            _toRadians(lat2).cos() *
            (dLon / 2).sin() *
            (dLon / 2).sin();

    final double c = 2 * a.sqrt().asin();
    return earthRadius * c;
  }

  double _toRadians(double degrees) => degrees * 3.14159265359 / 180;
}
