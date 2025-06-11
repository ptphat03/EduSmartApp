import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class EditableScheduleScreen extends StatefulWidget {
  const EditableScheduleScreen({super.key});

  @override
  State<EditableScheduleScreen> createState() => _EditableScheduleScreenState();
}

class _EditableScheduleScreenState extends State<EditableScheduleScreen> {
  List<Student> students = [];
  int selectedStudentIndex = 0;
  bool isLoading = true;
  DateTime currentWeekStart = DateTime.now();
  bool isEditMode = false;

  @override
  void initState() {
    super.initState();
    currentWeekStart = currentWeekStart.subtract(Duration(days: currentWeekStart.weekday - 1));
    loadStudentsFromFirebase();
  }

  Future<void> loadStudentsFromFirebase() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('students')
          .get();

      students = snapshot.docs.map((doc) {
        final data = doc.data();
        final rawTimetable = data['timetable'] ?? {};

        final parsedTimetable = <String, List<Map<String, dynamic>>>{};
        rawTimetable.forEach((date, sessions) {
          parsedTimetable[date] = List<Map<String, dynamic>>.from(sessions);
        });

        return Student(
          id: doc.id,
          name: data['student_name'] ?? 'Không tên',
          timetable: parsedTimetable,
        );
      }).toList();

      setState(() => isLoading = false);
    } catch (e) {
      debugPrint('Lỗi khi tải học sinh: $e');
      setState(() => isLoading = false);
    }
  }

  List<DateTime> getCurrentWeekDates() {
    return List.generate(7, (i) => currentWeekStart.add(Duration(days: i)));
  }

  void _nextWeek() {
    setState(() => currentWeekStart = currentWeekStart.add(const Duration(days: 7)));
  }

  void _previousWeek() {
    setState(() => currentWeekStart = currentWeekStart.subtract(const Duration(days: 7)));
  }

  Future<void> _addLesson(DateTime date, [int? editIndex]) async {
    final dateKey = DateFormat('yyyy-MM-dd').format(date);
    final student = students[selectedStudentIndex];

    final lesson = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => AddLessonDialog(
        initialData: (editIndex != null && student.timetable[dateKey] != null && student.timetable[dateKey]!.length > editIndex)
            ? student.timetable[dateKey]![editIndex]
            : null,
      ),
    );

    if (lesson != null) {
      setState(() {
        student.timetable.putIfAbsent(dateKey, () => []);
        if (editIndex != null) {
          student.timetable[dateKey]![editIndex] = lesson;
        } else {
          student.timetable[dateKey]!.add(lesson);
        }
      });
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('students')
            .doc(student.id)
            .set({'timetable': student.timetable}, SetOptions(merge: true));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final student = students[selectedStudentIndex];
    final weekDates = getCurrentWeekDates();

    return Scaffold(
      // appBar: AppBar(title: const Text("Thời khóa biểu")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: Row(
              children: [
                Expanded(
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
                      setState(() => selectedStudentIndex = value!);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'refresh') {
                      loadStudentsFromFirebase();
                    } else if (value == 'edit') {
                      setState(() => isEditMode = !isEditMode);
                    }
                  },
                  icon: const Icon(Icons.more_vert),
                  itemBuilder: (context) => [
                    PopupMenuItem<String>(
                      value: 'edit',
                      child: Text(isEditMode ? 'Tắt chỉnh sửa' : 'Bật chỉnh sửa'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'refresh',
                      child: Text('Làm mới'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_left, size: 24),
                  onPressed: _previousWeek,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 16, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        'Tuần: ${DateFormat('dd/MM/yyyy').format(weekDates.first)} - ${DateFormat('dd/MM/yyyy').format(weekDates.last)}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_right, size: 24),
                  onPressed: _nextWeek,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: weekDates.length,
              itemBuilder: (context, index) {
                final date = weekDates[index];
                final dateKey = DateFormat('yyyy-MM-dd').format(date);
                final lessons = student.timetable[dateKey] ?? [];

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      color: Colors.grey.shade200,
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${DateFormat('d/M').format(date)} ${DateFormat('E').format(date)}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          if (isEditMode)
                            IconButton(
                              icon: const Icon(Icons.add_circle, color: Colors.blue),
                              onPressed: () => _addLesson(date),
                            )
                        ],
                      ),
                    ),
                    if (lessons.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                        child: Text("— Không có lịch học", style: TextStyle(color: Colors.grey)),
                      )
                    else
                      ...List.generate(lessons.length, (i) {
                        final lesson = lessons[i];
                        return Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.schedule, color: Colors.blueAccent),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${lesson['start'] ?? ''} - ${lesson['end'] ?? ''}',
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                    if (isEditMode)
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.deepOrange),
                                        onPressed: () => _addLesson(date, i),
                                        tooltip: 'Chỉnh sửa',
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    const Icon(Icons.meeting_room_outlined, size: 20, color: Colors.grey),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'Phòng: ${lesson['room'] ?? ''}',
                                        style: const TextStyle(fontSize: 15),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.book_outlined, size: 20, color: Colors.grey),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'Môn: ${lesson['subject'] ?? ''}',
                                        style: const TextStyle(fontSize: 15),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.person_outline, size: 20, color: Colors.grey),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'Giảng viên: ${lesson['lecturer'] ?? ''}',
                                        style: const TextStyle(fontSize: 15),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );

                      })
                  ],
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
  final String id;
  final String name;
  final Map<String, List<Map<String, dynamic>>> timetable;

  Student({
    required this.id,
    required this.name,
    required this.timetable,
  });
}

