import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../providers/earthquake_provider.dart';
import '../widgets/earthquake_card.dart';
import '../../routes/app_routes.dart';

class EarthquakeListScreen extends StatefulWidget {
  const EarthquakeListScreen({super.key});

  @override
  State<EarthquakeListScreen> createState() => _EarthquakeListScreenState();
}

class _EarthquakeListScreenState extends State<EarthquakeListScreen> {
  final TextEditingController _searchController = TextEditingController();
  RangeValues _magnitudeRange = const RangeValues(0, 10);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Tüm Depremler'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Consumer<EarthquakeProvider>(
        builder: (context, provider, _) {
          final filteredEarthquakes = provider.getFilteredEarthquakes(
            minMagnitude: _magnitudeRange.start,
            maxMagnitude: _magnitudeRange.end,
            searchQuery: _searchController.text,
          );

          return Column(
            children: [
              // Search and filter section
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: Column(
                  children: [
                    // Search bar
                    TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Konum ara...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {});
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: AppColors.background,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Magnitude filter
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Büyüklük Aralığı: ${_magnitudeRange.start.toStringAsFixed(1)} - ${_magnitudeRange.end.toStringAsFixed(1)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        RangeSlider(
                          values: _magnitudeRange,
                          min: 0,
                          max: 10,
                          divisions: 20,
                          activeColor: AppColors.primary,
                          onChanged: (values) {
                            setState(() {
                              _magnitudeRange = values;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Results count
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${filteredEarthquakes.length} deprem bulundu',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textLight,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => provider.fetchEarthquakes(),
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Yenile'),
                    ),
                  ],
                ),
              ),

              // Earthquake list
              Expanded(
                child: ListView.builder(
                  itemCount: filteredEarthquakes.length,
                  itemBuilder: (context, index) {
                    final earthquake = filteredEarthquakes[index];
                    return EarthquakeCard(
                      earthquake: earthquake,
                      onTap: () => Navigator.pushNamed(
                        context,
                        AppRoutes.earthquakeDetail,
                        arguments: earthquake,
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
