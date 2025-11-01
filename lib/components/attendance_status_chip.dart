import 'package:flutter/material.dart';
import '../models/attendance.dart';

class AttendanceStatusChip extends StatelessWidget {
  final AttendanceStatus status;
  final bool isCompact;

  const AttendanceStatusChip({
    super.key,
    required this.status,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    IconData icon;
    String text;

    switch (status) {
      case AttendanceStatus.present:
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        icon = Icons.check_circle;
        text = 'حاضر';
        break;
      case AttendanceStatus.absent:
        backgroundColor = Colors.red.shade100;
        textColor = Colors.red.shade800;
        icon = Icons.cancel;
        text = 'غائب';
        break;
      case AttendanceStatus.late:
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        icon = Icons.schedule;
        text = 'متأخر';
        break;
      case AttendanceStatus.excused:
        backgroundColor = Colors.blue.shade100;
        textColor = Colors.blue.shade800;
        icon = Icons.event_note;
        text = 'بعذر';
        break;
    }

    if (isCompact) {
      return Icon(
        icon,
        color: textColor,
        size: 20,
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}