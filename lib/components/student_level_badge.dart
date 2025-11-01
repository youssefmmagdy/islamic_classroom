import 'package:flutter/material.dart';
import '../models/student.dart';

class StudentLevelBadge extends StatelessWidget {
  final StudentLevel level;
  final bool isCompact;

  const StudentLevelBadge({
    super.key,
    required this.level,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    String text;

    switch (level) {
      case StudentLevel.beginner:
        backgroundColor = Colors.grey.shade200;
        textColor = Colors.grey.shade800;
        text = 'مبتدئ';
        break;
      case StudentLevel.intermediate:
        backgroundColor = Colors.blue.shade100;
        textColor = Colors.blue.shade800;
        text = 'متوسط';
        break;
      case StudentLevel.advanced:
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        text = 'متقدم';
        break;
      case StudentLevel.excellent:
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        text = 'ممتاز';
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 6 : 8,
        vertical: isCompact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: isCompact ? 10 : 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}