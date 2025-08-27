import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../data/models/earthquake_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  Future<void> showEarthquakeNotification(Earthquake earthquake) async {
    const androidDetails = AndroidNotificationDetails(
      'earthquake_channel',
      'Deprem Bildirimleri',
      channelDescription: 'Deprem uyarı bildirimleri',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      earthquake.date.millisecondsSinceEpoch,
      '🚨 ${earthquake.magnitude.toStringAsFixed(1)} Büyüklüğünde Deprem!',
      '📍 ${earthquake.location}\n🕐 ${_formatTime(earthquake.date)}',
      details,
    );
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap
  }
}
