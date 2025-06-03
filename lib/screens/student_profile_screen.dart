import 'package:flutter/material.dart';

class StudentProfileScreen extends StatelessWidget {
  const StudentProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Thông tin học sinh"),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundImage: AssetImage('assets/avatar.png'), // hoặc NetworkImage nếu cần
            ),
            const SizedBox(height: 16),
            const Text(
              "Nguyễn Văn A",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text("Lớp: 5A2"),
            const Text("Ngày sinh: 12/04/2013"),
            const Text("Giới tính: Nam"),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("👨‍👩‍👧 Thông tin phụ huynh",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),
            infoRow("Họ tên phụ huynh", "Trần Thị Bích"),
            infoRow("Số điện thoại", "0912345678"),
            infoRow("Email", "phuhuynh@example.com"),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.edit),
              label: const Text("Chỉnh sửa thông tin"),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orangeAccent),
            )
          ],
        ),
      ),
    );
  }

  static Widget infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
              flex: 2,
              child: Text("$label:",
                  style: const TextStyle(fontWeight: FontWeight.w600))),
          Expanded(flex: 3, child: Text(value)),
        ],
      ),
    );
  }
}
