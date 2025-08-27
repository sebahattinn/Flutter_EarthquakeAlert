import 'package:earthquake_alert/presentation/widgets/safe_scroll_wrapper.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../data/models/earthquake_model.dart';
import '../providers/earthquake_provider.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<EarthquakeProvider>(
      builder: (context, prov, _) {
        final list = prov.earthquakes;
        final now = DateTime.now().toUtc();

        // Son 24 saat
        final last24 =
            list.where((e) => now.difference(e.date).inHours < 24).toList();
        // Büyük depremler (eşik ayarını da göstermek için)
        final big =
            list.where((e) => e.magnitude >= prov.minMagnitude).toList();

        // Histogram kovaları
        final buckets = <String, int>{
          '2-2.9': 0,
          '3-3.9': 0,
          '4-4.9': 0,
          '5-5.9': 0,
          '6+': 0
        };
        for (final q in last24) {
          final m = q.magnitude;
          if (m < 3) {
            buckets['2-2.9'] = buckets['2-2.9']! + 1;
          } else if (m < 4)
            // ignore: curly_braces_in_flow_control_structures
            buckets['3-3.9'] = buckets['3-3.9']! + 1;
          else if (m < 5)
            // ignore: curly_braces_in_flow_control_structures
            buckets['4-4.9'] = buckets['4-4.9']! + 1;
          else if (m < 6)
            // ignore: curly_braces_in_flow_control_structures
            buckets['5-5.9'] = buckets['5-5.9']! + 1;
          else
            // ignore: curly_braces_in_flow_control_structures
            buckets['6+'] = buckets['6+']! + 1;
        }

        // Zaman serisi (son 12 saat, büyüklük)
        final series = last24
            .where((e) => now.difference(e.date).inHours < 12)
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));
        final points = <FlSpot>[];
        for (var i = 0; i < series.length; i++) {
          points.add(FlSpot(i.toDouble(), series[i].magnitude));
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Analiz & Trendler'),
          ),
          body: list.isEmpty
              ? const Center(child: Text('Veri bekleniyor…'))
              : SafeScrollWrapper(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _StatCard(
                            title: 'Bugün Toplam',
                            value: '${_countToday(list)}',
                            subtitle: 'Bugünün depremleri',
                            icon: Icons.today,
                          ),
                          _StatCard(
                            title: '≥ ${prov.minMagnitude.toStringAsFixed(1)}',
                            value: '${big.length}',
                            subtitle: 'Eşik üzeri (tümü)',
                            icon: Icons.notification_important_outlined,
                          ),
                          _StatCard(
                            title: 'Son 24 saatte',
                            value: '${last24.length}',
                            subtitle: 'Toplam deprem',
                            icon: Icons.access_time,
                          ),
                          _StatCard(
                            title: 'En Büyük',
                            value: list.isNotEmpty
                                ? list
                                    .map((e) => e.magnitude)
                                    .reduce((a, b) => a > b ? a : b)
                                    .toStringAsFixed(1)
                                : '—',
                            subtitle: list.isNotEmpty
                                ? _placeShort(list.reduce((a, b) =>
                                    a.magnitude > b.magnitude ? a : b))
                                : '',
                            icon: Icons.trending_up,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text('Son 12 saat büyüklük trendi',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 220,
                        child: points.isEmpty
                            ? const _EmptyChart(text: 'Yeterli veri yok')
                            : LineChart(LineChartData(
                                minY: 0,
                                maxY: (series
                                            .map((e) => e.magnitude)
                                            .fold<double>(
                                                0, (p, e) => e > p ? e : p) +
                                        0.5)
                                    .clamp(0, 10),
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: points,
                                    isCurved: true,
                                    dotData: const FlDotData(show: false),
                                    barWidth: 3,
                                  ),
                                ],
                                gridData: const FlGridData(show: false),
                                titlesData: const FlTitlesData(show: false),
                                borderData: FlBorderData(show: true),
                              )),
                      ),
                      const SizedBox(height: 24),
                      Text('Son 24 saat büyüklük dağılımı',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 220,
                        child: BarChart(BarChartData(
                          barGroups: List.generate(buckets.length, (i) {
                            final key = buckets.keys.elementAt(i);
                            final val = buckets[key]!;
                            return BarChartGroupData(x: i, barRods: [
                              BarChartRodData(toY: val.toDouble())
                            ]);
                          }),
                          gridData: const FlGridData(show: false),
                          titlesData: FlTitlesData(
                            leftTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (v, meta) => Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    buckets.keys.elementAt(v.toInt()),
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          borderData: FlBorderData(show: true),
                        )),
                      ),
                      const SizedBox(height: 24),
                      Text('En son 10 deprem',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      for (final q in list.take(10)) _miniItem(context, q),
                    ],
                  ),
                ),
        );
      },
    );
  }

  static int _countToday(List<Earthquake> list) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    int c = 0;
    for (final e in list) {
      final l = e.date.toLocal();
      final d = DateTime(l.year, l.month, l.day);
      if (d.isAtSameMomentAs(today)) c++;
    }
    return c;
  }

  static String _placeShort(Earthquake e) {
    final p = e.location;
    return p.length > 24 ? '${p.substring(0, 24)}…' : p;
  }

  Widget _miniItem(BuildContext ctx, Earthquake q) {
    final time = DateFormat('HH:mm').format(q.date.toLocal());
    return ListTile(
      dense: true,
      leading: CircleAvatar(
        radius: 16,
        child: Text(q.magnitude.toStringAsFixed(1)),
      ),
      title: Text(q.location, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(time),
      onTap: () => Navigator.pushNamed(ctx, '/detail', arguments: q),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title, value, subtitle;
  final IconData icon;
  const _StatCard(
      {required this.title,
      required this.value,
      required this.subtitle,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 170,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              // ignore: deprecated_member_use
              color: Colors.black.withOpacity(.05),
              blurRadius: 8,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20),
          const SizedBox(height: 8),
          Text(value,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(title, style: Theme.of(context).textTheme.bodySmall),
          Text(subtitle,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.grey)),
        ],
      ),
    );
  }
}

class _EmptyChart extends StatelessWidget {
  final String text;
  const _EmptyChart({required this.text});
  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
          border: Border.all(color: Colors.black12),
          borderRadius: BorderRadius.circular(12)),
      child: Text(text),
    );
  }
}
