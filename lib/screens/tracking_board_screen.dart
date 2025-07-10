import 'package:flutter/material.dart';
import 'map_simulation_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'custom_address_picker.dart'; // 👈 Import màn chọn địa chỉ
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

  Future<void> fetchStudents() async {
    final snapshot = await FirebaseFirestore.instance.collection('users').get();
    final students = <Student>[];
    final idNameMap = <String, String>{};

    for (var userDoc in snapshot.docs) {
      final studentSnap = await userDoc.reference.collection('students').get();
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

  @override
  void initState() {
    super.initState();
    fetchStudents();
  }

  String get formattedCurrentDate => DateFormat('dd/MM/yyyy').format(currentDate);

  @override
  Widget build(BuildContext context) {
    final filteredStudents = allStudents.where((s) =>
    s.id == selectedStudentId &&
        s.date == DateFormat('yyyy-MM-dd').format(currentDate)
    ).toList();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueAccent, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView(
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
                      currentDate = currentDate.subtract(const Duration(days: 1));
                    });
                  },
                ),
                Text(
                  formattedCurrentDate,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_right),
                  onPressed: () {
                    setState(() {
                      currentDate = currentDate.add(const Duration(days: 1));
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
                sortedStudents.sort((a, b) => a.startTime.compareTo(b.startTime));
                return sortedStudents.map((s) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 4),
                      child: Text(
                        "⏰ ${s.startTime} - ${s.endTime}",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                    StudentCard(student: s),
                  ],
                )).toList();
              })(),
          ],
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
            if (student.fromAddress.isNotEmpty) Text("🚩 Đi: ${student.fromAddress}"),
            if (student.toAddress.isNotEmpty) Text("🏁 Đến: ${student.toAddress}"),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push<Map<String, String>>(
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
                      final fromAddress = result['from'];
                      final toAddress = result['to'];
                      final fromLatLngString = result['fromLatLng'] as String?;
                      final toLatLngString = result['toLatLng'] as String?;

                      if (fromLatLngString != null &&
                          toLatLngString != null &&
                          fromAddress != null &&
                          toAddress != null) {
                        final user = FirebaseAuth.instance.currentUser;
                        if (user == null) return;

                        final uid = user.uid;
                        final studentRef = FirebaseFirestore.instance
                            .collection('users')
                            .doc(uid)
                            .collection('students')
                            .doc(student.id);

                        final studentDoc = await studentRef.get();
                        if (!studentDoc.exists) return;

                        final data = studentDoc.data()!;
                        final timetable = data['timetable'] as Map<String, dynamic>?;

                        if (timetable != null && timetable.containsKey(student.date)) {
                          final lessons = List<Map<String, dynamic>>.from(timetable[student.date]);

                          for (int i = 0; i < lessons.length; i++) {
                            final lesson = lessons[i];
                            if (lesson['start'] == student.startTime && lesson['end'] == student.endTime) {
                              // ✅ Cập nhật dữ liệu mới
                              lessons[i]['fromAddress'] = fromAddress;
                              lessons[i]['toAddress'] = toAddress;
                              lessons[i]['fromLatLng'] = fromLatLngString;
                              lessons[i]['toLatLng'] = toLatLngString;
                              break;
                            }
                          }

                          // ✅ Ghi ngược lại vào Firestore
                          await studentRef.update({
                            'timetable.${student.date}': lessons,
                          });
                        }
                      }
                    }
                  },

                  icon: const Icon(Icons.edit_location),
                  label: const Text("Địa chỉ"),
                ),

                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Đi đến lịch ngày ${student.date}')),
                    );
                  },
                  icon: const Icon(Icons.schedule),
                  label: const Text("Lịch"),
                ),
                const SizedBox(width: 8),
                // ElevatedButton.icon(
                //   onPressed: () {
                //     final LatLng? destination = _parseLatLng(student.fromLatLng);
                //     if (destination == null) {
                //       ScaffoldMessenger.of(context).showSnackBar(
                //         const SnackBar(content: Text("❌ Chưa có địa chỉ điểm đi")),
                //       );
                //       return;
                //     }
                //
                //     Navigator.push(
                //       context,
                //       MaterialPageRoute(
                //         builder: (_) => LiveTrackingMapScreen(
                //           destination: destination,
                //         ),
                //       ),
                //     );
                //   },
                //   icon: const Icon(Icons.navigation),
                //   label: const Text("Theo dõi"),
                // ),


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
  String fromAddress;
  String toAddress;
  String fromLatLng;
  String toLatLng;
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