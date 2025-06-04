import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;
  const EmailVerificationScreen({super.key, required this.email});

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  Timer? _checkTimer;
  Timer? _timeoutTimer;
  bool canResendEmail = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _startVerificationChecks();
    _startTimeoutAutoDelete(); // bắt đầu đếm 1 phút tự hủy nếu chưa xác nhận
    sendVerificationEmail();   // gửi email lần đầu
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    _timeoutTimer?.cancel();
    super.dispose();
  }

  void _startVerificationChecks() {
    _checkTimer = Timer.periodic(const Duration(seconds: 5), (_) => checkEmailVerified());
  }

  void _startTimeoutAutoDelete() {
    _timeoutTimer = Timer(const Duration(minutes: 1), () async {
      final user = FirebaseAuth.instance.currentUser;
      await user?.reload();

      if (user != null && !user.emailVerified) {
        await user.delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tài khoản đã bị xoá do không xác nhận trong 1 phút.')),
          );
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const RegisterScreen()),
                (_) => false,
          );
        }
      }
    });
  }

  Future<void> sendVerificationEmail() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        setState(() => canResendEmail = false);
        await Future.delayed(const Duration(seconds: 5));
        setState(() => canResendEmail = true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi gửi email xác nhận: $e')),
      );
    }
  }

  Future<void> checkEmailVerified() async {
    await FirebaseAuth.instance.currentUser?.reload();
    final user = FirebaseAuth.instance.currentUser;

    if (user != null && user.emailVerified) {
      _checkTimer?.cancel();
      _timeoutTimer?.cancel();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Xác thực email')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.email_outlined, size: 80, color: Colors.green),
              const SizedBox(height: 16),
              Text(
                'Chúng tôi đã gửi email xác nhận đến:\n${widget.email}',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Tôi đã xác nhận'),
                onPressed: checkEmailVerified,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: canResendEmail ? sendVerificationEmail : null,
                child: const Text('Gửi lại email xác nhận'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () async {
                  _timeoutTimer?.cancel(); // huỷ đếm ngược
                  final user = FirebaseAuth.instance.currentUser;
                  await user?.delete();
                  await FirebaseAuth.instance.signOut();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  );
                },
                child: const Text('Huỷ'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
