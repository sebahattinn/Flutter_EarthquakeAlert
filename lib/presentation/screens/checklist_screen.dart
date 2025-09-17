import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../widgets/safe_scroll_wrapper.dart';

class ChecklistScreen extends StatefulWidget {
  const ChecklistScreen({super.key});

  @override
  State<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  
  // Emergency Kit Items
  final List<_EmergencyItem> _emergencyKit = [
    _EmergencyItem(
      'Su (kişi başı günlük 3L, en az 3 gün)',
      'Su yaşamın temel ihtiyacıdır. Temiz su olmadan 3 günden fazla yaşayamazsınız.',
      Icons.water_drop,
      _ItemCategory.water,
    ),
    _EmergencyItem(
      'Konserve/enerji barı (3 günlük)',
      'Uzun süre dayanıklı yiyecekler. Açacağı da unutmayın!',
      Icons.fastfood,
      _ItemCategory.food,
    ),
    _EmergencyItem(
      'İlk yardım çantası',
      'Yara bandı, antiseptik, ağrı kesici, termometre içermelidir.',
      Icons.medical_services,
      _ItemCategory.medical,
    ),
    _EmergencyItem(
      'El feneri + yedek piller',
      'LED fener tercih edin, pil ömrü daha uzundur.',
      Icons.flashlight_on,
      _ItemCategory.tools,
    ),
    _EmergencyItem(
      'Powerbank + şarj kablosu',
      'Telefon şarjı için. En az 10.000 mAh kapasiteli olmalı.',
      Icons.battery_charging_full,
      _ItemCategory.electronics,
    ),
    _EmergencyItem(
      'Islak mendil / hijyen seti',
      'Kişisel temizlik için vazgeçilmez.',
      Icons.cleaning_services,
      _ItemCategory.hygiene,
    ),
    _EmergencyItem(
      'Termal battaniye',
      'Vücut ısısını korur, kompakt ve hafiftir.',
      Icons.single_bed,
      _ItemCategory.shelter,
    ),
    _EmergencyItem(
      'Acil durum düdüğü',
      'Yardım çağırmak için ses çıkarır.',
      Icons.campaign,
      _ItemCategory.tools,
    ),
    _EmergencyItem(
      'Yedek giysi / çorap',
      'Su geçirmez poşette saklanmalıdır.',
      Icons.checkroom,
      _ItemCategory.clothing,
    ),
    _EmergencyItem(
      'Nakit para / kimlik fotokopisi',
      'Su geçirmez poşette saklayın. Kartlar çalışmayabilir.',
      Icons.account_balance_wallet,
      _ItemCategory.documents,
    ),
    _EmergencyItem(
      'İlaçlar (reçeteli)',
      'Düzenli kullandığınız ilaçların en az 1 haftalığı.',
      Icons.medication,
      _ItemCategory.medical,
    ),
    _EmergencyItem(
      'Çok fonksiyonlu çakı',
      'Konserve açacağı, makas, bıçak içeren model.',
      Icons.build,
      _ItemCategory.tools,
    ),
  ];

  // Safety Tips
  final List<_SafetyTip> _safetyTips = [
    _SafetyTip(
      'Deprem Sırasında',
      'Eğilin, Korunun, Tutunun! Masanın altına girin ve sakin kalın.',
      Icons.security,
      Colors.red,
    ),
    _SafetyTip(
      'Güvenli Noktalar',
      'Sağlam masa/kapı altı güvenlidir. Cam, ayna yakınından uzak durun.',
      Icons.home,
      Colors.green,
    ),
    _SafetyTip(
      'Deprem Sonrası',
      'Gaz vanasını kapatın, elektrik anahtarını kesin. Aftershock\'lara hazır olun.',
      Icons.warning,
      Colors.orange,
    ),
    _SafetyTip(
      'Tahliye Planı',
      'Ailenizle toplanma noktası belirleyin. En az 2 çıkış yolu bilin.',
      Icons.exit_to_app,
      Colors.blue,
    ),
    _SafetyTip(
      'İletişim',
      'Şehir dışından bir yakınınızın numarasını ezberleyin.',
      Icons.phone,
      Colors.purple,
    ),
  ];

  // Knowledge Quiz Questions
  final List<_QuizQuestion> _quizQuestions = [
    _QuizQuestion(
      'Deprem sırasında yapılması gereken ilk şey nedir?',
      ['Koşarak dışarı çıkmak', 'Eğilmek, korunmak, tutunmak', 'Pencereyi açmak', 'Asansöre binmek'],
      1,
      'Eğilin, korunun, tutunun kuralı en güvenli yaklaşımdır.',
    ),
    _QuizQuestion(
      'Deprem çantası nerede tutulmalı?',
      ['Bodrum katında', 'Kolay erişilebilir yerde', 'Balkonda', 'Garajda'],
      1,
      'Acil durumda hızlıca alabilmeniz için erişilebilir olmalı.',
    ),
    _QuizQuestion(
      'Kişi başı günlük kaç litre su gereklidir?',
      ['1 litre', '2 litre', '3 litre', '5 litre'],
      2,
      'Kişi başı günde minimum 3 litre su içmek gerekir.',
    ),
    _QuizQuestion(
      'Deprem sonrası ilk yapılacak şey nedir?',
      ['Gaz vanasını kapatmak', 'Sosyal medyada paylaşım yapmak', 'Dışarı çıkmak', 'Fotoğraf çekmek'],
      0,
      'Gaz kaçağı yangına neden olabilir, ilk önce vanayı kapatın.',
    ),
  ];

