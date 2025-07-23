import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'live_tracking_map_screen.dart';
import '../main.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

class NotificationService {
  static final _notifications = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();
    const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        final payload = response.payload;
        if (payload != null && payload.contains('|')) {
          _handleNotificationTap(payload);
        }
      },
    );
  }

  Future<void> cancel(int id) async {
    await _notifications.cancel(id);
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    await _notifications.zonedSchedule(
      id,
      '📚 $title',
      '⏰ $body',
      tz.TZDateTime.from(scheduledTime, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'schedule_channel',
          'Lịch học',
          channelDescription: 'Thông báo nhắc lịch học cho học sinh',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          enableLights: true,
          visibility: NotificationVisibility.public,
          ticker: 'Lịch học sắp tới',
          icon: '@mipmap/ic_launcher',
          colorized: true,
          color: Color(0xFF2196F3),
          styleInformation: BigTextStyleInformation(
            '📌 $body\n',
            contentTitle: '📚 $title',
            summaryText: '🔔 Nhắc lịch học',
          ),
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation
          .absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
    );
  }

  Future<void> scheduleLiveTrackingNotification({
    required int id,
    required String toLatLng,
    required Duration duration,
    required String type,
    required DateTime scheduledTime,
  }) async {
    final payload =
        '$toLatLng|${scheduledTime.toIso8601String()}|${duration
        .inSeconds}|$type';

    final isStart = type == 'start';
    final title = isStart
        ? '📍 Đang theo dõi đến lớp'
        : '📍 Đang theo dõi về nhà';
    final summary =
    isStart
        ? '🧭 Theo dõi hành trình đến trường'
        : '🧭 Theo dõi hành trình về nhà';
    final detail = isStart
        ? '➡️ Nhấn để xem quãng đường đến lớp'
        : '➡️ Nhấn để xem quãng đường về nhà';

    final scheduledTZ = tz.TZDateTime.from(scheduledTime, tz.local);

    await _notifications.zonedSchedule(
      id,
      title,
      detail,
      scheduledTZ,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'tracking_channel_id',
          'Thông báo theo dõi trực tiếp',
          channelDescription: 'Theo dõi hành trình học sinh đang diễn ra',
          importance: Importance.max,
          priority: Priority.high,
          ongoing: true,
          autoCancel: false,
          playSound: false,
          visibility: NotificationVisibility.public,
          colorized: true,
          color: const Color(0xFF4CAF50),
          icon: '@mipmap/ic_launcher',
          styleInformation: BigTextStyleInformation(
            detail,
            contentTitle: title,
            summaryText: summary,
          ),
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
      payload: payload,
    );

    // 🔔 Tự động hủy thông báo sau duration kể từ scheduledTime
    final cancelDelay = scheduledTZ.difference(DateTime.now()) + duration;
    Timer(cancelDelay, () {
      _notifications.cancel(id);
      print("🛑 Đã tự hủy thông báo tracking ID: $id sau duration");
    });
  }
}

  void _handleNotificationTap(String payload) {
  print("🟢 Đã nhận tap vào thông báo với payload: $payload");
  final parts = payload.split('|');
  if (parts.length >= 4) {
    final location = parts[0].split(',');
    final startTime = DateTime.tryParse(parts[1]);
    final totalSeconds = int.tryParse(parts[2]);
    final type = parts[3];

    if (location.length == 2 && startTime != null && totalSeconds != null) {
      final lat = double.tryParse(location[0]);
      final lng = double.tryParse(location[1]);

      final now = DateTime.now();
      final elapsed = now.difference(startTime).inSeconds;
      final secondsLeft = totalSeconds - elapsed;

      if (lat != null && lng != null && secondsLeft > 0) {
        print("⏳ Còn lại $secondsLeft giây để đến nơi");
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => LiveTrackingMapScreen(
              destination: LatLng(lat, lng),
              eta: Duration(seconds: secondsLeft),
              type: type,
            ),
          ),
        );
      } else {
        print("⚠️ Thời gian ETA đã hết");
      }
    }
  }
}
