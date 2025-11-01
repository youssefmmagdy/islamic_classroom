import 'package:flutter/material.dart';
import '../../models/course.dart';
import '../../services/database_service.dart';

class AssignmentSubmissionsScreen extends StatefulWidget {
  final Map<String, dynamic> assignment;
  final Course course;
  final List<Map<String, dynamic>> students;

  const AssignmentSubmissionsScreen({
    super.key,
    required this.assignment,
    required this.course,
    required this.students,
  });

  @override
  State<AssignmentSubmissionsScreen> createState() => _AssignmentSubmissionsScreenState();
}

class _AssignmentSubmissionsScreenState extends State<AssignmentSubmissionsScreen> {
  final _databaseService = DatabaseService();
  List<Map<String, dynamic>> _submissions = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSubmissions();
  }

  Future<void> _loadSubmissions() async {
    setState(() => _isLoading = true);

    try {
      final assignmentId = widget.assignment['id'] as String;
      final sessionId = widget.assignment['session_id'] as String;

      final submissions = await _databaseService.getAssignmentSubmissions(
        assignmentId,
        widget.course.id,
        sessionId,
      );

      setState(() {
        _submissions = submissions;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading submissions: $e');
      setState(() => _isLoading = false);
    }
  }

  bool _hasSubmission(String studentId) {
    return _submissions.any((s) => s['student_id'] == studentId);
  }

  Future<void> _toggleSubmission(String studentId, bool completed) async {
    if (_isSaving) return;
    
    setState(() => _isSaving = true);
    
    try {
      if (completed) {
        // Mark as completed - create submission
        final result = await _databaseService.createAssignmentSubmission(
          assignmentId: widget.assignment['id'] as String,
          studentId: studentId,
          courseId: widget.course.id,
          sessionId: widget.assignment['session_id'] as String,
        );
        
        if (result['success']) {
          await _loadSubmissions();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('تم تسجيل إكمال الواجب'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } else {
        // Mark as not completed - delete submission
        final result = await _databaseService.deleteAssignmentSubmission(
          assignmentId: widget.assignment['id'] as String,
          studentId: studentId,
        );
        
        if (result['success']) {
          await _loadSubmissions();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('تم إلغاء تسجيل إكمال الواجب'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      }
    } catch (e) {
      print('Error toggling submission: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final assignmentDesc = widget.assignment['desc'] as String? ?? 'واجب';
    final deadlineDate = widget.assignment['deadline_date'] as String?;

    // Parse deadline date
    DateTime? deadline;
    if (deadlineDate != null) {
      try {
        deadline = DateTime.parse(deadlineDate);
      } catch (e) {
        print('Error parsing deadline date: $e');
      }
    }

    // Calculate statistics
    final submittedCount = _submissions.length;
    final totalStudents = widget.students.length;
    final notSubmittedCount = totalStudents - submittedCount;
    final submissionPercentage = totalStudents > 0 
        ? (submittedCount / totalStudents * 100).toStringAsFixed(0) 
        : '0';

    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل الواجب'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadSubmissions,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Assignment Info Card
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.assignment,
                                size: 32,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  assignmentDesc,
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (deadline != null)
                            _buildInfoRow(
                              context,
                              Icons.calendar_today,
                              'الموعد النهائي',
                              '${deadline.day}/${deadline.month}/${deadline.year}',
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Statistics Card
                  Card(
                    elevation: 2,
                    color: Theme.of(context).colorScheme.primaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(
                            'إحصائيات التسليم',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatItem(
                                context,
                                'تم التسليم',
                                submittedCount.toString(),
                                Colors.green,
                                Icons.check_circle,
                              ),
                              _buildStatItem(
                                context,
                                'لم يسلم',
                                notSubmittedCount.toString(),
                                Colors.orange,
                                Icons.pending,
                              ),
                              _buildStatItem(
                                context,
                                'نسبة التسليم',
                                '$submissionPercentage%',
                                Theme.of(context).colorScheme.primary,
                                Icons.analytics,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Students List Header
                  Text(
                    'الطلاب الذين أكملوا الواجب (${widget.students.length})',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),

                  // Students List with Checkboxes
                  ...widget.students.asMap().entries.map((entry) {
                    final student = entry.value;
                    final studentId = student['id'] as String;
                    final studentName = student['name'] as String? ?? 'طالب';
                    final profileImage = student['image_link'] as String?;
                    final hasCompleted = _hasSubmission(studentId);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: hasCompleted 
                              ? Colors.green.withOpacity(0.2)
                              : Theme.of(context).colorScheme.primaryContainer,
                          backgroundImage: profileImage != null && profileImage.isNotEmpty
                              ? NetworkImage(profileImage)
                              : null,
                          child: profileImage == null || profileImage.isEmpty
                              ? Text(
                                  studentName.isNotEmpty ? studentName[0].toUpperCase() : 'ط',
                                  style: TextStyle(
                                    color: hasCompleted
                                        ? Colors.green
                                        : Theme.of(context).colorScheme.onPrimaryContainer,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                        title: Text(
                          studentName,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: hasCompleted 
                            ? const Text('أكمل الواجب', style: TextStyle(color: Colors.green))
                            : const Text('لم يكمل', style: TextStyle(color: Colors.orange)),
                        trailing: _isSaving
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Checkbox(
                                value: hasCompleted,
                                onChanged: (value) {
                                  if (value != null) {
                                    _toggleSubmission(studentId, value);
                                  }
                                },
                              ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color ?? Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, Color color, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 32, color: color),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}
