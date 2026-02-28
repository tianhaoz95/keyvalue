import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cpa.dart';

class CpaRepository {
  final FirebaseFirestore _firestore;

  CpaRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> saveCpa(Cpa cpa) async {
    await _firestore.collection('cpas').doc(cpa.uid).set(cpa.toMap());
  }

  Future<Cpa?> getCpa(String uid) async {
    final doc = await _firestore.collection('cpas').doc(uid).get();
    if (doc.exists) {
      final data = doc.data();
      if (data != null) {
        return Cpa.fromMap(data);
      }
    }
    return null;
  }

  Future<void> deleteCpa(String uid) async {
    await _firestore.collection('cpas').doc(uid).delete();
  }
}
