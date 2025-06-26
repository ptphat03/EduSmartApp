import 'package:flutter/material.dart';
import 'map_simulation_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'custom_address_picker.dart'; // 👈 Import màn chọn địa chỉ

class TrackingBoardScreen extends StatefulWidget {
  const TrackingBoardScreen({super.key});

  @override
  State<TrackingBoardScreen> createState() => _TrackingBoardScreenState();
}

class _TrackingBoardScreenState extends State<TrackingBoardScreen> {
  List<Student> allStudents = [];
  String? selectedStudentId;
  Map<String, String> studentIdNameMap = {};

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
                date: day,
              ));
            }
          }
        }
      }
    }

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

  @override
  Widget build(BuildContext context) {
    final filteredStudents = allStudents.where((s) => s.id == selectedStudentId).toList();

    final studentsByDate = <String, List<Student>>{};
    for (var student in filteredStudents) {
      studentsByDate.putIfAbsent(student.date, () => []).add(student);
    }

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
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MapScreen()),
                );
              },
              child: Container(
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [Colors.lightBlueAccent, Colors.white],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3)),
                  ],
                ),
                alignment: Alignment.center,
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map, size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text("🌍 Bản đồ giả lập", style: TextStyle(fontSize: 16)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ...studentsByDate.entries.map((entry) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("📅 Ngày: ${entry.key}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...entry.value.map((s) => StudentCard(student: s)).toList(),
                  const SizedBox(height: 20),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}

class StudentCard extends StatelessWidget {
  final Student student;

  const StudentCard({super.key, required this.student});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: const CircleAvatar(radius: 20),
        title: Text(student.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("⏰ Thời gian: ${student.startTime} - ${student.endTime}"),
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
                        builder: (_) => const CustomAddressPickerScreen(title: "Chọn địa chỉ"),
                      ),
                    );
                    if (result != null) {
                      // Có thể xử lý dữ liệu trả về nếu cần
                    }
                  },
                  icon: const Icon(Icons.edit_location),
                  label: const Text("Địa chỉ"),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    // Điều hướng đến trang schedule tại ngày tương ứng
                    // TODO: thay bằng Navigator.push với tham số cụ thể nếu bạn có màn hình Schedule
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Đi đến lịch ngày ${student.date}')), // placeholder
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
  });
}
