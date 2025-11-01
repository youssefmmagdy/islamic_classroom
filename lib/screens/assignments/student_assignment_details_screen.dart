import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../services/database_service.dart';

class StudentAssignmentDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> assignment;
  final String courseId;
  final User student;

  const StudentAssignmentDetailsScreen({
    super.key,
    required this.assignment,
    required this.courseId,
    required this.student,
  });

  @override
  State<StudentAssignmentDetailsScreen> createState() =>
      _StudentAssignmentDetailsScreenState();
}

class _StudentAssignmentDetailsScreenState
    extends State<StudentAssignmentDetailsScreen> {
  final DatabaseService _databaseService = DatabaseService();

  Map<String, dynamic>? _submission;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSubmission();
  }

  Future<void> _loadSubmission() async {
    setState(() => _isLoading = true);

    try {
      final submission = await _databaseService.getStudentSubmission(
        widget.assignment['id'] as String,
        widget.student.id,
      );

      setState(() {
        _submission = submission;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading submission: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final assignmentDesc = widget.assignment['desc'] as String? ?? 'واجب';
    final deadlineDate = widget.assignment['deadline_date'] as String?;

    DateTime? deadline;
    if (deadlineDate != null) {
      try {
        deadline = DateTime.parse(deadlineDate);
      } catch (e) {
        print('Error parsing deadline: $e');
      }
    }

    final hasCompleted = _submission != null;
    final submittedAt = _submission?['created_at'] as String?;

    DateTime? submissionDate;
    if (submittedAt != null) {
      try {
        submissionDate = DateTime.parse(submittedAt);
      } catch (e) {
        print('Error parsing submission date: $e');
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل الواجب'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Assignment Info Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.assignment,
                                color: Theme.of(context).colorScheme.primary,
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  assignmentDesc,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ),
                            ],
                          ),
                          if (deadline != null) ...[
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 20,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.6),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'الموعد النهائي: ${deadline.day}/${deadline.month}/${deadline.year}',
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Submission Status Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _submission == null
                                    ? Icons.pending_actions
                                    : Icons.check_circle,
                                color: _submission == null
                                    ? Colors.orange
                                    : Colors.green,
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _submission == null
                                      ? 'لم يتم التسليم بعد'
                                      : 'تم التسليم',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: _submission == null
                                            ? Colors.orange
                                            : Colors.green,
                                      ),
                                ),
                              ),
                            ],
                          ),
                          if (_submission != null) ...[
                            const Divider(height: 24),
                            if (submissionDate != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      size: 20,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withOpacity(0.6),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'تم وضع علامة الإكمال في: ${submissionDate.day}/${submissionDate.month}/${submissionDate.year}',
                                      style:
                                          Theme.of(context).textTheme.bodyLarge,
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Info Message
                  if (_submission == null)
                  Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'يقوم المعلم بتسجيل إكمالك للواجب بعد التحقق منه',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
