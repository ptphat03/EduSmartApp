// // 📁 Full code đã kết hợp PaymentService và PaymentScreen
//
// import 'package:flutter/material.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
//
// class PaymentService {
//   static Future<String> createPaymentLink({
//     required String userId,
//     required String userName,
//     required String userEmail,
//   }) async {
//     final now = DateTime.now();
//     final expiredAt = now.add(const Duration(hours: 1));
//     final amount = 20000;
//
//     final response = await http.post(
//       Uri.parse('https://api.payos.vn/v1/payment-requests'),
//       headers: {
//         'Content-Type': 'application/json',
//         'x-client-id': 'YOUR_CLIENT_ID',
//         'x-api-key': 'YOUR_API_KEY',
//       },
//       body: jsonEncode({
//         'amount': amount,
//         'description': 'Thanh toán Premium EduSmart',
//         'returnUrl': 'https://yourapp.com/return',
//         'cancelUrl': 'https://yourapp.com/cancel',
//         'expiredAt': expiredAt.toIso8601String(),
//         'buyerName': userName,
//         'buyerEmail': userEmail,
//         'orderCode': '${DateTime.now().millisecondsSinceEpoch}',
//       }),
//     );
//
//     if (response.statusCode != 200) {
//       throw 'Không thể tạo link thanh toán: ${response.body}';
//     }
//
//     final json = jsonDecode(response.body);
//     final paymentUrl = json['checkoutUrl'];
//     final transactionId = json['orderCode'];
//
//     await FirebaseFirestore.instance.collection('payments').doc(transactionId).set({
//       'userId': userId,
//       'userName': userName,
//       'userEmail': userEmail,
//       'amount': amount,
//       'createdAt': now,
//       'expiredAt': expiredAt,
//       'status': 'pending',
//       'paymentUrl': paymentUrl,
//       'orderCode': transactionId,
//     });
//
//     return paymentUrl;
//   }
// }
//
// class PaymentScreen extends StatefulWidget {
//   const PaymentScreen({super.key});
//
//   @override
//   State<PaymentScreen> createState() => _PaymentScreenState();
// }
//
// class _PaymentScreenState extends State<PaymentScreen> {
//   bool isLoading = false;
//
//   Future<void> createPaymentAndLaunch() async {
//     setState(() => isLoading = true);
//
//     try {
//       final user = FirebaseAuth.instance.currentUser;
//
//       if (user == null) throw 'Bạn chưa đăng nhập';
//
//       final userId = user.uid;
//       final fallbackName = user.displayName ?? 'No Name';
//       final userEmail = user.email ?? 'noemail@example.com';
//
//       final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
//       final nameFromProfile = userDoc.data()?['name'] ?? fallbackName;
//
//       final paymentUrl = await PaymentService.createPaymentLink(
//         userId: userId,
//         userName: nameFromProfile,
//         userEmail: userEmail,
//       );
//
//       final uri = Uri.parse(paymentUrl);
//       if (await canLaunchUrl(uri)) {
//         await launchUrl(uri, mode: LaunchMode.externalApplication);
//       } else {
//         throw 'Không thể mở link thanh toán.';
//       }
//     } catch (e) {
//       debugPrint('Payment error: $e');
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Lỗi: $e')),
//         );
//       }
//     } finally {
//       if (mounted) setState(() => isLoading = false);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Thanh toán Premium')),
//       body: Center(
//         child: isLoading
//             ? const CircularProgressIndicator()
//             : ElevatedButton.icon(
//           onPressed: createPaymentAndLaunch,
//           icon: const Icon(Icons.payment),
//           label: const Text('Thanh toán 20.000 VND'),
//         ),
//       ),
//     );
//   }
// }