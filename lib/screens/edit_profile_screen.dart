import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final user = FirebaseAuth.instance.currentUser;
  bool isLoading = true;
  bool _editingEmail = false;
  final emailChangeController = TextEditingController();

  final displayNameController = TextEditingController();
  final phoneController = TextEditingController();
  final genderController = TextEditingController();
  final dobController = TextEditingController();
  DateTime? userDob;
  String userName = '';
  List<Map<String, dynamic>> students = [];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final uid = user?.uid;
    if (uid == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final userData = userDoc.data() ?? {};

      displayNameController.text = userData['user_display_name'] ?? '';
      phoneController.text = userData['user_phone'] ?? '';
      genderController.text = userData['user_gender'] ?? '';
      userName = userData['user_name'] ?? '';
      final rawUserDob = userData['user_dob'];
      if (rawUserDob is Timestamp) {
        userDob = rawUserDob.toDate();
        dobController.text = DateFormat('dd/MM/yyyy').format(userDob!);
      }

      final studentDocs = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('students')
          .get();

      students = studentDocs.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': TextEditingController(text: data['student_name']),
          'phone': TextEditingController(text: data['student_phone']),
          'gender': TextEditingController(text: data['student_gender']),
          'dob': TextEditingController(
              text: data['student_dob'] != null
                  ? DateFormat('dd/MM/yyyy').format((data['student_dob'] as Timestamp).toDate())
                  : ''),
          'dob_raw': data['student_dob'] != null ? (data['student_dob'] as Timestamp).toDate() : null,
          'school': TextEditingController(text: data['student_school']),
        };
      }).toList();

      setState(() => isLoading = false);
    } catch (e) {
      debugPrint("Lỗi tải dữ liệu: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> saveData() async {
    if (!_formKey.currentState!.validate()) return;
    final uid = user?.uid;
    if (uid == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'user_display_name': displayNameController.text.trim(),
        'user_phone': phoneController.text.trim(),
        'user_gender': genderController.text.trim(),
        'user_dob': userDob != null ? Timestamp.fromDate(userDob!) : null,
      }, SetOptions(merge: true));

      final studentsRef = FirebaseFirestore.instance.collection('users').doc(uid).collection('students');

      for (var student in students) {
        await studentsRef.doc(student['id']).set({
          'student_name': student['name'].text.trim(),
          'student_phone': student['phone'].text.trim(),
          'student_gender': student['gender'].text.trim(),
          'student_dob': student['dob_raw'] != null ? Timestamp.fromDate(student['dob_raw']) : null,
          'student_school': student['school'].text.trim(),
        }, SetOptions(merge: true));
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cập nhật thành công")));
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint("Lỗi khi lưu: $e");
    }
  }

  Future<void> pickDate(
      BuildContext context,
      TextEditingController controller,
      void Function(DateTime) onPicked,
      ) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2010),
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      controller.text = DateFormat('dd/MM/yyyy').format(picked);
      onPicked(picked);
    }
  }

  Future<void> changeEmail() async {
    final newEmail = emailChangeController.text.trim();
    if (newEmail.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng nhập email mới.")),
      );
      return;
    }

    try {
      await user?.verifyBeforeUpdateEmail(newEmail);

      final uid = user?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'user_name': newEmail,
        }, SetOptions(merge: true));
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Đã gửi email xác minh. Hãy xác minh để hoàn tất.")),
      );
      emailChangeController.clear();
      loadData();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        await reauthenticateAndRetryEmailChange(newEmail);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: ${e.message}")));
      }
    }
  }

  Future<void> reauthenticateAndRetryEmailChange(String newEmail) async {
    final passwordController = TextEditingController();
    final email = user?.email;

    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Xác minh lại"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Nhập lại mật khẩu để xác minh:"),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Mật khẩu"),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Hủy")),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text("Xác nhận")),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final cred = EmailAuthProvider.credential(
          email: email!,
          password: passwordController.text.trim(),
        );
        await user?.reauthenticateWithCredential(cred);
        await user?.verifyBeforeUpdateEmail(newEmail);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Đã gửi email xác minh đến địa chỉ mới.")),
        );
        emailChangeController.clear();
        loadData();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chỉnh sửa hồ sơ"),
        actions: [
          IconButton(onPressed: saveData, icon: const Icon(Icons.save)),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text("Thông tin người dùng", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextFormField(controller: displayNameController, decoration: const InputDecoration(labelText: 'Tên hiển thị')),
              TextFormField(controller: phoneController, decoration: const InputDecoration(labelText: 'SĐT')),
              TextFormField(controller: genderController, decoration: const InputDecoration(labelText: 'Giới tính')),
              TextFormField(
                controller: dobController,
                readOnly: true,
                decoration: const InputDecoration(labelText: 'Ngày sinh'),
                onTap: () => pickDate(context, dobController, (d) => userDob = d),
              ),
              TextFormField(
                initialValue: userName,
                readOnly: true,
                decoration: const InputDecoration(labelText: "Email hiện tại"),
              ),
              const SizedBox(height: 10),
              if (_editingEmail) ...[
                TextField(
                  controller: emailChangeController,
                  decoration: const InputDecoration(labelText: "Email mới"),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          changeEmail();
                          setState(() => _editingEmail = false);
                        },
                        icon: const Icon(Icons.check),
                        label: const Text("Xác nhận"),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          emailChangeController.clear();
                          setState(() => _editingEmail = false);
                        },
                        icon: const Icon(Icons.cancel),
                        label: const Text("Huỷ"),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                ElevatedButton.icon(
                  onPressed: () => setState(() => _editingEmail = true),
                  icon: const Icon(Icons.email),
                  label: const Text("Đổi email"),
                ),
              ],
              const SizedBox(height: 24),
              const Text("Thông tin học sinh", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...students.map((student) {
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        TextFormField(controller: student['name'], decoration: const InputDecoration(labelText: 'Tên học sinh')),
                        TextFormField(controller: student['phone'], decoration: const InputDecoration(labelText: 'SĐT')),
                        TextFormField(controller: student['gender'], decoration: const InputDecoration(labelText: 'Giới tính')),
                        TextFormField(
                          controller: student['dob'],
                          readOnly: true,
                          decoration: const InputDecoration(labelText: 'Ngày sinh'),
                          onTap: () => pickDate(context, student['dob'], (picked) {
                            student['dob_raw'] = picked;
                          }),
                        ),
                        TextFormField(controller: student['school'], decoration: const InputDecoration(labelText: 'Trường học')),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }
}