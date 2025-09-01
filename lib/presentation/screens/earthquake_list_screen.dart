import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../providers/earthquake_provider.dart';
import '../widgets/earthquake_card.dart';
import '../widgets/safe_scroll_wrapper.dart';
import '../../routes/app_routes.dart';

class EarthquakeListScreen extends StatefulWidget {
  const EarthquakeListScreen({super.key});

  @override
  State<EarthquakeListScreen> createState() => _EarthquakeListScreenState();
}

class _EarthquakeListScreenState extends State<EarthquakeListScreen> {
  final TextEditingController _searchController = TextEditingController();

  // Uygulanan filtre değerleri
  RangeValues _magnitudeRange = const RangeValues(0, 10);
  String _appliedQuery = '';

  // UI akışkanlık için (yalnızca label/sürgü görseli)
  RangeValues _uiRange = const RangeValues(0, 10);

  // Debounce
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _uiRange = _magnitudeRange;
  }

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
            searchQuery: _appliedQuery,
          );

          return SafeScrollWrapper(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(), // klavyeyi kapat
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Search & Filter
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          // ignore: deprecated_member_use
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        // Search bar (debounce + onSubmitted)
                        TextField(
                          controller: _searchController,
                          textInputAction: TextInputAction.search,
                          onChanged: (txt) {
                            _searchDebounce?.cancel();
                            _searchDebounce = Timer(
                              const Duration(milliseconds: 200),
                              () {
                                if (!mounted) return;
                                setState(() => _appliedQuery = txt.trim());
                              },
                            );
                          },
                          onSubmitted: (txt) {
                            _searchDebounce?.cancel();
                            setState(() => _appliedQuery = txt.trim());
                          },
                          decoration: InputDecoration(
                            hintText: 'Konum ara…',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _searchDebounce?.cancel();
                                      _searchController.clear();
                                      setState(() => _appliedQuery = '');
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
                        const SizedBox(height: 12),

                        // Magnitude filter (onChangeEnd ile uygula)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Büyüklük: ${_uiRange.start.toStringAsFixed(1)} – ${_uiRange.end.toStringAsFixed(1)}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    _searchDebounce?.cancel();
                                    setState(() {
                                      _uiRange = const RangeValues(0, 10);
                                      _magnitudeRange =
                                          const RangeValues(0, 10);
                                      _searchController.clear();
                                      _appliedQuery = '';
                                    });
                                  },
                                  child: const Text('Sıfırla'),
                                ),
                              ],
                            ),
                            RangeSlider(
                              values: _uiRange,
                              min: 0,
                              max: 10,
                              divisions: 20,
                              activeColor: AppColors.primary,
                              onChanged: (values) {
                                // sadece UI güncelle (hafif)
                                setState(() => _uiRange = values);
                              },
                              onChangeEnd: (values) {
                                // filtreyi şimdi uygula (ağır)
                                setState(() => _magnitudeRange = values);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Results count + actions
                  Row(
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

                  const SizedBox(height: 8),

                  // Earthquake list (tek scroll: shrinkWrap + NeverScrollable)
                  if (filteredEarthquakes.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      alignment: Alignment.center,
                      child: const Text(
                        'Kriterlere uygun deprem bulunamadı.',
                        style: TextStyle(color: AppColors.textLight),
                      ),
                    )
                  else
                    ListView.separated(
                      itemCount: filteredEarthquakes.length,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
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
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }
}
