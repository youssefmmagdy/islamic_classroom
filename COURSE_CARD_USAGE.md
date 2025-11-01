# CourseCard Component Usage Guide

## Overview
The `CourseCard` component is a reusable widget that displays course information with a beautiful background image, title, description, and optional teacher name.

## Import
```dart
import '../components/course_card.dart';
```

## Basic Usage

### Example 1: Simple Course Card
```dart
CourseCard(
  course: course,
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CourseDetailsScreen(course: course),
      ),
    );
  },
)
```

### Example 2: Course Card with Teacher Name
```dart
CourseCard(
  course: course,
  teacherName: 'د. أحمد محمد',
  onTap: () {
    // Navigate to course details
  },
)
```

### Example 3: Course Card with Menu Button
```dart
CourseCard(
  course: course,
  teacherName: teacherName,
  onTap: () {
    // Navigate to course details
  },
  trailing: PopupMenuButton<String>(
    icon: Icon(
      Icons.more_vert,
      color: course.back != null ? Colors.white : null,
    ),
    onSelected: (value) => _handleMenuAction(value, course),
    itemBuilder: (context) => [
      const PopupMenuItem(
        value: 'copy_id',
        child: Row(
          children: [
            Icon(Icons.copy),
            SizedBox(width: 8),
            Text('نسخ رمز الحلقة'),
          ],
        ),
      ),
      const PopupMenuItem(
        value: 'delete',
        child: Row(
          children: [
            Icon(Icons.delete, color: Colors.red),
            SizedBox(width: 8),
            Text('حذف الحلقة', style: TextStyle(color: Colors.red)),
          ],
        ),
      ),
    ],
  ),
)
```

### Example 4: Custom Height
```dart
CourseCard(
  course: course,
  teacherName: 'د. محمد علي',
  height: 150, // Default is 120
  onTap: () {
    // Navigate to course details
  },
)
```

## Complete Example in ListView

Here's how to use `CourseCard` in a ListView (e.g., in home_screen.dart):

```dart
// Add import at the top
import '../components/course_card.dart';

// In your widget build method:
ListView.builder(
  padding: const EdgeInsets.all(8), // Reduced because CourseCard has its own margin
  itemCount: coursesData.length,
  itemBuilder: (context, index) {
    final courseData = coursesData[index];
    
    // Convert database course to Course model
    final course = Course(
      id: courseData['id'],
      name: courseData['title'] ?? '',
      description: courseData['desc'] ?? 'لا يوجد وصف',
      teacherId: courseData['teacher_id'],
      back: courseData['back'],
    );
    
    // Optional: Get teacher name if available
    String? teacherName;
    if (courseData['Teacher'] != null && courseData['Teacher']['User'] != null) {
      teacherName = courseData['Teacher']['User']['name'];
    }
    
    return CourseCard(
      course: course,
      teacherName: teacherName,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CourseDetailsScreen(course: course),
          ),
        );
      },
      trailing: PopupMenuButton<String>(
        icon: Icon(
          Icons.more_vert,
          color: course.back != null ? Colors.white : Colors.grey[700],
        ),
        onSelected: (value) => _handleCourseMenuAction(context, value, course, user),
        itemBuilder: (BuildContext context) => [
          // Your menu items here
        ],
      ),
    );
  },
)
```

## Fetching Teacher Information from Database

To get teacher name along with courses, modify your database query:

```dart
// In database_service.dart
Future<List<Map<String, dynamic>>> getCoursesWithTeacher() async {
  try {
    final response = await client
        .from('Course')
        .select('*, Teacher(id, User(id, name, email))');
    return List<Map<String, dynamic>>.from(response);
  } catch (e) {
    print('Error fetching courses with teacher: $e');
    return [];
  }
}
```

## Properties

| Property | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `course` | `Course` | Yes | - | The course object to display |
| `teacherName` | `String?` | No | `null` | Name of the teacher (optional) |
| `onTap` | `VoidCallback?` | No | `null` | Callback when card is tapped |
| `trailing` | `Widget?` | No | `null` | Widget to show at the end (e.g., menu button) |
| `height` | `double` | No | `120` | Height of the card |

## Features

✅ **Background Images**: Automatically displays background image from `assets/courses_back/` if `course.back` is set  
✅ **Fallback Gradient**: Shows a gradient background if no background image is available  
✅ **Teacher Information**: Displays teacher name with an icon if provided  
✅ **Text Shadows**: Adds shadows to text when background image is present for better readability  
✅ **Responsive Design**: Handles text overflow with ellipsis  
✅ **Customizable**: Supports custom height and trailing widgets  
✅ **Touch Feedback**: InkWell ripple effect on tap  

## Styling

The component automatically adapts its colors based on:
- **With Background Image**: White text with shadows for readability
- **Without Background Image**: Uses theme colors (primaryContainer)
- **Avatar**: Always white background with primary color text
- **Teacher Name**: Shows with person icon, adapts color based on background

## Tips

1. **Keep descriptions short**: The card limits description to 2 lines
2. **Teacher names**: Fetch teacher information in your database queries for better UX
3. **Menu buttons**: Make sure menu icon color contrasts with background
4. **Tap feedback**: Always provide `onTap` for better user experience
5. **Loading states**: Handle loading and empty states in your parent widget
