import 'package:uuid/uuid.dart';

enum SubmissionStatus { not_submitted, submitted, graded }

class AssignmentSubmission {
  final String id;
  final String assignmentId;
  final String studentId;
  final String? content;
  final List<String> attachments; // File paths or URLs
  final SubmissionStatus status;
  final double? grade;
  final String? feedback;
  final DateTime? submittedAt;
  final DateTime? gradedAt;
  final DateTime createdAt;

  AssignmentSubmission({
    String? id,
    required this.assignmentId,
    required this.studentId,
    this.content,
    this.attachments = const [],
    this.status = SubmissionStatus.not_submitted,
    this.grade,
    this.feedback,
    this.submittedAt,
    this.gradedAt,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'assignment_id': assignmentId,
      'student_id': studentId,
      'content': content,
      'attachments': attachments,
      'status': status.name,
      'grade': grade,
      'feedback': feedback,
      'submitted_at': submittedAt?.toIso8601String(),
      'graded_at': gradedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory AssignmentSubmission.fromJson(Map<String, dynamic> json) {
    return AssignmentSubmission(
      id: json['id'],
      assignmentId: json['assignment_id'],
      studentId: json['student_id'],
      content: json['content'],
      attachments: List<String>.from(json['attachments'] ?? []),
      status: SubmissionStatus.values
          .firstWhere((e) => e.name == json['status'], orElse: () => SubmissionStatus.not_submitted),
      grade: json['grade']?.toDouble(),
      feedback: json['feedback'],
      submittedAt: json['submitted_at'] != null
          ? DateTime.parse(json['submitted_at'])
          : null,
      gradedAt: json['graded_at'] != null
          ? DateTime.parse(json['graded_at'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  AssignmentSubmission copyWith({
    String? content,
    List<String>? attachments,
    SubmissionStatus? status,
    double? grade,
    String? feedback,
    DateTime? submittedAt,
    DateTime? gradedAt,
  }) {
    return AssignmentSubmission(
      id: id,
      assignmentId: assignmentId,
      studentId: studentId,
      content: content ?? this.content,
      attachments: attachments ?? this.attachments,
      status: status ?? this.status,
      grade: grade ?? this.grade,
      feedback: feedback ?? this.feedback,
      submittedAt: submittedAt ?? this.submittedAt,
      gradedAt: gradedAt ?? this.gradedAt,
      createdAt: createdAt,
    );
  }

  bool get isSubmitted => status == SubmissionStatus.submitted || status == SubmissionStatus.graded;
  bool get isGraded => status == SubmissionStatus.graded;
}
