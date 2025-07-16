import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/custom_app_bar.dart';
import 'login_screen.dart';
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';
import 'show_profile_screen.dart';
import 'review_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String displayName = "Đang tải...";
  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    loadDisplayName();
  }

  Future<void> loadDisplayName() async {
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
      final data = doc.data();
      if (data != null && data['user_display_name'] != null) {
        setState(() {
          displayName = data['user_display_name'];
        });
      } else {
        setState(() {
          displayName = "(Chưa có tên)";
        });
      }
    }
  }
  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color color = Colors.black87,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: buildCustomAppBar("Cài đặt", Icons.settings, showBack: true, context: context),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 30),
            const CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage('https://randomuser.me/api/portraits/men/32.jpg'), // ảnh mặc định
            ),
            const SizedBox(height: 12),
            Text(
              displayName.isNotEmpty ? displayName : 'Chưa đặt tên',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Divider(height: 1, thickness: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSettingsCard([
                    _buildSettingsTile(
                      icon: Icons.person_outline,
                      title: "Chỉnh sửa thông tin",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ProfileScreen()),
                        );
                      },
                    ),
                    _buildSettingsTile(
                      icon: Icons.lock_outline,
                      title: "Đổi mật khẩu",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
                        );
                      },
                    ),
                    _buildSettingsTile(
                      icon: Icons.star_rate_outlined,
                      title: "Đánh giá ứng dụng",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ReviewScreen()),
                        );
                      },
                    ),
                  ]),
                  const SizedBox(height: 20),
                  _buildSettingsCard([
                    _buildSettingsTile(
                      icon: Icons.logout,
                      title: "Đăng xuất",
                      color: Colors.red,
                      onTap: () {
                        FirebaseAuth.instance.signOut();
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                              (route) => false,
                        );
                      },
                    ),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}