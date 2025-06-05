import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main_navigation_screen.dart';

class StudentInfoScreen extends StatefulWidget {
  const StudentInfoScreen({super.key});

  @override
  State<StudentInfoScreen> createState() => _StudentInfoScreenState();
}

class _StudentInfoScreenState extends State<StudentInfoScreen> {
  final nameController = TextEditingController();
  final gradeController = TextEditingController();
  final schoolController = TextEditingController();
  bool isLoading = false;

  Future<void> saveInfo() async {
    final name = nameController.text.trim();
    final grade = gradeController.text.trim();
    final school = schoolController.text.trim();

    if (name.isEmpty || grade.isEmpty || school.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng điền đầy đủ thông tin.')),
      );
      return;
    }

    setState(() => isLoading = true);
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy người dùng!')),
      );
      setState(() => isLoading = false);
      return;
    }

    final data = {
      'uid': user.uid,
      'email': user.email ?? '',
      'phone': user.phoneNumber ?? '',
      'name': name,
      'grade': grade,
      'school': school,
      'createdAt': FieldValue.serverTimestamp(),
    };

    try {
      await FirebaseFirestore.instance
          .collection('students')
          .doc(user.uid)
          .set(data, SetOptions(merge: true));

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi lưu dữ liệu: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thông tin học sinh')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Họ và tên'),
            ),
            TextField(
              controller: gradeController,
              decoration: const InputDecoration(labelText: 'Lớp'),
            ),
            TextField(
              controller: schoolController,
              decoration: const InputDecoration(labelText: 'Trường'),
            ),
            const SizedBox(height: 20),
            isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
              onPressed: saveInfo,
              child: const Text('Lưu & tiếp tục'),
            ),
          ],
        ),
      ),
    );
  }
}
