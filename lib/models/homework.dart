import 'package:uuid/uuid.dart';

enum HomeworkType { new_content, review }

class Homework {
  final String id;
  final String sessionId; // Reference to Session
  final String title;
  final String description;
  final HomeworkType type;
  final DateTime dueDate;
  final bool isRequired;
  final DateTime createdAt;

  Homework({
    String? id,
    required this.sessionId,
    required this.title,
    required this.description,
    required this.type,
    required this.dueDate,
    this.isRequired = true,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sessionId': sessionId,
      'title': title,
      'description': description,
      'type': type.name,
      'dueDate': dueDate.toIso8601String(),
      'isRequired': isRequired,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Homework.fromJson(Map<String, dynamic> json) {
    return Homework(
      id: json['id'],
      sessionId: json['sessionId'],
      title: json['title'],
      description: json['description'],
      type: HomeworkType.values.firstWhere((e) => e.name == json['type']),
      dueDate: DateTime.parse(json['dueDate']),
      isRequired: json['isRequired'] ?? true,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Homework copyWith({
    String? title,
    String? description,
    HomeworkType? type,
    DateTime? dueDate,
    bool? isRequired,
  }) {
    return Homework(
      id: id,
      sessionId: sessionId,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      dueDate: dueDate ?? this.dueDate,
      isRequired: isRequired ?? this.isRequired,
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