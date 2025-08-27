import 'dart:io' show Platform;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../data/models/earthquake_model.dart';

class NotificationService {
  // Singleton
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  /// Kurulum: iOS izin bayrakları, Android 13+ runtime izin, kanal oluşturma.
  Future<void> initialize() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
      onDidReceiveBackgroundNotificationResponse:
          _onNotificationTappedBackground,
    );

    // Android: Android 13+ bildirim izni ve kanal
    if (Platform.isAndroid) {
      final androidImpl = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      // ✅ Eski 'requestPermission()' yerine:
      await androidImpl?.requestNotificationsPermission();

      const channel = AndroidNotificationChannel(
        'earthquake_channel',
        'Deprem Bildirimleri',
        description: 'Deprem uyarı bildirimleri',
        importance: Importance.high,
      );
      await androidImpl?.createNotificationChannel(channel);
    }
  }

  /// Deprem bildirimi göster
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

    final id = earthquake.date.millisecondsSinceEpoch ~/ 1000; // benzersiz
    final title =
        '🚨 ${earthquake.magnitude.toStringAsFixed(1)} Büyüklüğünde Deprem!';
    final body =
        '📍 ${earthquake.location}\n🕐 ${_formatTime(earthquake.date)}';

    await _notifications.show(
      id,
      title,
      body,
      details,
      payload: 'quake:$id',
    );
  }

  String _formatTime(DateTime date) {
    final local = date.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  void _onNotificationTapped(NotificationResponse response) {
   
    // final payload = response.payload;
  }

  @pragma('vm:entry-point')
  static void _onNotificationTappedBackground(NotificationResponse response) {
   
  }
}
