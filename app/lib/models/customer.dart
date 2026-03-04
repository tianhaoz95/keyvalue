import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

part 'customer.g.dart';

enum CustomerSortOption { name, nextContact }

@HiveType(typeId: 4)
class EngagementSchedule {
  @HiveField(0)
  final String scheduleId;
  @HiveField(1)
  final DateTime startDate;
  @HiveField(2)
  final DateTime? endDate;
  @HiveField(3)
  final int cadenceValue;
  @HiveField(4)
  final String cadencePeriod; // 'days', 'weeks', 'months', 'years'

  EngagementSchedule({
    required this.scheduleId,
    required this.startDate,
    this.endDate,
    required this.cadenceValue,
    required this.cadencePeriod,
  });

  factory EngagementSchedule.fromMap(Map<String, dynamic> map) {
    return EngagementSchedule(
      scheduleId: map['scheduleId'] as String,
      startDate: (map['startDate'] as Timestamp).toDate(),
      endDate: map['endDate'] != null ? (map['endDate'] as Timestamp).toDate() : null,
      cadenceValue: map['cadenceValue'] as int,
      cadencePeriod: map['cadencePeriod'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'scheduleId': scheduleId,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'cadenceValue': cadenceValue,
      'cadencePeriod': cadencePeriod,
    };
  }

  DateTime? nextOccurrence(DateTime fromDate) {
    if (endDate != null && fromDate.isAfter(endDate!)) return null;

    DateTime next = startDate;
    while (next.isBefore(fromDate) || next.isAtSameMomentAs(fromDate)) {
      switch (cadencePeriod) {
        case 'days':
          next = next.add(Duration(days: cadenceValue));
          break;
        case 'weeks':
          next = next.add(Duration(days: cadenceValue * 7));
          break;
        case 'months':
          next = DateTime(next.year, next.month + cadenceValue, next.day);
          break;
        case 'years':
          next = DateTime(next.year + cadenceValue, next.month, next.day);
          break;
        default:
          return null;
      }
      if (endDate != null && next.isAfter(endDate!)) return null;
    }
    return next;
  }
}

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
  final int engagementFrequencyDays; // Legacy
  @HiveField(6)
  final DateTime nextEngagementDate;
  @HiveField(7)
  final DateTime lastEngagementDate;
  @HiveField(8)
  final bool hasActiveDraft;
  @HiveField(9)
  final String occupation;
  @HiveField(10)
  final String phoneNumber;
  @HiveField(11)
  final String address;
  @HiveField(12)
  final List<String> tags;
  @HiveField(13)
  final int cadenceValue; // Legacy
  @HiveField(14)
  final String cadencePeriod; // Legacy
  @HiveField(15)
  final List<EngagementSchedule> schedules;
  @HiveField(16)
  final String? proposedDetails;
  @HiveField(17)
  final String? proposedGuidelines;

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
    this.occupation = '',
    this.phoneNumber = '',
    this.address = '',
    this.tags = const [],
    this.cadenceValue = 30,
    this.cadencePeriod = 'days',
    this.schedules = const [],
    this.proposedDetails,
    this.proposedGuidelines,
  });

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      customerId: map['customerId'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      details: map['details'] as String,
      guidelines: map['guidelines'] as String,
      engagementFrequencyDays: map['engagementFrequencyDays'] as int? ?? 30,
      nextEngagementDate: (map['nextEngagementDate'] as Timestamp).toDate(),
      lastEngagementDate: (map['lastEngagementDate'] as Timestamp).toDate(),
      hasActiveDraft: map['hasActiveDraft'] as bool? ?? false,
      occupation: map['occupation'] as String? ?? '',
      phoneNumber: map['phoneNumber'] as String? ?? '',
      address: map['address'] as String? ?? '',
      tags: (map['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      cadenceValue: map['cadenceValue'] as int? ?? map['engagementFrequencyDays'] as int? ?? 30,
      cadencePeriod: map['cadencePeriod'] as String? ?? 'days',
      schedules: (map['schedules'] as List<dynamic>?)
              ?.map((e) => EngagementSchedule.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      proposedDetails: map['proposedDetails'] as String?,
      proposedGuidelines: map['proposedGuidelines'] as String?,
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
      'occupation': occupation,
      'phoneNumber': phoneNumber,
      'address': address,
      'tags': tags,
      'cadenceValue': cadenceValue,
      'cadencePeriod': cadencePeriod,
      'schedules': schedules.map((e) => e.toMap()).toList(),
      'proposedDetails': proposedDetails,
      'proposedGuidelines': proposedGuidelines,
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
    String? occupation,
    String? phoneNumber,
    String? address,
    List<String>? tags,
    int? cadenceValue,
    String? cadencePeriod,
    List<EngagementSchedule>? schedules,
    Object? proposedDetails = _sentinel,
    Object? proposedGuidelines = _sentinel,
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
      occupation: occupation ?? this.occupation,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      tags: tags ?? this.tags,
      cadenceValue: cadenceValue ?? this.cadenceValue,
      cadencePeriod: cadencePeriod ?? this.cadencePeriod,
      schedules: schedules ?? this.schedules,
      proposedDetails: proposedDetails == _sentinel ? this.proposedDetails : proposedDetails as String?,
      proposedGuidelines: proposedGuidelines == _sentinel ? this.proposedGuidelines : proposedGuidelines as String?,
    );
  }

  static const _sentinel = Object();

  DateTime calculateNextEngagementDate(DateTime fromDate) {
    if (schedules.isEmpty) {
      // Fallback to legacy logic
      switch (cadencePeriod) {
        case 'weeks':
          return fromDate.add(Duration(days: cadenceValue * 7));
        case 'months':
          return DateTime(fromDate.year, fromDate.month + cadenceValue, fromDate.day);
        case 'days':
        default:
          return fromDate.add(Duration(days: cadenceValue));
      }
    }

    DateTime? earliest;
    for (var schedule in schedules) {
      final next = schedule.nextOccurrence(fromDate);
      if (next != null) {
        if (earliest == null || next.isBefore(earliest)) {
          earliest = next;
        }
      }
    }

    return earliest ?? fromDate.add(const Duration(days: 30)); // Ultimate fallback
  }
}
