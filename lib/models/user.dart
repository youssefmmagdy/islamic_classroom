import 'package:uuid/uuid.dart';

enum UserRole { teacher, student }
enum Gender { male, female }

class User {
  final String id;
  final String name;
  final String email;
  final String phone;
  final UserRole role;
  final Gender gender;
  final DateTime birthDate;
  final String countryCode;
  final String? imageLink;
  final DateTime createdAt;

  User({
    String? id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.gender,
    required this.birthDate,
    required this.countryCode,
    this.imageLink,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role.name,
      'gender': gender.name,
      'birth_date': birthDate.toIso8601String().split('T')[0], // Date only
      'country_code': countryCode,
      'image_link': imageLink,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    // Robust, case-insensitive parsing with defaults
    UserRole parseRole(dynamic v) {
      if (v is UserRole) return v;
      if (v is String) {
        final s = v.toLowerCase().trim();
        for (final e in UserRole.values) {
          if (e.name == s) return e;
        }
      }
      return UserRole.student;
    }

    Gender parseGender(dynamic v) {
      if (v is Gender) return v;
      if (v is String) {
        final s = v.toLowerCase().trim();
        for (final e in Gender.values) {
          if (e.name == s) return e;
        }
      }
      return Gender.male;
    }

    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      role: parseRole(json['role']),
      gender: parseGender(json['gender']),
      birthDate: DateTime.parse(json['birth_date']),
      countryCode: json['country_code'],
      imageLink: json['image_link'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  User copyWith({
    String? name,
    String? email,
    String? phone,
    UserRole? role,
    Gender? gender,
    DateTime? birthDate,
    String? countryCode,
    String? imageLink,
  }) {
    return User(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      gender: gender ?? this.gender,
      birthDate: birthDate ?? this.birthDate,
      countryCode: countryCode ?? this.countryCode,
      imageLink: imageLink ?? this.imageLink,
      createdAt: createdAt,
    );
  }
}