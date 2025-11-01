import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/course.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../services/database_service.dart';
import '../sessions/session_attendance_screen.dart';

class SessionsTabScreen extends StatefulWidget {
  final Course course;

  const SessionsTabScreen({super.key, required this.course});

  @override
  State<SessionsTabScreen> createState() => _SessionsTabScreenState();
}

class _SessionsTabScreenState extends State<SessionsTabScreen>
    with SingleTickerProviderStateMixin {
  final DatabaseService _databaseService = DatabaseService();
  List<Map<String, dynamic>> _sessions = [];
  bool _isLoading = true;
  late AnimationController _rippleController;
  late Animation<double> _rippleAnimation;

  @override
  void initState() {
    super.initState();
    _loadSessions();
    
    // Setup ripple animation
    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _rippleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _rippleController,
        curve: Curves.easeOut,
      ),
    );
    
    // Start animation after a short delay
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _rippleController.forward();
      }
    });
  }

  @override
  void dispose() {
    _rippleController.dispose();
    super.dispose();
  }

  Future<void> _loadSessions() async {
    setState(() => _isLoading = true);

    try {
      final sessions = await _databaseService.getCourseSessions(
        widget.course.id,
      );
      setState(() {
        _sessions = sessions;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading sessions: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadSessions,
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final user = authProvider.currentUser!;

          if (_isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_sessions.isEmpty) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height - 200,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_busy_outlined,
                          size: 64,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'لا توجد جلسات لهذه الحلقة بعد',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        if (user.role == UserRole.teacher) ...[
                          const SizedBox(height: 24),
                          FilledButton.icon(
                            onPressed: () async {
                              await _showCreateSessionDialog(context, user);
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('إنشاء جلسة جديدة'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          }

          return _buildSessionsTable(context, _sessions, user);
        },
      ),
    );
  }

  Widget _buildSessionsTable(
    BuildContext context,
    List<Map<String, dynamic>> sessions,
    User user,
  ) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    // Sort sessions by date (newest first)
    final sortedSessions = List<Map<String, dynamic>>.from(sessions)
      ..sort((a, b) {
        final aDate = DateTime.parse(
          (a['date'] ?? a['date_time'] ?? DateTime.now().toIso8601String())
              as String,
        );
        final bDate = DateTime.parse(
          (b['date'] ?? b['date_time'] ?? DateTime.now().toIso8601String())
              as String,
        );
        return bDate.compareTo(aDate);
      });

    return RefreshIndicator(
      onRefresh: _loadSessions,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'الجلسات',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                if (user.role == UserRole.teacher)
                  FilledButton.icon(
                    onPressed: () async {
                      await _showCreateSessionDialog(context, user);
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('إنشاء جلسة'),
                  ),
                
              ],
            ),
          const SizedBox(height: 16),
          Center(
            child: Card(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: AnimatedBuilder(
                  animation: _rippleAnimation,
                  builder: (context, child) {
                    return DataTable(
                      headingRowColor: WidgetStateProperty.all(
                        Theme.of(context).colorScheme.primaryContainer,
                      ),
                      columnSpacing: 24,
                      columns: [
                  DataColumn(
                    label: Text(
                      'وصف الجلسة',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(
                          context,
                        ).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'اسم المعلم',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(
                          context,
                        ).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'التاريخ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(
                          context,
                        ).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
                rows: List<DataRow>.generate(sortedSessions.length, (
                      index,
                    ) {
                      final session = sortedSessions[index];
                      // final isCompleted = session['is_completed'] as bool? ?? false;
                      final dateTime = DateTime.parse(
                        (session['date'] ??
                                session['date_time'] ??
                                DateTime.now().toIso8601String())
                            as String,
                      );
                      // final isPast = dateTime.isBefore(DateTime.now());

                      final description =
                          (session['desc'] as String?) ??
                          (session['description'] as String?);
                      final String? teacherName =
                          (session['teacher_name'] as String?) ??
                          (session['User'] is Map<String, dynamic>
                              ? (session['User']
                                        as Map<String, dynamic>)['name']
                                    as String?
                              : null);

                      // status removed from table; keep logic minimal

                      // numbering available if needed: final sessionNumber = sortedSessions.length - index;

                      // Create ripple effect for first row (teachers only)
                      final isFirstRow = index == 0;
                      final showRipple = isFirstRow && user.role == UserRole.teacher;

                      return DataRow(
                        color: showRipple
                            ? WidgetStateProperty.all(
                                Color.lerp(
                                  Colors.transparent,
                                  Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                                  _rippleAnimation.value,
                                )?.withOpacity(1.0 - _rippleAnimation.value),
                              )
                            : null,
                        cells: [
                          DataCell(
                            Text(description ?? ''),
                            onTap: user.role == UserRole.teacher
                                ? () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            SessionAttendanceScreen(
                                          course: widget.course,
                                          session: session,
                                        ),
                                      ),
                                    );
                                    // Refresh sessions list when returning
                                    _loadSessions();
                                  }
                                : null,
                          ),
                          DataCell(
                            Text(teacherName ?? '-'),
                            onTap: user.role == UserRole.teacher
                                ? () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            SessionAttendanceScreen(
                                          course: widget.course,
                                          session: session,
                                        ),
                                      ),
                                    );
                                    // Refresh sessions list when returning
                                    _loadSessions();
                                  }
                                : null,
                          ),
                          DataCell(
                            Text(dateFormat.format(dateTime)),
                            onTap: user.role == UserRole.teacher
                                ? () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            SessionAttendanceScreen(
                                          course: widget.course,
                                          session: session,
                                        ),
                                      ),
                                    );
                                    // Refresh sessions list when returning
                                    _loadSessions();
                                  }
                                : null,
                          ),
                        ],
                      );
                    }),
                    );
                  },
                ),
              ),
            ),
          ),
          if (user.role == UserRole.teacher) ...[
            const SizedBox(height: 24),
            _buildStatisticsCard(context, sortedSessions),
          ],
        ],
      ),
      ),
    );
  }

  Future<void> _showCreateSessionDialog(BuildContext context, User user) async {
    final formKey = GlobalKey<FormState>();
    final descController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    bool submitting = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('إنشاء جلسة جديدة'),
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
                            final result = await _databaseService.createSession(
                              teacherId: user.id,
                              courseId: widget.course.id,
                              description: descController.text.trim(),
                              date: selectedDate,
                            );
                            if (result['success'] == true) {
                              if (context.mounted) Navigator.pop(context);
                              await _loadSessions();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('تم إنشاء الجلسة'),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    result['message'] ?? 'فشل في إنشاء الجلسة',
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(SnackBar(content: Text('خطأ: $e')));
                          } finally {
                            if (context.mounted)
                              setState(() => submitting = false);
                          }
                        },
                  child: submitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('إنشاء'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildStatisticsCard(
    BuildContext context,
    List<Map<String, dynamic>> sessions,
  ) {
    final now = DateTime.now();
    int pastCount = 0;
    for (final s in sessions) {
      final raw =
          (s['date'] ?? s['date_time'] ?? now.toIso8601String()) as String;
      final dt = DateTime.tryParse(raw) ?? now;
      if (dt.isBefore(now)) pastCount++;
    }
    final completed = pastCount; // consider past sessions as completed
    final upcoming = sessions.length - pastCount; // sessions that will start
    final past = pastCount; // passed sessions

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'إحصائيات الجلسات',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  context,
                  'مكتملة',
                  completed,
                  Colors.green,
                  Icons.check_circle,
                ),
                _buildStatItem(
                  context,
                  'قادمة',
                  upcoming,
                  Colors.blue,
                  Icons.schedule,
                ),
                _buildStatItem(
                  context,
                  'فائتة',
                  past,
                  Colors.orange,
                  Icons.history,
                ),
                _buildStatItem(
                  context,
                  'المجموع',
                  sessions.length,
                  Theme.of(context).colorScheme.primary,
                  Icons.event,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    int value,
    Color color,
    IconData icon,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          value.toString(),
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
