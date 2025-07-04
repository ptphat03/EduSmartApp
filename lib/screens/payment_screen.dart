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
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
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
      appBar: AppBar(title: const Text('Thanh toán Premium')),
      body: Center(
        child: isLoading
            ? const CircularProgressIndicator()
            : ElevatedButton.icon(
          onPressed: createPaymentAndLaunch,
          icon: const Icon(Icons.payment),
          label: const Text('Thanh toán 20.000 VND'),
        ),
      ),
    );
  }
}
