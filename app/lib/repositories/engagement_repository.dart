import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/engagement.dart';

class EngagementRepository {
  final FirebaseFirestore _firestore;

  EngagementRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference _engagementsRef(String advisorUid, String customerId) {
    return _firestore.collection('advisors').doc(advisorUid).collection('customers').doc(customerId).collection('engagements');
  }

  Future<void> saveEngagement(String advisorUid, String customerId, Engagement engagement) async {
    if (advisorUid == 'demo_user') return;
    await _engagementsRef(advisorUid, customerId).doc(engagement.engagementId).set(engagement.toMap());
  }

  Future<void> updateEngagement(String advisorUid, String customerId, Engagement engagement) async {
    if (advisorUid == 'demo_user') return;
    await _engagementsRef(advisorUid, customerId).doc(engagement.engagementId).update(engagement.toMap());
  }

  Future<void> deleteEngagement(String advisorUid, String customerId, String engagementId) async {
    if (advisorUid == 'demo_user') return;
    await _engagementsRef(advisorUid, customerId).doc(engagementId).delete();
  }

  Future<void> deleteCustomerEngagements(String advisorUid, String customerId) async {
    if (advisorUid == 'demo_user') return;
    final snapshots = await _engagementsRef(advisorUid, customerId).get();
    for (var doc in snapshots.docs) {
      await doc.reference.delete();
    }
  }

  Stream<List<Engagement>> getEngagements(String advisorUid, String customerId) {
    if (advisorUid == 'demo_user') {
      return Stream.value([
        Engagement(
          engagementId: 'e_demo_1',
          status: EngagementStatus.received,
          draftMessage: 'Hi Sarah, hope the quarter is going well!',
          sentMessage: 'Hi Sarah, hope the quarter is going well!',
          customerResponse: 'Hi! Things are great. Just landed a big new client.',
          pointsOfInterest: ['Landed a big new client (Revenue increase)', 'Needs to discuss quarterly estimated taxes'],
          updatedDetailsDiff: 'Added info about new client contract.',
          createdAt: DateTime.now().subtract(const Duration(days: 7)),
        ),
      ]);
    }
    return _engagementsRef(advisorUid, customerId).orderBy('createdAt', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Engagement.fromMap(doc.data() as Map<String, dynamic>)).toList();
    });
  }

  Future<bool> hasDraft(String advisorUid, String customerId) async {
    if (advisorUid == 'demo_user') return false;
    final snapshot = await _engagementsRef(advisorUid, customerId)
        .where('status', isEqualTo: EngagementStatus.draft.name)
        .get();
    return snapshot.docs.isNotEmpty;
  }
}
