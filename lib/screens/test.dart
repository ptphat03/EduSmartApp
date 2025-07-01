//
// import 'package:flutter/material.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:timezone/data/latest.dart' as tz;
// import 'package:timezone/timezone.dart' as tz;
// import '../main.dart';
//
// class ScheduleNotificationScreen extends StatefulWidget {
//   const ScheduleNotificationScreen({super.key});
//
//   @override
//   State<ScheduleNotificationScreen> createState() =>
//       _ScheduleNotificationScreenState();
// }
//
// class _ScheduleNotificationScreenState
//     extends State<ScheduleNotificationScreen> {
//   DateTime? selectedDateTime;
//
//   @override
//   void initState() {
//     super.initState();
//     tz.initializeTimeZones();
//   }
//
//   Future<void> _scheduleNotification(DateTime scheduledTime) async {
//     final tz.TZDateTime tzTime = tz.TZDateTime.from(scheduledTime, tz.local);
//     await flutterLocalNotificationsPlugin.zonedSchedule(
//       scheduledTime.millisecondsSinceEpoch ~/ 1000,
//       'Lịch học sắp tới',
//       'Sự kiện bắt đầu lúc ${scheduledTime.hour}:${scheduledTime.minute.toString().padLeft(2, '0')}',
//       tzTime,
//       const NotificationDetails(
//         android: AndroidNotificationDetails(
//           'schedule_channel',
//           'Lịch học',
//           importance: Importance.max,
//           priority: Priority.high,
//         ),
//       ),
//       androidAllowWhileIdle: true,
//       uiLocalNotificationDateInterpretation:
//       UILocalNotificationDateInterpretation.absoluteTime,
//       matchDateTimeComponents: DateTimeComponents.dateAndTime,
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Hẹn giờ thông báo")),
//       body: Center(
//         child: ElevatedButton(
//           child: const Text("Chọn thời gian"),
//           onPressed: () async {
//             final now = DateTime.now();
//             final selected = await showDatePicker(
//               context: context,
//               initialDate: now,
//               firstDate: now,
//               lastDate: now.add(const Duration(days: 30)),
//             );
//             if (selected != null) {
//               final time = await showTimePicker(
//                 context: context,
//                 initialTime: TimeOfDay.now(),
//               );
//               if (time != null) {
//                 final dt = DateTime(
//                   selected.year,
//                   selected.month,
//                   selected.day,
//                   time.hour,
//                   time.minute,
//                 );
//                 await _scheduleNotification(dt);
//               }
//             }
//           },
//         ),
//       ),
//     );
//   }
// }
