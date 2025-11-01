import 'package:flutter/material.dart';
import '../../models/course.dart';
import '../../services/database_service.dart';

class AssignmentDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> assignment;
  final Course course;

  const AssignmentDetailsScreen({
    super.key,
    required this.assignment,
    required this.course,
  });

  @override
  State<AssignmentDetailsScreen> createState() => _AssignmentDetailsScreenState();
}

class _AssignmentDetailsScreenState extends State<AssignmentDetailsScreen> {
  final _databaseService = DatabaseService();
  List<Map<String, dynamic>> _students = [];
  Set<String> _completedStudentIds = {};
  Set<String> _originalCompletedIds = {};
  bool _isLoading = true;
  bool _isEditMode = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      // Load students from Student_Course table
      final students = await _databaseService.getCourseStudents(widget.course.id);

      // Load submissions (students who completed)
      final submissions = await _databaseService.getAssignmentSubmissions(
        widget.assignment['id'] as String, 
        widget.course.id,
        widget.assignment['session_id'] as String,
      );
      
      // Extract student IDs who completed
      final completedIds = submissions
          .map((s) => s['student_id'] as String?)
          .where((id) => id != null)
          .cast<String>()
          .toSet();
      print('Loaded completed student IDs: $completedIds');
      setState(() {
        _students = students;
        _completedStudentIds = completedIds;
        _originalCompletedIds = Set.from(completedIds);
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading assignment details: $e');
      setState(() => _isLoading = false);
    }
  }

  void _toggleCompletion(String studentId) async {
    if (!_isEditMode) return; // Can only change when in edit mode
    
    final wasCompleted = _completedStudentIds.contains(studentId);
    
    // Update UI immediately
    setState(() {
      if (wasCompleted) {
        _completedStudentIds.remove(studentId);
      } else {
        _completedStudentIds.add(studentId);
      }
    });

    // Perform database operation
    try {
      if (!wasCompleted) {
        // Student is now marked as completed - insert into database
        await _databaseService.createAssignmentSubmission(
          assignmentId: widget.assignment['id'] as String,
          studentId: studentId,
          courseId: widget.course.id,
          sessionId: widget.assignment['session_id'] as String,
        );
      } else {
        // Student is now marked as not completed - delete from database
        await _databaseService.deleteAssignmentSubmission(
          assignmentId: widget.assignment['id'] as String,
          studentId: studentId,
        );
      }
      
      // Update original state to reflect saved changes
      setState(() {
        _originalCompletedIds = Set.from(_completedStudentIds);
      });
    } catch (e) {
      print('Error toggling completion: $e');
      // Revert UI change on error
      setState(() {
        if (wasCompleted) {
          _completedStudentIds.add(studentId);
        } else {
          _completedStudentIds.remove(studentId);
        }
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _startEditMode() {
    setState(() {
      _isEditMode = true;
      _originalCompletedIds = Set.from(_completedStudentIds);
    });
  }

  void _cancelEdit() {
    setState(() {
      _completedStudentIds = Set.from(_originalCompletedIds);
      _isEditMode = false;
    });
  }

  Future<void> _saveChanges() async {
    // Changes are already saved immediately when toggling
    // This just exits edit mode
    setState(() {
      _isEditMode = false;
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حفظ التغييرات'),
          backgroundColor: Colors.green,
        ),
      );
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل الواجب'),
        centerTitle: true,
        actions: [
          if (!_isEditMode && !_isLoading)
            IconButton(
              onPressed: _startEditMode,
              icon: const Icon(Icons.edit),
              tooltip: 'تعديل',
            ),
          if (_isEditMode) ...[
            IconButton(
              onPressed: _isSaving ? null : _cancelEdit,
              icon: const Icon(Icons.close),
              tooltip: 'إلغاء',
            ),
            IconButton(
              onPressed: _isSaving ? null : _saveChanges,
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check),
              tooltip: 'حفظ',
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: Column(
                children: [
                  // Assignment Info Card
                  Card(
                    margin: const EdgeInsets.all(16),
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
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
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
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
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

                // Students List with Checkboxes
                
                
                // Statistics Card (moved here)
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildSummaryItem(
                          context,
                          'أكملوا',
                          _completedStudentIds.length.toString(),
                          Colors.green,
                          Icons.check_circle,
                        ),
                        _buildSummaryItem(
                          context,
                          'لم يكملوا',
                          (_students.length - _completedStudentIds.length).toString(),
                          Colors.orange,
                          Icons.pending,
                        ),
                        _buildSummaryItem(
                          context,
                          'المجموع',
                          _students.length.toString(),
                          Theme.of(context).colorScheme.primary,
                          Icons.people,
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'قائمة الطلاب',
                        style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${_students.length} طالب',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _students.length,
                    itemBuilder: (context, index) {
                      final student = _students[index];
                      final studentId = student['id'] as String;
                      final studentName = student['name'] as String? ?? 'طالب';
                      final profileImage = student['image_link'] as String?;
                      final hasCompleted = _completedStudentIds.contains(studentId);

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
                                    studentName.substring(0, 1).toUpperCase(),
                                    style: TextStyle(
                                      color: hasCompleted
                                          ? Colors.green
                                          : Theme.of(context).colorScheme.onPrimaryContainer,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                          ),
                          title: Text(studentName),
                          subtitle: Text(
                            hasCompleted ? 'أكمل الواجب' : 'لم يكمل',
                            style: TextStyle(
                              color: hasCompleted ? Colors.green : Colors.orange,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          trailing: Checkbox(
                            value: hasCompleted,
                            onChanged: _isEditMode
                                ? (value) {
                                    _toggleCompletion(studentId);
                                  }
                                : null, // Disabled when not in edit mode
                            activeColor: Colors.green,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildSummaryItem(
    BuildContext context,
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
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
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }
}
