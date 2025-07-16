import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({Key? key}) : super(key: key);

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  int selectedStars = 5;
  final TextEditingController commentController = TextEditingController();
  final user = FirebaseAuth.instance.currentUser;
  bool isSubmitting = false;
  String? reviewDocId;

  @override
  void initState() {
    super.initState();
    loadExistingReview();
  }

  Future<void> loadExistingReview() async {
    if (user == null) return;

    final query = await FirebaseFirestore.instance
        .collection('app_reviews')
        .where('userId', isEqualTo: user!.uid)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      final doc = query.docs.first;
      setState(() {
        reviewDocId = doc.id;
        selectedStars = doc['rating'];
        commentController.text = doc['comment'] ?? '';
      });
    }
  }

  Future<void> submitReview() async {
    if (user == null) return;

    setState(() => isSubmitting = true);

    final data = {
      "userId": user!.uid,
      "rating": selectedStars,
      "comment": commentController.text.trim(),
      "updatedAt": FieldValue.serverTimestamp(),
    };

    if (reviewDocId == null) {
      data["createdAt"] = FieldValue.serverTimestamp();
      final docRef =
      await FirebaseFirestore.instance.collection('app_reviews').add(data);
      reviewDocId = docRef.id;
    } else {
      await FirebaseFirestore.instance
          .collection('app_reviews')
          .doc(reviewDocId)
          .update(data);
    }

    setState(() => isSubmitting = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          reviewDocId == null
              ? "✅ Cảm ơn bạn đã đánh giá!"
              : "✅ Đánh giá đã được cập nhật!",
        ),
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Đánh giá ứng dụng"),
        centerTitle: true,
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Card(
          elevation: 5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Chọn số sao:",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      icon: Icon(
                        index < selectedStars
                            ? Icons.star
                            : Icons.star_border_outlined,
                        color: Colors.green,
                        size: 36,
                      ),
                      onPressed: () {
                        setState(() {
                          selectedStars = index + 1;
                        });
                      },
                    );
                  }),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Nhận xét:",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: commentController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: "Nhập nhận xét của bạn...",
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: const EdgeInsets.all(16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                Center(
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isSubmitting ? null : submitReview,
                      icon: isSubmitting
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                          : const Icon(Icons.send, color: Colors.white),
                      label: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Text(
                          isSubmitting
                              ? "Đang gửi..."
                              : (reviewDocId == null
                              ? "Gửi đánh giá"
                              : "Cập nhật đánh giá"),
                          key: ValueKey(isSubmitting),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.blue, width: 2),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

    );
  }
}
