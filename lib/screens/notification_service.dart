import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'live_tracking_map_screen.dart'; // 👈 đảm bảo import đúng
import '../main.dart'; // 👈 chứa navigatorKey, chỉnh đường dẫn nếu cần
import 'package:geolocator/geolocator.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

class NotificationService {
  static final _notifications = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        final payload = response.payload;
        if (payload != null && payload.contains(',')) {
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

      print("⏳ Bắt đầu ETA đếm ngược: ${eta.inSeconds}s");

      await Future.delayed(eta); // Chờ đến khi tới nơi (mô phỏng)

      print("✅ Đã đến nơi");
      return true;
    } catch (e) {
      print("❌ Lỗi ETA: $e");
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
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'schedule_channel',
          'Lịch học',
          importance: Importance.max,
          priority: Priority.high,
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
    final scheduledTime = tz.TZDateTime.now(tz.local).add(const Duration(seconds: 1));

    await _notifications.zonedSchedule(
      999,
      'Bắt đầu theo dõi',
      'Nhấn để xem vị trí: $toLatLng',
      scheduledTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'tracking_channel_id',
          'Live Tracking Notifications',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker',
          ongoing: true,     // ✅ luôn hiển thị
          autoCancel: false, // ✅ không tự đóng
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: toLatLng,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

}

/// ✅ Hàm xử lý khi nhấn vào thông báo (toLatLng dạng "10.93,106.85")
void _handleNotificationTap(String payload) {
  print("🟢 Đã nhận tap vào thông báo với payload: $payload");
  final parts = payload.split(',');
  if (parts.length == 2) {
    final lat = double.tryParse(parts[0]);
    final lng = double.tryParse(parts[1]);
    if (lat != null && lng != null) {
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => LiveTrackingMapScreen(
            destination: LatLng(lat, lng),
          ),
        ),
      );
    }
  }
}
