import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/course.dart';
import '../../services/database_service.dart';

class SessionAttendanceScreen extends StatefulWidget {
  final Course course;
  final Map<String, dynamic> session;

  const SessionAttendanceScreen({
    super.key,
    required this.course,
    required this.session,
  });

  @override
  State<SessionAttendanceScreen> createState() =>
      _SessionAttendanceScreenState();
}

class _SessionAttendanceScreenState extends State<SessionAttendanceScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<Map<String, dynamic>> _students = [];
  Set<String> _attendedStudentIds = {};
  Set<String> _originalAttendedIds = {}; // Track original state
  bool _isLoading = true;
  bool _isEditMode = false; // Track if in edit mode
  bool _isSaving = false; // Track if saving

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

      // Load attendance records for this session (students who are in Student_Attendance table)
      final attendedIds = await _databaseService.getSessionAttendance(
        widget.session['id'] as String,
      );

      setState(() {
        _students = students;
        _attendedStudentIds = Set.from(attendedIds);
        _originalAttendedIds = Set.from(attendedIds); // Save original state
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading session attendance: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleAttendance(String studentId) async {
    // Only toggle locally, don't make API calls
    if (!_isEditMode) return; // Can only change when in edit mode
    
    setState(() {
      if (_attendedStudentIds.contains(studentId)) {
        _attendedStudentIds.remove(studentId);
      } else {
        _attendedStudentIds.add(studentId);
      }
    });
  }

  void _startEditMode() {
    setState(() {
      _isEditMode = true;
      _originalAttendedIds = Set.from(_attendedStudentIds);
    });
  }

  void _cancelEdit() {
    setState(() {
      _attendedStudentIds = Set.from(_originalAttendedIds);
      _isEditMode = false;
    });
  }

  Future<void> _saveAttendance() async {
    setState(() => _isSaving = true);
    
    try {
      final result = await _databaseService.saveAttendanceBatch(
        sessionId: widget.session['id'] as String,
        courseId: widget.course.id,
        attendedStudentIds: _attendedStudentIds,
        originalAttendedIds: _originalAttendedIds,
      );

      if (mounted) {
        if (result['success']) {
          setState(() {
            _isEditMode = false;
            _originalAttendedIds = Set.from(_attendedStudentIds);
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.green,
            ),
          );
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionDesc = widget.session['desc'] as String? ?? 
                       widget.session['description'] as String? ?? 
                       'الجلسة';
    final sessionDate = DateTime.parse(
      (widget.session['date'] ?? 
       widget.session['date_time'] ?? 
       DateTime.now().toIso8601String()) as String,
    );
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('حضور الطلاب'),
        centerTitle: true,
        actions: [
          if (!_isEditMode && !_isLoading)
            IconButton(
              onPressed: _startEditMode,
              icon: const Icon(Icons.edit),
              tooltip: 'تعديل الحضور',
            ),
          if (_isEditMode) ...[
            IconButton(
              onPressed: _isSaving ? null : _cancelEdit,
              icon: const Icon(Icons.close),
              tooltip: 'إلغاء',
            ),
            IconButton(
              onPressed: _isSaving ? null : _saveAttendance,
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
                  // Session Info Card
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
                              Icons.event_note,
                              color: Theme.of(context).colorScheme.primary,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    sessionDesc,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'التاريخ: ${dateFormat.format(sessionDate)}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withOpacity(0.7),
                                        ),
                                  ),
                              ],
                            ),
                          ),
                          // Edit and Delete session buttons at top-right
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                color: Colors.blue,
                                tooltip: 'تعديل الجلسة',
                                onPressed: () => _showEditSessionDialog(context),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                color: Colors.red,
                                tooltip: 'حذف الجلسة',
                                onPressed: () => _showDeleteSessionDialog(context),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatChip(
                            context,
                            'إجمالي الطلاب',
                            '${_students.length}',
                            Icons.people,
                            Colors.blue,
                          ),
                          _buildStatChip(
                            context,
                            'الحضور',
                            '${_attendedStudentIds.length}',
                            Icons.check_circle,
                            Colors.green,
                          ),
                          _buildStatChip(
                            context,
                            'الغياب',
                            '${_students.length - _attendedStudentIds.length}',
                            Icons.cancel,
                            Colors.red,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

                // Students List Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
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
                const SizedBox(height: 8),

                // Students List
                Expanded(
                  child: _students.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 64,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.3),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'لا يوجد طلاب في هذه الحلقة',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withOpacity(0.6),
                                    ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _students.length,
                          itemBuilder: (context, index) {
                            final student = _students[index];
                            final studentId = student['id'] as String;
                            final studentName = student['name'] as String? ?? 'طالب';
                            final isAttended = _attendedStudentIds.contains(studentId);
                            final imageUrl = student['image_link'] as String?;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 2,
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                leading: CircleAvatar(
                                  radius: 25,
                                  backgroundColor: isAttended
                                      ? Colors.green.shade100
                                      : Colors.grey.shade200,
                                  backgroundImage: imageUrl != null && imageUrl.isNotEmpty
                                      ? NetworkImage(imageUrl)
                                      : null,
                                  child: imageUrl == null || imageUrl.isEmpty
                                      ? Icon(
                                          Icons.person,
                                          color: isAttended
                                              ? Colors.green.shade700
                                              : Colors.grey.shade600,
                                        )
                                      : null,
                                ),
                                title: Text(
                                  studentName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  isAttended ? 'حاضر' : 'غائب',
                                  style: TextStyle(
                                    color: isAttended
                                        ? Colors.green.shade700
                                        : Colors.red.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                trailing: Checkbox(
                                  value: isAttended,
                                  onChanged: _isEditMode
                                      ? (_) => _toggleAttendance(studentId)
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

  Widget _buildStatChip(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withOpacity(0.6),
              ),
        ),
      ],
    );
  }

  Future<void> _showEditSessionDialog(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    final descController = TextEditingController(
      text: widget.session['desc'] as String?,
    );
    DateTime selectedDate = DateTime.parse(
      widget.session['date'] as String? ?? DateTime.now().toIso8601String(),
    );
    bool submitting = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('تعديل الجلسة'),
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
                          labelText: 'وصف الجلسة',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'يرجى إدخال وصف للجلسة'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.calendar_today),
                        title: Text(
                          'التاريخ: ${DateFormat('dd/MM/yyyy').format(selectedDate)}',
                        ),
                        trailing: TextButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setState(() => selectedDate = picked);
                            }
                          },
                          child: const Text('اختيار التاريخ'),
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
                            final result = await _databaseService.updateSession(
                              sessionId: widget.session['id'] as String,
                              description: descController.text.trim(),
                              date: selectedDate,
                            );
                            if (result['success'] == true) {
                              if (context.mounted) {
                                Navigator.pop(context);
                                // Update the local session data
                                widget.session['desc'] = descController.text.trim();
                                widget.session['date'] = selectedDate.toIso8601String();
                                // Reload the screen
                                this.setState(() {});
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('تم تحديث الجلسة'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    result['message'] ?? 'فشل في تحديث الجلسة',
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

  Future<void> _showDeleteSessionDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text(
          'هل أنت متأكد من حذف الجلسة "${widget.session['desc']}"?\n\nسيتم حذف جميع البيانات المرتبطة بها (الحضور، الواجبات، التسليمات).',
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
      try {
        final result = await _databaseService.deleteSession(
          widget.session['id'] as String,
        );

        if (result['success']) {
          if (context.mounted) {
            // Go back to sessions tab
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message']),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message']),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطأ: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
