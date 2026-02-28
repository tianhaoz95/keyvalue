import 'package:cloud_firestore/cloud_firestore.dart';

enum EngagementStatus { draft, pendingReview, sent, received, completed }

class Engagement {
  final String engagementId;
  final EngagementStatus status;
  final String draftMessage;
  final String sentMessage;
  final String customerResponse;
  final List<String> pointsOfInterest;
  final String updatedDetailsDiff;
  final DateTime createdAt;

  Engagement({
    required this.engagementId,
    required this.status,
    required this.draftMessage,
    required this.sentMessage,
    required this.customerResponse,
    required this.pointsOfInterest,
    required this.updatedDetailsDiff,
    required this.createdAt,
  });

  factory Engagement.fromMap(Map<String, dynamic> map) {
    return Engagement(
      engagementId: map['engagementId'] as String,
      status: EngagementStatus.values.byName(map['status'] as String),
      draftMessage: map['draftMessage'] as String,
      sentMessage: map['sentMessage'] as String,
      customerResponse: map['customerResponse'] as String,
      pointsOfInterest: (map['pointsOfInterest'] as List).cast<String>(),
      updatedDetailsDiff: map['updatedDetailsDiff'] as String,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'engagementId': engagementId,
      'status': status.name,
      'draftMessage': draftMessage,
      'sentMessage': sentMessage,
      'customerResponse': customerResponse,
      'pointsOfInterest': pointsOfInterest,
      'updatedDetailsDiff': updatedDetailsDiff,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  Engagement copyWith({
    EngagementStatus? status,
    String? draftMessage,
    String? sentMessage,
    String? customerResponse,
    List<String>? pointsOfInterest,
    String? updatedDetailsDiff,
  }) {
    return Engagement(
      engagementId: engagementId,
      status: status ?? this.status,
      draftMessage: draftMessage ?? this.draftMessage,
      sentMessage: sentMessage ?? this.sentMessage,
      customerResponse: customerResponse ?? this.customerResponse,
      pointsOfInterest: pointsOfInterest ?? this.pointsOfInterest,
      updatedDetailsDiff: updatedDetailsDiff ?? this.updatedDetailsDiff,
      createdAt: createdAt,
    );
  }
}
