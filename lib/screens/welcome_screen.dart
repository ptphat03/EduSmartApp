import 'package:flutter/material.dart';
import 'student_info_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chào mừng bạn!')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.emoji_people, size: 80, color: Colors.green),
              const SizedBox(height: 20),
              const Text(
                '🎉 Xin chào!',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'Cảm ơn bạn đã đăng ký.\nChúng tôi sẽ giúp bạn bắt đầu một hành trình an toàn & tiện lợi.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Bắt đầu nhập thông tin'),
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const StudentInfoScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
