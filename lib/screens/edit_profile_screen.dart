import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final user = FirebaseAuth.instance.currentUser;

  final displayNameController = TextEditingController();
  final photoUrlController = TextEditingController();

  final nameController = TextEditingController();
  final schoolController = TextEditingController();
  final phoneController = TextEditingController();

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    if (user == null) return;

    displayNameController.text = user!.displayName ?? '';
    photoUrlController.text = user!.photoURL ?? '';

    final doc = await FirebaseFirestore.instance
        .collection('students')
        .doc(user!.uid)
        .get();

    final data = doc.data();
    if (data != null) {
      nameController.text = data['name'] ?? '';
      schoolController.text = data['school'] ?? '';
      phoneController.text = data['phone'] ?? '';
    }

    setState(() => isLoading = false);
  }

  Future<void> saveChanges() async {
    if (user == null) return;

    try {
      await user!.updateDisplayName(displayNameController.text.trim());
      await user!.updatePhotoURL(photoUrlController.text.trim());
      await user!.reload();

      await FirebaseFirestore.instance
          .collection('students')
          .doc(user!.uid)
          .set({
        'name': nameController.text.trim(),
        'school': schoolController.text.trim(),
        'phone': phoneController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cập nhật thành công!")),
      );

      Navigator.pop(context); // Quay lại Profile
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi: $e")),
      );
    }
  }

    @override
    Widget build(BuildContext context) {
      final email = user?.email ?? '(Không có)';
      final phone = user?.phoneNumber ?? '(Không có)';

      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.green,
          title: const Text("Chỉnh sửa hồ sơ", style: TextStyle(color: Colors.white)),
          iconTheme: const IconThemeData(color: Colors.white),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              final shouldLeave = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                  actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  title: Row(
                    children: const [
                      Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
                      SizedBox(width: 8),
                      Text("Xác nhận rời khỏi"),
                    ],
                  ),
                  content: const Text(
                    "Bạn có chắc muốn rời khỏi? Các thay đổi chưa lưu sẽ bị mất.",
                    style: TextStyle(fontSize: 16),
                  ),
                  actions: [
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey[700],
                        textStyle: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text("Ở lại"),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text("Rời khỏi"),
                    ),
                  ],
                ),
              );

              if (shouldLeave == true) {
                Navigator.pop(context);
              }
            },

          ),
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
                backgroundImage: (photoUrlController.text.isNotEmpty)
                    ? NetworkImage(photoUrlController.text)
                    : null,
                child: (photoUrlController.text.isEmpty)
                    ? const Icon(Icons.person, size: 60, color: Colors.grey)
                    : null,
              ),
            ),

            const SizedBox(height: 16),
            TextField(
              controller: photoUrlController,
              decoration: const InputDecoration(labelText: "URL ảnh đại diện"),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: displayNameController,
              decoration: const InputDecoration(labelText: "Tên hiển thị"),
            ),
            const SizedBox(height: 24),
            const Text("Thông tin tài khoản", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const Divider(),
            const SizedBox(height: 4),
            Text("📧 Email: $email", style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 10),
            Text("📱 Số điện thoại: $phone", style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 24),
            const Text("Thông tin học sinh", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const Divider(),
            const SizedBox(height: 8),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Họ tên"),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: schoolController,
              decoration: const InputDecoration(labelText: "Trường"),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: "SĐT học sinh"),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: saveChanges,
              icon: const Icon(Icons.save),
              label: const Text("Lưu thay đổi"),
            )
          ],
        ),
      ),
    );
  }
}
