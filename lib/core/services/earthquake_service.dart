import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

import '../../data/models/earthquake_model.dart';

class EarthquakeService {
  //–––––––––––– Endpoints ––––––––––––
  static const String _kandilliUrl =
      'https://api.orhanaydogdu.com.tr/deprem/kandilli/live'; // proxy 1
  static const String _afadUrl =
      'https://deprem.afad.gov.tr/EventData/GetEventsByFilter'; // resmi
  static const String _usgsUrl =
      'https://earthquake.usgs.gov/fdsnws/event/1/query'; // proxy 2 (GeoJSON, bbox TR)

  //–––––––––––– Toplu fetch ––––––––––––
  Future<List<Earthquake>> fetchEarthquakes({int limit = 50}) async {
    try {
      final results = await Future.wait<List<Earthquake>>([
        _fetchFromAfad(take: limit).catchError((_) => <Earthquake>[]),
        _fetchFromKandilli(limit: limit).catchError((_) => <Earthquake>[]),
        _fetchFromUsgs(limit: limit).catchError((_) => <Earthquake>[]),
      ]);

      final merged =
          _dedupeAndSort([...results[0], ...results[1], ...results[2]]);

      if (merged.isEmpty) {
        throw Exception('All sources returned empty');
      }
      return merged.take(limit).toList();
    } catch (e) {
      throw Exception('Error fetching earthquakes: $e');
    }
  }

  //–––––––––––– Canlı izleme (polling stream) ––––––––––––
  /// Her `interval` sürede tüm kaynaklardan çekip birleştirir; tepe kayıt değiştiyse listeyi yayar.
  Stream<List<Earthquake>> watchEarthquakes({
    Duration interval = const Duration(seconds: 2),
    int limit = 50,
  }) async* {
    List<Earthquake>? last;
    while (true) {
      try {
        final list = await fetchEarthquakes(limit: limit);
        if (!_sameTop(last, list)) {
          yield list;
          last = list;
        }
      } catch (_) {
        // sessizce geç; bir sonraki döngüde tekrar dene
      }
      await Future.delayed(interval);
    }
  }

  //–––––––––––– Kaynaklar ––––––––––––
  Future<List<Earthquake>> _fetchFromKandilli({int limit = 100}) async {
    final ts = DateTime.now().millisecondsSinceEpoch; // cache-buster
    final uri = Uri.parse('$_kandilliUrl?limit=$limit&_ts=$ts');

    final res = await http.get(uri, headers: const {
      'Cache-Control': 'no-cache',
      'Accept': 'application/json',
      'Pragma': 'no-cache',
      'User-Agent': 'deprem-tr/1.0'
    }).timeout(const Duration(seconds: 8));

    if (res.statusCode != 200) {
      throw Exception('Kandilli HTTP ${res.statusCode}');
    }

    final decoded = json.decode(utf8.decode(res.bodyBytes));
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Unexpected response (kandilli)');
    }

    final List<dynamic> raw =
        (decoded['result'] ?? decoded['data'] ?? []) as List<dynamic>;

