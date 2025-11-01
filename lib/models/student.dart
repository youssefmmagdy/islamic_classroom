enum StudentLevel { beginner, intermediate, advanced, excellent }

class Student {
  final String id; // Primary Key and Foreign Key to Users table
  final String? parentId; // Reference to Parent User
  final StudentLevel level;
  final double balance; // Outstanding fees
  final List<String> memorizedContent; // ما حفظه الطالب
  final DateTime createdAt;

  Student({
    required this.id, // Now required since it's the PK/FK
    this.parentId,
    this.level = StudentLevel.beginner,
    this.balance = 0.0,
    this.memorizedContent = const [],
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'parent_id': parentId,
      'level': level.name,
      'balance': balance,
      'memorized_content': memorizedContent,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'],
      parentId: json['parent_id'],
      level: StudentLevel.values.firstWhere((e) => e.name == json['level']),
      balance: (json['balance'] as num).toDouble(),
      memorizedContent: List<String>.from(json['memorized_content'] ?? []),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Student copyWith({
    String? parentId,
    StudentLevel? level,
    double? balance,
    List<String>? memorizedContent,
  }) {
    return Student(
      id: id,
      parentId: parentId ?? this.parentId,
      level: level ?? this.level,
      balance: balance ?? this.balance,
      memorizedContent: memorizedContent ?? this.memorizedContent,
      createdAt: createdAt,
    );
  }

  bool get hasOutstandingFees => balance > 0;
}