import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/payment_service.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool isLoading = false;

  Future<void> createPaymentAndLaunch() async {
    setState(() => isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw 'Bạn chưa đăng nhập';
      }

      final userId = user.uid;
      final userName = user.displayName ?? 'No Name';
      final userEmail = user.email ?? 'noemail@example.com';

      // Nếu bạn cần lấy thêm thông tin user từ Firestore:
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(
          userId).get();
      final userData = userDoc.data();
      final nameFromProfile = userData?['name'] ?? userName;

      final paymentUrl = await PaymentService.createPaymentLink(
        userId: userId,
        userName: nameFromProfile,
        userEmail: userEmail,
      );

      final uri = Uri.parse(paymentUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        Navigator.pop(context); // quay lại màn trước (ví dụ: TrackingBoardScreen)
      } else {
        throw 'Không thể mở link: $paymentUrl';
      }
    } catch (e) {
      print('Payment error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Thanh toán',
          style: TextStyle(
            color: Colors.white,           // 🔹 Chữ trắng
            fontWeight: FontWeight.bold,  // 🔹 In đậm
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.blue.shade700,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white), // 🔹 Mũi tên back màu trắng
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: isLoading
              ? const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text("Đang tạo liên kết thanh toán...",
                  style: TextStyle(fontSize: 16)),
            ],
          )
              : Card(
            elevation: 10,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star, size: 80, color: Colors.blue),
                  const SizedBox(height: 16),
                  const Text(
                    "Nâng cấp lên Premium",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "20.000đ/tháng\n"
                        "Truy cập tính năng theo dõi hành trình",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                      fontWeight: FontWeight.bold, // 🔹 In đậm
                    ),
                  ),

                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: createPaymentAndLaunch,
                      icon: const Icon(Icons.payment, color: Colors.white),
                      label: const Text(
                        'Thanh toán ngay',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
