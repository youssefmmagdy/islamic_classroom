import 'package:uuid/uuid.dart';

class Course {
  final String id;
  final String name;
  final String description;
  final String teacherId; // Reference to Teacher User
  final List<String> studentIds; // References to Students
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;
  final String? courseImage;
  final String? back; // Background image name (e.g., 'back1', 'back2', etc.)

  Course({
    String? id,
    required this.name,
    required this.description,
    required this.teacherId,
    this.studentIds = const [],
    DateTime? startDate,
    this.endDate,
    this.isActive = true,
    this.courseImage,
    this.back,
  })  : id = id ?? const Uuid().v4(),
        startDate = startDate ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'teacherId': teacherId,
      'studentIds': studentIds,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'isActive': isActive,
      'courseImage': courseImage,
      'back': back,
    };
  }

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      teacherId: json['teacherId'],
      studentIds: List<String>.from(json['studentIds'] ?? []),
      startDate: DateTime.parse(json['startDate']),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      isActive: json['isActive'] ?? true,
      courseImage: json['courseImage'],
      back: json['back'],
    );
  }

  Course copyWith({
    String? name,
    String? description,
    List<String>? studentIds,
    DateTime? endDate,
    bool? isActive,
    String? courseImage,
    String? back,
  }) {
    return Course(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      teacherId: teacherId,
      studentIds: studentIds ?? this.studentIds,
      startDate: startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      courseImage: courseImage ?? this.courseImage,
      back: back ?? this.back,
    );
  }

  int get studentCount => studentIds.length;
}