import 'package:earthquake_alert/presentation/widgets/safe_scroll_wrapper.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;

import '../../core/constants/app_colors.dart';
import '../../data/models/earthquake_model.dart';
import '../providers/earthquake_provider.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  String _selectedTimeFrame = '24h';
  bool _showDepthAnalysis = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Deprem Analiz Merkezi'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.analytics), text: 'Genel'),
            Tab(icon: Icon(Icons.timeline), text: 'Trendler'),
            Tab(icon: Icon(Icons.location_on), text: 'Bölgesel'),
          ],
        ),
      ),
      body: Consumer<EarthquakeProvider>(
        builder: (context, provider, _) {
          if (provider.earthquakes.isEmpty) {
            return _buildEmptyState();
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(provider),
              _buildTrendsTab(provider),
              _buildRegionalTab(provider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return SafeScrollWrapper(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Icon(Icons.analytics_outlined, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Veri Analizi Bekleniyor',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Deprem verileri yüklendiğinde detaylı analiz burada görünecek',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(EarthquakeProvider provider) {
    final analytics = _calculateAnalytics(provider.earthquakes);
    
    return SafeScrollWrapper(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTimeFrameSelector(),
          const SizedBox(height: 20),
          _buildMetricsGrid(analytics),
          const SizedBox(height: 24),
          _buildActivityGauge(analytics),
          const SizedBox(height: 24),
          _buildRiskAssessment(analytics),
          const SizedBox(height: 24),
          _buildRecentSignificantEvents(provider.earthquakes),
        ],
      ),
    );
  }

  Widget _buildTrendsTab(EarthquakeProvider provider) {
    final trends = _calculateTrends(provider.earthquakes);
    
    return SafeScrollWrapper(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildMagnitudeDistribution(trends),
          const SizedBox(height: 24),
          _buildTimeSeriesChart(trends),
          const SizedBox(height: 24),
          _buildDepthAnalysisToggle(),
          const SizedBox(height: 16),
          if (_showDepthAnalysis) ...[
            _buildDepthAnalysis(provider.earthquakes),
            const SizedBox(height: 24),
          ],
          _buildFrequencyAnalysis(trends),
        ],
      ),
    );
  }

  Widget _buildRegionalTab(EarthquakeProvider provider) {
    final regional = _calculateRegionalData(provider.earthquakes);
    
    return SafeScrollWrapper(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildRegionalHeatmap(regional),
          const SizedBox(height: 24),
          _buildTopActiveRegions(regional),
          const SizedBox(height: 24),
          _buildRegionalRiskLevels(regional),
        ],
      ),
    );
  }

  Widget _buildTimeFrameSelector() {
    final options = ['24h', '7d', '30d', 'Tümü'];
    
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: options.map((option) {
          final isSelected = _selectedTimeFrame == option;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTimeFrame = option;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  option,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[700],
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMetricsGrid(_AnalyticsData analytics) {
    return GridView.count(
      crossAxisCount: 2,
      childAspectRatio: 1.3,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildMetricCard(
          'Toplam Deprem',
          '${analytics.totalCount}',
          'Son ${_getTimeFrameLabel()}',
          Icons.waves,
          Colors.blue,
          trend: analytics.countTrend,
        ),
        _buildMetricCard(
          'Ortalama Büyüklük',
          analytics.averageMagnitude.toStringAsFixed(1),
          'Richter ölçeği',
          Icons.speed,
          Colors.orange,
          trend: analytics.magnitudeTrend,
        ),
        _buildMetricCard(
          'En Derin',
          '${analytics.maxDepth.toInt()} km',
          analytics.deepestLocation,
          Icons.arrow_downward,
          Colors.purple,
        ),
        _buildMetricCard(
          'En Güçlü',
          analytics.maxMagnitude.toStringAsFixed(1),
          analytics.strongestLocation,
          Icons.trending_up,
          Colors.red,
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color, {
    double? trend,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              if (trend != null) _buildTrendIndicator(trend),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTrendIndicator(double trend) {
    final isPositive = trend > 0;
    final color = isPositive ? Colors.red : Colors.green;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.arrow_upward : Icons.arrow_downward,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 2),
          Text(
            '${trend.abs().toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityGauge(_AnalyticsData analytics) {
    final activityLevel = _calculateActivityLevel(analytics.totalCount);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Sismik Aktivite Seviyesi',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: 200,
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    startDegreeOffset: -90,
                    sectionsSpace: 4,
                    centerSpaceRadius: 60,
                    sections: [
                      PieChartSectionData(
                        value: activityLevel.percentage,
                        color: activityLevel.color,
                        radius: 30,
                        showTitle: false,
                      ),
                      PieChartSectionData(
                        value: 100 - activityLevel.percentage,
                        color: Colors.grey[200]!,
                        radius: 30,
                        showTitle: false,
                      ),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${activityLevel.percentage.toInt()}%',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: activityLevel.color,
                      ),
                    ),
                    Text(
                      activityLevel.label,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskAssessment(_AnalyticsData analytics) {
    final riskLevel = _calculateRiskLevel(analytics);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [riskLevel.color.withOpacity(0.1), riskLevel.color.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: riskLevel.color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(riskLevel.icon, color: riskLevel.color, size: 28),
              const SizedBox(width: 12),
              Text(
                'Risk Değerlendirmesi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: riskLevel.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            riskLevel.title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: riskLevel.color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            riskLevel.description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMagnitudeDistribution(_TrendsData trends) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Büyüklük Dağılımı',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceEvenly,
                maxY: trends.magnitudeDistribution.values.isNotEmpty 
                    ? trends.magnitudeDistribution.values.reduce(math.max).toDouble()
                    : 10,
                barGroups: trends.magnitudeDistribution.entries.map((entry) {
                  final index = trends.magnitudeDistribution.keys.toList().indexOf(entry.key);
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value.toDouble(),
                        color: _getMagnitudeColor(entry.key),
                        width: 20,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ],
                  );
                }).toList(),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final keys = trends.magnitudeDistribution.keys.toList();
                        if (value.toInt() < keys.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              keys[value.toInt()],
                              style: const TextStyle(fontSize: 12),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSeriesChart(_TrendsData trends) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Zaman Serisi Analizi',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: trends.timeSeriesData.isEmpty
                ? _buildEmptyChart('Yeterli veri yok')
                : LineChart(
                    LineChartData(
                      lineBarsData: [
                        LineChartBarData(
                          spots: trends.timeSeriesData,
                          isCurved: true,
                          color: AppColors.primary,
                          barWidth: 3,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) {
                              return FlDotCirclePainter(
                                radius: 4,
                                color: AppColors.primary,
                                strokeColor: Colors.white,
                                strokeWidth: 2,
                              );
                            },
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            color: AppColors.primary.withOpacity(0.1),
                          ),
                        ),
                      ],
                      titlesData: const FlTitlesData(
                        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
                        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 1,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.grey[300]!,
                            strokeWidth: 1,
                          );
                        },
                      ),
                      borderData: FlBorderData(show: false),
                      minY: 0,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDepthAnalysisToggle() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.layers, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Derinlik Analizi',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Deprem derinliği vs büyüklük ilişkisi',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _showDepthAnalysis,
            onChanged: (value) {
              setState(() {
                _showDepthAnalysis = value;
              });
            },
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildDepthAnalysis(List<Earthquake> earthquakes) {
    final filteredEarthquakes = _filterByTimeFrame(earthquakes);
    if (filteredEarthquakes.isEmpty) {
      return _buildEmptyChart('Veri bulunamadı');
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Derinlik vs Büyüklük Analizi',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: ScatterChart(
              ScatterChartData(
                scatterSpots: filteredEarthquakes.map((eq) {
                  return ScatterSpot(
                    eq.depth ?? 10,
                    eq.magnitude,
                    dotPainter: FlDotCirclePainter(
                      radius: eq.magnitude * 2,
                      color: _getMagnitudeColor('${eq.magnitude.floor()}-${eq.magnitude.floor() + 1}'),
                    ),
                  );
                }).toList(),
                minX: 0,
                maxX: filteredEarthquakes.map((e) => e.depth ?? 10).reduce(math.max),
                minY: filteredEarthquakes.map((e) => e.magnitude).reduce(math.min) - 0.5,
                maxY: filteredEarthquakes.map((e) => e.magnitude).reduce(math.max) + 0.5,
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                    axisNameWidget: const Text('Büyüklük', style: TextStyle(fontSize: 12)),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}',
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                    axisNameWidget: const Text('Derinlik (km)', style: TextStyle(fontSize: 12)),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(color: Colors.grey[300]!, strokeWidth: 1);
                  },
                  getDrawingVerticalLine: (value) {
                    return FlLine(color: Colors.grey[300]!, strokeWidth: 1);
                  },
                ),
                borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey[300]!)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFrequencyAnalysis(_TrendsData trends) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sıklık Analizi',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildFrequencyMetric(
                  'Saatlik Ortalama',
                  '${trends.hourlyAverage.toStringAsFixed(1)}',
                  'deprem/saat',
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFrequencyMetric(
                  'Günlük Ortalama',
                  '${trends.dailyAverage.toStringAsFixed(1)}',
                  'deprem/gün',
                  Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFrequencyMetric(String title, String value, String unit, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            unit,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegionalHeatmap(Map<String, _RegionalData> regional) {
    if (regional.isEmpty) {
      return _buildEmptyChart('Bölgesel veri yok');
    }

    final sortedRegions = regional.entries.toList()
      ..sort((a, b) => b.value.count.compareTo(a.value.count));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bölgesel Aktivite Haritası',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 1,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: math.min(sortedRegions.length, 16),
              itemBuilder: (context, index) {
                final region = sortedRegions[index];
                final intensity = region.value.count / sortedRegions.first.value.count;
                
                return Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(intensity),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          region.key.length > 8 
                            ? '${region.key.substring(0, 8)}...'
                            : region.key,
                          style: TextStyle(
                            fontSize: 10,
                            color: intensity > 0.5 ? Colors.white : Colors.grey[800],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopActiveRegions(Map<String, _RegionalData> regional) {
    if (regional.isEmpty) {
      return _buildEmptyChart('Bölgesel veri yok');
    }

    final sortedRegions = regional.entries.toList()
      ..sort((a, b) => b.value.count.compareTo(a.value.count));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'En Aktif Bölgeler',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: math.min(sortedRegions.length, 5),
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final region = sortedRegions[index];
              final maxCount = sortedRegions.first.value.count;
              final percentage = (region.value.count / maxCount * 100).round();
              
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.8 - (index * 0.15)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            region.key,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${region.value.count} deprem • Ort: ${region.value.averageMagnitude.toStringAsFixed(1)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '$percentage%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRegionalRiskLevels(Map<String, _RegionalData> regional) {
    final riskRegions = regional.entries
        .where((e) => e.value.averageMagnitude > 3.0)
        .toList()
      ..sort((a, b) => b.value.averageMagnitude.compareTo(a.value.averageMagnitude));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bölgesel Risk Seviyeleri',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (riskRegions.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'Yüksek riskli bölge bulunamadı',
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: math.min(riskRegions.length, 5),
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final region = riskRegions[index];
                final riskLevel = _getRiskLevel(region.value.averageMagnitude);
                
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: riskLevel.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: riskLevel.color.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(riskLevel.icon, color: riskLevel.color, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              region.key,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${region.value.count} deprem • Ort: ${region.value.averageMagnitude.toStringAsFixed(1)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: riskLevel.color,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          riskLevel.label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildRecentSignificantEvents(List<Earthquake> earthquakes) {
    final significantEvents = earthquakes
        .where((eq) => eq.magnitude >= 4.0)
        .take(5)
        .toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Son Önemli Depremler',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (significantEvents.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'Son dönemde 4.0+ büyüklüğünde deprem yok',
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: significantEvents.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final earthquake = significantEvents[index];
                final timeAgo = _getTimeAgo(earthquake.date);
                
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _getMagnitudeColor('${earthquake.magnitude.floor()}-${earthquake.magnitude.floor() + 1}').withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        earthquake.magnitude.toStringAsFixed(1),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _getMagnitudeColor('${earthquake.magnitude.floor()}-${earthquake.magnitude.floor() + 1}'),
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    earthquake.location,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '$timeAgo${earthquake.depth != null ? ' • ${earthquake.depth!.toInt()} km derinlik' : ''}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  trailing: Icon(
                    Icons.chevron_right,
                    color: Colors.grey[400],
                  ),
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/detail',
                      arguments: earthquake,
                    );
                  },
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyChart(String message) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: Colors.grey[600],
        ),
      ),
    );
  }

  // Helper Methods
  String _getTimeFrameLabel() {
    switch (_selectedTimeFrame) {
      case '24h': return '24 saat';
      case '7d': return '7 gün';
      case '30d': return '30 gün';
      case 'Tümü': return 'tüm zamanlarda';
      default: return '24 saat';
    }
  }

  List<Earthquake> _filterByTimeFrame(List<Earthquake> earthquakes) {
    final now = DateTime.now().toUtc();
    
    switch (_selectedTimeFrame) {
      case '24h':
        return earthquakes.where((e) => now.difference(e.date).inHours < 24).toList();
      case '7d':
        return earthquakes.where((e) => now.difference(e.date).inDays < 7).toList();
      case '30d':
        return earthquakes.where((e) => now.difference(e.date).inDays < 30).toList();
      case 'Tümü':
      default:
        return earthquakes;
    }
  }

  _AnalyticsData _calculateAnalytics(List<Earthquake> allEarthquakes) {
    final earthquakes = _filterByTimeFrame(allEarthquakes);
    
    if (earthquakes.isEmpty) {
      return _AnalyticsData(
        totalCount: 0,
        averageMagnitude: 0.0,
        maxMagnitude: 0.0,
        maxDepth: 0.0,
        strongestLocation: '',
        deepestLocation: '',
        countTrend: 0.0,
        magnitudeTrend: 0.0,
      );
    }

    final maxMagEq = earthquakes.reduce((a, b) => a.magnitude > b.magnitude ? a : b);
    final maxDepthEq = earthquakes.reduce((a, b) => (a.depth ?? 0) > (b.depth ?? 0) ? a : b);
    
    return _AnalyticsData(
      totalCount: earthquakes.length,
      averageMagnitude: earthquakes.map((e) => e.magnitude).reduce((a, b) => a + b) / earthquakes.length,
      maxMagnitude: maxMagEq.magnitude,
      maxDepth: maxDepthEq.depth ?? 0,
      strongestLocation: _truncateLocation(maxMagEq.location),
      deepestLocation: _truncateLocation(maxDepthEq.location),
      countTrend: _calculateTrend(allEarthquakes, 'count'),
      magnitudeTrend: _calculateTrend(allEarthquakes, 'magnitude'),
    );
  }

  _TrendsData _calculateTrends(List<Earthquake> allEarthquakes) {
    final earthquakes = _filterByTimeFrame(allEarthquakes);
    
    // Magnitude distribution
    final magnitudeDistribution = <String, int>{
      '2-3': 0,
      '3-4': 0,
      '4-5': 0,
      '5-6': 0,
      '6+': 0,
    };

    for (final eq in earthquakes) {
      final mag = eq.magnitude;
      if (mag < 3) magnitudeDistribution['2-3'] = magnitudeDistribution['2-3']! + 1;
      else if (mag < 4) magnitudeDistribution['3-4'] = magnitudeDistribution['3-4']! + 1;
      else if (mag < 5) magnitudeDistribution['4-5'] = magnitudeDistribution['4-5']! + 1;
      else if (mag < 6) magnitudeDistribution['5-6'] = magnitudeDistribution['5-6']! + 1;
      else magnitudeDistribution['6+'] = magnitudeDistribution['6+']! + 1;
    }

    // Time series data
    final sortedEarthquakes = List<Earthquake>.from(earthquakes)
      ..sort((a, b) => a.date.compareTo(b.date));
    
    final timeSeriesData = <FlSpot>[];
    for (int i = 0; i < sortedEarthquakes.length; i++) {
      timeSeriesData.add(FlSpot(i.toDouble(), sortedEarthquakes[i].magnitude));
    }

    // Frequency analysis
    final totalHours = _selectedTimeFrame == '24h' ? 24 : 
                      _selectedTimeFrame == '7d' ? 168 : 
                      _selectedTimeFrame == '30d' ? 720 : 8760;
    
    return _TrendsData(
      magnitudeDistribution: magnitudeDistribution,
      timeSeriesData: timeSeriesData,
      hourlyAverage: earthquakes.length / totalHours,
      dailyAverage: earthquakes.length / (totalHours / 24),
    );
  }

  Map<String, _RegionalData> _calculateRegionalData(List<Earthquake> allEarthquakes) {
    final earthquakes = _filterByTimeFrame(allEarthquakes);
    final regional = <String, List<Earthquake>>{};
    
    for (final eq in earthquakes) {
      final region = _extractRegion(eq.location);
      regional.putIfAbsent(region, () => []).add(eq);
    }

    return regional.map((key, value) => MapEntry(
      key,
      _RegionalData(
        count: value.length,
        averageMagnitude: value.map((e) => e.magnitude).reduce((a, b) => a + b) / value.length,
      ),
    ));
  }

  String _extractRegion(String location) {
    // Simple region extraction - you might want to improve this
    final parts = location.split(' ');
    if (parts.length > 2) {
      return '${parts[parts.length - 2]} ${parts[parts.length - 1]}';
    }
    return location;
  }

  String _truncateLocation(String location) {
    return location.length > 20 ? '${location.substring(0, 20)}...' : location;
  }

  double _calculateTrend(List<Earthquake> earthquakes, String type) {
    // Simple trend calculation - could be improved
    final now = DateTime.now().toUtc();
    final recent = earthquakes.where((e) => now.difference(e.date).inHours < 24).toList();
    final previous = earthquakes.where((e) {
      final diff = now.difference(e.date).inHours;
      return diff >= 24 && diff < 48;
    }).toList();

    if (previous.isEmpty) return 0.0;

    if (type == 'count') {
      return ((recent.length - previous.length) / previous.length * 100);
    } else {
      final recentAvg = recent.isEmpty ? 0.0 : recent.map((e) => e.magnitude).reduce((a, b) => a + b) / recent.length;
      final prevAvg = previous.map((e) => e.magnitude).reduce((a, b) => a + b) / previous.length;
      return ((recentAvg - prevAvg) / prevAvg * 100);
    }
  }

  _ActivityLevel _calculateActivityLevel(int count) {
    if (count > 50) return _ActivityLevel('Çok Yüksek', 90, Colors.red);
    if (count > 25) return _ActivityLevel('Yüksek', 70, Colors.orange);
    if (count > 10) return _ActivityLevel('Orta', 50, Colors.yellow);
    if (count > 5) return _ActivityLevel('Düşük', 30, Colors.green);
    return _ActivityLevel('Çok Düşük', 10, Colors.blue);
  }

  _RiskLevel _calculateRiskLevel(_AnalyticsData analytics) {
    if (analytics.averageMagnitude > 5.0 && analytics.totalCount > 10) {
      return _RiskLevel(
        'Yüksek Risk',
        'Son dönemde büyük depremler ve yüksek aktivite gözleniyor. Hazırlıklarınızı gözden geçirin.',
        Colors.red,
        Icons.warning,
        'Yüksek',
      );
    } else if (analytics.averageMagnitude > 4.0 || analytics.totalCount > 20) {
      return _RiskLevel(
        'Orta Risk',
        'Sismik aktivite normale göre artmış durumda. Deprem çantanızı kontrol edin.',
        Colors.orange,
        Icons.info,
        'Orta',
      );
    } else {
      return _RiskLevel(
        'Düşük Risk',
        'Sismik aktivite normal seviyelerde. Yine de hazırlıklı olmayı sürdürün.',
        Colors.green,
        Icons.check_circle,
        'Düşük',
      );
    }
  }

  _RiskLevel _getRiskLevel(double averageMagnitude) {
    if (averageMagnitude > 5.0) {
      return _RiskLevel('Yüksek', '', Colors.red, Icons.dangerous, 'Yüksek');
    } else if (averageMagnitude > 4.0) {
      return _RiskLevel('Orta', '', Colors.orange, Icons.warning, 'Orta');
    } else {
      return _RiskLevel('Düşük', '', Colors.green, Icons.info, 'Düşük');
    }
  }

  Color _getMagnitudeColor(String range) {
    switch (range) {
      case '2-3': return Colors.green;
      case '3-4': return Colors.yellow[700]!;
      case '4-5': return Colors.orange;
      case '5-6': return Colors.red;
      case '6+': return Colors.red[900]!;
      default: return Colors.grey;
    }
  }

  String _getTimeAgo(DateTime date) {
    final now = DateTime.now().toUtc();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} gün önce';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} saat önce';
    } else {
      return '${difference.inMinutes} dakika önce';
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

// Data Classes
class _AnalyticsData {
  final int totalCount;
  final double averageMagnitude;
  final double maxMagnitude;
  final double maxDepth;
  final String strongestLocation;
  final String deepestLocation;
  final double countTrend;
  final double magnitudeTrend;

  _AnalyticsData({
    required this.totalCount,
    required this.averageMagnitude,
    required this.maxMagnitude,
    required this.maxDepth,
    required this.strongestLocation,
    required this.deepestLocation,
    required this.countTrend,
    required this.magnitudeTrend,
  });
}

class _TrendsData {
  final Map<String, int> magnitudeDistribution;
  final List<FlSpot> timeSeriesData;
  final double hourlyAverage;
  final double dailyAverage;

  _TrendsData({
    required this.magnitudeDistribution,
    required this.timeSeriesData,
    required this.hourlyAverage,
    required this.dailyAverage,
  });
}

class _RegionalData {
  final int count;
  final double averageMagnitude;

  _RegionalData({
    required this.count,
    required this.averageMagnitude,
  });
}

class _ActivityLevel {
  final String label;
  final double percentage;
  final Color color;

  _ActivityLevel(this.label, this.percentage, this.color);
}

class _RiskLevel {
  final String title;
  final String description;
  final Color color;
  final IconData icon;
  final String label;

  _RiskLevel(this.title, this.description, this.color, this.icon, this.label);
}

// Add this variable declaration at the top of your State class if it's missing
  String _selectedTimeFrame = '24h';

  // Helper Methods for Filtering and Data Processing
  String _getTimeFrameLabel() {
    switch (_selectedTimeFrame) {
      case '24h': return '24 saat';
      case '7d': return '7 gün';
      case '30d': return '30 gün';
      case 'Tümü': return 'tüm zamanlarda';
      default: return '24 saat';
    }
  }

  List<Earthquake> _filterByTimeFrame(List<Earthquake> earthquakes) {
    final now = DateTime.now().toUtc();
    
    switch (_selectedTimeFrame) {
      case '24h':
        return earthquakes.where((e) => now.difference(e.date).inHours < 24).toList();
      case '7d':
        return earthquakes.where((e) => now.difference(e.date).inDays < 7).toList();
      case '30d':
        return earthquakes.where((e) => now.difference(e.date).inDays < 30).toList();
      case 'Tümü':
      default:
        return earthquakes;
    }
  }

  _AnalyticsData _calculateAnalytics(List<Earthquake> allEarthquakes) {
    final earthquakes = _filterByTimeFrame(allEarthquakes);
    
    if (earthquakes.isEmpty) {
      return _AnalyticsData(
        totalCount: 0,
        averageMagnitude: 0.0,
        maxMagnitude: 0.0,
        maxDepth: 0.0,
        strongestLocation: 'Veri yok',
        deepestLocation: 'Veri yok',
        countTrend: 0.0,
        magnitudeTrend: 0.0,
      );
    }

    final maxMagEq = earthquakes.reduce((a, b) => a.magnitude > b.magnitude ? a : b);
    final maxDepthEq = earthquakes.reduce((a, b) => (a.depth ?? 0) > (b.depth ?? 0) ? a : b);
    
    return _AnalyticsData(
      totalCount: earthquakes.length,
      averageMagnitude: earthquakes.map((e) => e.magnitude).reduce((a, b) => a + b) / earthquakes.length,
      maxMagnitude: maxMagEq.magnitude,
      maxDepth: maxDepthEq.depth ?? 0,
      strongestLocation: _truncateLocation(maxMagEq.location),
      deepestLocation: _truncateLocation(maxDepthEq.location),
      countTrend: _calculateTrend(allEarthquakes, 'count'),
      magnitudeTrend: _calculateTrend(allEarthquakes, 'magnitude'),
    );
  }

  _TrendsData _calculateTrends(List<Earthquake> allEarthquakes) {
    final earthquakes = _filterByTimeFrame(allEarthquakes);
    
    final magnitudeDistribution = <String, int>{
      '2-3': 0,
      '3-4': 0,
      '4-5': 0,
      '5-6': 0,
      '6+': 0,
    };

    for (final eq in earthquakes) {
      final mag = eq.magnitude;
      if (mag < 3) {
        magnitudeDistribution['2-3'] = magnitudeDistribution['2-3']! + 1;
      } else if (mag < 4) {
        magnitudeDistribution['3-4'] = magnitudeDistribution['3-4']! + 1;
      } else if (mag < 5) {
        magnitudeDistribution['4-5'] = magnitudeDistribution['4-5']! + 1;
      } else if (mag < 6) {
        magnitudeDistribution['5-6'] = magnitudeDistribution['5-6']! + 1;
      } else {
        magnitudeDistribution['6+'] = magnitudeDistribution['6+']! + 1;
      }
    }

    final sortedEarthquakes = List<Earthquake>.from(earthquakes)
      ..sort((a, b) => a.date.compareTo(b.date));
    
    final timeSeriesData = <FlSpot>[];
    for (int i = 0; i < sortedEarthquakes.length; i++) {
      timeSeriesData.add(FlSpot(i.toDouble(), sortedEarthquakes[i].magnitude));
    }

    final totalHours = _selectedTimeFrame == '24h' ? 24.0 : 
                      _selectedTimeFrame == '7d' ? 168.0 : 
                      _selectedTimeFrame == '30d' ? 720.0 : 8760.0;
    
    return _TrendsData(
      magnitudeDistribution: magnitudeDistribution,
      timeSeriesData: timeSeriesData,
      hourlyAverage: earthquakes.length / totalHours,
      dailyAverage: earthquakes.length / (totalHours / 24.0),
    );
  }

  Map<String, _RegionalData> _calculateRegionalData(List<Earthquake> allEarthquakes) {
    final earthquakes = _filterByTimeFrame(allEarthquakes);
    final regional = <String, List<Earthquake>>{};
    
    for (final eq in earthquakes) {
      final region = _extractRegion(eq.location);
      regional.putIfAbsent(region, () => []).add(eq);
    }

    return regional.map((key, value) {
      if (value.isEmpty) {
        return MapEntry(key, _RegionalData(count: 0, averageMagnitude: 0.0));
      }
      return MapEntry(
        key,
        _RegionalData(
          count: value.length,
          averageMagnitude: value.map((e) => e.magnitude).reduce((a, b) => a + b) / value.length,
        ),
      );
    });
  }

  String _extractRegion(String location) {
    final parts = location.split(' ');
    if (parts.length > 2) {
      return '${parts[parts.length - 2]} ${parts[parts.length - 1]}';
    }
    return location.length > 15 ? '${location.substring(0, 15)}...' : location;
  }

  String _truncateLocation(String location) {
    return location.length > 20 ? '${location.substring(0, 20)}...' : location;
  }

  double _calculateTrend(List<Earthquake> earthquakes, String type) {
    final now = DateTime.now().toUtc();
    final recent = earthquakes.where((e) => now.difference(e.date).inHours < 24).toList();
    final previous = earthquakes.where((e) {
      final diff = now.difference(e.date).inHours;
      return diff >= 24 && diff < 48;
    }).toList();

    if (previous.isEmpty) return 0.0;

    if (type == 'count') {
      return ((recent.length - previous.length) / previous.length * 100);
    } else {
      if (recent.isEmpty) return 0.0;
      final recentAvg = recent.map((e) => e.magnitude).reduce((a, b) => a + b) / recent.length;
      final prevAvg = previous.map((e) => e.magnitude).reduce((a, b) => a + b) / previous.length;
      return ((recentAvg - prevAvg) / prevAvg * 100);
    }
  }

  _ActivityLevel _calculateActivityLevel(int count) {
    if (count > 50) return _ActivityLevel('Çok Yüksek', 90, Colors.red);
    if (count > 25) return _ActivityLevel('Yüksek', 70, Colors.orange);
    if (count > 10) return _ActivityLevel('Orta', 50, Colors.yellow);
    if (count > 5) return _ActivityLevel('Düşük', 30, Colors.green);
    return _ActivityLevel('Çok Düşük', 10, Colors.blue);
  }

  _RiskLevel _calculateRiskLevel(_AnalyticsData analytics) {
    if (analytics.averageMagnitude > 5.0 && analytics.totalCount > 10) {
      return _RiskLevel(
        'Yüksek Risk',
        'Son dönemde büyük depremler ve yüksek aktivite gözleniyor. Hazırlıklarınızı gözden geçirin.',
        Colors.red,
        Icons.warning,
        'Yüksek',
      );
    } else if (analytics.averageMagnitude > 4.0 || analytics.totalCount > 20) {
      return _RiskLevel(
        'Orta Risk',
        'Sismik aktivite normale göre artmış durumda. Deprem çantanızı kontrol edin.',
        Colors.orange,
        Icons.info,
        'Orta',
      );
    } else {
      return _RiskLevel(
        'Düşük Risk',
        'Sismik aktivite normal seviyelerde. Yine de hazırlıklı olmayı sürdürün.',
        Colors.green,
        Icons.check_circle,
        'Düşük',
      );
    }
  }

  _RiskLevel _getRiskLevel(double averageMagnitude) {
    if (averageMagnitude > 5.0) {
      return _RiskLevel('Yüksek', '', Colors.red, Icons.dangerous, 'Yüksek');
    } else if (averageMagnitude > 4.0) {
      return _RiskLevel('Orta', '', Colors.orange, Icons.warning, 'Orta');
    } else {
      return _RiskLevel('Düşük', '', Colors.green, Icons.info, 'Düşük');
    }
  }

  Color _getMagnitudeColor(String range) {
    switch (range) {
      case '2-3': return Colors.green;
      case '3-4': return Colors.yellow[700]!;
      case '4-5': return Colors.orange;
      case '5-6': return Colors.red;
      case '6+': return Colors.red[900]!;
      default: return Colors.grey;
    }
  }

  String _getTimeAgo(DateTime date) {
    final now = DateTime.now().toUtc();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} gün önce';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} saat önce';
    } else {
      return '${difference.inMinutes} dakika önce';
    }
  }
                    