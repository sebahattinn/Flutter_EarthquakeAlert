import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../widgets/safe_scroll_wrapper.dart';

class InfoScreen extends StatelessWidget {
  const InfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Deprem Bilgileri'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      // Tek scroll için SafeScrollWrapper kullanıyoruz
      body: SafeScrollWrapper(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildInfoSection(
              'Deprem Anında Yapılması Gerekenler',
              [
                'Sakin olun ve panik yapmayın',
                'Güvenli bir yere (masa altı, yatak yanı üçgen alanlar) sığının',
                'Çök-Kapan-Tutun pozisyonunu alın',
                'Pencere ve aynalardan uzak durun',
                'Asansör kullanmayın',
                'Deprem bitene kadar güvenli alanda kalın',
              ],
              Icons.warning_amber_rounded,
              AppColors.primary,
            ),
            const SizedBox(height: 16),
            _buildInfoSection(
              'Deprem Çantası İçeriği',
              [
                'Su (kişi başı günde 3 litre)',
                'Konserve ve kuru gıdalar',
                'İlk yardım malzemeleri',
                'El feneri ve yedek piller',
                'Düdük',
                'Radyo',
                'Battaniye',
                'Önemli evrakların fotokopileri',
                'Nakit para',
                'Telefon şarj aleti (powerbank)',
              ],
              Icons.backpack,
              AppColors.secondary,
            ),
            const SizedBox(height: 16),
            _buildInfoSection(
              'Deprem Sonrası',
              [
                'Artçılardan korunun',
                'Hasarlı binalardan uzak durun',
                'Gaz kaçağı kontrolü yapın',
                'Telefon hatlarını meşgul etmeyin',
                'Resmi açıklamaları takip edin',
                'Toplanma alanlarına gidin',
              ],
              Icons.info_outline,
              AppColors.accent,
            ),
            const SizedBox(height: 16),
            _buildEmergencyNumbers(context),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(
    String title,
    List<String> items,
    IconData icon,
    Color color,
  ) {
    return Container(
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
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 28),
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
              children: items.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 6),
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item,
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.5,
                            color: AppColors.textDark,
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

  Widget _buildEmergencyNumbers(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFFD62828)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.phone, color: Colors.white, size: 28),
              SizedBox(width: 12),
              Text(
                'Acil Durum Numaraları',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildEmergencyNumber(context, 'AFAD', '122'),
          _buildEmergencyNumber(context, 'Ambulans', '112'),
          _buildEmergencyNumber(context, 'İtfaiye', '110'),
          _buildEmergencyNumber(context, 'Polis', '155'),
          _buildEmergencyNumber(context, 'Jandarma', '156'),
        ],
      ),
    );
  }

  Widget _buildEmergencyNumber(
      BuildContext context, String label, String number) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _call(number),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
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
    );
  }

  Future<void> _call(String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
