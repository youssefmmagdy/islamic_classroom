import 'package:uuid/uuid.dart';

enum AttendanceStatus { present, absent, late, excused }

class Attendance {
  final String id;
  final String sessionId; // Reference to Session
  final String studentId; // Reference to Student
  final AttendanceStatus status;
  final String? notes;
  final DateTime markedAt;

  Attendance({
    String? id,
    required this.sessionId,
    required this.studentId,
    required this.status,
    this.notes,
    DateTime? markedAt,
  })  : id = id ?? const Uuid().v4(),
        markedAt = markedAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sessionId': sessionId,
      'studentId': studentId,
      'status': status.name,
      'notes': notes,
      'markedAt': markedAt.toIso8601String(),
    };
  }

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      id: json['id'],
      sessionId: json['sessionId'],
      studentId: json['studentId'],
      status: AttendanceStatus.values
          .firstWhere((e) => e.name == json['status']),
      notes: json['notes'],
      markedAt: DateTime.parse(json['markedAt']),
    );
  }

  Attendance copyWith({
    AttendanceStatus? status,
    String? notes,
  }) {
    return Attendance(
      id: id,
      sessionId: sessionId,
      studentId: studentId,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      markedAt: markedAt,
    );
  }

  bool get isPresent => status == AttendanceStatus.present;
  bool get isAbsent => status == AttendanceStatus.absent;
}