import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/user.dart';
import '../../models/course.dart';
import '../../providers/auth_provider.dart';
import '../../services/database_service.dart';
import '../assignments/create_assignment_screen.dart';
import '../assignments/assignment_details_screen.dart';
import '../assignments/student_assignment_details_screen.dart';

class AssignmentsTabScreen extends StatefulWidget {
  final Course course;

  const AssignmentsTabScreen({super.key, required this.course});

  @override
  State<AssignmentsTabScreen> createState() => _AssignmentsTabScreenState();
}

class _AssignmentsTabScreenState extends State<AssignmentsTabScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<Map<String, dynamic>> _sessions = [];
  Map<String, List<Map<String, dynamic>>> _sessionAssignments = {};
  Map<String, List<Map<String, dynamic>>> _assignmentSubmissions = {};
  List<Map<String, dynamic>> _students = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Load sessions for this course
      final sessions = await _databaseService.getCourseSessions(widget.course.id);
      
      // Load assignments for each session using the new getAssignments function
      final Map<String, List<Map<String, dynamic>>> sessionAssignmentsMap = {};
      for (var session in sessions) {
        final sessionId = session['id'] as String;
        final assignments = await _databaseService.getAssignments(
          courseId: widget.course.id,
          sessionId: sessionId,
        );
        sessionAssignmentsMap[sessionId] = assignments;
      }
      
      // Load submissions for each assignment
      final Map<String, List<Map<String, dynamic>>> submissionsMap = {};
      for (var sessionAssignments in sessionAssignmentsMap.values) {
        for (var assignment in sessionAssignments) {
          final assignmentId = assignment['id'] as String;
          final sessionId = assignment['session_id'] as String;
          final submissions = await _databaseService.getAssignmentSubmissions(
            assignmentId,
            widget.course.id,
            sessionId,
          );
          submissionsMap[assignmentId] = submissions;
        }
      }
      
      // Load students in this course
      final List<Map<String, dynamic>> studentsData = [];
      for (final studentId in widget.course.studentIds) {
        final studentData = await _databaseService.getUserById(studentId);
        if (studentData != null) {
          studentsData.add(studentData);
        }
      }

      setState(() {
        _sessions = sessions;
        _sessionAssignments = sessionAssignmentsMap;
        _assignmentSubmissions = submissionsMap;
        _students = studentsData;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading assignments data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showEditAssignmentDialog(
    BuildContext context,
    Map<String, dynamic> assignment,
  ) async {
    final formKey = GlobalKey<FormState>();
    final descController = TextEditingController(text: assignment['desc'] as String?);
    DateTime? selectedDeadline;
    
    final deadlineStr = assignment['deadline_date'] as String?;
    if (deadlineStr != null) {
      try {
        selectedDeadline = DateTime.parse(deadlineStr);
      } catch (e) {
        print('Error parsing deadline: $e');
      }
    }
    
    bool submitting = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('تعديل الواجب'),
              content: Form(
                key: formKey,
                child: SizedBox(
                  width: 400,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: descController,
                        decoration: const InputDecoration(
                          labelText: 'وصف الواجب',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'يرجى إدخال وصف للواجب'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.calendar_today),
                        title: Text(
                          selectedDeadline != null
                              ? 'الموعد النهائي: ${DateFormat('dd/MM/yyyy').format(selectedDeadline!)}'
                              : 'لا يوجد موعد نهائي',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextButton(
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: selectedDeadline ?? DateTime.now(),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2100),
                                );
                                if (picked != null) {
                                  setState(() => selectedDeadline = picked);
                                }
                              },
                              child: const Text('اختيار'),
                            ),
                            if (selectedDeadline != null)
                              IconButton(
                                icon: const Icon(Icons.clear, size: 20),
                                onPressed: () {
                                  setState(() => selectedDeadline = null);
                                },
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: submitting ? null : () => Navigator.pop(context),
                  child: const Text('إلغاء'),
                ),
                FilledButton(
                  onPressed: submitting
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setState(() => submitting = true);
                          try {
                            final result = await _databaseService.updateAssignment(
                              assignmentId: assignment['id'] as String,
                              description: descController.text.trim(),
                              deadlineDate: selectedDeadline,
                            );
                            if (result['success'] == true) {
                              if (context.mounted) Navigator.pop(context);
                              await _loadData();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('تم تحديث الواجب'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    result['message'] ?? 'فشل في تحديث الواجب',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('خطأ: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          } finally {
                            if (context.mounted) {
                              setState(() => submitting = false);
                            }
                          }
                        },
                  child: submitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('تحديث'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showDeleteConfirmationDialog(
    BuildContext context,
    String assignmentId,
    String assignmentDesc,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text(
          'هل أنت متأكد من حذف الواجب "$assignmentDesc"؟\n\nسيتم حذف جميع التسليمات المرتبطة بهذا الواجب.',
          style: const TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await _deleteAssignment(assignmentId);
    }
  }

  Future<void> _deleteAssignment(String assignmentId) async {
    // Show loading indicator
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 16),
              Text('جاري حذف الواجب...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );
    }

    try {
      final result = await _databaseService.deleteAssignment(assignmentId);

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.green,
            ),
          );

          // Reload data
          await _loadData();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final user = authProvider.currentUser!;

          if (_isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (user.role == UserRole.teacher) {
            return _buildTeacherView(context);
          } else {
            return _buildStudentView(context, user);
          }
        },
      ),
    );
  }

  Widget _buildTeacherView(BuildContext context) {
    if (_sessions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.event_busy_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
              ),
              const SizedBox(height: 16),
              Text(
                'لا توجد جلسات لهذه الحلقة بعد',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'قم بإنشاء جلسة أولاً من تبويب "الجلسات" لتتمكن من إضافة واجبات',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: Column(
        children: [
          // Instructions banner
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'اضغط على أيقونة + بجانب كل جلسة لإضافة واجب جديد',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Sessions list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _sessions.length,
              itemBuilder: (context, index) {
                final session = _sessions[index];
                final sessionId = session['id'] as String;
                final assignments = _sessionAssignments[sessionId] ?? [];

                return _buildSessionCard(context, session, assignments);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionCard(BuildContext context, Map<String, dynamic> session, List<Map<String, dynamic>> assignments) {
    final sessionTitle = session['desc'] as String? ?? 'جلسة';
    final sessionId = session['id'] as String;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        leading: const Icon(Icons.event_note),
        title: Text(
          sessionTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('${assignments.length} واجب${assignments.length != 1 ? "ات" : ""}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Create Assignment Button
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              color: Theme.of(context).colorScheme.primary,
              tooltip: 'إنشاء واجب جديد',
              onPressed: () async {
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => CreateAssignmentScreen(
                      course: widget.course,
                      sessionId: sessionId,
                    ),
                  ),
                );
                
                if (result == true) {
                  _loadData();
                }
              },
            ),
            // Expansion icon
            const SizedBox(width: 8),
          ],
        ),
        children: assignments.isEmpty
            ? [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        'لا توجد واجبات لهذه الجلسة',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final result = await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => CreateAssignmentScreen(
                                course: widget.course,
                                sessionId: sessionId,
                              ),
                            ),
                          );
                          
                          if (result == true) {
                            _loadData();
                          }
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('إنشاء واجب الآن'),
                      ),
                    ],
                  ),
                ),
              ]
            : assignments.map((assignment) {
                return _buildAssignmentSubmissionsTable(context, assignment);
              }).toList(),
      ),
    );
  }

  Widget _buildAssignmentSubmissionsTable(BuildContext context, Map<String, dynamic> assignment) {
    final assignmentId = assignment['id'] as String;
    final assignmentDesc = assignment['desc'] as String? ?? 'واجب';
    final assignmentLink = assignment['assignment_link'] as String?;
    final deadlineDate = assignment['deadline_date'] as String?;
    final submissions = _assignmentSubmissions[assignmentId] ?? [];

    // Parse deadline date
    DateTime? deadline;
    if (deadlineDate != null) {
      try {
        deadline = DateTime.parse(deadlineDate);
      } catch (e) {
        print('Error parsing deadline date: $e');
      }
    }

    // Create a map of student submissions for quick lookup
    final Map<String, Map<String, dynamic>> submissionsByStudent = {};
    for (var submission in submissions) {
      final studentId = submission['student_id'] as String?;
      if (studentId != null) {
        submissionsByStudent[studentId] = submission;
      }
    }

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => AssignmentDetailsScreen(
              assignment: assignment,
              course: widget.course,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Assignment Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.assignment,
                        size: 24,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          assignmentDesc,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                      // Edit button
                      IconButton(
                        icon: const Icon(Icons.edit),
                        color: Colors.blue.shade400,
                        tooltip: 'تعديل الواجب',
                        onPressed: () => _showEditAssignmentDialog(
                          context,
                          assignment,
                        ),
                      ),
                      // Delete button
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        color: Colors.red.shade400,
                        tooltip: 'حذف الواجب',
                        onPressed: () => _showDeleteConfirmationDialog(
                          context,
                          assignmentId,
                          assignmentDesc,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Deadline and PDF info
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      if (deadline != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'الموعد النهائي: ${deadline.day}/${deadline.month}/${deadline.year}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      if (assignmentLink != null && assignmentLink.isNotEmpty)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.picture_as_pdf,
                              size: 16,
                              color: Colors.red.shade400,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'يحتوي على ملف PDF',
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Submission stats
                  
                ],
              ),
            ),
            // Students Table Preview (click to see full details)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'انقر لعرض تفاصيل التسليمات',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentView(BuildContext context, User user) {
    if (_sessions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.event_busy_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
              ),
              const SizedBox(height: 16),
              Text(
                'لا توجد جلسات لهذه الحلقة بعد',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _sessions.length,
        itemBuilder: (context, index) {
          final session = _sessions[index];
          final sessionId = session['id'] as String;
          final assignments = _sessionAssignments[sessionId] ?? [];

          return _buildStudentSessionCard(context, session, assignments, user);
        },
      ),
    );
  }

  Widget _buildStudentSessionCard(
    BuildContext context,
    Map<String, dynamic> session,
    List<Map<String, dynamic>> assignments,
    User user,
  ) {
    final sessionTitle = session['desc'] as String? ?? 'جلسة';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        leading: const Icon(Icons.event_note),
        title: Text(
          sessionTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('${assignments.length} واجب${assignments.length != 1 ? "ات" : ""}'),
        children: assignments.isEmpty
            ? [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'لا توجد واجبات لهذه الجلسة',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ),
              ]
            : assignments.map((assignment) {
                return _buildStudentAssignmentCard(context, assignment, user);
              }).toList(),
      ),
    );
  }

  Widget _buildStudentAssignmentCard(
    BuildContext context,
    Map<String, dynamic> assignment,
    User user,
  ) {
    final assignmentDesc = assignment['desc'] as String? ?? 'واجب';
    final assignmentLink = assignment['assignment_link'] as String?;
    final deadlineDate = assignment['deadline_date'] as String?;

    // Parse deadline date
    DateTime? deadline;
    if (deadlineDate != null) {
      try {
        deadline = DateTime.parse(deadlineDate);
      } catch (e) {
        print('Error parsing deadline date: $e');
      }
    }

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => StudentAssignmentDetailsScreen(
              assignment: assignment,
              courseId: widget.course.id,
              student: user,
            ),
          ),
        ).then((_) => _loadData());
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.assignment,
                    size: 24,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      assignmentDesc,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Deadline and PDF info
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  if (deadline != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'الموعد النهائي: ${deadline.day}/${deadline.month}/${deadline.year}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  if (assignmentLink != null && assignmentLink.isNotEmpty)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.picture_as_pdf,
                          size: 16,
                          color: Colors.red.shade400,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'يحتوي على ملف PDF',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'انقر لعرض التفاصيل والتسليم',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
