import 'package:flutter/material.dart';
import 'dart:async';

class GpsTrackingScreen extends StatefulWidget {
  const GpsTrackingScreen({super.key});

  @override
  State<GpsTrackingScreen> createState() => _GpsTrackingScreenState();
}

class _GpsTrackingScreenState extends State<GpsTrackingScreen> {
  String location = "Chưa xác định";
  String status = "⛔ Chưa đến trường";
  String time = "--:--";
  bool isArrived = false;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _startAutoUpdate();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _startAutoUpdate() {
    _timer = Timer.periodic(const Duration(seconds: 10), (_) {
      final now = DateTime.now();
      if (now.hour >= 7 && now.minute >= 30 && !isArrived) {
        setState(() {
          location = "Trường Tiểu học ABC - Q.1, TP.HCM";
          status = "✅ Đã đến trường (Tự động)";
          time = "${now.hour}:${now.minute.toString().padLeft(2, '0')}";
          isArrived = true;
        });
      }
    });
  }

  void updateLocationManually() {
    final now = DateTime.now();
    setState(() {
      location = "Trường Tiểu học ABC - Q.1, TP.HCM";
      status = "✅ Đã đến trường";
      time = "${now.hour}:${now.minute.toString().padLeft(2, '0')}";
      isArrived = true;
    });
  }

  void sendNotificationMock() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("📩 Thông báo đã gửi đến phụ huynh"),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Theo dõi học sinh"),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              height: 240,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                children: [
                  const Center(
                    child: Text("🌍 Bản đồ giả lập"),
                  ),
                  if (isArrived)
                    const Positioned(
                      top: 90,
                      left: 150,
                      child: Icon(Icons.location_on, color: Colors.red, size: 40),
                    ),
                  if (isArrived)
                    const Positioned(
                      bottom: 16,
                      right: 16,
                      child: Chip(
                        label: Text("🚌 Đã đến trường"),
                        backgroundColor: Colors.greenAccent,
                      ),
                    )
                ],
              ),
            ),
            const SizedBox(height: 24),
            buildInfoRow("📍 Vị trí hiện tại:", location),
            buildInfoRow("🕒 Thời gian cập nhật:", time),
            buildInfoRow("📌 Trạng thái:", status),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: updateLocationManually,
              icon: const Icon(Icons.location_on),
              label: const Text("Cập nhật vị trí thủ công"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: sendNotificationMock,
              icon: const Icon(Icons.send),
              label: const Text("Gửi thông báo đến phụ huynh"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
