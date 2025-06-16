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
  final Duration timeoutDuration = const Duration(minutes: 1);
  DateTime? _startTime;
  Timer? _checkTimer;
  Timer? _timeoutTimer;
  Timer? _countdownTimer;
  bool canResendEmail = false;

  @override
  void initState() {
    super.initState();
    sendVerificationEmail();
    _startTime = DateTime.now();
    _startVerificationChecks();
    _startTimeoutAutoDelete();
    _startCountdownTimer();
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    _timeoutTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startVerificationChecks() {
    _checkTimer = Timer.periodic(const Duration(seconds: 5), (_) => checkEmailVerified());
  }
  Color _getCountdownColor() {
    final remaining = timeoutDuration - DateTime.now().difference(_startTime!);
    return remaining.inSeconds <= 10 ? Colors.red.shade50 : Colors.green.shade50;
  }

  Color _getCountdownTextColor() {
    final remaining = timeoutDuration - DateTime.now().difference(_startTime!);
    return remaining.inSeconds <= 10 ? Colors.red : Colors.green.shade800;
  }

  void _startTimeoutAutoDelete() {
    _timeoutTimer = Timer(timeoutDuration, () async {
      final user = FirebaseAuth.instance.currentUser;
      await user?.reload();

      if (user != null && !user.emailVerified) {
        await user.delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tài khoản đã bị xoá do không xác nhận trong thời gian quy định.')),
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

  void _startCountdownTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {});
    });
  }

  String getRemainingTimeText() {
    if (_startTime == null) return '';
    final elapsed = DateTime.now().difference(_startTime!);
    final remaining = timeoutDuration - elapsed;
    if (remaining.isNegative) return '00:00';

    final minutes = remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> sendVerificationEmail() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();

        setState(() {
          canResendEmail = false;
          _startTime = DateTime.now(); // 🔁 Reset thời gian
        });

        // Cập nhật lại đếm ngược (hủy cái cũ, chạy cái mới)
        _countdownTimer?.cancel();
        _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
          setState(() {});
        });

        _timeoutTimer?.cancel();
        _startTimeoutAutoDelete(); // 🔁 Reset luôn timeout xoá user

        await Future.delayed(const Duration(seconds: 5));
        if (mounted) setState(() => canResendEmail = true);
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
      _countdownTimer?.cancel();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Colors.blue.shade700;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Xác thực Email',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.mark_email_read_rounded, size: screenWidth * 0.3, color: Colors.blueAccent),
              const SizedBox(height: 24),
              Text(
                'Vui lòng kiểm tra hộp thư của bạn để xác nhận địa chỉ email:',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18, height: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.email,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.black87),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: _getCountdownColor(), // <-- dùng hàm để lấy màu theo thời gian
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '⏳ Thời gian xác nhận: ${getRemainingTimeText()}',
                  style: TextStyle(
                    color: _getCountdownTextColor(),
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),

              const SizedBox(height: 32),
              ElevatedButton.icon(
                icon: const Icon(Icons.verified_user_outlined, size: 20),
                label: const Text('Tôi đã xác nhận'),
                onPressed: checkEmailVerified,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Gửi lại email xác nhận'),
                onPressed: canResendEmail ? sendVerificationEmail : null,
                style: TextButton.styleFrom(
                  foregroundColor: primaryColor,
                  textStyle: const TextStyle(fontSize: 15),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () async {
                  _timeoutTimer?.cancel();
                  _countdownTimer?.cancel();
                  final user = FirebaseAuth.instance.currentUser;
                  await user?.delete();
                  await FirebaseAuth.instance.signOut();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  );
                },
                child: const Text(
                  'Huỷ',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500, fontSize: 15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
