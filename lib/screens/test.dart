// File: report_card_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReportCardScreen extends StatefulWidget {
  const ReportCardScreen({super.key});

  @override
  State<ReportCardScreen> createState() => _ReportCardScreenState();
}

class _ReportCardScreenState extends State<ReportCardScreen> {
  bool isLoading = true;
  List<Student> students = [];
  List<Map<String, dynamic>> studentSubjects = [];
  Map<String, Map<String, dynamic>> gradeGroups = {};
  String? selectedStudentId;

  @override
  void initState() {
    super.initState();
    loadAllData();
  }

  Student? get selectedStudent => students.firstWhere(
        (s) => s.id == selectedStudentId,
    orElse: () => Student(id: '', name: '', grades: {}),
  );

  Future<void> loadAllData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final studentsSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('students')
        .get();

    students = studentsSnap.docs.map((doc) {
      final data = doc.data();
      return Student(
        id: doc.id,
        name: data['student_name'] ?? 'Không tên',
        grades: Map<String, dynamic>.from(data['grades'] ?? {}),
      );
    }).toList();

    if (students.isNotEmpty) {
      selectedStudentId = students.first.id;
      await loadGradeGroups();
      await loadStudentSubjects();
    }

    setState(() => isLoading = false);
  }

  Future<void> loadGradeGroups() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || selectedStudentId == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('students')
        .doc(selectedStudentId)
        .collection('gradeGroups')
        .get();

    gradeGroups.clear();
    for (var doc in snapshot.docs) {
      gradeGroups[doc.id] = doc.data();
    }
  }

  Future<void> loadStudentSubjects() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || selectedStudentId == null) return;
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('students')
        .doc(selectedStudentId)
        .collection('subjects')
        .get();
    studentSubjects =
        snapshot.docs.map((doc) => {"id": doc.id, ...doc.data()}).toList();
  }

  void updateGrade(String studentId, String subject, String col, double value) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection('students')
        .doc(studentId)
        .set({
      "grades": {subject: {col: value}}
    }, SetOptions(merge: true));
  }

  Future<void> assignGradeGroup(String subjectId, String groupId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || selectedStudentId == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('students')
        .doc(selectedStudentId)
        .collection('subjects')
        .doc(subjectId)
        .update({'gradeGroupId': groupId});

    await loadStudentSubjects();
    setState(() {});
  }

  Future<void> showAssignGroupDialog(String subjectId) async {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Chọn nhóm cột điểm'),
        content: DropdownButtonFormField<String>(
          items: gradeGroups.entries
              .map((e) => DropdownMenuItem(
            value: e.key,
            child: Text(e.value['groupName']),
          ))
              .toList(),
          onChanged: (groupId) {
            if (groupId != null) {
              assignGradeGroup(subjectId, groupId);
              Navigator.pop(context);
            }
          },
        ),
      ),
    );
  }

  Future<void> showAddGradeGroupDialog() async {
    final nameController = TextEditingController();
    final columnsController = TextEditingController();
    final weightsController = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Tạo nhóm cột điểm mới'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Tên nhóm'),
            ),
            TextField(
              controller: columnsController,
              decoration:
              const InputDecoration(labelText: 'Tên các cột (phân cách bằng dấu phẩy)'),
            ),
            TextField(
              controller: weightsController,
              decoration:
              const InputDecoration(labelText: 'Trọng số tương ứng (phân cách bằng dấu phẩy)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Huỷ')),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final columns = columnsController.text.split(',').map((e) => e.trim()).toList();
              final weights =
              weightsController.text.split(',').map((e) => num.tryParse(e.trim()) ?? 0).toList();

              if (name.isNotEmpty &&
                  columns.isNotEmpty &&
                  columns.length == weights.length) {
                final uid = FirebaseAuth.instance.currentUser!.uid;
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .collection('students')
                    .doc(selectedStudentId)
                    .collection('gradeGroups')
                    .add({
                  'groupName': name,
                  'columns': columns,
                  'weights': weights,
                });
                Navigator.pop(context);
                await loadGradeGroups();
                setState(() {});
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  Future<void> editGradeGroup(String groupId, Map<String, dynamic> data) async {
    final nameController = TextEditingController(text: data['groupName']);
    final columnsController =
    TextEditingController(text: (data['columns'] as List).join(', '));
    final weightsController =
    TextEditingController(text: (data['weights'] as List).join(', '));

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Chỉnh sửa nhóm cột điểm'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Tên nhóm')),
            TextField(controller: columnsController, decoration: const InputDecoration(labelText: 'Tên các cột')),
            TextField(controller: weightsController, decoration: const InputDecoration(labelText: 'Trọng số')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Huỷ')),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final columns = columnsController.text.split(',').map((e) => e.trim()).toList();
              final weights =
              weightsController.text.split(',').map((e) => num.tryParse(e.trim()) ?? 0).toList();

              if (name.isNotEmpty && columns.length == weights.length) {
                final uid = FirebaseAuth.instance.currentUser!.uid;
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .collection('students')
                    .doc(selectedStudentId)
                    .collection('gradeGroups')
                    .doc(groupId)
                    .update({
                  'groupName': name,
                  'columns': columns,
                  'weights': weights,
                });
                Navigator.pop(context);
                await loadGradeGroups();
                setState(() {});
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  Future<void> deleteGradeGroup(String groupId) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('students')
        .doc(selectedStudentId)
        .collection('gradeGroups')
        .doc(groupId)
        .delete();

    await loadGradeGroups();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Bảng điểm"),
        backgroundColor: Colors.blue.shade600,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_outlined),
            tooltip: 'Tạo nhóm cột',
            onPressed: showAddGradeGroupDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: DropdownButtonFormField<String>(
              value: selectedStudentId,
              items: students.map((student) => DropdownMenuItem(
                value: student.id,
                child: Text(student.name),
              )).toList(),
              onChanged: (value) async {
                selectedStudentId = value;
                await loadGradeGroups();
                await loadStudentSubjects();
                setState(() {});
              },
              decoration: const InputDecoration(labelText: 'Chọn học sinh'),
            ),
          ),
          if (isLoading)
            const CircularProgressIndicator()
          else
            Expanded(
              child: ListView(
                children: [
                  ...groupedSubjectWidgets(),
                  ...ungroupedSubjectWidgets(),
                  ...gradeGroupManagementWidgets(),
                ],
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> groupedSubjectWidgets() {
    final student = selectedStudent;
    final grades = student?.grades ?? {};
    final widgets = <Widget>[];

    for (final entry in gradeGroups.entries) {
      final groupId = entry.key;
      final groupData = entry.value;
      final subjectsInGroup =
      studentSubjects.where((s) => s['gradeGroupId'] == groupId).toList();
      if (subjectsInGroup.isEmpty) continue;

      final columns = List<String>.from(groupData['columns']);
      final weights = List<num>.from(groupData['weights']);

      widgets.add(Card(
        margin: const EdgeInsets.all(12),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(groupData['groupName'], style: const TextStyle(fontWeight: FontWeight.bold)),
              Table(
                border: TableBorder.all(),
                children: [
                  TableRow(
                    children: [
                      const Padding(padding: EdgeInsets.all(6), child: Text('Môn học')),
                      ...columns.map((c) => Padding(padding: const EdgeInsets.all(6), child: Text(c))),
                      const Padding(padding: EdgeInsets.all(6), child: Text('Trung bình')),
                    ],
                  ),
                  ...subjectsInGroup.map((subject) {
                    final subjectName = subject['name'];
                    final subjectId = subject['id'];
                    final studentGrades = grades[subjectName] ?? {};
                    double avg = 0;
                    for (int i = 0; i < columns.length; i++) {
                      final score = (studentGrades[columns[i]] ?? 0).toDouble();
                      avg += score * weights[i];
                    }
                    return TableRow(
                      children: [
                        Padding(padding: const EdgeInsets.all(6), child: Text(subjectName)),
                        ...columns.map((col) {
                          final controller =
                          TextEditingController(text: (studentGrades[col] ?? '').toString());
                          return Padding(
                            padding: const EdgeInsets.all(6),
                            child: TextField(
                              controller: controller,
                              keyboardType: TextInputType.number,
                              onSubmitted: (val) {
                                final v = double.tryParse(val);
                                if (v != null) {
                                  updateGrade(student!.id, subjectName, col, v);
                                  setState(() => studentGrades[col] = v);
                                }
                              },
                            ),
                          );
                        }).toList(),
                        Padding(
                          padding: const EdgeInsets.all(6),
                          child: Text(avg.toStringAsFixed(1)),
                        ),
                      ],
                    );
                  }).toList()
                ],
              ),
            ],
          ),
        ),
      ));
    }

    return widgets;
  }

  List<Widget> ungroupedSubjectWidgets() {
    final ungrouped = studentSubjects.where((s) => s['gradeGroupId'] == null).toList();
    return ungrouped
        .map((subject) => ListTile(
      title: Text(subject['name'] ?? ''),
      subtitle: const Text("(Chưa có nhóm cột)"),
      trailing: IconButton(
        icon: const Icon(Icons.add_circle, color: Colors.blue),
        onPressed: () => showAssignGroupDialog(subject['id']),
      ),
    ))
        .toList();
  }

  List<Widget> gradeGroupManagementWidgets() {
    return [
      const Padding(
        padding: EdgeInsets.only(top: 24, left: 16),
        child: Text("Tất cả nhóm cột điểm:", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      ...gradeGroups.entries.map((entry) {
        final groupId = entry.key;
        final name = entry.value['groupName'] ?? '';
        final columns = List<String>.from(entry.value['columns']);
        final weights = List<num>.from(entry.value['weights']);
        return ListTile(
          title: Text(name),
          subtitle: Text("Cột: ${columns.join(', ')}\nTrọng số: ${weights.join(', ')}"),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.orange),
                onPressed: () => editGradeGroup(groupId, entry.value),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => deleteGradeGroup(groupId),
              ),
            ],
          ),
        );
      }).toList(),
    ];
  }
}

class Student {
  final String id;
  final String name;
  final Map<String, dynamic> grades;

  Student({required this.id, required this.name, required this.grades});
}
