import 'package:flutter/material.dart';
import '../widgets/custom_app_bar.dart';

class ReportCardScreen extends StatefulWidget {
  const ReportCardScreen({super.key});

  @override
  State<ReportCardScreen> createState() => _ReportCardScreenState();
}

class _ReportCardScreenState extends State<ReportCardScreen> {
  int _selectedStudentIndex = 0;

  final List<Student> students = [
    Student(name: "Nguyễn Văn A - Lớp 5A2", grades: [
      SubjectGrade(subject: "Toán", midterm: 8.5, finalExam: 9.0),
      SubjectGrade(subject: "Văn", midterm: 7.0, finalExam: 8.0),
      SubjectGrade(subject: "Tiếng Anh", midterm: 9.0, finalExam: 9.5),
      SubjectGrade(subject: "Lý", midterm: 6.5, finalExam: 7.5),
      SubjectGrade(subject: "Hóa", midterm: 7.5, finalExam: 8.0),
    ]),
    Student(name: "Trần Thị B - Lớp 4A1", grades: [
      SubjectGrade(subject: "Toán", midterm: 9.0, finalExam: 9.5),
      SubjectGrade(subject: "Văn", midterm: 8.0, finalExam: 8.5),
    ]),
  ];

  final _subjectController = TextEditingController();
  final _midtermController = TextEditingController();
  final _finalController = TextEditingController();

  void _addSubject() {
    final subject = _subjectController.text.trim();
    final mid = double.tryParse(_midtermController.text.trim());
    final fin = double.tryParse(_finalController.text.trim());

    if (subject.isNotEmpty && mid != null && fin != null) {
      setState(() {
        students[_selectedStudentIndex].grades.add(
          SubjectGrade(subject: subject, midterm: mid, finalExam: fin),
        );
      });
      _subjectController.clear();
      _midtermController.clear();
      _finalController.clear();
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = students[_selectedStudentIndex];

    return Scaffold(
      //appBar: buildCustomAppBar("Bảng điểm", Icons.bar_chart),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.greenAccent, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<int>(
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              value: _selectedStudentIndex,
              items: List.generate(
                students.length,
                    (i) => DropdownMenuItem(
                  value: i,
                  child: Text(students[i].name),
                ),
              ),
              onChanged: (val) => setState(() => _selectedStudentIndex = val!),
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  )
                ],
              ),
              child: Table(
                border: TableBorder.all(color: Colors.grey.shade300),
                columnWidths: const {
                  0: FlexColumnWidth(2),
                  1: FlexColumnWidth(1.5),
                  2: FlexColumnWidth(1.5),
                  3: FlexColumnWidth(1.5),
                },
                children: [
                  const TableRow(
                    decoration: BoxDecoration(color: Colors.lightGreen),
                    children: [
                      Padding(
                        padding: EdgeInsets.all(8),
                        child: Text("Môn học", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8),
                        child: Text("Giữa kỳ", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8),
                        child: Text("Cuối kỳ", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8),
                        child: Text("TB", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  ...current.grades.map((g) {
                    final avg = ((g.midterm + g.finalExam) / 2).toStringAsFixed(1);
                    return TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(g.subject),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: TextField(
                            controller: TextEditingController(text: g.midterm.toString()),
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(border: InputBorder.none),
                            onSubmitted: (val) => setState(() {
                              g.midterm = double.tryParse(val) ?? g.midterm;
                            }),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: TextField(
                            controller: TextEditingController(text: g.finalExam.toString()),
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(border: InputBorder.none),
                            onSubmitted: (val) => setState(() {
                              g.finalExam = double.tryParse(val) ?? g.finalExam;
                            }),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(avg),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              top: 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Thêm môn học", style: TextStyle(fontSize: 18)),
                TextField(
                  controller: _subjectController,
                  decoration: const InputDecoration(labelText: "Môn học"),
                ),
                TextField(
                  controller: _midtermController,
                  decoration: const InputDecoration(labelText: "Điểm giữa kỳ"),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: _finalController,
                  decoration: const InputDecoration(labelText: "Điểm cuối kỳ"),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _addSubject,
                  child: const Text("Lưu"),
                )
              ],
            ),
          ),
        ),
        backgroundColor: Colors.green,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class Student {
  final String name;
  final List<SubjectGrade> grades;

  Student({required this.name, required this.grades});
}

class SubjectGrade {
  final String subject;
  double midterm;
  double finalExam;

  SubjectGrade({required this.subject, required this.midterm, required this.finalExam});
}
