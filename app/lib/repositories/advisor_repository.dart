import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/advisor.dart';

class AdvisorRepository {
  final FirebaseFirestore _firestore;

  AdvisorRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> saveAdvisor(Advisor advisor) async {
    await _firestore.collection('advisors').doc(advisor.uid).set(advisor.toMap());
  }

  Future<Advisor?> getAdvisor(String uid) async {
    final doc = await _firestore.collection('advisors').doc(uid).get();
    if (doc.exists) {
      final data = doc.data();
      if (data != null) {
        return Advisor.fromMap(data);
      }
    }
    return null;
  }

  Future<void> deleteAdvisor(String uid) async {
    await _firestore.collection('advisors').doc(uid).delete();
  }
}
