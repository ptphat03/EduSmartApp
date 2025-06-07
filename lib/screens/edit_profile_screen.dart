import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final user = FirebaseAuth.instance.currentUser;

  final displayNameController = TextEditingController();
  final photoUrlController = TextEditingController();

  final nameController = TextEditingController();
  final schoolController = TextEditingController();
  final phoneController = TextEditingController();

  final emailChangeController = TextEditingController();
  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    if (user == null) return;

    displayNameController.text = user!.displayName ?? '';
    photoUrlController.text = user!.photoURL ?? '';

    final doc = await FirebaseFirestore.instance
        .collection('students')
        .doc(user!.uid)
        .get();

    final data = doc.data();
    if (data != null) {
      nameController.text = data['name'] ?? '';
      schoolController.text = data['school'] ?? '';
      phoneController.text = data['phone'] ?? '';
    }

    setState(() => isLoading = false);
  }

  Future<void> saveChanges() async {
    if (user == null) return;

    try {
      await user!.updateDisplayName(displayNameController.text.trim());
      await user!.updatePhotoURL(photoUrlController.text.trim());
      await user!.reload();

      await FirebaseFirestore.instance
          .collection('students')
          .doc(user!.uid)
          .set({
        'name': nameController.text.trim(),
        'school': schoolController.text.trim(),
        'phone': phoneController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cập nhật thành công!")),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi: $e")),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Đã gửi email xác minh. Hãy xác minh để hoàn tất.")),
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        await reauthenticateAndRetryEmailChange(newEmail);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: \${e.message}")));
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
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
      }
    }
  }

  Future<void> changePassword() async {
    final currentPassword = currentPasswordController.text.trim();
    final newPassword = newPasswordController.text.trim();

    if (currentPassword.isEmpty || newPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng nhập đầy đủ mật khẩu hiện tại và mới.")),
      );
      return;
    }

    try {
      final cred = EmailAuthProvider.credential(
        email: user!.email!,
        password: currentPassword,
      );
      await user!.reauthenticateWithCredential(cred);
      await user!.updatePassword(newPassword);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Đổi mật khẩu thành công.")),
      );

      currentPasswordController.clear();
      newPasswordController.clear();
    } on FirebaseAuthException catch (e) {
      String msg = "Lỗi đổi mật khẩu.";
      if (e.code == 'wrong-password') msg = "Mật khẩu hiện tại không đúng.";
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = user?.email ?? '(Không có)';
    final phone = user?.phoneNumber ?? '(Không có)';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text("Chỉnh sửa hồ sơ", style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Colors.grey[200],
                backgroundImage: (photoUrlController.text.isNotEmpty)
                    ? NetworkImage(photoUrlController.text)
                    : null,
                child: (photoUrlController.text.isEmpty)
                    ? const Icon(Icons.person, size: 60, color: Colors.grey)
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: photoUrlController,
              decoration: const InputDecoration(labelText: "URL ảnh đại diện"),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: displayNameController,
              decoration: const InputDecoration(labelText: "Tên hiển thị"),
            ),
            const SizedBox(height: 24),
            const Text("Thông tin tài khoản", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const Divider(),
            Text("📧 Email hiện tại: $email", style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 10),
            TextField(
              controller: emailChangeController,
              decoration: const InputDecoration(labelText: "Email mới"),
              keyboardType: TextInputType.emailAddress,
            ),
            ElevatedButton.icon(
              onPressed: changeEmail,
              icon: const Icon(Icons.email),
              label: const Text("Đổi email"),
            ),
            const SizedBox(height: 10),
            Text("📱 Số điện thoại: $phone", style: const TextStyle(fontSize: 16)),
            const Divider(height: 32),
            const Text("Đổi mật khẩu", style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(
              controller: currentPasswordController,
              decoration: const InputDecoration(labelText: "Mật khẩu hiện tại"),
              obscureText: true,
            ),
            TextField(
              controller: newPasswordController,
              decoration: const InputDecoration(labelText: "Mật khẩu mới"),
              obscureText: true,
            ),
            ElevatedButton.icon(
              onPressed: changePassword,
              icon: const Icon(Icons.lock),
              label: const Text("Đổi mật khẩu"),
            ),
            const Divider(height: 32),
            const Text("Thông tin học sinh", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Họ tên"),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: schoolController,
              decoration: const InputDecoration(labelText: "Trường"),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: "SĐT học sinh"),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: saveChanges,
              icon: const Icon(Icons.save),
              label: const Text("Lưu thay đổi"),
            ),
          ],
        ),
      ),
    );
  }
}
