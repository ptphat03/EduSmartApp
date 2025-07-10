import 'package:flutter/material.dart';

class PaymentScreen extends StatelessWidget {
  const PaymentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thanh toán Premium')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Quét mã QR bên dưới để thanh toán 20.000 VND',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Image.asset(
              'assets/images/qr_payment.png',
              width: 250,
              height: 250,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // Thêm hành động nếu muốn
              },
              icon: const Icon(Icons.qr_code),
              label: const Text('Mở mã QR lớn hơn'),
            ),
          ],
        ),
      ),
    );
  }
}
