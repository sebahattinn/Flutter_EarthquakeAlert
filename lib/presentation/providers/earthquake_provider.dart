import 'package:flutter/material.dart';
import '../../core/services/earthquake_service.dart';
import '../../core/services/notification_service.dart';
import '../../data/models/earthquake_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EarthquakeProvider extends ChangeNotifier {
  final EarthquakeService _service = EarthquakeService();
  final NotificationService _notificationService = NotificationService();

  List<Earthquake> _earthquakes = [];
  bool _isLoading = false;
  String? _error;

  // Settings
  double _minMagnitude = 3.0;
  bool _notificationsEnabled = true;
  Set<String> _notifiedEarthquakes = {};

  List<Earthquake> get earthquakes => _earthquakes;
  bool get isLoading => _isLoading;
  String? get error => _error;
  double get minMagnitude => _minMagnitude;
  bool get notificationsEnabled => _notificationsEnabled;

  EarthquakeProvider() {
    _loadSettings();
    _startPeriodicFetch();
  }

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

  void _startPeriodicFetch() {
    fetchEarthquakes();
    // Fetch every 5 minutes
    Future.delayed(const Duration(minutes: 5), () {
      _startPeriodicFetch();
    });
  }

  Future<void> fetchEarthquakes() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final earthquakes = await _service.fetchEarthquakes();
      _earthquakes = earthquakes;

      // Check for new significant earthquakes
      if (_notificationsEnabled) {
        for (final eq in earthquakes) {
          if (eq.magnitude >= _minMagnitude &&
              !_notifiedEarthquakes.contains(eq.id)) {
            await _notificationService.showEarthquakeNotification(eq);
            _notifiedEarthquakes.add(eq.id);

            // Save notified earthquakes
            final prefs = await SharedPreferences.getInstance();
            await prefs.setStringList(
                'notifiedEarthquakes', _notifiedEarthquakes.toList());
          }
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

  List<Earthquake> getTodayEarthquakes() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return _earthquakes.where((eq) {
      final eqDate = DateTime(eq.date.year, eq.date.month, eq.date.day);
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
        final query = searchQuery.toLowerCase();
        return eq.location.toLowerCase().contains(query);
      }
      return true;
    }).toList();
  }
}
