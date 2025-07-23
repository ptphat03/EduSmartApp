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
import 'screens/payment_screen.dart';
import 'screens/tracking_board_screen.dart';

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
      navigatorKey: navigatorKey,
      // ✅ để điều hướng toàn cục nếu cần
      title: 'EduSmart',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const LoginScreenTest(),
      routes: {
        '/payment': (context) => const PaymentScreen(),
        '/tracking': (context) => const TrackingBoardScreen(), // 👈 Thêm route nếu cần// 👈 route thêm vào
      },
    );
  }

}