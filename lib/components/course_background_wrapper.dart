import 'package:flutter/material.dart';
import '../models/course.dart';

/// A wrapper widget that adds course background to any screen
class CourseBackgroundWrapper extends StatelessWidget {
  final Course course;
  final Widget child;
  
  const CourseBackgroundWrapper({
    super.key,
    required this.course,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final backImage = null;

    return Stack(
      children: [
        // Background Image Layer
        
        if (backImage == null)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    // Theme.of(context).colorScheme.primaryContainer,
                    // Theme.of(context).colorScheme.primaryContainer.withOpacity(0.7),
                  ],
                ),
              ),
            ),
          ),
        
        // Semi-transparent overlay
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85),
            ),
          ),
        ),
        
        // Content
        child,
      ],
    );
  }
}
