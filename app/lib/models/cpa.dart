class Cpa {
  final String uid;
  final String name;
  final String firmName;
  final String email;

  Cpa({
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
}
