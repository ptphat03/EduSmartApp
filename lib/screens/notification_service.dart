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
      '📚 $title', // ví dụ: 📚 Toán học - Tiết 1
      '⏰ $body',  // ví dụ: ⏰ Bắt đầu lúc 7:30 sáng, Phòng A101
      tz.TZDateTime.from(scheduledTime, tz.local),
      NotificationDetails( // bỏ const vì có biến
        android: AndroidNotificationDetails(
          'schedule_channel', // ID kênh
          'Lịch học',          // Tên hiển thị trong setting
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
          color: Color(0xFF2196F3), // Màu xanh dương đặc trưng cho học tập
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
    final scheduledTime = tz.TZDateTime.now(tz.local).add(const Duration(seconds: 1));

    await _notifications.zonedSchedule(
      999,
      '📍 Bắt đầu theo dõi học sinh',
      '🚶 Theo dõi vị trí đến: $toLatLng\n➡️ Nhấn để mở bản đồ',
      scheduledTime,
      NotificationDetails( // ❌ bỏ 'const' ở đây
        android: AndroidNotificationDetails(
          'tracking_channel_id',
          'Thông báo theo dõi trực tiếp',
          channelDescription: 'Thông báo khi đến giờ theo dõi vị trí học sinh',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'Tracking Started',
          ongoing: true,
          autoCancel: false,
          visibility: NotificationVisibility.public,
          playSound: true,
          enableLights: true,
          colorized: true,
          color: Color(0xFF4CAF50),
          icon: '@mipmap/ic_launcher',
          styleInformation: BigTextStyleInformation(
            '🚶 Đã đến giờ theo dõi hành trình học sinh.\n'
                '➡️ Nhấn vào đây để xem bản đồ với vị trí đến: $toLatLng',
            contentTitle: '📍 Bắt đầu theo dõi',
            summaryText: 'Tracking started • Live mode',
          ),
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
