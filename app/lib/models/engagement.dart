import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

part 'engagement.g.dart';

@HiveType(typeId: 2)
enum EngagementStatus {
  @HiveField(0)
  draft,
  @HiveField(1)
  pendingReview,
  @HiveField(2)
  sent,
  @HiveField(3)
  received,
  @HiveField(4)
  completed
}

@HiveType(typeId: 4)
enum AiSource {
  @HiveField(0)
  onDevice,
  @HiveField(1)
  cloud,
  @HiveField(2)
  unknown
}

@HiveType(typeId: 3)
class Engagement {
  @HiveField(0)
  final String engagementId;
  @HiveField(1)
  final EngagementStatus status;
  @HiveField(2)
  final String draftMessage;
  @HiveField(3)
  final String sentMessage;
  @HiveField(4)
  final String customerResponse;
  @HiveField(5)
  final List<String> pointsOfInterest;
  @HiveField(6)
  final String updatedDetailsDiff;
  @HiveField(9)
  final String changeSummary;
  @HiveField(7)
  final DateTime createdAt;
  @HiveField(8)
  final AiSource aiSource;

  Engagement({
    required this.engagementId,
    required this.status,
    required this.draftMessage,
    required this.sentMessage,
    required this.customerResponse,
    required this.pointsOfInterest,
    required this.updatedDetailsDiff,
    this.changeSummary = '',
    required this.createdAt,
    this.aiSource = AiSource.unknown,
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
      changeSummary: map['changeSummary'] as String? ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      aiSource: map['aiSource'] != null 
          ? AiSource.values.byName(map['aiSource'] as String)
          : AiSource.unknown,
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
      'changeSummary': changeSummary,
      'createdAt': Timestamp.fromDate(createdAt),
      'aiSource': aiSource.name,
    };
  }

  Engagement copyWith({
    EngagementStatus? status,
    String? draftMessage,
    String? sentMessage,
    String? customerResponse,
    List<String>? pointsOfInterest,
    String? updatedDetailsDiff,
    String? changeSummary,
    AiSource? aiSource,
  }) {
    return Engagement(
      engagementId: engagementId,
      status: status ?? this.status,
      draftMessage: draftMessage ?? this.draftMessage,
      sentMessage: sentMessage ?? this.sentMessage,
      customerResponse: customerResponse ?? this.customerResponse,
      pointsOfInterest: pointsOfInterest ?? this.pointsOfInterest,
      updatedDetailsDiff: updatedDetailsDiff ?? this.updatedDetailsDiff,
      changeSummary: changeSummary ?? this.changeSummary,
      createdAt: createdAt,
      aiSource: aiSource ?? this.aiSource,
    );
  }
}
