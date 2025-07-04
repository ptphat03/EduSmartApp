import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PremiumService {
  static Future<bool> isUserPremium() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    return doc.data()?['premium'] ?? false;
  }
}