  int _currentQuizIndex = 0;
  int _quizScore = 0;
  bool _quizCompleted = false;
  bool _showQuizAnswer = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final completed = prefs.getStringList('emergency_kit_completed') ?? [];
    
    setState(() {
      for (var item in _emergencyKit) {
        item.isCompleted = completed.contains(item.title);
      }
    });
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    final completed = _emergencyKit
        .where((item) => item.isCompleted)
        .map((item) => item.title)
        .toList();
    await prefs.setStringList('emergency_kit_completed', completed);
  }

  void _resetQuiz() {
    setState(() {
      _currentQuizIndex = 0;
      _quizScore = 0;
      _quizCompleted = false;
      _showQuizAnswer = false;
    });
  }

  void _answerQuestion(int selectedAnswer) {
    if (_showQuizAnswer) return;
    
    setState(() {
      _showQuizAnswer = true;
      if (selectedAnswer == _quizQuestions[_currentQuizIndex].correctAnswer) {
        _quizScore++;
      }
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      
      setState(() {
        if (_currentQuizIndex < _quizQuestions.length - 1) {
          _currentQuizIndex++;
          _showQuizAnswer = false;
        } else {
          _quizCompleted = true;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Acil Durum Hazırlığı'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.list_alt), text: 'Çanta'),
            Tab(icon: Icon(Icons.lightbulb), text: 'İpuçları'),
            Tab(icon: Icon(Icons.quiz), text: 'Quiz'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildEmergencyKitTab(),
          _buildSafetyTipsTab(),
          _buildQuizTab(),
        ],
      ),
    );
  }

  Widget _buildEmergencyKitTab() {
    final completedItems = _emergencyKit.where((item) => item.isCompleted).length;
    final progress = completedItems / _emergencyKit.length;

    return SafeScrollWrapper(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Progress Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.emergency, color: Colors.white, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Hazırlık Durumu',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '$completedItems/${_emergencyKit.length} öğe tamamlandı',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${(progress * 100).round()}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white30,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Category Stats
          _buildCategoryStats(),

          const SizedBox(height: 16),

          // Emergency Kit Items
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _emergencyKit.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = _emergencyKit[index];
              return _buildEmergencyKitItem(item);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryStats() {
    Map<_ItemCategory, List<_EmergencyItem>> categoryGroups = {};
    for (var item in _emergencyKit) {
      categoryGroups.putIfAbsent(item.category, () => []).add(item);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          const Text(
            'Kategori Durumu',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: categoryGroups.entries.map((entry) {
              final completed = entry.value.where((item) => item.isCompleted).length;
              final total = entry.value.length;
              final isComplete = completed == total;
              
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isComplete 
                    ? AppColors.primary.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isComplete ? AppColors.primary : Colors.grey,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isComplete ? Icons.check_circle : Icons.circle_outlined,
                      size: 16,
                      color: isComplete ? AppColors.primary : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_getCategoryName(entry.key)} ($completed/$total)',
                      style: TextStyle(
                        fontSize: 12,
                        color: isComplete ? AppColors.primary : Colors.grey[700],
                        fontWeight: isComplete ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyKitItem(_EmergencyItem item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: CheckboxListTile(
        value: item.isCompleted,
        onChanged: (value) {
          setState(() {
            item.isCompleted = value ?? false;
          });
          _saveData();
        },
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getCategoryColor(item.category).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                item.icon,
                color: _getCategoryColor(item.category),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      decoration: item.isCompleted 
                        ? TextDecoration.lineThrough 
                        : null,
                      color: item.isCompleted 
                        ? Colors.grey 
                        : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        controlAffinity: ListTileControlAffinity.trailing,
        activeColor: AppColors.primary,
      ),
    );
  }

  Widget _buildSafetyTipsTab() {
    return SafeScrollWrapper(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Güvenlik İpuçları',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _safetyTips.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final tip = _safetyTips[index];
              return Container(
                padding: const EdgeInsets.all(16),
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
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: tip.color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            tip.icon,
                            color: tip.color,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            tip.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      tip.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        height: 1.4,
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

  Widget _buildQuizTab() {
    if (_quizCompleted) {
      return _buildQuizResultsView();
    }

    final question = _quizQuestions[_currentQuizIndex];

    return SafeScrollWrapper(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Quiz Progress
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Soru ${_currentQuizIndex + 1}/${_quizQuestions.length}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Puan: $_quizScore',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: (_currentQuizIndex + 1) / _quizQuestions.length,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Question
          Container(
            padding: const EdgeInsets.all(20),
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
            child: Text(
              question.question,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 20),

          // Answer Options
          ...question.options.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;
            final isCorrect = index == question.correctAnswer;
            final isSelected = _showQuizAnswer;

            Color? backgroundColor;
            Color? textColor;

            if (_showQuizAnswer) {
              if (isCorrect) {
                backgroundColor = Colors.green.withOpacity(0.1);
                textColor = Colors.green[700];
              } else {
                backgroundColor = Colors.red.withOpacity(0.1);
                textColor = Colors.red[700];
              }
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Material(
                color: backgroundColor ?? Colors.white,
                borderRadius: BorderRadius.circular(12),
                elevation: _showQuizAnswer ? 0 : 2,
                shadowColor: Colors.black.withOpacity(0.1),
                child: InkWell(
                  onTap: () => _answerQuestion(index),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: _showQuizAnswer
                          ? Border.all(
                              color: isCorrect ? Colors.green : Colors.red,
                              width: 2,
                            )
                          : null,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: textColor?.withOpacity(0.2) ?? AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              String.fromCharCode(65 + index), // A, B, C, D
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: textColor ?? AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            option,
                            style: TextStyle(
                              fontSize: 16,
                              color: textColor,
                            ),
                          ),
                        ),
                        if (_showQuizAnswer && isCorrect)
                          const Icon(Icons.check_circle, color: Colors.green),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),

          if (_showQuizAnswer) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info, color: Colors.blue[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      question.explanation,
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuizResultsView() {
    final percentage = (_quizScore / _quizQuestions.length * 100).round();
    String resultMessage;
    Color resultColor;
    IconData resultIcon;

    if (percentage >= 80) {
      resultMessage = 'Mükemmel! Deprem konusunda çok bilgilisiniz!';
      resultColor = Colors.green;
      resultIcon = Icons.emoji_events;
    } else if (percentage >= 60) {
      resultMessage = 'İyi! Biraz daha çalışarak mükemmel olabilirsiniz.';
      resultColor = Colors.orange;
      resultIcon = Icons.thumb_up;
    } else {
      resultMessage = 'Deprem hazırlığı konusunda daha çok öğrenmeniz gerekiyor.';
      resultColor = Colors.red;
      resultIcon = Icons.school;
    }

    return SafeScrollWrapper(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: resultColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Icon(
                    resultIcon,
                    size: 48,
                    color: resultColor,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Quiz Tamamlandı!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$_quizScore/${_quizQuestions.length} doğru',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: resultColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '%$percentage',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: resultColor,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  resultMessage,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _resetQuiz,
            icon: const Icon(Icons.refresh),
            label: const Text('Tekrar Dene'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getCategoryName(_ItemCategory category) {
    switch (category) {
      case _ItemCategory.water: return 'Su';
      case _ItemCategory.food: return 'Yiyecek';
      case _ItemCategory.medical: return 'Tıbbi';
      case _ItemCategory.tools: return 'Araçlar';
      case _ItemCategory.electronics: return 'Elektronik';
      case _ItemCategory.hygiene: return 'Hijyen';
      case _ItemCategory.shelter: return 'Barınak';
      case _ItemCategory.clothing: return 'Giyim';
      case _ItemCategory.documents: return 'Belgeler';
    }
  }

  Color _getCategoryColor(_ItemCategory category) {
    switch (category) {
      case _ItemCategory.water: return Colors.blue;
      case _ItemCategory.food: return Colors.orange;
      case _ItemCategory.medical: return Colors.red;
      case _ItemCategory.tools: return Colors.grey;
      case _ItemCategory.electronics: return Colors.purple;
      case _ItemCategory.hygiene: return Colors.green;
      case _ItemCategory.shelter: return Colors.brown;
      case _ItemCategory.clothing: return Colors.indigo;
      case _ItemCategory.documents: return Colors.teal;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

// Data Classes
class _EmergencyItem {
  final String title;
  final String description;
  final IconData icon;
  final _ItemCategory category;
  bool isCompleted;

  _EmergencyItem(
    this.title,
    this.description,
    this.icon,
    this.category, {
    this.isCompleted = false,
  });
}

enum _ItemCategory {
  water,
  food,
  medical,
  tools,
  electronics,
  hygiene,
  shelter,
  clothing,
  documents,
}

class _SafetyTip {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  _SafetyTip(this.title, this.description, this.icon, this.color);
}

class _QuizQuestion {
  final String question;
  final List<String> options;
  final int correctAnswer;
  final String explanation;

  _QuizQuestion(this.question, this.options, this.correctAnswer, this.explanation);
}