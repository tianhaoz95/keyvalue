import 'package:hive/hive.dart';

part 'advisor.g.dart';

@HiveType(typeId: 0)
class Advisor {
  @HiveField(0)
  final String uid;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final String firmName;
  @HiveField(3)
  final String email;
  @HiveField(4)
  final String aiCapability;
  @HiveField(5)
  final bool isExpressiveAiEnabled;
  @HiveField(6)
  final bool isMultimodalAiEnabled;

  const Advisor({
    required this.uid,
    required this.name,
    required this.firmName,
    required this.email,
    this.aiCapability = 'pro',
    this.isExpressiveAiEnabled = true,
    this.isMultimodalAiEnabled = false,
  });

  Advisor copyWith({
    String? uid,
    String? name,
    String? firmName,
    String? email,
    String? aiCapability,
    bool? isExpressiveAiEnabled,
    bool? isMultimodalAiEnabled,
  }) {
    return Advisor(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      firmName: firmName ?? this.firmName,
      email: email ?? this.email,
      aiCapability: aiCapability ?? this.aiCapability,
      isExpressiveAiEnabled: isExpressiveAiEnabled ?? this.isExpressiveAiEnabled,
      isMultimodalAiEnabled: isMultimodalAiEnabled ?? this.isMultimodalAiEnabled,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'firmName': firmName,
      'email': email,
      'aiCapability': aiCapability,
      'isExpressiveAiEnabled': isExpressiveAiEnabled,
      'isMultimodalAiEnabled': isMultimodalAiEnabled,
    };
  }

  factory Advisor.fromMap(Map<String, dynamic> map) {
    return Advisor(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      firmName: map['firmName'] ?? '',
      email: map['email'] ?? '',
      aiCapability: map['aiCapability'] ?? 'pro',
      isExpressiveAiEnabled: map['isExpressiveAiEnabled'] ?? true,
      isMultimodalAiEnabled: map['isMultimodalAiEnabled'] ?? false,
    );
  }
}
