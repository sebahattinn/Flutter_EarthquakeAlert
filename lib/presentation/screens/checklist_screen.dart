import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/safe_scroll_wrapper.dart';

class ChecklistScreen extends StatefulWidget {
  const ChecklistScreen({super.key});

  @override
  State<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistScreen> {
  final List<_Item> _items = [
    _Item('Su (kişi başı günlük 3L, en az 3 gün)'),
    _Item('Konserve/enerji barı'),
    _Item('İlk yardım çantası'),
    _Item('El feneri + piller'),
    _Item('Powerbank + kablo'),
    _Item('Islak mendil / hijyen seti'),
    _Item('Termal battaniye'),
    _Item('Düdük'),
    _Item('Yedek giysi / çorap'),
    _Item('Nakit / kimlik fotokopisi'),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final done = prefs.getStringList('kit_done') ?? [];
    setState(() {
      for (var i = 0; i < _items.length; i++) {
        _items[i].checked = done.contains(_items[i].title);
      }
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'kit_done',
      _items.where((e) => e.checked).map((e) => e.title).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = _items.where((e) => e.checked).length / _items.length;

    return Scaffold(
      appBar: AppBar(title: const Text('Deprem Çantası')),
      // 👇 Column'ı tek bir widget olarak SafeScrollWrapper.child içine koyduk
      body: SafeScrollWrapper(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LinearProgressIndicator(value: progress),
            const SizedBox(height: 12),

            // 👇 ListView artık scroll ETMİYOR (SafeScrollWrapper kaydırıyor)
            ListView.separated(
              itemCount: _items.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (ctx, i) {
                final it = _items[i];
                return CheckboxListTile(
                  title: Text(it.title),
                  value: it.checked,
                  onChanged: (v) {
                    setState(() => it.checked = v ?? false);
                    _save();
                  },
                );
              },
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _Item {
  final String title;
  bool checked;
  _Item(this.title, {this.checked = false});
}
