import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'student_info_screen.dart';

class PhoneOTPScreen extends StatefulWidget {
  final String phoneNumber;
  final String verificationId;

  const PhoneOTPScreen({
    super.key,
    required this.phoneNumber,
    required this.verificationId,
  });

  @override
  State<PhoneOTPScreen> createState() => _PhoneOTPScreenState();
}

class _PhoneOTPScreenState extends State<PhoneOTPScreen> {
  final otpController = TextEditingController();
  bool isVerifying = false;

  Future<void> verifyOTP() async {
    final otp = otpController.text.trim();
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Mã OTP không hợp lệ.")),
      );
      return;
    }

    setState(() => isVerifying = true);

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: otp,
      );

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.linkWithCredential(credential);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Xác minh số điện thoại thành công.")),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const StudentInfoScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi: ${e.message}")),
      );
    } finally {
      setState(() => isVerifying = false);
    }
  }

  @override
  void dispose() {
    otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Xác minh OTP"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              "Nhập mã OTP đã gửi đến ${widget.phoneNumber}",
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: "Mã OTP",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            isVerifying
                ? const CircularProgressIndicator()
                : ElevatedButton.icon(
              onPressed: verifyOTP,
              icon: const Icon(Icons.verified),
              label: const Text("Xác minh"),
            ),
          ],
        ),
      ),
    );
  }
}
