import 'package:uuid/uuid.dart';

enum SubmissionStatus { not_submitted, submitted, graded }

class HomeworkSubmission {
  final String id;
  final String homeworkId; // Reference to Homework
  final String studentId; // Reference to Student
  final String? content;
  final List<String> attachments; // File paths or URLs
  final SubmissionStatus status;
  final double? grade;
  final String? feedback;
  final DateTime? submittedAt;
  final DateTime? gradedAt;

  HomeworkSubmission({
    String? id,
    required this.homeworkId,
    required this.studentId,
    this.content,
    this.attachments = const [],
    this.status = SubmissionStatus.not_submitted,
    this.grade,
    this.feedback,
    this.submittedAt,
    this.gradedAt,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'homeworkId': homeworkId,
      'studentId': studentId,
      'content': content,
      'attachments': attachments,
      'status': status.name,
      'grade': grade,
      'feedback': feedback,
      'submittedAt': submittedAt?.toIso8601String(),
      'gradedAt': gradedAt?.toIso8601String(),
    };
  }

  factory HomeworkSubmission.fromJson(Map<String, dynamic> json) {
    return HomeworkSubmission(
      id: json['id'],
      homeworkId: json['homeworkId'],
      studentId: json['studentId'],
      content: json['content'],
      attachments: List<String>.from(json['attachments'] ?? []),
      status: SubmissionStatus.values
          .firstWhere((e) => e.name == json['status']),
      grade: json['grade']?.toDouble(),
      feedback: json['feedback'],
      submittedAt: json['submittedAt'] != null
          ? DateTime.parse(json['submittedAt'])
          : null,
      gradedAt: json['gradedAt'] != null
          ? DateTime.parse(json['gradedAt'])
          : null,
    );
  }

  HomeworkSubmission copyWith({
    String? content,
    List<String>? attachments,
    SubmissionStatus? status,
    double? grade,
    String? feedback,
    DateTime? submittedAt,
    DateTime? gradedAt,
  }) {
    return HomeworkSubmission(
      id: id,
      homeworkId: homeworkId,
      studentId: studentId,
      content: content ?? this.content,
      attachments: attachments ?? this.attachments,
      status: status ?? this.status,
      grade: grade ?? this.grade,
      feedback: feedback ?? this.feedback,
      submittedAt: submittedAt ?? this.submittedAt,
      gradedAt: gradedAt ?? this.gradedAt,
    );
  }

  bool get isSubmitted => status != SubmissionStatus.not_submitted;
  bool get isGraded => status == SubmissionStatus.graded;
}