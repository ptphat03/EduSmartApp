import 'dart:convert';
import 'package:http/http.dart' as http;

class PaymentService {
  /// Endpoint server Node.js PayOS webhook bạn đã triển khai
  static const String serverUrl = 'https://payos-server-demo.onrender.com/create-payment-link';

  /// Tạo link thanh toán từ server, nhận về checkoutUrl
  static Future<String> createPaymentLink({
    required String userId,
    required String userName,
    required String userEmail,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(serverUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'userName': userName,
          'userEmail': userEmail,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        /// ✅ Sửa tại đây:
        if (data['checkoutUrl'] != null) {
          return data['checkoutUrl'];
        } else {
          throw Exception('Không nhận được checkoutUrl từ server');
        }
      } else {
        throw Exception('Server trả về lỗi: ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }
}
