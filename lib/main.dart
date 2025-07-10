import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/login_screen.dart';
import 'screens/login_test_screen.dart';
import 'screens/test.dart';
import 'screens/notification_service.dart';
import 'screens/payment_screen.dart';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await NotificationService().init(); // ⬅ khởi tạo flutter_local_notifications

  runApp(const MyApp());
}

Future<void> _initializeNotifications() async {
  // Khởi tạo timezone
  tz.initializeTimeZones();

  // Thiết lập cài đặt khởi tạo Android
  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );


  // 📢 Xin quyền thông báo (chỉ cần thiết Android 13+)
  final status = await Permission.notification.request();
  if (status != PermissionStatus.granted) {
    debugPrint('❌ Quyền gửi thông báo bị từ chối');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey, // ✅ Thêm dòng này
      title: 'Flutter Demo',
      home: LoginScreenTest(), // hoặc màn hình chính bạn muốn
    );
  }
}

