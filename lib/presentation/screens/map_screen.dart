import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../providers/earthquake_provider.dart';
import '../../data/models/earthquake_model.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<EarthquakeProvider>(
      builder: (context, prov, _) {
        final quakes = prov.earthquakes;

        return Scaffold(
          appBar: AppBar(title: const Text('Harita')),
          body: FlutterMap(
            options: const MapOptions(
              initialCenter: LatLng(39.0, 35.0), // Türkiye orta
              initialZoom: 5.3,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'earthquake_alert',
              ),
              MarkerLayer(
                markers:
                    quakes.take(200).map((q) => _marker(context, q)).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Marker _marker(BuildContext ctx, Earthquake q) {
    final mag = q.magnitude;
    final color = mag >= 5.0
        ? Colors.red
        : mag >= 4.0
            ? Colors.orange
            : Colors.amber;

    return Marker(
      width: 42,
      height: 42,
      point: LatLng(q.latitude, q.longitude),
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(ctx, '/detail', arguments: q),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(.85),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                mag.toStringAsFixed(1),
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const Icon(Icons.location_on, color: Colors.black54, size: 22),
          ],
        ),
      ),
    );
  }
}
