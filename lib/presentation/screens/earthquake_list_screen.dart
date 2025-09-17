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

  // Debounce timer for search
  Timer? _searchDebounce;

  // Cached filtered results
  List<dynamic>? _cachedFilteredEarthquakes;
  String _lastCacheKey = '';

  @override
  void initState() {
    super.initState();
  }

  // Generate cache key for current filter state
  String _generateCacheKey() {
    return '${_magnitudeRange.start}-${_magnitudeRange.end}-$_appliedQuery';
  }

  // Get filtered earthquakes with caching
  List<dynamic> _getFilteredEarthquakes(EarthquakeProvider provider) {
    final currentCacheKey = _generateCacheKey();
    
    // Return cached results if filters haven't changed
    if (_cachedFilteredEarthquakes != null && _lastCacheKey == currentCacheKey) {
      return _cachedFilteredEarthquakes!;
    }

    // Calculate new filtered results
    _cachedFilteredEarthquakes = provider.getFilteredEarthquakes(
      minMagnitude: _magnitudeRange.start,
      maxMagnitude: _magnitudeRange.end,
      searchQuery: _appliedQuery,
    );
    _lastCacheKey = currentCacheKey;
    
    return _cachedFilteredEarthquakes!;
  }

  // Invalidate cache when provider data changes
  void _invalidateCache() {
    _cachedFilteredEarthquakes = null;
    _lastCacheKey = '';
  }

  // Debounced search update
  void _updateSearchQuery(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      const Duration(milliseconds: 400),
      () {
        if (!mounted) return;
        setState(() {
          _appliedQuery = query.trim();
          _invalidateCache();
        });
      },
    );
  }

  // Update magnitude filter (called from slider widget)
  void _updateMagnitudeRange(RangeValues values) {
    setState(() {
      _magnitudeRange = values;
      _invalidateCache();
    });
  }

  // Reset all filters
  void _resetFilters() {
    _searchDebounce?.cancel();
    
    setState(() {
      _magnitudeRange = const RangeValues(0, 10);
      _searchController.clear();
      _appliedQuery = '';
      _invalidateCache();
    });
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
          // Invalidate cache if provider data changed
          if (_lastCacheKey.isNotEmpty && provider.earthquakes.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _invalidateCache();
            });
          }

          final filteredEarthquakes = _getFilteredEarthquakes(provider);

          return SafeScrollWrapper(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Search & Filter Container
                  _buildFilterContainer(),
                  
                  const SizedBox(height: 12),

                  // Results count + actions
                  _buildResultsHeader(provider, filteredEarthquakes.length),

                  const SizedBox(height: 8),

                  // Earthquake list
                  _buildEarthquakeList(filteredEarthquakes),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterContainer() {
    return Container(
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
          // Search bar
          _buildSearchField(),
          const SizedBox(height: 12),
          // Magnitude filter - using the optimized slider
          _MagnitudeRangeSlider(
            initialRange: _magnitudeRange,
            onRangeChanged: _updateMagnitudeRange,
            onReset: _resetFilters,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      textInputAction: TextInputAction.search,
      onChanged: _updateSearchQuery,
      onSubmitted: (txt) {
        _searchDebounce?.cancel();
        setState(() {
          _appliedQuery = txt.trim();
          _invalidateCache();
        });
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
                  setState(() {
                    _appliedQuery = '';
                    _invalidateCache();
                  });
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: AppColors.background,
      ),
    );
  }

  Widget _buildResultsHeader(EarthquakeProvider provider, int resultCount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$resultCount deprem bulundu',
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textLight,
          ),
        ),
        TextButton.icon(
          onPressed: () {
            provider.fetchEarthquakes();
            _invalidateCache(); // Invalidate cache when refreshing data
          },
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('Yenile'),
        ),
      ],
    );
  }

  Widget _buildEarthquakeList(List<dynamic> filteredEarthquakes) {
    if (filteredEarthquakes.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40),
        alignment: Alignment.center,
        child: const Text(
          'Kriterlere uygun deprem bulunamadı.',
          style: TextStyle(color: AppColors.textLight),
        ),
      );
    }

    return ListView.separated(
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
    );
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }
}

// ---------------- Optimized Range Slider Widget ----------------
class _MagnitudeRangeSlider extends StatefulWidget {
  final RangeValues initialRange;
  final Function(RangeValues) onRangeChanged;
  final VoidCallback onReset;

  const _MagnitudeRangeSlider({
    required this.initialRange,
    required this.onRangeChanged,
    required this.onReset,
  });

  @override
  State<_MagnitudeRangeSlider> createState() => _MagnitudeRangeSliderState();
}

class _MagnitudeRangeSliderState extends State<_MagnitudeRangeSlider> {
  late ValueNotifier<RangeValues> _sliderRange;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _sliderRange = ValueNotifier<RangeValues>(widget.initialRange);
  }

  @override
  void didUpdateWidget(_MagnitudeRangeSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialRange != widget.initialRange) {
      _sliderRange.value = widget.initialRange;
    }
  }

  void _onSliderChanged(RangeValues values) {
    _sliderRange.value = values;
  }

  void _onSliderChangeEnd(RangeValues values) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 200), () {
      if (mounted) {
        widget.onRangeChanged(values);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<RangeValues>(
      valueListenable: _sliderRange,
      builder: (context, range, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Büyüklük: ${range.start.toStringAsFixed(1)} – ${range.end.toStringAsFixed(1)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    _debounceTimer?.cancel();
                    _sliderRange.value = const RangeValues(0, 10);
                    widget.onReset();
                  },
                  child: const Text('Sıfırla'),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                children: [
                  // Range display badges
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          // ignore: deprecated_member_use
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Min: ${range.start.toStringAsFixed(1)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          // ignore: deprecated_member_use
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Max: ${range.end.toStringAsFixed(1)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Range slider
                  RangeSlider(
                    values: range,
                    min: 0,
                    max: 10,
                    divisions: 20,
                    activeColor: AppColors.primary,
                    // ignore: deprecated_member_use
                    inactiveColor: AppColors.primary.withOpacity(0.3),
                    onChanged: _onSliderChanged,
                    onChangeEnd: _onSliderChangeEnd,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _sliderRange.dispose();
    super.dispose();
  }
}