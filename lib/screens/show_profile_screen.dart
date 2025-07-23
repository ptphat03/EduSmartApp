import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'edit_profile_screen.dart';
import 'map_picker_screen.dart'; // ✅ dùng map_picker_screen

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? userInfo;
  List<Map<String, dynamic>> students = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy người dùng!')),
      );
      return;
    }

    try {
      final db = FirebaseFirestore.instance;

      final userDoc = await db.collection('users').doc(user.uid).get();
      final studentSnapshot = await db
          .collection('users')
          .doc(user.uid)
          .collection('students')
          .get();

      final userData = userDoc.data() ?? {};
      final studentList = studentSnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      setState(() {
        userInfo = userData;
        students = studentList;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể tải dữ liệu.')),
      );
      debugPrint("Lỗi khi tải dữ liệu: $e");
    }
  }

  void openMapScreen({
    required GeoPoint? currentLocation,
    required String title,
    required Function(GeoPoint location, String placeName) onPicked,
  }) async {
    LatLng? initial;

    if (currentLocation != null) {
      initial = LatLng(currentLocation.latitude, currentLocation.longitude);
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MapPickerScreen(
          initialLocation: initial,
          editable: true,
          title: title,
        ),
      ),
    );

    if (result != null && result is Map) {
      final LatLng? latlng = result['latlng'];
      final String? placeName = result['placeName'];
      if (latlng != null && placeName != null) {
        onPicked(GeoPoint(latlng.latitude, latlng.longitude), placeName);
      }
    }
  }


  Widget buildInfoRow(String label, dynamic value, {VoidCallback? onTap}) {
    final text = value?.toString().trim();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label: ",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              child: Text(
                (text != null && text.isNotEmpty) ? text : "(Chưa có)",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                  fontWeight: onTap != null ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue.shade700,
        iconTheme: const IconThemeData(
          color: Colors.white, // ← màu trắng cho nút back
        ),
        title: const Text(
          "Hồ sơ cá nhân",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
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
                child: Text("Chỉnh sửa"),
              ),
              const PopupMenuItem<String>(
                value: 'refresh',
                child: Text("Tải lại"),
              ),
            ],
          ),
        ],
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: () async {
          setState(() => isLoading = true);
          await loadUserData();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: const NetworkImage(
                    'https://upload.wikimedia.org/wikipedia/commons/7/7c/Profile_avatar_placeholder_large.png',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  (userInfo?['user_display_name']?.toString().trim().isNotEmpty ?? false)
                      ? userInfo!['user_display_name']
                      : 'Chưa đặt tên',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 20),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      buildInfoRow("Email", userInfo?['user_name']),
                      buildInfoRow("SĐT", userInfo?['user_phone']),
                      buildInfoRow("Giới tính", userInfo?['user_gender']),
                      buildInfoRow(
                        "Ngày sinh",
                        (() {
                          final timestamp = userInfo?['user_dob'];
                          if (timestamp == null) return '(Chưa có)';
                          try {
                            final date = (timestamp as Timestamp).toDate();
                            return DateFormat('dd/MM/yyyy').format(date);
                          } catch (_) {
                            return '(Lỗi định dạng)';
                          }
                        })(),
                      ),

                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ...students.map((student) => Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("🎓 Thông tin học sinh",
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const Divider(),
                      buildInfoRow("Họ tên", student['student_name']),
                      buildInfoRow("Giới tính", student['student_gender']),
                      buildInfoRow(
                        "Ngày sinh",
                        (() {
                          final timestamp = student['student_dob'];
                          if (timestamp == null) return '(Chưa có)';
                          try {
                            final date = (timestamp as Timestamp).toDate();
                            return DateFormat('dd/MM/yyyy').format(date);
                          } catch (_) {
                            return '(Lỗi định dạng)';
                          }
                        })(),
                      ),


                    ],
                  ),
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }
}
