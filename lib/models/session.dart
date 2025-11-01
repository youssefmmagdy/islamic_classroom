import 'package:uuid/uuid.dart';

class Session {
  final String id;
  final String courseId; // Reference to Course
  final String title;
  final String? description;
  final DateTime dateTime;
  final int durationMinutes;
  final String? content; // محتوى الحصة
  final bool isCompleted;

  Session({
    String? id,
    required this.courseId,
    required this.title,
    this.description,
    required this.dateTime,
    this.durationMinutes = 60,
    this.content,
    this.isCompleted = false,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'courseId': courseId,
      'title': title,
      'description': description,
      'dateTime': dateTime.toIso8601String(),
      'durationMinutes': durationMinutes,
      'content': content,
      'isCompleted': isCompleted,
    };
  }

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      id: json['id'],
      courseId: json['courseId'],
      title: json['title'],
      description: json['description'],
      dateTime: DateTime.parse(json['dateTime']),
      durationMinutes: json['durationMinutes'] ?? 60,
      content: json['content'],
      isCompleted: json['isCompleted'] ?? false,
    );
  }

  Session copyWith({
    String? title,
    String? description,
    DateTime? dateTime,
    int? durationMinutes,
    String? content,
    bool? isCompleted,
  }) {
    return Session(
      id: id,
      courseId: courseId,
      title: title ?? this.title,
      description: description ?? this.description,
      dateTime: dateTime ?? this.dateTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      content: content ?? this.content,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  bool get isPast => DateTime.now().isAfter(dateTime);
  bool get isToday {
    final now = DateTime.now();
    return dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day;
  }
}