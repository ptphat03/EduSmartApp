// File: report_card_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
  bool isEditingGrades = false;
  Map<String, Map<String, Map<String, double>>> tempGrades = {}; // temp storage

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

    try {
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

      // 🛡️ Kiểm tra widget còn tồn tại không
      if (!mounted) return;

      setState(() => isLoading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false); // Bạn có thể hiển thị lỗi ở đây nếu cần
    }
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

  void showGradeGroupManagerDialog() {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Quản lý nhóm cột điểm", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              ...gradeGroups.entries.map((entry) {
                final groupId = entry.key;
                final name = entry.value['groupName'] ?? '';
                final columns = List<String>.from(entry.value['columns']);
                final weights = List<num>.from(entry.value['weights']);
                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 3,
                  child: ListTile(
                    title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black)),
                    subtitle: Text("Cột: ${columns.join(', ')}\nTrọng số: ${weights.join(', ')}", style: const TextStyle(color: Colors.black87)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.orange),
                          onPressed: () async {
                            Navigator.pop(context); // đóng dialog trước
                            await editGradeGroup(groupId, entry.value);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            await deleteGradeGroup(groupId);
                            setState(() {}); // cập nhật lại UI trong dialog
                            Navigator.pop(context);
                            showGradeGroupManagerDialog(); // mở lại dialog
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const Divider(),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text("Thêm nhóm cột mới", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  Navigator.pop(context);
                  await showAddGradeGroupDialog();
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Đóng", style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  void showSubjectManagerDialog() {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Quản lý môn học", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              ...studentSubjects.map((subject) {
                final subjectId = subject['id'];
                final name = subject['name'] ?? '';
                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 3,
                  child: ListTile(
                    title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.green),
                          onPressed: () {
                            nameController.text = name;
                            String? selectedGroupId = subject['gradeGroupId'];

                            showDialog(
                              context: context,
                              builder: (_) => StatefulBuilder(
                                builder: (context, setState) => AlertDialog(
                                  backgroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  title: const Text("Chỉnh sửa môn học", style: TextStyle(color: Colors.black)),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      TextField(
                                        controller: nameController,
                                        decoration: const InputDecoration(
                                          labelText: "Tên môn học",
                                          border: OutlineInputBorder(),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      DropdownButtonFormField<String>(
                                        value: selectedGroupId,
                                        decoration: const InputDecoration(
                                          labelText: "Nhóm cột điểm",
                                          border: OutlineInputBorder(),
                                        ),
                                        items: gradeGroups.entries.map((e) => DropdownMenuItem(
                                          value: e.key,
                                          child: Text(e.value['groupName'], style: const TextStyle(color: Colors.black)),
                                        )).toList(),
                                        onChanged: (value) => setState(() => selectedGroupId = value),
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(context), child: const Text("Huỷ", style: TextStyle(color: Colors.black))),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                                      onPressed: () async {
                                        final uid = FirebaseAuth.instance.currentUser!.uid;
                                        await FirebaseFirestore.instance
                                            .collection('users')
                                            .doc(uid)
                                            .collection('students')
                                            .doc(selectedStudentId)
                                            .collection('subjects')
                                            .doc(subjectId)
                                            .update({
                                          'name': nameController.text.trim(),
                                          'gradeGroupId': selectedGroupId,
                                        });
                                        Navigator.pop(context);
                                        Navigator.pop(context);
                                        await loadAllData(); // tải lại toàn bộ (gồm student, subject, group)
                                        setState(() {});
                                        showSubjectManagerDialog(); // mở lại để thấy danh sách cập nhật
                                      },
                                      child: const Text("Lưu", style: TextStyle(color: Colors.white)),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            final uid = FirebaseAuth.instance.currentUser!.uid;
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(uid)
                                .collection('students')
                                .doc(selectedStudentId)
                                .collection('subjects')
                                .doc(subjectId)
                                .delete();
                            await loadStudentSubjects();
                            setState(() {});
                            Navigator.pop(context);
                            showSubjectManagerDialog();
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const Divider(),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text("Thêm môn học mới", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  nameController.clear();
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      title: const Text("Thêm môn học", style: TextStyle(color: Colors.black)),
                      content: TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: "Tên môn học",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Huỷ", style: TextStyle(color: Colors.black))),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                          onPressed: () async {
                            final uid = FirebaseAuth.instance.currentUser!.uid;
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(uid)
                                .collection('students')
                                .doc(selectedStudentId)
                                .collection('subjects')
                                .add({'name': nameController.text.trim()});
                            Navigator.pop(context);
                            Navigator.pop(context);
                            await loadStudentSubjects();
                            setState(() {});
                            showSubjectManagerDialog();
                          },
                          child: const Text("Lưu", style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Đóng", style: TextStyle(color: Colors.black))),
        ],
      ),
    );
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
    await loadGradeGroups();

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) {
          String? selectedGroupId;
          return AlertDialog(
            title: const Text('Chọn nhóm cột điểm'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: "Nhóm cột điểm",
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    ...gradeGroups.entries.map((e) => DropdownMenuItem(
                      value: e.key,
                      child: Text(e.value['groupName']),
                    )),
                    const DropdownMenuItem(
                      value: 'new',
                      child: Text("+ Tạo nhóm mới"),
                    ),
                  ],
                  onChanged: (groupId) async {
                    if (groupId == 'new') {
                      Navigator.pop(context);
                      await showAddGradeGroupDialog();
                      await showAssignGroupDialog(subjectId);
                    } else {
                      selectedGroupId = groupId;
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Huỷ"),
              ),
              ElevatedButton(
                onPressed: () {
                  if (selectedGroupId != null && selectedGroupId != 'new') {
                    assignGradeGroup(subjectId, selectedGroupId!);
                    Navigator.pop(context);
                  }
                },
                child: const Text("Lưu"),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> showAddGradeGroupDialog() async {
    final nameController = TextEditingController();
    List<Map<String, TextEditingController>> fields = [
      {
        'col': TextEditingController(),
        'weight': TextEditingController(),
      }
    ];

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Tạo nhóm cột điểm mới'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Tên nhóm'),
                ),
                const SizedBox(height: 12),
                const Text("Danh sách cột và trọng số:", style: TextStyle(fontWeight: FontWeight.bold)),
                ...List.generate(fields.length, (index) {
                  final field = fields[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: field['col'],
                            decoration: const InputDecoration(labelText: 'Tên cột'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: field['weight'],
                            decoration: const InputDecoration(labelText: 'Trọng số'),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 4),
                        // Mũi tên lên/xuống sát nhau
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              padding: EdgeInsets.zero,
                              iconSize: 20,
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(Icons.arrow_upward),
                              onPressed: index > 0
                                  ? () {
                                setState(() {
                                  final temp = fields[index - 1];
                                  fields[index - 1] = fields[index];
                                  fields[index] = temp;
                                });
                              }
                                  : null,
                            ),
                            IconButton(
                              padding: EdgeInsets.zero,
                              iconSize: 20,
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(Icons.arrow_downward),
                              onPressed: index < fields.length - 1
                                  ? () {
                                setState(() {
                                  final temp = fields[index + 1];
                                  fields[index + 1] = fields[index];
                                  fields[index] = temp;
                                });
                              }
                                  : null,
                            ),
                          ],
                        ),
                        // Nút xoá
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: fields.length > 1
                              ? () => setState(() => fields.removeAt(index))
                              : null,
                          tooltip: "Xoá",
                        ),
                      ],
                    ),
                  );


                }),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: const Icon(Icons.add_circle, color: Colors.green),
                    tooltip: 'Thêm cột',
                    onPressed: () {
                      setState(() {
                        fields.add({
                          'col': TextEditingController(),
                          'weight': TextEditingController(),
                        });
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Huỷ')),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final columns = fields.map((f) => f['col']!.text.trim()).toList();
                final weights = fields.map((f) => num.tryParse(f['weight']!.text.trim()) ?? 0).toList();

                if (name.isNotEmpty && columns.isNotEmpty && !columns.any((c) => c.isEmpty)) {
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
      ),
    );
  }




  Future<void> editGradeGroup(String groupId, Map<String, dynamic> data) async {
    final nameController = TextEditingController(text: data['groupName']);
    List<Map<String, TextEditingController>> fields = [];

    final columns = List<String>.from(data['columns']);
    final weights = List<num>.from(data['weights']);
    for (int i = 0; i < columns.length; i++) {
      fields.add({
        'col': TextEditingController(text: columns[i]),
        'weight': TextEditingController(text: weights[i].toString()),
      });
    }

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Chỉnh sửa nhóm cột điểm'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Tên nhóm'),
                ),
                const SizedBox(height: 12),
                const Text("Danh sách cột và trọng số:", style: TextStyle(fontWeight: FontWeight.bold)),
                ...List.generate(fields.length, (index) {
                  final field = fields[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: field['col'],
                            decoration: const InputDecoration(labelText: 'Tên cột'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: field['weight'],
                            decoration: const InputDecoration(labelText: 'Trọng số'),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 4),
                        // Mũi tên lên/xuống sát nhau
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              padding: EdgeInsets.zero,
                              iconSize: 20,
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(Icons.arrow_upward),
                              onPressed: index > 0
                                  ? () {
                                setState(() {
                                  final temp = fields[index - 1];
                                  fields[index - 1] = fields[index];
                                  fields[index] = temp;
                                });
                              }
                                  : null,
                            ),
                            IconButton(
                              padding: EdgeInsets.zero,
                              iconSize: 20,
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(Icons.arrow_downward),
                              onPressed: index < fields.length - 1
                                  ? () {
                                setState(() {
                                  final temp = fields[index + 1];
                                  fields[index + 1] = fields[index];
                                  fields[index] = temp;
                                });
                              }
                                  : null,
                            ),
                          ],
                        ),
                        // Nút xoá
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: fields.length > 1
                              ? () => setState(() => fields.removeAt(index))
                              : null,
                          tooltip: "Xoá",
                        ),
                      ],
                    ),
                  );

                }),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: const Icon(Icons.add_circle, color: Colors.green),
                    tooltip: 'Thêm cột',
                    onPressed: () {
                      setState(() {
                        fields.add({
                          'col': TextEditingController(),
                          'weight': TextEditingController(),
                        });
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Huỷ')),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final columns = fields.map((f) => f['col']!.text.trim()).toList();
                final weights = fields.map((f) => num.tryParse(f['weight']!.text.trim()) ?? 0).toList();

                if (name.isNotEmpty && columns.isNotEmpty && !columns.any((c) => c.isEmpty)) {
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
      ),
    );
  }




  Future<void> deleteGradeGroup(String groupId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || selectedStudentId == null) return;

    final studentRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('students')
        .doc(selectedStudentId!);

    final batch = FirebaseFirestore.instance.batch();

    // Xóa group
    final groupDocRef = studentRef.collection('gradeGroups').doc(groupId);
    batch.delete(groupDocRef);

    // Lấy tất cả subject có gradeGroupId == groupId
    final subjectSnap = await studentRef.collection('subjects').get();
    for (final doc in subjectSnap.docs) {
      final data = doc.data();
      if (data['gradeGroupId'] == groupId) {
        // Gỡ liên kết
        batch.update(doc.reference, {'gradeGroupId': FieldValue.delete()});
      }
    }

    await batch.commit();
    await loadGradeGroups();
    await loadStudentSubjects();
    setState(() {});
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedStudentId,
                    decoration: InputDecoration(
                      labelText: 'Chọn học sinh',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
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
                  ),
                ),
                const SizedBox(width: 8),

                if (!isEditingGrades) // Khi chưa bật chế độ chỉnh sửa
                  IconButton(
                    icon: const Icon(Icons.edit),
                    tooltip: 'Bật chỉnh sửa điểm',
                    onPressed: () {
                      setState(() {
                        tempGrades = {}; // reset
                        final student = selectedStudent;
                        if (student != null) {
                          for (var subject in student.grades.entries) {
                            final subjectName = subject.key;
                            final gradeMap = Map<String, double>.from(
                              subject.value.map((k, v) => MapEntry(k, (v as num).toDouble())),
                            );
                            tempGrades[student.id] ??= {};
                            tempGrades[student.id]![subjectName] = gradeMap;
                          }
                        }
                        isEditingGrades = true;
                      });

                    },
                  )
                else // Khi đang ở chế độ chỉnh sửa
                  Row(
                    children: [
                      IconButton(
                          icon: const Icon(Icons.check, color: Colors.green),
                          tooltip: 'Tắt chỉnh sửa điểm',
                          onPressed: () async {
                            final uid = FirebaseAuth.instance.currentUser?.uid;
                            final student = selectedStudent;
                            if (uid == null || student == null) return;

                            final updatedGrades = tempGrades[student.id];
                            if (updatedGrades != null) {
                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(uid)
                                  .collection('students')
                                  .doc(student.id)
                                  .set({'grades': updatedGrades}, SetOptions(merge: true));
                            }

                            await loadAllData();
                            setState(() => isEditingGrades = false);
                          }

                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        tooltip: 'Huỷ chỉnh sửa',
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Quay lại?'),
                              content: const Text('Mọi thay đổi sẽ không được lưu.\nBạn vẫn muốn tiếp tục?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Hủy'),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Quay lại'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await loadAllData(); // Tải lại dữ liệu cũ
                            setState(() => isEditingGrades = false);
                          }
                        },
                      ),
                    ],
                  ),
                const SizedBox(width: 4),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  tooltip: 'Tùy chọn',
                  onSelected: (value) async {
                    if (value == 'edit') {
                      if (gradeGroups.isNotEmpty) {
                        final firstEntry = gradeGroups.entries.first;
                        await editGradeGroup(firstEntry.key, firstEntry.value);
                      }
                    } else if (value == 'manage') {
                      showGradeGroupManagerDialog();
                    } else if (value == 'subjects') {
                      showSubjectManagerDialog();
                    } else if (value == 'refresh') {
                      setState(() => isLoading = true);
                      await loadGradeGroups();
                      await loadStudentSubjects();
                      setState(() => isLoading = false);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem<String>(
                      value: 'subjects',
                      child: ListTile(
                        leading: Icon(Icons.book),
                        title: Text("Quản lý môn học"),
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'manage',
                      child: ListTile(
                        leading: Icon(Icons.list),
                        title: Text("Quản lý nhóm cột điểm"),
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'refresh',
                      child: ListTile(
                        leading: Icon(Icons.refresh),
                        title: Text("Tải lại"),
                      ),
                    ),
                  ],
                ),
              ],
            ),

          ),
          if (isLoading)
            const CircularProgressIndicator()
          else
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  setState(() => isLoading = true);
                  await loadAllData();
                },
                child: studentSubjects.isEmpty
                    ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: SingleChildScrollView(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SvgPicture.asset(
                                'assets/images/empty.svg',
                                height: 180,
                              ),
                              const SizedBox(height: 24),
                              const Text(
                                "Chưa có bảng điểm nào",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF333333),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.add, color: Colors.white),
                                label: const Text(
                                  "Thêm môn học mới",
                                  style: TextStyle(color: Colors.white),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: showSubjectManagerDialog,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  ),
                )
                    : ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    ...groupedSubjectWidgets(),
                    ...ungroupedSubjectWidgets(),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> groupedSubjectWidgets() {
    final student = selectedStudent;
    if (student == null) return [];

    final grades = student.grades;
    final widgets = <Widget>[];

    for (final entry in gradeGroups.entries) {
      final groupId = entry.key;
      final groupData = entry.value;
      final subjectsInGroup = studentSubjects
          .where((s) => s['gradeGroupId'] == groupId)
          .toList();
      if (subjectsInGroup.isEmpty) continue;

      final columns = List<String>.from(groupData['columns']);
      final weights = List<num>.from(groupData['weights']);

      widgets.add(
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 4,
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.folder_copy, size: 20, color: Colors.deepPurple),
                      const SizedBox(width: 6),
                      Text(
                        groupData['groupName'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView( // ✅ Cho phép scroll ngang khi tràn
                  scrollDirection: Axis.horizontal,
                  child: Table(
                    columnWidths: {
                      0: const FixedColumnWidth(120), // ✅ Cột "Môn học" không bị ép dòng
                      for (int i = 1; i <= columns.length; i++) i: const FixedColumnWidth(70),
                      columns.length + 1: const FixedColumnWidth(80), // ✅ Cột "Tổng điểm"
                    },
                    border: TableBorder.symmetric(
                      inside: BorderSide(color: Colors.grey.shade300),
                      outside: const BorderSide(color: Colors.grey),
                    ),
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    children: [
                      // Header
                      TableRow(
                        decoration: BoxDecoration(color: Colors.grey[200]),
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(8),
                            child: Text(
                              'Môn học',
                              softWrap: false,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          ...columns.map((c) => Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(
                              c,
                              textAlign: TextAlign.center,
                              softWrap: false,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          )),
                          const Padding(
                            padding: EdgeInsets.all(8),
                            child: Text(
                              'Tổng điểm',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),

                      // Data rows
                      ...subjectsInGroup.map((subject) {
                        final subjectName = subject['name'];
                        final currentGrades = isEditingGrades
                            ? (tempGrades[student.id]?[subjectName] ?? {})
                            : (grades[subjectName] ?? {});

                        double total = 0;
                        for (int i = 0; i < columns.length; i++) {
                          final col = columns[i];
                          final weight = weights[i].toDouble();
                          final raw = currentGrades[col];
                          if (raw is num) {
                            total += raw.toDouble() * weight;
                          }
                        }

                        return TableRow(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                              child: Text(
                                subjectName,
                                softWrap: false,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            ...columns.map((col) {
                              final score = (currentGrades[col] ?? 0).toString();
                              final controller = TextEditingController(text: score);
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                child: TextField(
                                  controller: controller,
                                  textAlign: TextAlign.center,
                                  enabled: isEditingGrades,
                                  decoration: InputDecoration(
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                                    border: const OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.number,
                                  onChanged: (val) {
                                    if (!isEditingGrades) return;
                                    final v = double.tryParse(val);
                                    if (v != null) {
                                      tempGrades[student.id] ??= {};
                                      tempGrades[student.id]![subjectName] ??= {};
                                      tempGrades[student.id]![subjectName]![col] = v;
                                    }
                                  },
                                ),
                              );
                            }).toList(),
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Text(
                                total.toStringAsFixed(1),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.teal,
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );


    }

    return widgets;
  }



  List<Widget> ungroupedSubjectWidgets() {
    final ungrouped = studentSubjects
        .where((s) => s['gradeGroupId'] == null)
        .toList();

    if (ungrouped.isEmpty) return [];

    return [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(
          "Môn học chưa phân nhóm",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.deepOrange.shade700,
          ),
        ),
      ),
      ...ungrouped.map((subject) {
        final name = subject['name'] ?? '';
        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 3,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            leading: const Icon(Icons.book_outlined, color: Colors.grey),
            title: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: const Text("(Chưa có nhóm cột điểm)"),
            trailing: ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text("Gán nhóm"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                textStyle: const TextStyle(fontSize: 14),
              ),
              onPressed: () => showAssignGroupDialog(subject['id']),
            ),
          ),
        );
      }),
    ];
  }
}

class Student {
  final String id;
  final String name;
  final Map<String, dynamic> grades;

  Student({required this.id, required this.name, required this.grades});
}