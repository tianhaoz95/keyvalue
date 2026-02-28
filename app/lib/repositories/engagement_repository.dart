import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/engagement.dart';

class EngagementRepository {
  final FirebaseFirestore _firestore;

  EngagementRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference _engagementsRef(String cpaUid, String customerId) {
    return _firestore.collection('cpas').doc(cpaUid).collection('customers').doc(customerId).collection('engagements');
  }

  Future<void> saveEngagement(String cpaUid, String customerId, Engagement engagement) async {
    if (cpaUid == 'demo_user') return;
    await _engagementsRef(cpaUid, customerId).doc(engagement.engagementId).set(engagement.toMap());
  }

  Stream<List<Engagement>> getEngagements(String cpaUid, String customerId) {
    if (cpaUid == 'demo_user') {
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
    return _engagementsRef(cpaUid, customerId).orderBy('createdAt', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Engagement.fromMap(doc.data() as Map<String, dynamic>)).toList();
    });
  }

  Future<bool> hasDraft(String cpaUid, String customerId) async {
    if (cpaUid == 'demo_user') return false;
    final snapshot = await _engagementsRef(cpaUid, customerId)
        .where('status', isEqualTo: EngagementStatus.draft.name)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  Future<void> updateEngagement(String cpaUid, String customerId, Engagement engagement) async {
    if (cpaUid == 'demo_user') return;
    await _engagementsRef(cpaUid, customerId).doc(engagement.engagementId).update(engagement.toMap());
  }
}
