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

  const Advisor({
    required this.uid,
    required this.name,
    required this.firmName,
    required this.email,
  });

  Advisor copyWith({
    String? uid,
    String? name,
    String? firmName,
    String? email,
  }) {
    return Advisor(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      firmName: firmName ?? this.firmName,
      email: email ?? this.email,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'firmName': firmName,
      'email': email,
    };
  }

  factory Advisor.fromMap(Map<String, dynamic> map) {
    return Advisor(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      firmName: map['firmName'] ?? '',
      email: map['email'] ?? '',
    );
  }
}
