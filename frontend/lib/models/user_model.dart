class User {
  final String id;
  final String email;
  final String gender;
  final DateTime? birth;

  User({
    required this.id,
    required this.email,
    required this.gender,
    this.birth,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'] as String,
    email: json['email'] as String,
    gender: json['gender'] as String,
    birth: json['birth'] != null
        ? DateTime.parse(json['birth'] as String)
        : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'gender': gender,
    'birth': birth?.toIso8601String(),
  };
}