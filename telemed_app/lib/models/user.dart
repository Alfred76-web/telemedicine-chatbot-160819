class User {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String role;
  final String languagePref;
  final String? dateOfBirth;
  final String? gender;
  final String? chronicConditions;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    required this.languagePref,
    this.dateOfBirth,
    this.gender,
    this.chronicConditions,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'].toString(),
        name: json['name'] ?? '',
        email: json['email'] ?? '',
        phone: json['phone'],
        role: json['role'] ?? 'patient',
        languagePref: json['language_pref'] ?? 'en',
        dateOfBirth: json['date_of_birth']?.toString(),
        gender: json['gender'],
        chronicConditions: json['chronic_conditions'],
      );

  User copyWith({String? languagePref}) => User(
        id: id,
        name: name,
        email: email,
        phone: phone,
        role: role,
        languagePref: languagePref ?? this.languagePref,
        dateOfBirth: dateOfBirth,
        gender: gender,
        chronicConditions: chronicConditions,
      );
}