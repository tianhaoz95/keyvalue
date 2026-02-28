import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

part 'customer.g.dart';

@HiveType(typeId: 1)
class Customer {
  @HiveField(0)
  final String customerId;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final String email;
  @HiveField(3)
  final String details; // Markdown
  @HiveField(4)
  final String guidelines; // Markdown
  @HiveField(5)
  final int engagementFrequencyDays;
  @HiveField(6)
  final DateTime nextEngagementDate;
  @HiveField(7)
  final DateTime lastEngagementDate;
  @HiveField(8)
  final bool hasActiveDraft;

  Customer({
    required this.customerId,
    required this.name,
    required this.email,
    required this.details,
    required this.guidelines,
    required this.engagementFrequencyDays,
    required this.nextEngagementDate,
    required this.lastEngagementDate,
    this.hasActiveDraft = false,
  });

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      customerId: map['customerId'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      details: map['details'] as String,
      guidelines: map['guidelines'] as String,
      engagementFrequencyDays: map['engagementFrequencyDays'] as int,
      nextEngagementDate: (map['nextEngagementDate'] as Timestamp).toDate(),
      lastEngagementDate: (map['lastEngagementDate'] as Timestamp).toDate(),
      hasActiveDraft: map['hasActiveDraft'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'name': name,
      'email': email,
      'details': details,
      'guidelines': guidelines,
      'engagementFrequencyDays': engagementFrequencyDays,
      'nextEngagementDate': Timestamp.fromDate(nextEngagementDate),
      'lastEngagementDate': Timestamp.fromDate(lastEngagementDate),
      'hasActiveDraft': hasActiveDraft,
    };
  }

  Customer copyWith({
    String? name,
    String? email,
    String? details,
    String? guidelines,
    int? engagementFrequencyDays,
    DateTime? nextEngagementDate,
    DateTime? lastEngagementDate,
    bool? hasActiveDraft,
  }) {
    return Customer(
      customerId: customerId,
      name: name ?? this.name,
      email: email ?? this.email,
      details: details ?? this.details,
      guidelines: guidelines ?? this.guidelines,
      engagementFrequencyDays: engagementFrequencyDays ?? this.engagementFrequencyDays,
      nextEngagementDate: nextEngagementDate ?? this.nextEngagementDate,
      lastEngagementDate: lastEngagementDate ?? this.lastEngagementDate,
      hasActiveDraft: hasActiveDraft ?? this.hasActiveDraft,
    );
  }
}
