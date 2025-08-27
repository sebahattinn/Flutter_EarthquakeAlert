import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/earthquake_service.dart';
import '../../core/services/notification_service.dart';
import '../../data/models/earthquake_model.dart';

class EarthquakeProvider extends ChangeNotifier {
  final EarthquakeService _service = EarthquakeService();
  final NotificationService _notificationService = NotificationService();

  // STATE
  List<Earthquake> _earthquakes = [];
  bool _isLoading = false;
  String? _error;

  // Settings
  double _minMagnitude = 3.0;
  bool _notificationsEnabled = true;
  Set<String> _notifiedEarthquakes = {};

  // Stream subscription
  StreamSubscription<List<Earthquake>>? _sub;
  bool _watching = false;

  // Getters
  List<Earthquake> get earthquakes => _earthquakes;
  bool get isLoading => _isLoading;
  String? get error => _error;
  double get minMagnitude => _minMagnitude;
  bool get notificationsEnabled => _notificationsEnabled;

  EarthquakeProvider() {
    _loadSettings();
    _startWatching(); // anlık izleme
  }

  // ---------------- Settings ----------------
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _minMagnitude = prefs.getDouble('minMagnitude') ?? 3.0;
    _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
    _notifiedEarthquakes =
        prefs.getStringList('notifiedEarthquakes')?.toSet() ?? {};
    notifyListeners();
  }

  Future<void> updateMinMagnitude(double value) async {
    _minMagnitude = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('minMagnitude', value);
    notifyListeners();
  }

  Future<void> toggleNotifications(bool value) async {
    _notificationsEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificationsEnabled', value);
    notifyListeners();
  }

  // ---------------- Streaming (watch) ----------------
  void _startWatching() {
    if (_watching) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    _sub = _service
        .watchEarthquakes(interval: const Duration(seconds: 2), limit: 50)
        .listen((list) async {
      // Liste güncellendi (en yeni deprem değişti)
      _earthquakes = list;
      _isLoading = false;
      _error = null;
      notifyListeners();

      // Bildirim: sadece EN YENİ kayıt için (spam'i önlemek için)
      if (_notificationsEnabled && list.isNotEmpty) {
        final newest = list.first;
        if (newest.magnitude >= _minMagnitude &&
            !_notifiedEarthquakes.contains(newest.id)) {
          await _notificationService.showEarthquakeNotification(newest);
          _notifiedEarthquakes.add(newest.id);

          final prefs = await SharedPreferences.getInstance();
          await prefs.setStringList(
              'notifiedEarthquakes', _notifiedEarthquakes.toList());
        }
      }
    }, onError: (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }, cancelOnError: false);

    _watching = true;
  }

  void stopWatching() {
    _sub?.cancel();
    _sub = null;
    _watching = false;
  }

  // Manuel tek seferlik fetch (çekmek istersen UI’dan çağırabilirsin)
  Future<void> fetchEarthquakes() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final earthquakes = await _service.fetchEarthquakes(limit: 50);
      _earthquakes = earthquakes;

      // İsteğe bağlı: manuel refresh’te de yeni en üst kaydı bildir
      if (_notificationsEnabled && earthquakes.isNotEmpty) {
        final newest = earthquakes.first;
        if (newest.magnitude >= _minMagnitude &&
            !_notifiedEarthquakes.contains(newest.id)) {
          await _notificationService.showEarthquakeNotification(newest);
          _notifiedEarthquakes.add(newest.id);

          final prefs = await SharedPreferences.getInstance();
          await prefs.setStringList(
              'notifiedEarthquakes', _notifiedEarthquakes.toList());
        }
      }

      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ---------------- Helpers for UI ----------------
  List<Earthquake> getTodayEarthquakes() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return _earthquakes.where((eq) {
      final local = eq.date.toLocal();
      final eqDate = DateTime(local.year, local.month, local.day);
      return eqDate.isAtSameMomentAs(today);
    }).toList();
  }

  List<Earthquake> getSignificantEarthquakes() {
    return _earthquakes.where((eq) => eq.magnitude >= 4.0).toList();
  }

  List<Earthquake> getFilteredEarthquakes({
    double? minMagnitude,
    double? maxMagnitude,
    String? searchQuery,
  }) {
    return _earthquakes.where((eq) {
      if (minMagnitude != null && eq.magnitude < minMagnitude) return false;
      if (maxMagnitude != null && eq.magnitude > maxMagnitude) return false;
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase();
        return eq.location.toLowerCase().contains(q);
      }
      return true;
    }).toList();
  }

  @override
  void dispose() {
    stopWatching();
    super.dispose();
  }
}
