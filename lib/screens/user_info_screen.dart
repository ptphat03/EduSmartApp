import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'student_info_screen.dart';
import 'welcome_screen.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart'; // thêm dòng này ở đầu
import 'map_picker_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class UserInfoScreen extends StatefulWidget {
  const UserInfoScreen({super.key});

  @override
  State<UserInfoScreen> createState() => _UserInfoScreenState();
}

class _UserInfoScreenState extends State<UserInfoScreen> {
  final displayNameController = TextEditingController();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final dobController = TextEditingController();
  DateTime? selectedDob;
  String gender = 'Nam';
  bool isLoading = false;
  final addressController = TextEditingController();
  LatLng? selectedLocation; // Tọa độ từ Google Map
  final searchController = TextEditingController();
  List<dynamic> suggestions = [];


  Future<void> saveUserInfo() async {
    final phone = phoneController.text.trim();
    final display_name = displayNameController.text.trim();

    if (display_name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng điền đầy đủ thông tin.')),
      );
      return;

    }
    if (selectedDob == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ngày sinh không đúng định dạng dd/MM/yyyy.')),
      );
      return;
    }

    setState(() => isLoading = true);
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy người dùng!')),
      );
      setState(() => isLoading = false);
      return;
    }

    final data = {
      'uid': user.uid,
      'user_name': user.email ?? '',
      'user_phone': phone,
      'user_display_name': display_name,
      'user_gender': gender,
      'user_dob': Timestamp.fromDate(selectedDob!),
      'user_address': addressController.text,
      'user_location': selectedLocation != null
          ? GeoPoint(selectedLocation!.latitude, selectedLocation!.longitude)
          : null,

    };
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(data, SetOptions(merge: true));

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const StudentInfoScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi lưu dữ liệu: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }
  Future<void> selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2010, 1, 1),
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        selectedDob = picked;
        dobController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }


  void handleDobInput(String value) {
    try {
      final parts = value.split('/');
      if (parts.length == 3) {
        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        final parsed = DateTime(year, month, day);
        if (parsed.isBefore(DateTime.now())) {
          setState(() => selectedDob = parsed);
        }
      }
    } catch (_) {
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        title: const Text(
          "Thông tin người dùng",
          style: TextStyle(
            color: Colors.white,
            fontSize: 24, // 👈 chỉnh cỡ chữ
            fontWeight: FontWeight.bold, // 👈 tô đậm
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const WelcomeScreen()),
            );
          },
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            elevation: 6,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    "Điền thông tin của bạn",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: displayNameController,
                    decoration: const InputDecoration(
                      labelText: "Họ tên",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneController,
                    decoration: const InputDecoration(
                      labelText: "Số điện thoại",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly, // Chỉ cho phép nhập 0–9
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: dobController,
                    keyboardType: TextInputType.datetime,
                    decoration: InputDecoration(
                      labelText: 'Ngày sinh (dd/MM/yyyy)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.cake),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () => selectDate(context),
                      ),
                    ),
                    onChanged: handleDobInput,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: gender,
                    decoration: const InputDecoration(
                      labelText: "Giới tính",
                      border: OutlineInputBorder(),
                    ),
                    items: ['Nam', 'Nữ', 'Khác']
                        .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                        .toList(),
                    onChanged: (value) => setState(() => gender = value ?? 'Nam'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: addressController,
                    decoration: InputDecoration(
                      labelText: 'Địa chỉ',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_on),
                      suffixIcon: IconButton(
                        icon: Icon(Icons.map),
                        onPressed: () async {
                          // Chuyển sang màn chọn địa điểm
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const MapPickerScreen(initialLocation: null, editable: true)),
                          );
                          if (result != null && result is Map<String, dynamic>) {
                            setState(() {
                              addressController.text = result['placeName'];
                              selectedLocation = result['latlng'];
                            });
                          }
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton.icon(
                      icon: const Icon(Icons.save, color: Colors.white),
                      label: const Text(
                        "Lưu & Tiếp tục",
                        style: TextStyle(color: Colors.white,
                          fontSize: 18,),
                      ),
                      onPressed: saveUserInfo,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white, // Cách viết chuẩn
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
