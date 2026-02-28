import 'package:hive/hive.dart';

part 'cpa.g.dart';

@HiveType(typeId: 0)
class Cpa {
  @HiveField(0)
  final String uid;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final String firmName;
  @HiveField(3)
  final String email;

  const Cpa({
    required this.uid,
    required this.name,
    required this.firmName,
    required this.email,
  });

  factory Cpa.fromMap(Map<String, dynamic> map) {
    return Cpa(
      uid: map['uid'] as String,
      name: map['name'] as String,
      firmName: map['firmName'] as String,
      email: map['email'] as String,
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

  Cpa copyWith({
    String? uid,
    String? name,
    String? firmName,
    String? email,
  }) {
    return Cpa(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      firmName: firmName ?? this.firmName,
      email: email ?? this.email,
    );
  }
}
