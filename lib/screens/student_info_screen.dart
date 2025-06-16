import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'main_navigation_screen.dart';
import 'user_info_screen.dart';
import 'package:flutter/services.dart'; // thêm dòng này ở đầu

class StudentInfoScreen extends StatefulWidget {
  const StudentInfoScreen({super.key});

  @override
  State<StudentInfoScreen> createState() => _StudentInfoScreenState();
}

class _StudentInfoScreenState extends State<StudentInfoScreen> {
  final studentNameController = TextEditingController();
  final dobController = TextEditingController();
  final schoolController = TextEditingController();
  final phoneController = TextEditingController();
  DateTime? selectedDob;
  String gender = 'Nam';
  bool isLoading = false;

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
    } catch (_) {}
  }

  Future<void> saveStudentInfo() async {
    final name = studentNameController.text.trim();
    final school = schoolController.text.trim();
    final phone = phoneController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng điền đầy đủ thông tin.')),
      );
      return;
    }

    if (selectedDob == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ngày sinh không đúng định dạng dd/MM/yyyy.')),
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
      'student_name': name,
      'student_dob': Timestamp.fromDate(selectedDob!),
      'student_phone': phone,
      'student_school': school,
      'student_gender': gender,
      'created_at': FieldValue.serverTimestamp(),
    };

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('students')
          .add(data); // Lưu vào subcollection students của user

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
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        title: const Text(
          "Thông tin học sinh",
          style: TextStyle(
            fontSize: 24, // bạn có thể chỉnh to hơn nếu cần, ví dụ 22
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const UserInfoScreen()),
            );
          },
        ),
      ),

      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            elevation: 6,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    "Nhập thông tin học sinh",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: studentNameController,
                    decoration: const InputDecoration(
                      labelText: "Tên học sinh",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: gender,
                    decoration: const InputDecoration(
                      labelText: "Giới tính",
                      border: OutlineInputBorder(),
                    ),
                    items: ['Nam', 'Nữ', 'Khác']
                        .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                        .toList(),
                    onChanged: (value) => setState(() => gender = value ?? 'Nam'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: dobController,
                    keyboardType: TextInputType.datetime,
                    decoration: InputDecoration(
                      labelText: 'Ngày sinh (dd/MM/yyyy)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.cake),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () => selectDate(context),
                      ),
                    ),
                    onChanged: handleDobInput,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneController,
                    decoration: const InputDecoration(
                      labelText: "Số điện thoại",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly, // Chỉ cho phép nhập 0–9
                    ],
                  ),
                  const SizedBox(height: 12),


                  TextField(
                    controller: schoolController,
                    decoration: const InputDecoration(
                      labelText: "Trường học",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.school),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton.icon(
                      icon: const Icon(Icons.save, color: Colors.white),
                      label: const Text(
                        "Lưu & Tiếp tục",
                        style: TextStyle(color: Colors.white, fontSize: 17),
                      ),
                      onPressed: saveStudentInfo,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        foregroundColor: Colors.white, // giúp icon và ripple effect cũng màu trắng
                        textStyle: const TextStyle(fontSize: 18),
                      ),
                    ),
                  )

                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
