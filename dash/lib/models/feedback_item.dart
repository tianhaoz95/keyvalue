import 'package:cloud_firestore/cloud_firestore.dart';

class FeedbackItem {
  final String id;
  final String advisorUid;
  final String advisorName;
  final String text;
  final String screenName;
  final DateTime createdAt;

  FeedbackItem({
    required this.id,
    required this.advisorUid,
    required this.advisorName,
    required this.text,
    required this.screenName,
    required this.createdAt,
  });

  factory FeedbackItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FeedbackItem(
      id: doc.id,
      advisorUid: data['advisorUid'] ?? '',
      advisorName: data['advisorName'] ?? '',
      text: data['text'] ?? '',
      screenName: data['screenName'] ?? 'UNKNOWN',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
