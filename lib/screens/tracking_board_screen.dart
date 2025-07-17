import 'package:flutter/material.dart';
import 'map_simulation_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'custom_address_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'live_tracking_map_screen.dart';

class TrackingBoardScreen extends StatefulWidget {
  const TrackingBoardScreen({super.key});

  @override
  State<TrackingBoardScreen> createState() => _TrackingBoardScreenState();
}

class _TrackingBoardScreenState extends State<TrackingBoardScreen> {
  List<Student> allStudents = [];
  String? selectedStudentId;
  Map<String, String> studentIdNameMap = {};
  DateTime currentDate = DateTime.now();

  bool? canAccess;

  @override
  void initState() {
    super.initState();
    checkPremiumStatus();
  }

  Future<void> checkPremiumStatus() async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final userDoc =
      await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (userDoc.exists) {
        final isPremium = userDoc.get('premium') ?? false;
        final Timestamp? activateAt = userDoc.get('premiumActivatedAt');
        final Timestamp? expiredAt = userDoc.get('premiumExpiredAt');

        if (isPremium == true && expiredAt != null && activateAt != null) {
          final now = DateTime.now();
          final activatedDate = activateAt.toDate();
          final expiredDate = expiredAt.toDate();

          if (now.isAfter(activatedDate) && now.isBefore(expiredDate)) {
            setState(() {
              canAccess = true;
            });
            await fetchStudents();
            return;
          }
        }
      }
    } catch (e) {
      debugPrint("Error checking premium: $e");
    }

    setState(() {
      canAccess = false;
    });
  }

  Future<void> fetchStudents() async {
    final snapshot = await FirebaseFirestore.instance.collection('users').get();
    final students = <Student>[];
    final idNameMap = <String, String>{};

    for (var userDoc in snapshot.docs) {
      final studentSnap =
      await userDoc.reference.collection('students').get();
      for (var studentDoc in studentSnap.docs) {
        final data = studentDoc.data();
        final studentId = studentDoc.id;
        final studentName = data['student_name'] ?? 'Không tên';
        idNameMap[studentId] = studentName;

        final timetable = data['timetable'] as Map<String, dynamic>?;
        if (timetable != null) {
          for (var entry in timetable.entries) {
            final day = entry.key;
            final lessons = entry.value as List<dynamic>;
            for (var lesson in lessons) {
              students.add(Student(
                id: studentId,
                name: studentName,
                startTime: lesson['start'] ?? '',
                endTime: lesson['end'] ?? '',
                status: lesson['status'] ?? 'waiting',
                fromAddress: lesson['fromAddress'] ?? '',
                toAddress: lesson['toAddress'] ?? '',
                fromLatLng: lesson['fromLatLng'] ?? '',
                toLatLng: lesson['toLatLng'] ?? '',
                date: day,
              ));
            }
          }
        }
      }
    }

    if (!mounted) return;
    setState(() {
      allStudents = students;
      studentIdNameMap = idNameMap;
      if (idNameMap.isNotEmpty) {
        selectedStudentId = idNameMap.keys.first;
      }
    });
  }

  String get formattedCurrentDate =>
      DateFormat('dd/MM/yyyy').format(currentDate);

  @override
  Widget build(BuildContext context) {
    if (canAccess == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!canAccess!) {
      return Scaffold(
        body: RefreshIndicator(
          onRefresh: checkPremiumStatus,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.15, // 👈 Đẩy card xuống ~30% chiều cao màn hình
                ),
                Center(
                  child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.lock_outline, size: 80, color: Colors.redAccent),
                          const SizedBox(height: 20),
                          const Text(
                            "Bạn cần nâng cấp gói Premium để sử dụng tính năng này",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.payment, color: Colors.white),
                              label: const Text(
                                "Nâng cấp ngay",
                                style: TextStyle(fontSize: 16, color: Colors.white),
                              ),
                              onPressed: () {
                                Navigator.pushNamed(context, '/payment');
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.shade700,
                                padding: const EdgeInsets.symmetric(vertical: 14),
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
              ],
            ),

          ),
        ),
      );
    }

    final filteredStudents = allStudents
        .where((s) =>
    s.id == selectedStudentId &&
        s.date == DateFormat('yyyy-MM-dd').format(currentDate))
        .toList();

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: checkPremiumStatus,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blueAccent, Colors.white],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              DropdownButton<String>(
                value: selectedStudentId,
                isExpanded: true,
                hint: const Text("Chọn học sinh"),
                items: studentIdNameMap.entries.map((entry) {
                  return DropdownMenuItem<String>(
                    value: entry.key,
                    child: Text(entry.value),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedStudentId = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_left),
                    onPressed: () {
                      setState(() {
                        currentDate =
                            currentDate.subtract(const Duration(days: 1));
                      });
                    },
                  ),
                  Text(
                    formattedCurrentDate,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_right),
                    onPressed: () {
                      setState(() {
                        currentDate =
                            currentDate.add(const Duration(days: 1));
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (filteredStudents.isEmpty)
                const Center(child: Text("Không có lịch học cho ngày này"))
              else
                ...(() {
                  final sortedStudents = [...filteredStudents];
                  sortedStudents
                      .sort((a, b) => a.startTime.compareTo(b.startTime));
                  return sortedStudents.map((s) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 4),
                          child: Text(
                            "⏰ ${s.startTime} - ${s.endTime}",
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ),
                        StudentCard(student: s),
                      ],
                    );
                  }).toList();
                })(),
            ],
          ),
        ),
      ),
    );
  }
}

class StudentCard extends StatelessWidget {
  final Student student;

  const StudentCard({super.key, required this.student});

  LatLng? _parseLatLng(String input) {
    try {
      final parts = input.split(',');
      if (parts.length == 2) {
        final lat = double.parse(parts[0]);
        final lng = double.parse(parts[1]);
        return LatLng(lat, lng);
      }
    } catch (_) {}
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: const CircleAvatar(radius: 20),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (student.fromAddress.isNotEmpty)
              Text("🚩 Đi: ${student.fromAddress}"),
            if (student.toAddress.isNotEmpty)
              Text("🏁 Đến: ${student.toAddress}"),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    final result =
                    await Navigator.push<Map<String, String>>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CustomAddressPickerScreen(
                          title: "Chọn địa chỉ",
                          initialFrom: _parseLatLng(student.fromLatLng),
                          initialTo: _parseLatLng(student.toLatLng),
                        ),
                      ),
                    );
                    if (result != null) {
                      // xử lý nếu cần
                    }
                  },
                  icon: const Icon(Icons.edit_location),
                  label: const Text("Địa chỉ"),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('Đi đến lịch ngày ${student.date}')),
                    );
                  },
                  icon: const Icon(Icons.schedule),
                  label: const Text("Lịch"),
                ),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.check_circle, color: Colors.green),
      ),
    );
  }
}

class Student {
  final String id;
  final String name;
  final String startTime;
  final String endTime;
  final String status;
  final String fromAddress;
  final String toAddress;
  final String fromLatLng;
  final String toLatLng;
  final String date;

  Student({
    required this.id,
    required this.name,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.fromAddress,
    required this.toAddress,
    required this.date,
    required this.fromLatLng,
    required this.toLatLng,
  });
}
