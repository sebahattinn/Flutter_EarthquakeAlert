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

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  // Performance optimization: cache the formatted dates
  final Map<DateTime, String> _dateFormatCache = {};

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _dateFormatCache.clear();
    super.dispose();
    
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Deprem Türkiye'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _navigateWithTransition(
              context,
              AppRoutes.settings,
            ),
          ),
        ],
      ),
      body: Consumer<EarthquakeProvider>(
        builder: (context, provider, child) {
          // Loading state
          if (provider.isLoading && provider.earthquakes.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            );
          }

          // Error state
          if (provider.error != null) {
            return _buildErrorState(provider);
          }

          // Empty state
          if (provider.earthquakes.isEmpty) {
            return _buildEmptyState(provider);
          }

          // Main content with fade animation
          return FadeTransition(
            opacity: _fadeAnimation,
            child: RefreshIndicator.adaptive(
              onRefresh: () async {
                await provider.fetchEarthquakes();
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  // Latest earthquake card - animated
                  SliverToBoxAdapter(
                    child: TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 600),
                      tween: Tween(begin: 0.0, end: 1.0),
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: 0.9 + (0.1 * value),
                          child: Opacity(
                            opacity: value,
                            child: _buildLatestEarthquakeCard(provider),
                          ),
                        );
                      },
                    ),
                  ),

                  // Quick access buttons - staggered animation
                  SliverToBoxAdapter(
                    child: _buildQuickAccess(context),
                  ),

                  // Stats cards - optimized
                  SliverToBoxAdapter(
                    child: _buildStatsSection(provider),
                  ),

                  // Section header
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

                  // Earthquake list - optimized with SliverList
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index >= 10) return null;
                        final earthquake = provider.earthquakes[index];
                        
                        return TweenAnimationBuilder<double>(
                          duration: Duration(milliseconds: 300 + (index * 50)),
                          tween: Tween(begin: 0.0, end: 1.0),
                          builder: (context, value, child) {
                            return Transform.translate(
                              offset: Offset(0, 20 * (1 - value)),
                              child: Opacity(
                                opacity: value,
                                child: EarthquakeCard(
                                  key: ValueKey(earthquake.id),
                                  earthquake: earthquake,
                                  onTap: () => _navigateWithTransition(
                                    context,
                                    AppRoutes.earthquakeDetail,
                                    arguments: earthquake,
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                      childCount: provider.earthquakes.length > 10 
                          ? 10 
                          : provider.earthquakes.length,
                    ),
                  ),

                  // View all button
                  if (provider.earthquakes.length > 10)
                    SliverToBoxAdapter(
                      child: Container(
                        margin: const EdgeInsets.all(16),
                        child: ElevatedButton(
                          onPressed: () => _navigateWithTransition(
                            context,
                            AppRoutes.earthquakeList,
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

                  const SliverToBoxAdapter(child: SizedBox(height: 12)),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          if (index == _selectedIndex) return;
          
          setState(() => _selectedIndex = index);
          
          switch (index) {
            case 0:
              break;
            case 1:
              _navigateWithTransition(context, AppRoutes.earthquakeList);
              break;
            case 2:
              _navigateWithTransition(context, AppRoutes.info);
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

  Widget _buildLatestEarthquakeCard(EarthquakeProvider provider) {
    final latest = provider.earthquakes.first;
    final magnitudeColor = AppColors.getMagnitudeColor(latest.magnitude);
    
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            magnitudeColor,
            // ignore: deprecated_member_use
            magnitudeColor.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: magnitudeColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _navigateWithTransition(
            context,
            AppRoutes.earthquakeDetail,
            arguments: latest,
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        // ignore: deprecated_member_use
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'SON DEPREM',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      latest.magnitude.toStringAsFixed(1),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 56,
                        fontWeight: FontWeight.bold,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  latest.location,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.access_time,
                                color: Colors.white70,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatDateCached(latest.date),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAccess(BuildContext context) {
    final buttons = [
      _QuickAccessData(Icons.analytics_outlined, 'Analiz', AppRoutes.analytics),
      _QuickAccessData(Icons.map_outlined, 'Harita', AppRoutes.map),
      _QuickAccessData(Icons.backpack_outlined, 'Çanta', AppRoutes.checklist),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: buttons.asMap().entries.map((entry) {
          final index = entry.key;
          final data = entry.value;
          
          return Expanded(
            child: TweenAnimationBuilder<double>(
              duration: Duration(milliseconds: 400 + (index * 100)),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: 0.8 + (0.2 * value),
                  child: Opacity(
                    opacity: value,
                    child: _QuickAccessButton(
                      icon: data.icon,
                      label: data.label,
                      onTap: () => _navigateWithTransition(
                        context,
                        data.route,
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatsSection(EarthquakeProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              title: 'Bugün',
              value: '${provider.getTodayEarthquakes().length}',
              icon: Icons.today,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              title: '≥ ${provider.minMagnitude.toStringAsFixed(1)}',
              value: '${provider.getSignificantEarthquakes().length}',
              icon: Icons.warning,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              title: 'Toplam',
              value: '${provider.earthquakes.length}',
              icon: Icons.public,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(EarthquakeProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.primary,
            ),
            const SizedBox(height: 16),
            Text(
              provider.error!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => provider.fetchEarthquakes(),
              icon: const Icon(Icons.refresh),
              label: const Text('Tekrar Dene'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(EarthquakeProvider provider) {
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
        ],
      ),
    );
  }

  // Optimized navigation with hero animation support
  Future<void> _navigateWithTransition(
    BuildContext context,
    String route, {
    Object? arguments,
  }) async {
    await Navigator.pushNamed(
      context,
      route,
      arguments: arguments,
    );
  }

  // Cached date formatting for performance
  String _formatDateCached(DateTime date) {
    if (_dateFormatCache.containsKey(date)) {
      return _dateFormatCache[date]!;
    }
    
    final now = DateTime.now();
    final difference = now.difference(date);
    String formatted;
    
    if (difference.inMinutes < 60) {
      formatted = '${difference.inMinutes} dakika önce';
    } else if (difference.inHours < 24) {
      formatted = '${difference.inHours} saat önce';
    } else {
      formatted = '${difference.inDays} gün önce';
    }
    
    // Cache the result
    if (_dateFormatCache.length < 100) {
      _dateFormatCache[date] = formatted;
    }
    
    return formatted;
  }
}

class _QuickAccessData {
  final IconData icon;
  final String label;
  final String route;
  
  _QuickAccessData(this.icon, this.label, this.route);
}

class _QuickAccessButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAccessButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 28, color: AppColors.primary),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // ignore: deprecated_member_use
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          // ignore: deprecated_member_use
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
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
            style: TextStyle(
              fontSize: 12,
              // ignore: deprecated_member_use
              color: color.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}