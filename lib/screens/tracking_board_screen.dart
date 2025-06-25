import 'package:flutter/material.dart';
import 'map_simulation_screen.dart';

  class TrackingBoardScreen extends StatelessWidget {
    const TrackingBoardScreen({super.key});

    @override
    Widget build(BuildContext context) {
      final List<Student> myStudents = [
        Student(name: "Nguyễn Văn A", time: "06:50", status: "waiting"),
        Student(name: "Trần Thị B", time: "07:10", status: "onbus"),
        Student(name: "Lê Văn C", time: "07:30", status: "arrived"),
        Student(name: "Phạm Quốc Dũng", time: "06:45", status: "waiting"),
      ];

      final waiting = myStudents.where((s) => s.status == "waiting").toList();
      final onbus = myStudents.where((s) => s.status == "onbus").toList();
      final arrived = myStudents.where((s) => s.status == "arrived").toList();

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
              TrackingSection(title: "🚶 Trước khi lên xe", color: Colors.orange, students: waiting),
              TrackingSection(title: "🚌 Đang trên xe", color: Colors.blue, students: onbus),
              TrackingSection(title: "🏫 Đã đến trường", color: Colors.green, students: arrived),
            ],
          ),
        ),
      );
    }
  }

  class TrackingSection extends StatelessWidget {
    final String title;
    final Color color;
    final List<Student> students;

    const TrackingSection({
      super.key,
      required this.title,
      required this.color,
      required this.students,
    });

    @override
    Widget build(BuildContext context) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 8),
          ...students.map((s) => StudentCard(name: s.name, time: s.time)).toList(),
          const SizedBox(height: 20),
        ],
      );
    }
  }

  class StudentCard extends StatelessWidget {
    final String name;
    final String time;

    const StudentCard({super.key, required this.name, required this.time});

    @override
    Widget build(BuildContext context) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: ListTile(
          leading: const CircleAvatar(
            radius: 20,
            // backgroundImage: AssetImage('assets/avatar.png'),
          ),
          title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text("⏰ Thời gian: $time"),
          trailing: const Icon(Icons.check_circle, color: Colors.green),
        ),
      );
    }
  }

  class Student {
    final String name;
    final String time;
    final String status;

    Student({required this.name, required this.time, required this.status});
  }
