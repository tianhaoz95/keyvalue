import 'package:cloud_firestore/cloud_firestore.dart';

class Customer {
  final String customerId;
  final String name;
  final String email;
  final String details; // Markdown
  final String guidelines; // Markdown
  final int engagementFrequencyDays;
  final DateTime nextEngagementDate;
  final DateTime lastEngagementDate;

  Customer({
    required this.customerId,
    required this.name,
    required this.email,
    required this.details,
    required this.guidelines,
    required this.engagementFrequencyDays,
    required this.nextEngagementDate,
    required this.lastEngagementDate,
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
    );
  }
}
