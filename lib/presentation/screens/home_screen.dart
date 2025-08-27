import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../providers/earthquake_provider.dart';
import '../widgets/earthquake_card.dart';
import '../../routes/app_routes.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // mini-splash kilit bayrağı (üst üste açılmasın)
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Deprem Türkiye',
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _goWithMiniSplash(
              () => Navigator.pushNamed(context, AppRoutes.settings),
            ),
          ),
        ],
      ),
      body: Consumer<EarthquakeProvider>(
        builder: (context, provider, _) {
          // Yükleniyor (ilk açılış)
          if (provider.isLoading && provider.earthquakes.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          // Hata
          if (provider.error != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 64, color: AppColors.primary),
                    const SizedBox(height: 16),
                    Text(
                      provider.error!,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => provider.fetchEarthquakes(),
                      child: const Text('Tekrar Dene'),
                    ),
                  ],
                ),
              ),
            );
          }

          // Boş durum
          if (provider.earthquakes.isEmpty) {
            return RefreshIndicator.adaptive(
              onRefresh: provider.fetchEarthquakes,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 80),
                  Icon(Icons.public, size: 72, color: AppColors.textLight),
                  SizedBox(height: 12),
                  Center(
                    child: Text(
                      'Henüz deprem verisi bulunamadı.\nAşağı çekerek yenileyin.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textLight),
                    ),
                  ),
                  SizedBox(height: 80),
                ],
              ),
            );
          }

          // Normal durum: tek scroll + pull-to-refresh
          return RefreshIndicator.adaptive(
            onRefresh: provider.fetchEarthquakes,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // Son Deprem kartı
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.getMagnitudeColor(
                              provider.earthquakes.first.magnitude),
                          AppColors.getMagnitudeColor(
                                  provider.earthquakes.first.magnitude)
                              .withOpacity(0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Son Deprem',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          provider.earthquakes.first.magnitude
                              .toStringAsFixed(1),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.location_on,
                                color: Colors.white, size: 18),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                provider.earthquakes.first.location,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 16),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.access_time,
                                color: Colors.white, size: 18),
                            const SizedBox(width: 4),
                            Text(
                              _formatDate(provider.earthquakes.first.date),
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 14),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Hızlı Erişim – sabit yükseklik YOK; küçük ekranlarda satır kırılır
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _QuickBtn(
                          icon: Icons.analytics_outlined,
                          label: 'Analiz',
                          onTap: () => _goWithMiniSplash(
                            () => Navigator.pushNamed(
                                context, AppRoutes.analytics),
                          ),
                        ),
                        _QuickBtn(
                          icon: Icons.map_outlined,
                          label: 'Harita',
                          onTap: () => _goWithMiniSplash(
                            () => Navigator.pushNamed(context, AppRoutes.map),
                          ),
                        ),
                        _QuickBtn(
                          icon: Icons.backpack_outlined,
                          label: 'Çanta',
                          onTap: () => _goWithMiniSplash(
                            () => Navigator.pushNamed(
                                context, AppRoutes.checklist),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Hızlı istatistikler – Wrap ile akışkan
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _StatCard(
                          title: 'Bugün',
                          value: '${provider.getTodayEarthquakes().length}',
                          icon: Icons.today,
                          color: AppColors.secondary,
                        ),
                        _StatCard(
                          title:
                              '≥ ${provider.minMagnitude.toStringAsFixed(1)}',
                          value:
                              '${provider.getSignificantEarthquakes().length}',
                          icon: Icons.warning,
                          color: AppColors.accent,
                        ),
                        _StatCard(
                          title: 'Toplam',
                          value: '${provider.earthquakes.length}',
                          icon: Icons.public,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ),

                // Bölüm başlığı
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Son Depremler',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                ),

                // Deprem listesi (yalnızca ilk 10)
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final earthquake = provider.earthquakes[index];
                      return EarthquakeCard(
                        earthquake: earthquake,
                        onTap: () => _goWithMiniSplash(
                          () => Navigator.pushNamed(
                            context,
                            AppRoutes.earthquakeDetail,
                            arguments: earthquake,
                          ),
                        ),
                      );
                    },
                    childCount: provider.earthquakes.length > 10
                        ? 10
                        : provider.earthquakes.length,
                  ),
                ),

                // Tümünü gör
                if (provider.earthquakes.length > 10)
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      child: ElevatedButton(
                        onPressed: () => _goWithMiniSplash(
                          () => Navigator.pushNamed(
                              context, AppRoutes.earthquakeList),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Tümünü Görüntüle'),
                      ),
                    ),
                  ),

                // Alt boşluk
                const SliverToBoxAdapter(child: SizedBox(height: 12)),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
          switch (index) {
            case 0:
              break;
            case 1:
              _goWithMiniSplash(
                () => Navigator.pushNamed(context, AppRoutes.earthquakeList),
              );
              break;
            case 2:
              _goWithMiniSplash(
                () => Navigator.pushNamed(context, AppRoutes.info),
              );
              break;
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Ana Sayfa',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_outlined),
            selectedIcon: Icon(Icons.list),
            label: 'Depremler',
          ),
          NavigationDestination(
            icon: Icon(Icons.info_outline),
            selectedIcon: Icon(Icons.info),
            label: 'Bilgi',
          ),
        ],
      ),
    );
  }

  /// Mini-splash: await ETMİYORUZ; kısa gecikme -> pop -> action
  Future<void> _goWithMiniSplash(Future<void> Function() action) async {
    if (_busy) return;
    _busy = true;

    showGeneralDialog(
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.05),
      context: context,
      pageBuilder: (_, __, ___) {
        return Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(.08), blurRadius: 16)
              ],
            ),
            child: const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.6),
            ),
          ),
        );
      },
      transitionBuilder: (_, anim, __, child) =>
          Opacity(opacity: anim.value, child: child),
      transitionDuration: const Duration(milliseconds: 150),
    );

    // kısa göster -> kapat -> sonra aksiyon
    await Future.delayed(const Duration(milliseconds: 250));
    if (mounted) {
      try {
        Navigator.of(context, rootNavigator: true).pop(); // dialog kapat
      } catch (_) {}
    }
    await action();

    _busy = false;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} dakika önce';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} saat önce';
    } else {
      return '${difference.inDays} gün önce';
    }
  }
}

/// Hızlı erişim butonu (Wrap ile akışkan)
class _QuickBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickBtn({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        width: 104, // küçük ekranlarda ikinci satıra geçebilir
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 8)
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

/// İstatistik kartı (yükseklik sabit değil; içerik kadar)
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: color),
          ),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: color.withOpacity(0.8)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