class AddLessonDialog extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  const AddLessonDialog({super.key, this.initialData});

  @override
  State<AddLessonDialog> createState() => _AddLessonDialogState();
}

class _AddLessonDialogState extends State<AddLessonDialog> {
  final _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> controllers;

  @override
  void initState() {
    super.initState();
    controllers = {
      'start': TextEditingController(text: widget.initialData?['start'] ?? ''),
      'end': TextEditingController(text: widget.initialData?['end'] ?? ''),
      'room': TextEditingController(text: widget.initialData?['room'] ?? ''),
      'subject': TextEditingController(text: widget.initialData?['subject'] ?? ''),
      'lecturer': TextEditingController(text: widget.initialData?['lecturer'] ?? ''),
    };
  }

  Future<void> _pickTime(String key) async {
    final now = TimeOfDay.now();
    final text = controllers[key]?.text ?? '';
    TimeOfDay initial;

    try {
      final parts = text.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      initial = TimeOfDay(hour: hour, minute: minute);
    } catch (_) {
      initial = now;
    }

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );

    if (picked != null) {
      setState(() {
        controllers[key]?.text = picked.format(context);
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(32),
      child: FractionallySizedBox(
        widthFactor: 0.7,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Thông tin buổi học", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                for (var entry in controllers.entries)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: TextFormField(
                      controller: entry.value,
                      readOnly: entry.key == 'start' || entry.key == 'end',
                      onTap: entry.key == 'start' || entry.key == 'end' ? () => _pickTime(entry.key) : null,
                      decoration: InputDecoration(
                        labelText: _getLabel(entry.key),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) => value == null || value.isEmpty ? 'Không được để trống' : null,
                    ),
                  ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          Navigator.pop(context, {
                            for (var entry in controllers.entries) entry.key: entry.value.text,
                          });
                        }
                      },
                      child: const Text("Lưu"),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getLabel(String key) {
    switch (key) {
      case 'start':
        return 'Giờ bắt đầu';
      case 'end':
        return 'Giờ kết thúc';
      case 'room':
        return 'Phòng';
      case 'subject':
        return 'Môn học';
      case 'lecturer':
        return 'Giảng viên';
      default:
        return key;
    }
  }
}
