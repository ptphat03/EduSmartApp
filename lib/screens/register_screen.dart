import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'mail_verification_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;

  Future<void> register() async {
    setState(() => isLoading = true);
    try {
      // Tạo tài khoản mới
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final user = userCredential.user;
      if (user != null) {
        // Chuyển sang màn hình xác minh email (ở đó sẽ gửi email)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => EmailVerificationScreen(email: user.email!),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Đăng ký thất bại';
      if (e.code == 'email-already-in-use') {
        message = 'Email đã được sử dụng';
      } else if (e.code == 'invalid-email') {
        message = 'Email không hợp lệ';
      } else if (e.code == 'weak-password') {
        message = 'Mật khẩu quá yếu';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi không xác định: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Đăng ký")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: "Email"),
              keyboardType: TextInputType.emailAddress,
            ),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: "Mật khẩu"),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
              onPressed: register,
              child: const Text("Tạo tài khoản"),
            ),
          ],
        ),
      ),
    );
  }
}
