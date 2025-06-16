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
  bool isEditingGrades = false;

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
  void showGradeGroupManagerDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Quản lý nhóm cột điểm'),
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
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    title: Text(name),
                    subtitle: Text("Cột: ${columns.join(', ')}\nTrọng số: ${weights.join(', ')}"),
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
              }).toList(),
              const Divider(),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text("Thêm nhóm cột mới"),
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
            child: const Text('Đóng'),
            onPressed: () => Navigator.pop(context),
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
        title: const Text("Quản lý môn học"),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              ...studentSubjects.map((subject) {
                final subjectId = subject['id'];
                final name = subject['name'] ?? '';
                return Card(
                  child: ListTile(
                    title: Text(name),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.orange),
                          onPressed: () {
                            nameController.text = name;
                            String? selectedGroupId = subject['gradeGroupId'];

                            showDialog(
                              context: context,
                              builder: (_) => StatefulBuilder(
                                builder: (context, setState) => AlertDialog(
                                  title: const Text("Chỉnh sửa môn học"),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      TextField(
                                        controller: nameController,
                                        decoration: const InputDecoration(labelText: "Tên môn học"),
                                      ),
                                      const SizedBox(height: 12),
                                      DropdownButtonFormField<String>(
                                        value: selectedGroupId,
                                        decoration: const InputDecoration(labelText: "Nhóm cột điểm"),
                                        items: gradeGroups.entries.map((e) => DropdownMenuItem(
                                          value: e.key,
                                          child: Text(e.value['groupName']),
                                        )).toList(),
                                        onChanged: (value) => setState(() => selectedGroupId = value),
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(context), child: const Text("Huỷ")),
                                    ElevatedButton(
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
                                        Navigator.pop(context); // đóng dialog sửa
                                        Navigator.pop(context); // đóng dialog quản lý
                                        await loadStudentSubjects();
                                        setState(() {});
                                        showSubjectManagerDialog(); // mở lại
                                      },
                                      child: const Text("Lưu"),
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
                            showSubjectManagerDialog(); // reload UI
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
                label: const Text("Thêm môn học mới"),
                onPressed: () {
                  nameController.clear();
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text("Thêm môn học"),
                      content: TextField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: "Tên môn học"),
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Huỷ")),
                        ElevatedButton(
                          onPressed: () async {
                            final uid = FirebaseAuth.instance.currentUser!.uid;
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(uid)
                                .collection('students')
                                .doc(selectedStudentId)
                                .collection('subjects')
                                .add({'name': nameController.text.trim()});
                            Navigator.pop(context); // đóng form thêm
                            Navigator.pop(context); // đóng dialog quản lý
                            await loadStudentSubjects();
                            setState(() {});
                            showSubjectManagerDialog(); // mở lại
                          },
                          child: const Text("Lưu"),
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Đóng")),
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
    final List<TextEditingController> columnControllers = [];
    final List<TextEditingController> weightControllers = [];

    void addColumnField() {
      columnControllers.add(TextEditingController());
      weightControllers.add(TextEditingController());
    }

    addColumnField(); // Khởi tạo 1 dòng mặc định

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Tạo nhóm cột điểm mới'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Tên nhóm'),
                ),
                const SizedBox(height: 12),
                const Text("Danh sách cột và trọng số:", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                ...List.generate(columnControllers.length, (index) {
                  return Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: columnControllers[index],
                          decoration: const InputDecoration(labelText: 'Tên cột'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: weightControllers[index],
                          decoration: const InputDecoration(labelText: 'Trọng số'),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  );
                }),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: const Icon(Icons.add_circle, color: Colors.green),
                    tooltip: 'Thêm cột',
                    onPressed: () => setState(addColumnField),
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
                final columns = columnControllers.map((c) => c.text.trim()).toList();
                final weights = weightControllers.map((w) => num.tryParse(w.text.trim()) ?? 0).toList();

                if (name.isNotEmpty &&
                    columns.isNotEmpty &&
                    !columns.any((c) => c.isEmpty) &&
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
      ),
    );
  }


  Future<void> editGradeGroup(String groupId, Map<String, dynamic> data) async {
    final nameController = TextEditingController(text: data['groupName']);
    final columns = List<String>.from(data['columns']);
    final weights = List<num>.from(data['weights']);

    final List<TextEditingController> columnControllers =
    columns.map((c) => TextEditingController(text: c)).toList();
    final List<TextEditingController> weightControllers =
    weights.map((w) => TextEditingController(text: w.toString())).toList();

    void addColumnField() {
      columnControllers.add(TextEditingController());
      weightControllers.add(TextEditingController());
    }

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Chỉnh sửa nhóm cột điểm'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Tên nhóm'),
                ),
                const SizedBox(height: 12),
                const Text("Danh sách cột và trọng số:", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                ...List.generate(columnControllers.length, (index) {
                  return Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: columnControllers[index],
                          decoration: const InputDecoration(labelText: 'Tên cột'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: weightControllers[index],
                          decoration: const InputDecoration(labelText: 'Trọng số'),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  );
                }),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: const Icon(Icons.add_circle, color: Colors.green),
                    tooltip: 'Thêm cột',
                    onPressed: () => setState(addColumnField),
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
                final cols = columnControllers.map((c) => c.text.trim()).toList();
                final ws = weightControllers.map((w) => num.tryParse(w.text.trim()) ?? 0).toList();

                if (name.isNotEmpty &&
                    cols.isNotEmpty &&
                    !cols.any((c) => c.isEmpty) &&
                    cols.length == ws.length) {
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
                    'columns': cols,
                    'weights': ws,
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
                IconButton(
                  icon: Icon(isEditingGrades ? Icons.check : Icons.edit),
                  tooltip: isEditingGrades ? 'Tắt chỉnh sửa điểm' : 'Bật chỉnh sửa điểm',
                  onPressed: () {
                    setState(() => isEditingGrades = !isEditingGrades);
                  },
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
              child: ListView(
                children: [
                  ...groupedSubjectWidgets(),
                  ...ungroupedSubjectWidgets(),
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
                              enabled: isEditingGrades,
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
}

class Student {
  final String id;
  final String name;
  final Map<String, dynamic> grades;

  Student({required this.id, required this.name, required this.grades});
}
