import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math' as math;

import '../../core/constants/app_colors.dart';
import '../widgets/safe_scroll_wrapper.dart';

class InfoScreen extends StatefulWidget {
  const InfoScreen({super.key});

  @override
  State<InfoScreen> createState() => _InfoScreenState();
}

class _InfoScreenState extends State<InfoScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _pulseAnimationController;
  late AnimationController _rotationAnimationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;

  int _selectedMagnitudeIndex = 3; // Default to magnitude 4-5

  final List<_MagnitudeInfo> _magnitudeData = [
    _MagnitudeInfo(
      range: '0-2',
      description: 'Genellikle hissedilmez',
      color: Colors.green,
      effects: 'Sadece sismograflarla tespit edilir',
      frequency: 'Günde binlerce',
      icon: Icons.circle_outlined,
    ),
    _MagnitudeInfo(
      range: '2-3',
      description: 'Çok hafif',
      color: Colors.lightGreen,
      effects: 'Üst katlarda hafif sallanma',
      frequency: 'Günde yüzlerce',
      icon: Icons.trip_origin,
    ),
    _MagnitudeInfo(
      range: '3-4',
      description: 'Hafif',
      color: Colors.yellow,
      effects: 'Asılı eşyalar sallanır',
      frequency: 'Günde onlarca',
      icon: Icons.radio_button_unchecked,
    ),
    _MagnitudeInfo(
      range: '4-5',
      description: 'Orta şiddetli',
      color: Colors.orange,
      effects: 'Herkes hisseder, eşyalar düşer',
      frequency: 'Günde birkaç tane',
      icon: Icons.adjust,
    ),
    _MagnitudeInfo(
      range: '5-6',
      description: 'Güçlü',
      color: Colors.deepOrange,
      effects: 'Mobilyalar hareket eder, çatlaklar',
      frequency: 'Ayda birkaç tane',
      icon: Icons.gps_not_fixed,
    ),
    _MagnitudeInfo(
      range: '6-7',
      description: 'Şiddetli',
      color: Colors.red,
      effects: 'Binalarda hasar, paniğe neden olur',
      frequency: 'Yılda birkaç tane',
      icon: Icons.warning,
    ),
    _MagnitudeInfo(
      range: '7-8',
      description: 'Çok şiddetli',
      color: Colors.red[700]!,
      effects: 'Binalar yıkılır, yer çatlar',
      frequency: 'Yılda 1-2 tane',
      icon: Icons.dangerous,
    ),
    _MagnitudeInfo(
      range: '8+',
      description: 'Felaket',
      color: Colors.red[900]!,
      effects: 'Geniş çaplı yıkım ve tsunami riski',
      frequency: 'Yılda 1 veya daha az',
      icon: Icons.crisis_alert,
    ),
  ];

  final List<_EarthquakeMyth> _myths = [
    _EarthquakeMyth(
      myth: 'Depremler belirli mevsimlerde daha çok olur',
      truth: 'Depremler mevsimsel değildir. Her zaman eşit olasılıkla olabilir.',
      icon: Icons.calendar_today,
    ),
    _EarthquakeMyth(
      myth: 'Hayvanlar depremi önceden hisseder',
      truth: 'Bilimsel kanıt yoktur. Hayvanlar strese tepki verebilir ama deprem tahmin edemezler.',
      icon: Icons.pets,
    ),
    _EarthquakeMyth(
      myth: 'Depremler hava durumu ile ilgilidir',
      truth: 'Hava koşulları depremle ilgisizdir. Yeraltındaki tektonik hareketler nedeniyledir.',
      icon: Icons.cloud,
    ),
    _EarthquakeMyth(
      myth: 'Büyük şehirler deprem riski taşımaz',
      truth: 'İstanbul, İzmir gibi büyük şehirler de yüksek deprem riski altındadır.',
      icon: Icons.location_city,
    ),
    _EarthquakeMyth(
      myth: 'Küçük depremler büyük depremi önler',
      truth: 'Küçük depremler enerjiyi yeterince boşaltmaz. Büyük deprem riskini azaltmaz.',
      icon: Icons.trending_down,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _startAnimations();
  }

  void _initializeControllers() {
    try {
      _tabController = TabController(length: 4, vsync: this);
      
      _pulseAnimationController = AnimationController(
        duration: const Duration(milliseconds: 1500),
        vsync: this,
      );
      
      _rotationAnimationController = AnimationController(
        duration: const Duration(seconds: 4),
        vsync: this,
      );

      _pulseAnimation = Tween<double>(
        begin: 1.0,
        end: 1.15,
      ).animate(CurvedAnimation(
        parent: _pulseAnimationController,
        curve: Curves.easeInOut,
      ));

      _rotationAnimation = Tween<double>(
        begin: 0,
        end: 2 * math.pi,
      ).animate(CurvedAnimation(
        parent: _rotationAnimationController,
        curve: Curves.linear,
      ));
    } catch (e) {
      debugPrint('Error initializing controllers: $e');
    }
  }

  void _startAnimations() {
    try {
      // Only start rotation animation, no continuous pulse
      _rotationAnimationController.repeat();
    } catch (e) {
      debugPrint('Error starting animations: $e');
    }
  }

  void _updateMagnitudeSelection(int newIndex) {
    if (newIndex == _selectedMagnitudeIndex) return;
    
    try {
      setState(() {
        _selectedMagnitudeIndex = newIndex;
      });

      // Only do a single pulse for dangerous magnitudes, not continuous
      if (newIndex > 4) {
        _pulseAnimationController.reset();
        _pulseAnimationController.forward().then((_) {
          if (mounted) {
            _pulseAnimationController.reverse();
          }
        });
      } else {
        _pulseAnimationController.stop();
        _pulseAnimationController.reset();
      }
    } catch (e) {
      debugPrint('Error updating magnitude selection: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Deprem Eğitim Merkezi'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.timeline), text: 'Büyüklük'),
            Tab(icon: Icon(Icons.psychology), text: 'Efsaneler'),
            Tab(icon: Icon(Icons.shield), text: 'Güvenlik'),
            Tab(icon: Icon(Icons.phone), text: 'Acil'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMagnitudeTab(),
          _buildMythsTab(),
          _buildSafetyTab(),
          _buildEmergencyTab(),
        ],
      ),
    );
  }

  Widget _buildMagnitudeTab() {
    return SafeScrollWrapper(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Interactive Magnitude Selector
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primary.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Text(
                  'Deprem Büyüklüğünü Keşfet',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                
                // Optimized Magnitude Visual Indicator
                _buildMagnitudeIndicator(),
                
                const SizedBox(height: 20),
                
                // Optimized Magnitude Slider
                _buildMagnitudeSlider(),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Selected Magnitude Details
          _buildMagnitudeDetails(),

          const SizedBox(height: 20),

          // All Magnitudes Overview
          _buildMagnitudeOverview(),
        ],
      ),
    );
  }

  Widget _buildMagnitudeIndicator() {
    final currentMagnitude = _magnitudeData[_selectedMagnitudeIndex];
    
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: currentMagnitude.color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: currentMagnitude.color.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: _selectedMagnitudeIndex > 4 ? 8 : 4,
          ),
        ],
      ),
      child: _selectedMagnitudeIndex > 4
          ? AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return _buildIndicatorContent(currentMagnitude);
              },
            )
          : _buildIndicatorContent(currentMagnitude),
    );
  }

  Widget _buildIndicatorContent(_MagnitudeInfo magnitude) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            magnitude.icon,
            size: 40,
            color: Colors.white,
          ),
          const SizedBox(height: 4),
          Text(
            magnitude.range,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMagnitudeSlider() {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        activeTrackColor: Colors.white,
        inactiveTrackColor: Colors.white30,
        thumbColor: Colors.white,
        overlayColor: Colors.white.withOpacity(0.2),
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
      ),
      child: Slider(
        value: _selectedMagnitudeIndex.toDouble(),
        min: 0,
        max: _magnitudeData.length - 1.0,
        divisions: _magnitudeData.length - 1,
        onChanged: (value) {
          final newIndex = value.round();
          _updateMagnitudeSelection(newIndex);
        },
      ),
    );
  }

  Widget _buildMagnitudeDetails() {
    final currentMagnitude = _magnitudeData[_selectedMagnitudeIndex];
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: currentMagnitude.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  currentMagnitude.icon,
                  color: currentMagnitude.color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Büyüklük ${currentMagnitude.range}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      currentMagnitude.description,
                      style: TextStyle(
                        fontSize: 16,
                        color: currentMagnitude.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDetailRow(Icons.visibility, 'Etkiler', currentMagnitude.effects),
          const SizedBox(height: 8),
          _buildDetailRow(Icons.schedule, 'Sıklık', currentMagnitude.frequency),
        ],
      ),
    );
  }

  Widget _buildMagnitudeOverview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tüm Büyüklük Seviyeleri',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _magnitudeData.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final magnitude = _magnitudeData[index];
            final isSelected = index == _selectedMagnitudeIndex;
            
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: isSelected ? magnitude.color.withOpacity(0.1) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: isSelected ? Border.all(color: magnitude.color, width: 2) : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: magnitude.color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(magnitude.icon, color: magnitude.color, size: 20),
                ),
                title: Text(
                  'Büyüklük ${magnitude.range}',
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  ),
                ),
                subtitle: Text(magnitude.description),
                trailing: isSelected 
                  ? Icon(Icons.radio_button_checked, color: magnitude.color)
                  : const Icon(Icons.radio_button_unchecked, color: Colors.grey),
                onTap: () => _updateMagnitudeSelection(index),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMythsTab() {
    return SafeScrollWrapper(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.red, Colors.pink],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              children: [
                Icon(Icons.psychology, size: 48, color: Colors.white),
                SizedBox(height: 12),
                Text(
                  'Deprem Efsaneleri vs Gerçekler',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  'Yaygın yanlış inançları gerçeklerle karşılaştır',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _myths.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              return _buildMythCard(_myths[index]);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMythCard(_EarthquakeMyth myth) {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Myth Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.close, color: Colors.red, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'EFSANE',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        myth.myth,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Truth Section
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.check, color: Colors.green, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'GERÇEK',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        myth.truth,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyTab() {
    return SafeScrollWrapper(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Animated Safety Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.green, Colors.teal],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                // Simplified safety header without continuous rotation
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: const Icon(Icons.shield, size: 48, color: Colors.white),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Güvenlik Protokolleri',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Deprem öncesi, sırası ve sonrası yapılacaklar',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          _buildSafetySection(
            'Deprem Öncesi Hazırlık',
            [
              'Evde güvenli noktaları belirleyin (sağlam masa altları)',
              'Deprem çantası hazırlayın ve erişilebilir yerde tutun',
              'Ağır eşyaları sabitleyin, yüksek raflara koymayın',
              'Gaz, elektrik ve su vanalarının yerini öğrenin',
              'Aile toplanma noktası belirleyin',
              'Acil durum numaralarını ezberleyin',
              'Yapısal güçlendirme yaptırın (gerekiyorsa)',
            ],
            Icons.build_circle,
            Colors.blue,
          ),

          const SizedBox(height: 16),

          _buildSafetySection(
            'Deprem Anında',
            [
              'ÇÖK: Yere çömelin',
              'KAPAN: Sağlam masa altına girin',
              'TUTUN: Masaya sıkıca tutunun',
              'Asansör kullanmayın',
              'Cam eşyalardan uzak durun',
              'Kapı eşiğinde durmayın (eski bilgi)',
              'Sarsıntı bitene kadar bekleyin',
            ],
            Icons.warning_amber,
            Colors.orange,
          ),

          const SizedBox(height: 16),

          _buildSafetySection(
            'Deprem Sonrası',
            [
              'Yaralanmaları kontrol edin, ilk yardım yapın',
              'Gaz vanasını kapatın, elektrik anahtarını kesin',
              'Hasarlı binalardan uzaklaşın',
              'Artçı sarsıntılara hazır olun',
              'Resmi açıklamaları takip edin',
              'Gereksiz telefon görüşmesi yapmayın',
              'Toplanma alanına gidin',
              'Hasarları fotoğraflayın (sigorta için)',
            ],
            Icons.healing,
            Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildSafetySection(String title, List<String> items, IconData icon, Color color) {
    return Container(
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
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: items.asMap().entries.map((entry) {
                final index = entry.key + 1;
                final item = entry.value;
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            '$index',
                            style: TextStyle(
                              color: color,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item,
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyTab() {
    return SafeScrollWrapper(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Emergency Numbers Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.red, Colors.red[700]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              children: [
                Icon(Icons.emergency, size: 48, color: Colors.white),
                SizedBox(height: 12),
                Text(
                  'Acil Durum İletişim',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Dokunun ve anında arayın',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Updated Turkish Emergency Numbers (All unified under 112)
          _buildEmergencyNumberCard(
            'Genel Acil Çağrı',
            '112',
            'Ambulans, İtfaiye, Polis, Jandarma',
            Icons.emergency,
            Colors.red,
          ),

          const SizedBox(height: 12),

          _buildEmergencyNumberCard(
            'AFAD Acil Durum',
            '122',
            'Afet ve Acil Durum Yönetimi',
            Icons.crisis_alert,
            Colors.orange,
          ),

          const SizedBox(height: 20),

          // Additional Important Numbers
          Container(
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
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.phone_in_talk, color: Colors.grey),
                      SizedBox(width: 12),
                      Text(
                        'Diğer Önemli Numaralar',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildSimpleEmergencyNumber('Sahil Güvenlik', '158', Icons.sailing),
                _buildSimpleEmergencyNumber('Orman Yangını', '177', Icons.forest),
                _buildSimpleEmergencyNumber('İtfaiye (Eski)', '110', Icons.local_fire_department, isDeprecated: true),
                _buildSimpleEmergencyNumber('Polis (Eski)', '155', Icons.local_police, isDeprecated: true),
                _buildSimpleEmergencyNumber('Jandarma (Eski)', '156', Icons.security, isDeprecated: true),
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    '⚠️ Eski numaralar halen çalışmaktadır ancak tüm acil durumlar için 112\'yi arayın.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Important Information Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info, color: Colors.amber[700]),
                    const SizedBox(width: 8),
                    Text(
                      'Önemli Hatırlatmalar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  '• Türkiye\'de tüm acil durumlar için 112\'yi arayın\n'
                  '• Sakin olmaya çalışın ve net konuşun\n'
                  '• Bulunduğunuz konumu tarif edin\n'
                  '• Yaralanma durumunu belirtin\n'
                  '• Hat meşgul olabilir, tekrar deneyin\n'
                  '• AFAD (122) özellikle deprem için önemlidir',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyNumberCard(String title, String number, String description, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _makePhoneCall(number),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: color, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Text(
                    number,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSimpleEmergencyNumber(String title, String number, IconData icon, {bool isDeprecated = false}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _makePhoneCall(number),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(
                icon, 
                color: isDeprecated ? Colors.grey[400] : Colors.grey[600], 
                size: 20
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    color: isDeprecated ? Colors.grey[500] : null,
                    decoration: isDeprecated ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: isDeprecated 
                    ? Colors.grey[200] 
                    : AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  number,
                  style: TextStyle(
                    color: isDeprecated ? Colors.grey[500] : AppColors.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _makePhoneCall(String number) async {
    try {
      final uri = Uri(scheme: 'tel', path: number);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showErrorSnackBar('$number numarası aranamıyor');
      }
    } catch (e) {
      debugPrint('Error making phone call: $e');
      _showErrorSnackBar('Arama sırasında hata oluştu');
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    try {
      _tabController.dispose();
      _pulseAnimationController.dispose();
      _rotationAnimationController.dispose();
    } catch (e) {
      debugPrint('Error disposing controllers: $e');
    }
    super.dispose();
  }
}

// Data Classes
class _MagnitudeInfo {
  final String range;
  final String description;
  final Color color;
  final String effects;
  final String frequency;
  final IconData icon;

  _MagnitudeInfo({
    required this.range,
    required this.description,
    required this.color,
    required this.effects,
    required this.frequency,
    required this.icon,
  });
}

class _EarthquakeMyth {
  final String myth;
  final String truth;
  final IconData icon;

  _EarthquakeMyth({
    required this.myth,
    required this.truth,
    required this.icon,
  });
}