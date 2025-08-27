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
      body: Consumer<EarthquakeProvider>(
        builder: (context, provider, _) {
          return ListView(
            children: [
              // Notification settings
              Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
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
                    SwitchListTile(
                      title: const Text('Bildirimleri Aç'),
                      subtitle: const Text('Deprem bildirimleri alın'),
                      value: provider.notificationsEnabled,
                      activeColor: AppColors.primary,
                      onChanged: (value) => provider.toggleNotifications(value),
                    ),
                    const Divider(),
                    ListTile(
                      title: const Text('Minimum Büyüklük'),
                      subtitle: Text(
                        'Sadece ${provider.minMagnitude.toStringAsFixed(1)} ve üzeri depremler için bildirim',
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          provider.minMagnitude.toStringAsFixed(1),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Slider(
                        value: provider.minMagnitude,
                        min: 2.0,
                        max: 7.0,
                        divisions: 10,
                        activeColor: AppColors.primary,
                        label: provider.minMagnitude.toStringAsFixed(1),
                        onChanged: provider.notificationsEnabled
                            ? (value) => provider.updateMinMagnitude(value)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),

              // About section
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Column(
                  children: [
                    ListTile(
                      leading:
                          Icon(Icons.info_outline, color: AppColors.secondary),
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
          );
        },
      ),
    );
  }
}
