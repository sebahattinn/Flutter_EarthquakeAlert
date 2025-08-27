import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../routes/app_routes.dart';
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
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Harita'),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          body: Stack(
            children: [
              // Tam ekran interaktif harita
              FlutterMap(
                options: const MapOptions(
                  initialCenter: LatLng(39.0, 35.0), // Türkiye orta
                  initialZoom: 5.3,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'earthquake_alert',
                  ),
                  MarkerLayer(
                    markers: quakes
                        .take(300)
                        .map((q) => _marker(context, q))
                        .toList(),
                  ),
                ],
              ),

              // Üstte küçük bir açıklama şeridi (taşma engel / bilgilendirme)
              SafeArea(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(.08), blurRadius: 8)
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _legendChip('≥ 5.0', Colors.red),
                        const SizedBox(width: 8),
                        _legendChip('4.0–4.9', Colors.orange),
                        const SizedBox(width: 8),
                        _legendChip('< 4.0', Colors.amber),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _legendChip(String label, Color color) {
    return Row(
      children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
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
        onTap: () =>
            Navigator.pushNamed(ctx, AppRoutes.earthquakeDetail, arguments: q),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
