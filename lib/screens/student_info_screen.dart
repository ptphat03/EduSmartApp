import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'main_navigation_screen.dart';
import 'user_info_screen.dart';

class StudentInfoScreen extends StatefulWidget {
  const StudentInfoScreen({super.key});

  @override
  State<StudentInfoScreen> createState() => _StudentInfoScreenState();
}

class _StudentInfoScreenState extends State<StudentInfoScreen> {
  final nameController = TextEditingController();
  final schoolController = TextEditingController();
  final dobController = TextEditingController();
  String selectedGender = 'Nam';
  DateTime? selectedDob;
  bool isLoading = false;

  Future<void> saveInfo() async {
    final name = nameController.text.trim();
    final school = schoolController.text.trim();

    if (name.isEmpty || school.isEmpty || selectedDob == null) {
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
      'gender': selectedGender,
      'dob': Timestamp.fromDate(selectedDob!),
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

  Future<void> selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2010, 1, 1),
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        selectedDob = picked;
        dobController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  void handleDobInput(String value) {
    try {
      final parts = value.split('/');
      if (parts.length == 3) {
        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        final parsed = DateTime(year, month, day);
        if (parsed.isBefore(DateTime.now())) {
          setState(() => selectedDob = parsed);
        }
      }
    } catch (_) {
      // Nếu sai định dạng thì không gán
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông tin học sinh'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const UserInfoScreen()),
            );
          },
          // hoặc Navigator.pushReplacement nếu cần
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Họ và tên'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Giới tính: ', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: selectedGender,
                  items: const [
                    DropdownMenuItem(value: 'Nam', child: Text('Nam')),
                    DropdownMenuItem(value: 'Nữ', child: Text('Nữ')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedGender = value!;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: dobController,
              keyboardType: TextInputType.datetime,
              decoration: InputDecoration(
                labelText: 'Ngày sinh (VD:01/01/2025)',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () => selectDate(context),
                ),
              ),
              onChanged: handleDobInput,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: schoolController,
              decoration: const InputDecoration(labelText: 'Trường'),
            ),
            const SizedBox(height: 24),
            isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton.icon(
              onPressed: saveInfo,
              icon: const Icon(Icons.save),
              label: const Text('Lưu & tiếp tục'),
            ),
          ],
        ),
      ),
    );
  }
}
