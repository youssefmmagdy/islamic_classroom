import 'package:flutter/material.dart';
import '../models/course.dart';


class CourseCard extends StatelessWidget {
  final Course course;
  final String? teacherName;
  final VoidCallback? onTap;
  final Widget? trailing;
  final double height;

  const CourseCard({
    super.key,
    required this.course,
    this.teacherName,
    this.onTap,
    this.trailing,
    this.height = 140,
  });

  @override
  Widget build(BuildContext context) {
    // Get background image path
    final backImage = course.back != null 
        ? 'lib/assets/${course.back}.jpg'
        : null;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            // Background Image Layer
            if (backImage != null)
              Positioned.fill(
                child: Image.asset(
                  backImage,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback to gradient if image fails to load
                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Theme.of(context).colorScheme.primaryContainer,
                            Theme.of(context).colorScheme.primaryContainer.withOpacity(0.7),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            if (backImage == null)
              // Fallback gradient when no background image
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).colorScheme.primaryContainer,
                        Theme.of(context).colorScheme.primaryContainer.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),
              ),
            
            // Semi-transparent overlay for the whole card (reduced opacity to show background)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.75),
                ),
              ),
            ),
            
            // Content Layer
            SizedBox(
              height: height,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Calculate responsive font size based on available width AND height
                    final titleFontSize = (constraints.maxWidth * 0.09).clamp(16.0, 28.0);
                    final descFontSize = (constraints.maxWidth * 0.035).clamp(11.0, 13.0);
                    final teacherFontSize = (constraints.maxWidth * 0.035).clamp(11.0, 13.0);
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        // Top section with title
                        Flexible(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Course Title - Responsive font size
                              Flexible(
                                child: Text(
                                  course.name,
                                  style: TextStyle(
                                    fontSize: titleFontSize,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF000000),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(height: 4),
                              
                              // Course Description
                              Flexible(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                                    child: Text(
                                      course.description,
                                      style: TextStyle(
                                        fontSize: descFontSize,
                                        height: 1.2,
                                        color: Colors.black,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 4),
                        
                        // Bottom section with teacher name
                        if (teacherName != null)
                          Flexible(
                            flex: 0,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    ' بواسطة الشيخ: $teacherName',
                                    style: TextStyle(
                                      fontSize: teacherFontSize,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.left,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
            
            // Trailing Widget positioned at top-left
            if (trailing != null)
              Positioned(
                top: 8,
                left: 8,
                child: Transform.scale(
                  scale: 1.3,
                  child: trailing!,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
