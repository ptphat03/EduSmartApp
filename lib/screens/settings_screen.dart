import 'package:flutter/material.dart';
import '../widgets/custom_app_bar.dart';
import 'login_screen.dart';
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';
import 'show_profile_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //appBar: buildCustomAppBar("Cài đặt", Icons.settings),
      body: Column(
        children: [
          const SizedBox(height: 24),
          const CircleAvatar(
            radius: 40,
            backgroundImage: AssetImage('assets/avatar.png'),
          ),
          const SizedBox(height: 12),
          const Text("👩 Trần Thị Bích", style: TextStyle(fontSize: 18)),
          const Text("📞 0912345678"),
          const Divider(height: 32),

          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text("Chỉnh sửa thông tin"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text("Đổi mật khẩu"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text("Đăng xuất"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }
}
