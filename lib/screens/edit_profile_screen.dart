import 'package:flutter/material.dart';
import '../widgets/custom_app_bar.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _nameController =
  TextEditingController(text: "Trần Thị Bích");
  final TextEditingController _phoneController =
  TextEditingController(text: "0912345678");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildCustomAppBar(
        "Chỉnh sửa thông tin",
        Icons.person_outline,
        showBack: true,
        context: context,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const CircleAvatar(radius: 40, backgroundImage: AssetImage('assets/avatar.png')),
            const SizedBox(height: 24),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Họ tên"),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: "Số điện thoại"),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Thông tin đã được cập nhật!")),
                );
              },
              child: const Text("Lưu thay đổi"),
            ),
          ],
        ),
      ),
    );
  }
}
