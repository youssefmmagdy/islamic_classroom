import 'package:uuid/uuid.dart';

class Assignment {
  final String id;
  final String courseId;
  final String sessionId;
  final String title;
  final String description;
  final String? pdfUrl; // URL to uploaded PDF file
  final DateTime dueDate;
  final DateTime createdAt;

  Assignment({
    String? id,
    required this.courseId,
    required this.sessionId,
    required this.title,
    required this.description,
    this.pdfUrl,
    required this.dueDate,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'course_id': courseId,
      'session_id': sessionId,
      'title': title,
      'desc': description,
      'assignment_link': pdfUrl,
      'due_date': dueDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Assignment.fromJson(Map<String, dynamic> json) {
    return Assignment(
      id: json['id'],
      courseId: json['course_id'],
      sessionId: json['session_id'],
      title: json['title'] ?? '',
      description: json['desc'] ?? '',
      pdfUrl: json['assignment_link'],
      dueDate: json['due_date'] != null 
          ? DateTime.parse(json['due_date'])
          : DateTime.now().add(const Duration(days: 7)),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Assignment copyWith({
    String? title,
    String? description,
    String? pdfUrl,
    DateTime? dueDate,
  }) {
    return Assignment(
      id: id,
      courseId: courseId,
      sessionId: sessionId,
      title: title ?? this.title,
      description: description ?? this.description,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt,
    );
  }

  bool get isOverdue => DateTime.now().isAfter(dueDate);
  bool get isDueToday {
    final now = DateTime.now();
    return dueDate.year == now.year &&
        dueDate.month == now.month &&
        dueDate.day == now.day;
  }
}
