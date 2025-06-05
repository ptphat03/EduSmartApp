import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'phone_otp_screen.dart';
import 'student_info_screen.dart';

class UserInfoScreen extends StatefulWidget {
  const UserInfoScreen({super.key});

  @override
  State<UserInfoScreen> createState() => _UserInfoScreenState();
}

class _UserInfoScreenState extends State<UserInfoScreen> {
  final user = FirebaseAuth.instance.currentUser;

  final displayNameController = TextEditingController();
  final phoneNumberController = TextEditingController();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    if (user != null) {
      displayNameController.text = user!.displayName ?? '';
      phoneNumberController.text = user!.phoneNumber ?? '';
    }
  }

  Future<void> sendOtpToPhone() async {
    final phone = phoneNumberController.text.trim();

    // Đảm bảo số bắt đầu bằng dấu + và đúng chuẩn quốc tế
    if (!RegExp(r'^\+?[1-9]\d{7,14}$').hasMatch(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Số điện thoại không đúng định dạng quốc tế (+84...)")),
      );
      return;
    }

    setState(() => isLoading = true);

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phone,
      verificationCompleted: (PhoneAuthCredential credential) {},
      verificationFailed: (FirebaseAuthException e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi xác minh: ${e.message}")),
        );
        setState(() => isLoading = false);
      },
      codeSent: (String verificationId, int? resendToken) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => PhoneOTPScreen(
              phoneNumber: phone,
              verificationId: verificationId,
            ),
          ),
        );
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Số điện thoại"),
        backgroundColor: Colors.green,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
            color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: phoneNumberController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Số điện thoại (vd: +84981234567)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: sendOtpToPhone,
                    icon: const Icon(Icons.send),
                    label: const Text("Gửi mã OTP"),
                  ),
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const StudentInfoScreen(),
                      ),
                    );
                  },
                  child: const Text("Bỏ qua"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
