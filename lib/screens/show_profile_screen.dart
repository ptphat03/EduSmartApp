import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'edit_profile_screen.dart'; // import trang chỉnh sửa

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final user = FirebaseAuth.instance.currentUser;

  String name = '';
  String phone = '';
  String school = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('students')
        .doc(user!.uid)
        .get();

    final data = doc.data();
    if (data != null) {
      name = data['name'] ?? '';
      phone = data['phone'] ?? '';
      school = data['school'] ?? '';
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final photoURL = user?.photoURL;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        title: const Text("Hồ sơ cá nhân"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'refresh') {
                setState(() => isLoading = true);
                loadUserData();
              } else if (value == 'edit') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 20, color: Colors.black),
                    SizedBox(width: 8),
                    Text("Chỉnh sửa"),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh, size: 20, color: Colors.black),
                    SizedBox(width: 8),
                    Text("Tải lại"),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Colors.grey[200],
                backgroundImage: (photoURL != null && photoURL.isNotEmpty)
                    ? NetworkImage(photoURL)
                    : null,
                child: (photoURL == null || photoURL.isEmpty)
                    ? const Icon(Icons.person, size: 60, color: Colors.grey)
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                user?.displayName ?? 'Chưa đặt tên',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 24),
            const Text("Thông tin tài khoản", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const Divider(),
            const SizedBox(height: 4),
            Text.rich(TextSpan(children: [
              const TextSpan(text: "📧 Email: ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              TextSpan(text: user?.email ?? '(Không có)', style: const TextStyle(fontSize: 16)),
            ])),
            const SizedBox(height: 10),
            Text.rich(TextSpan(children: [
              const TextSpan(text: "📱 Số điện thoại: ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              TextSpan(text: user?.phoneNumber ?? '(Không có)', style: const TextStyle(fontSize: 16)),
            ])),
            const SizedBox(height: 24),
            const Text("Thông tin học sinh", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const Divider(),
            const SizedBox(height: 8),
            Text.rich(TextSpan(children: [
              const TextSpan(text: "👤 Họ tên: ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              TextSpan(text: name.isNotEmpty ? name : "(Chưa có)", style: const TextStyle(fontSize: 16)),
            ])),
            const SizedBox(height: 8),
            Text.rich(TextSpan(children: [
              const TextSpan(text: "🏫 Trường: ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              TextSpan(text: school.isNotEmpty ? school : "(Chưa có)", style: const TextStyle(fontSize: 16)),
            ])),
            const SizedBox(height: 8),
            Text.rich(TextSpan(children: [
              const TextSpan(text: "📞 SĐT học sinh: ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              TextSpan(text: phone.isNotEmpty ? phone : "(Chưa có)", style: const TextStyle(fontSize: 16)),
            ])),
          ],
        ),
      ),
    );
  }
}