    return raw
        .whereType<Map<String, dynamic>>()
        .map(Earthquake.fromJson)
        .toList();
  }

  Future<List<Earthquake>> _fetchFromAfad({int take = 100}) async {
    final now = DateTime.now().toUtc();
    final from = now.subtract(const Duration(hours: 24));

    final body = {
      "EventSearchFilterList": [
        {"FilterType": 8, "Value": from.toIso8601String()},
        {"FilterType": 9, "Value": now.toIso8601String()}
      ],
      "Skip": 0,
      "Take": take,
      "SortDescriptor": {"field": "eventDate", "dir": "desc"}
    };

    final res = await http
        .post(Uri.parse(_afadUrl),
            headers: const {
              'Content-Type': 'application/json',
              'Cache-Control': 'no-cache',
              'Pragma': 'no-cache',
              'User-Agent': 'deprem-tr/1.0'
            },
            body: jsonEncode(body))
        .timeout(const Duration(seconds: 8));

    if (res.statusCode != 200) {
      throw Exception('AFAD HTTP ${res.statusCode}');
    }

    final Map<String, dynamic> jsonMap =
        json.decode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final List data = (jsonMap['data'] ?? jsonMap['Data'] ?? []) as List;

    return data.map<Earthquake>((e) {
      final m = {
        'earthquake_id': e['eventID'],
        'date': e['eventDate'], // ISO (+03:00)
        'lat': e['latitude'],
        'lng': e['longitude'],
        'depth': e['depth'],
        'mag': e['magnitude'],
        'title': e['location'],
      };
      return Earthquake.fromJson(Map<String, dynamic>.from(m));
    }).toList();
  }

  Future<List<Earthquake>> _fetchFromUsgs({int limit = 100}) async {
    // Türkiye yaklaşık bbox: lat 35–43.5, lon 25–45
    final now = DateTime.now().toUtc();
    final from = now.subtract(const Duration(hours: 24));
    final uri =
        Uri.parse('$_usgsUrl?format=geojson&starttime=${from.toIso8601String()}'
            '&endtime=${now.toIso8601String()}'
            '&minlatitude=35&maxlatitude=43.5&minlongitude=25&maxlongitude=45'
            '&orderby=time&limit=$limit');

    final res = await http.get(uri, headers: const {
      'Cache-Control': 'no-cache',
      'Accept': 'application/json',
      'Pragma': 'no-cache',
      'User-Agent': 'deprem-tr/1.0'
    }).timeout(const Duration(seconds: 8));

    if (res.statusCode != 200) {
      throw Exception('USGS HTTP ${res.statusCode}');
    }

    final decoded = json.decode(utf8.decode(res.bodyBytes));
    final features = (decoded['features'] ?? []) as List<dynamic>;

    return features.whereType<Map<String, dynamic>>().map((f) {
      final props = (f['properties'] ?? {}) as Map<String, dynamic>;
      final geom = (f['geometry'] ?? {}) as Map<String, dynamic>;
      final coords =
          (geom['coordinates'] ?? []) as List<dynamic>; // [lon, lat, depth]

      final m = {
        'earthquake_id': f['id'],
        'date': (props['time'] ?? '').toString(), // epoch ms
        'lat': coords.length > 1 ? coords[1] : null,
        'lng': coords.isNotEmpty ? coords[0] : null,
        'depth': coords.length > 2 ? coords[2] : null,
        'mag': props['mag'],
        'title': props['place'] ?? 'USGS',
      };
      return Earthquake.fromJson(Map<String, dynamic>.from(m));
    }).toList();
  }

  //–––––––––––– Yakınlar ––––––––––––
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

  //–––––––––––– Yardımcılar ––––––––––––
  List<Earthquake> _dedupeAndSort(List<Earthquake> all) {
    if (all.isEmpty) return all;

    // 1) ID'ye göre tekilleştir
    final byId = <String, Earthquake>{};
    for (final q in all) {
      final k = q.id;
      final old = byId[k];
      if (old == null || q.date.isAfter(old.date)) {
        byId[k] = q;
      }
    }

    // 2) ID farklıysa zaman+koordinata göre yakın eşleşme
    final approx = <String, Earthquake>{};
    for (final q in byId.values) {
      final key =
          '${q.date.millisecondsSinceEpoch ~/ 1e3}_${q.latitude.toStringAsFixed(3)}_${q.longitude.toStringAsFixed(3)}';
      final old = approx[key];
      if (old == null || q.date.isAfter(old.date)) {
        approx[key] = q;
      }
    }

    final list = approx.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date)); // yeni en üstte
    return list;
  }

  bool _sameTop(List<Earthquake>? a, List<Earthquake>? b) {
    if (a == null || b == null || a.isEmpty || b.isEmpty) return false;
    final A = a.first, B = b.first;
    return A.id == B.id &&
        A.date.millisecondsSinceEpoch == B.date.millisecondsSinceEpoch;
  }

  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const double R = 6371; // km
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = pow(sin(dLat / 2), 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) * pow(sin(dLon / 2), 2);
    return 2 * R * asin(sqrt(a));
  }

  double _toRadians(double d) => d * pi / 180;
}
