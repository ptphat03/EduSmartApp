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
  Timer? _countdownTimer;

  Future<void> init() async {
    tz.initializeTimeZones();
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
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

  Future<bool> startLiveTrackingCountdown({
    required LatLng toLatLng,
    Duration? duration,
  }) async {
    try {
      Position currentPosition = await Geolocator.getCurrentPosition();
      double distanceMeters = Geolocator.distanceBetween(
        currentPosition.latitude,
        currentPosition.longitude,
        toLatLng.latitude,
        toLatLng.longitude,
      );

      double speed = currentPosition.speed > 1 ? currentPosition.speed : 5; // m/s mặc định
      double estimatedSeconds = distanceMeters / speed;
      Duration eta = Duration(seconds: estimatedSeconds.round());

      print("⏳ Bắt đầu ETA đếm ngược: \${eta.inSeconds}s");
      await Future.delayed(eta);

      print("✅ Đã đến nơi");
      return true;
    } catch (e) {
      print("❌ Lỗi ETA: \$e");
      return false;
    }
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
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
    );
  }

  Future<void> showLiveTrackingNotification({
    required String toLatLng,
    required Duration duration,
  }) async {
    final now = DateTime.now();
    final payload = '$toLatLng|${now.toIso8601String()}|${duration.inSeconds}';

    // 1. Hiển thị thông báo ngay
    await _notifications.show(
      999,
      '📍 Đang theo dõi học sinh',
      '🚶 Vị trí đến: $toLatLng\n➡️ Nhấn để mở bản đồ',
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
            '🚶 Vị trí đến: $toLatLng\n➡️ Nhấn vào đây để xem bản đồ',
            contentTitle: '📍 Đang theo dõi',
            summaryText: 'Live tracking đang diễn ra',
          ),
        ),
      ),
      payload: payload,
    );

    // 2. Tự động hủy sau thời gian đếm ngược
    Future.delayed(duration, () async {
      await _notifications.cancel(999); // Hủy thông báo chính
    });
  }
}

void _handleNotificationTap(String payload) {
  print("🟢 Đã nhận tap vào thông báo với payload: $payload");
  final parts = payload.split('|');
  if (parts.length == 3) {
    final location = parts[0].split(',');
    final startTime = DateTime.tryParse(parts[1]);
    final totalSeconds = int.tryParse(parts[2]);

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
            ),
          ),
        );
      } else {
        print("⚠️ Thời gian ETA đã hết");
      }
    }
  }
}

