import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/course.dart';
import '../../models/user.dart';
import '../../services/database_service.dart';
import '../../providers/auth_provider.dart';
import '../profiles/student_profile_screen.dart';
import '../profiles/teacher_profile_screen.dart';

class UsersTabScreen extends StatefulWidget {
  final Course course;

  const UsersTabScreen({super.key, required this.course});

  @override
  State<UsersTabScreen> createState() => _UsersTabScreenState();
}

class _UsersTabScreenState extends State<UsersTabScreen> {
  final DatabaseService _databaseService = DatabaseService();
  Map<String, dynamic>? _teacher;
  List<Map<String, dynamic>> _students = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);

    try {
      // Load teacher
      final teacherData = await _databaseService.getUserById(widget.course.teacherId);
      // Load students from Student_Course table
      final studentsData = await _databaseService.getCourseStudents(widget.course.id);

      setState(() {
        _teacher = teacherData;
        _students = studentsData;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading users: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadUsers,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Teachers Section
            Text(
              'المعلمون',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            _buildTeacherCard(context),
            const SizedBox(height: 24),

            // Students Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'الطلاب',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_students.length}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (_students.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.person_off_outlined,
                          size: 48,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'لا يوجد طلاب مسجلين بعد',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _students.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final student = _students[index];
                  return _buildStudentCard(context, student, index);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeacherCard(BuildContext context) {
    if (_teacher == null) {
      return Card(
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Icon(
              Icons.school,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          title: const Text('معلم الحلقة'),
          subtitle: Text('ID: ${widget.course.teacherId}'),
          trailing: const Icon(Icons.verified, color: Colors.green),
        ),
      );
    }

    final profileImage = _teacher!['image_link'] as String?;
    final name = _teacher!['name'] as String? ?? 'معلم الحلقة';
    final email = _teacher!['email'] as String?;
    final phone = _teacher!['phone'] as String?;
    final countryCode = _teacher!['country_code'] as String? ?? '+966';
    final gender = _teacher!['gender'] as String?;
    
    // Check if current user is a student
    final currentUser = context.read<AuthProvider>().currentUser;
    final isStudent = currentUser?.role == UserRole.student;

    return Card(
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: isStudent
            ? () {
                // Students can view teacher profile
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TeacherProfileScreen(
                      teacherId: widget.course.teacherId,
                    ),
                  ),
                );
              }
            : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    backgroundImage: profileImage != null && profileImage.isNotEmpty
                        ? NetworkImage(profileImage)
                        : null,
                    child: profileImage == null || profileImage.isEmpty
                        ? Text(
                            name.isNotEmpty ? name[0].toUpperCase() : 'م',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.green.withOpacity(0.3)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.verified, color: Colors.green, size: 16),
                                  SizedBox(width: 4),
                                  Text(
                                    'معلم',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (email != null) ...[
                          Row(
                            children: [
                              Icon(
                                Icons.email,
                                size: 16,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  email,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                        ],
                        if (phone != null) ...[
                          Row(
                            children: [
                              Icon(
                                Icons.phone,
                                size: 16,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '$countryCode $phone',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                ),
                                textDirection: TextDirection.ltr,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                        ],
                        if (gender != null) ...[
                          Row(
                            children: [
                              Icon(
                                gender == 'male' ? Icons.male : Icons.female,
                                size: 16,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                gender == 'male' ? 'ذكر' : 'أنثى',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Show arrow icon for students to indicate clickability
                  if (isStudent) ...[
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStudentCard(BuildContext context, Map<String, dynamic> student, int index) {
    final profileImage = student['image_link'] as String?;
    final name = student['name'] as String? ?? 'طالب ${index + 1}';
    final email = student['email'] as String?;
    
    // Check if current user is a teacher
    final currentUser = context.read<AuthProvider>().currentUser;
    final isTeacher = currentUser?.role == UserRole.teacher;

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          radius: 26,
          backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
          backgroundImage: profileImage != null && profileImage.isNotEmpty
              ? NetworkImage(profileImage)
              : null,
          child: profileImage == null || profileImage.isEmpty
              ? Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '${index + 1}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                )
              : null,
        ),
        title: Text(
          name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        subtitle: email != null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.email,
                        size: 12,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          email,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '#${index + 1}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            // Show arrow icon for teachers to indicate clickability
            if (isTeacher) ...[
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey,
              ),
            ],
          ],
        ),
        onTap: isTeacher
            ? () {
                // Teachers can view and edit student profile
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StudentProfileScreen(
                      student: student,
                      courseId: widget.course.id,
                      course: widget.course,
                    ),
                  ),
                ).then((_) {
                  // Refresh users list when returning from profile screen
                  _loadUsers();
                });
              }
            : null,
      ),
    );
  }
}
