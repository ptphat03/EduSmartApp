import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/custom_app_bar.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmController = TextEditingController();

  final _auth = FirebaseAuth.instance;
  bool _isLoading = false;

  Future<void> _changePassword() async {
    final user = _auth.currentUser;
    final oldPassword = _oldPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmController.text.trim();

    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Xác nhận không khớp!")),
      );
      return;
    }

    if (user?.email == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Không xác định được người dùng hiện tại.")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Xác thực lại người dùng với mật khẩu cũ
      final credential = EmailAuthProvider.credential(
        email: user!.email!,
        password: oldPassword,
      );

      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Đổi mật khẩu thành công!")),
      );

      Navigator.pop(context); // Quay lại sau khi đổi xong
    } on FirebaseAuthException catch (e) {
      String message = "Lỗi không xác định!";
      if (e.code == 'wrong-password') {
        message = "Mật khẩu cũ không đúng!";
      } else if (e.code == 'weak-password') {
        message = "Mật khẩu mới quá yếu!";
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildCustomAppBar("Đổi mật khẩu", Icons.lock_outline, showBack: true, context: context),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _oldPasswordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Mật khẩu cũ"),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Mật khẩu mới"),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Xác nhận mật khẩu mới"),
            ),
            const SizedBox(height: 32),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
              onPressed: _changePassword,
              child: const Text("Đổi mật khẩu"),
            ),
          ],
        ),
      ),
    );
  }
}
