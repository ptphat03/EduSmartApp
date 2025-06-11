import 'package:flutter/material.dart';
import '../widgets/custom_app_bar.dart';

class EditableScheduleScreen extends StatefulWidget {
  const EditableScheduleScreen({super.key});

  @override
  State<EditableScheduleScreen> createState() => _EditableScheduleScreenState();
}

class _EditableScheduleScreenState extends State<EditableScheduleScreen> {
  final List<String> days = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
  final List<String> sessions = ['Sáng', 'Chiều'];

  int selectedStudentIndex = 0;

  final List<Student> students = [
    Student.withDefaultSchedule('Nguyễn Văn A', {
      'T2': {
        'Sáng': ['Toán', 'Văn'],
        'Chiều': ['Tiếng Anh']
      },
      'T3': {
        'Sáng': ['Lý'],
        'Chiều': []
      },
      'T4': {
        'Sáng': ['Hóa'],
        'Chiều': ['Tin học']
      },
    }),
    Student.withDefaultSchedule('Trần Thị B'),
  ];

  void _editSubjects(String day, String session) {
    final student = students[selectedStudentIndex];
    final controller = TextEditingController(
      text: student.schedule[day]![session]!.join(', '),
    );

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('📝 $day - $session'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Nhập các môn (cách nhau bằng dấu phẩy)',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                student.schedule[day]![session] =
                    controller.text.split(',').map((e) => e.trim()).toList();
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Lưu'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final student = students[selectedStudentIndex];

    return Scaffold(
      // appBar: buildCustomAppBar("Thời khóa biểu", Icons.calendar_month),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: DropdownButtonFormField<int>(
              value: selectedStudentIndex,
              decoration: InputDecoration(
                labelText: 'Chọn học sinh',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              items: List.generate(
                students.length,
                    (index) => DropdownMenuItem(
                  value: index,
                  child: Text(students[index].name),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  selectedStudentIndex = value!;
                });
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: days.length,
              padding: const EdgeInsets.all(12),
              itemBuilder: (context, index) {
                final day = days[index];
                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("📅 $day", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        const SizedBox(height: 8),
                        ...sessions.map((session) {
                          final subjects = student.schedule[day]![session]!;
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text("🕒 $session"),
                            subtitle: subjects.isEmpty
                                ? const Text("— (chưa có môn)", style: TextStyle(color: Colors.grey))
                                : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: subjects.map((s) => Text("• $s")).toList(),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.edit, color: Colors.green),
                              onPressed: () => _editSubjects(day, session),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class Student {
  final String name;
  final Map<String, Map<String, List<String>>> schedule;

  Student({required this.name, required this.schedule});

  factory Student.withDefaultSchedule(String name, [Map<String, Map<String, List<String>>>? init]) {
    final Map<String, Map<String, List<String>>> defaultSchedule = {
      for (var day in ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'])
        day: {
          'Sáng': [],
          'Chiều': [],
        }
    };

    if (init != null) {
      for (var day in init.keys) {
        defaultSchedule[day] = {
          'Sáng': init[day]?['Sáng'] ?? [],
          'Chiều': init[day]?['Chiều'] ?? [],
        };
      }
    }

    return Student(name: name, schedule: defaultSchedule);
  }
}
