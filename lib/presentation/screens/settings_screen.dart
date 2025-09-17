import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../providers/earthquake_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Ayarlar'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          // Bildirim Ayarları Container
          Container(
            margin: const EdgeInsets.all(16),
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
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Bildirim Ayarları',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                // Switch sadece kendi Consumer ile rebuild oluyor
                Consumer<EarthquakeProvider>(
                  builder: (context, provider, _) => SwitchListTile(
                    title: const Text('Bildirimleri Aç'),
                    subtitle: const Text('Deprem bildirimleri alın'),
                    value: provider.notificationsEnabled,
                    activeThumbColor: AppColors.primary,
                    onChanged: (value) => provider.toggleNotifications(value),
                  ),
                ),
                const Divider(),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text('Minimum Büyüklük'),
                ),
                // Slider için performanslı widget
                const _MinMagnitudeSlider(),
                const SizedBox(height: 16),
              ],
            ),
          ),

          // Hakkında Container
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
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
            child: const Column(
              children: [
                ListTile(
                  leading: Icon(Icons.info_outline, color: AppColors.secondary),
                  title: Text('Versiyon'),
                  subtitle: Text('1.0.0+1'),
                ),
                Divider(),
                ListTile(
                  leading: Icon(Icons.source, color: AppColors.secondary),
                  title: Text('Veri Kaynağı'),
                  subtitle: Text('Kandilli Rasathanesi'),
                ),
                Divider(),
                ListTile(
                  leading: Icon(Icons.update, color: AppColors.secondary),
                  title: Text('Güncelleme Sıklığı'),
                  subtitle: Text('5 dakikada bir'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ---------------- Slider Widget ----------------
class _MinMagnitudeSlider extends StatefulWidget {
  const _MinMagnitudeSlider();

  @override
  State<_MinMagnitudeSlider> createState() => _MinMagnitudeSliderState();
}

class _MinMagnitudeSliderState extends State<_MinMagnitudeSlider> {
  late ValueNotifier<double> _sliderValue;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<EarthquakeProvider>(context, listen: false);
    _sliderValue = ValueNotifier<double>(provider.minMagnitude);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<EarthquakeProvider>(context, listen: false);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ValueListenableBuilder<double>(
        valueListenable: _sliderValue,
        builder: (context, value, child) {
          return Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  // ignore: deprecated_member_use
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  value.toStringAsFixed(1),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              Slider(
                value: value,
                min: 2.0,
                max: 7.0,
                divisions: 10,
                activeColor: AppColors.primary,
                label: value.toStringAsFixed(1),
                onChanged: provider.notificationsEnabled
                    ? (newValue) => _sliderValue.value = newValue
                    : null,
                onChangeEnd: provider.notificationsEnabled
                    ? (newValue) => provider.updateMinMagnitude(newValue)
                    : null,
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _sliderValue.dispose();
    super.dispose();
  }
}
