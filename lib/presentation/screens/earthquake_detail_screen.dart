import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../data/models/earthquake_model.dart';

class EarthquakeDetailScreen extends StatelessWidget {
  final Earthquake earthquake;

  const EarthquakeDetailScreen({super.key, required this.earthquake});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppColors.getMagnitudeColor(earthquake.magnitude),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                earthquake.location,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Map
                  FlutterMap(
                    options: MapOptions(
                      initialCenter:
                          LatLng(earthquake.latitude, earthquake.longitude),
                      initialZoom: 9.0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(
                                earthquake.latitude, earthquake.longitude),
                            width: 80,
                            height: 80,
                            child: Icon(
                              Icons.location_on,
                              color: AppColors.getMagnitudeColor(
                                  earthquake.magnitude),
                              size: 40,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppColors.getMagnitudeColor(earthquake.magnitude)
                              // ignore: deprecated_member_use
                              .withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // CONTENT
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Magnitude card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.getMagnitudeColor(earthquake.magnitude)
                          // ignore: deprecated_member_use
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color:
                            AppColors.getMagnitudeColor(earthquake.magnitude),
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Column(
                          children: [
                            Text(
                              earthquake.magnitude.toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: AppColors.getMagnitudeColor(
                                    earthquake.magnitude),
                              ),
                            ),
                            Text(
                              _getMagnitudeDescription(earthquake.magnitude),
                              style: TextStyle(
                                fontSize: 16,
                                color: AppColors.getMagnitudeColor(
                                    earthquake.magnitude),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Details
                  _buildDetailCard(
                    'Detaylı Bilgiler',
                    [
                      _DetailRow('Tarih', _formatDate(earthquake.date)),
                      _DetailRow('Saat', _formatTime(earthquake.date)),
                      _DetailRow('Derinlik',
                          '${earthquake.depth.toStringAsFixed(1)} km'),
                      _DetailRow(
                          'Enlem', earthquake.latitude.toStringAsFixed(4)),
                      _DetailRow(
                          'Boylam', earthquake.longitude.toStringAsFixed(4)),
                      if (earthquake.city != null)
                        _DetailRow('Şehir', earthquake.city!),
                      if (earthquake.district != null)
                        _DetailRow('İlçe', earthquake.district!),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _openInMaps(earthquake),
                          icon: const Icon(Icons.map),
                          label: const Text('Haritada Göster'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _share(earthquake),
                          icon: const Icon(Icons.share),
                          label: const Text('Paylaş'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12), // bottom spacing
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard(String title, List<_DetailRow> rows) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
          ),
          const Divider(height: 1),
          ...rows.map(
            (row) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      row.label,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      row.value,
                      textAlign: TextAlign.right,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getMagnitudeDescription(double magnitude) {
    if (magnitude < 3.0) return 'Hafif';
    if (magnitude < 4.5) return 'Orta';
    if (magnitude < 6.0) return 'Kuvvetli';
    if (magnitude < 7.0) return 'Çok Kuvvetli';
    return 'Yıkıcı';
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}';
  }

  Future<void> _openInMaps(Earthquake earthquake) async {
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${earthquake.latitude},${earthquake.longitude}',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void _share(Earthquake earthquake) {
    // İstersen share_plus ekleyip burada paylaşımı yapabilirsin.
    // örn: Share.share('...', subject: 'Deprem');
  }
}

class _DetailRow {
  final String label;
  final String value;
  _DetailRow(this.label, this.value);
}
