import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../components/custom_card.dart';
import '../../components/common_widgets.dart';
import '../../models/student.dart';

class StudentProfileScreen extends StatelessWidget {
  const StudentProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ملفي الشخصي'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.pushNamed(context, '/profile');
            },
          ),
        ],
      ),
      body: Consumer2<AuthProvider, DataProvider>(
        builder: (context, authProvider, dataProvider, child) {
          final user = authProvider.currentUser;
          if (user == null) {
            return const Center(
              child: Text('لم يتم العثور على بيانات المستخدم'),
            );
          }

          // Find student data
          final student = dataProvider.students
              .where((s) => s.id == user.id)
              .firstOrNull;

          final studentCourses = dataProvider.getCoursesByStudent(
            student?.id ?? '',
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Student Profile Header
                _buildProfileHeader(context, user, student),
                const SizedBox(height: 16),

                // Student Stats
                _buildStudentStats(context, student, studentCourses.length),
                const SizedBox(height: 16),

                // Academic Progress
                _buildAcademicProgress(context, student),
                const SizedBox(height: 16),

                // My Courses
                _buildMyCoursesSection(context, studentCourses),
                const SizedBox(height: 16),

                // Recent Activities
                _buildRecentActivitiesSection(context),
                const SizedBox(height: 16),

                // Homework Status
                _buildHomeworkSection(context),
                const SizedBox(height: 16),

                // Attendance Overview
                _buildAttendanceSection(context),
                const SizedBox(height: 16),

                // Settings
                _buildSettingsSection(context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, user, Student? student) {
    return CustomCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            // backgroundImage: user.profileImage != null
            //     ? NetworkImage(user.profileImage!)
            //     : null,
            child: /* user.profileImage == null ? */ Icon(
              Icons.person,
              size: 40,
              color: Theme.of(context).colorScheme.primary,
            ) /* : null */,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'طالب',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.school,
                      size: 16,
                      color: _getLevelColor(student?.level ?? StudentLevel.beginner),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _getLevelDisplayName(student?.level ?? StudentLevel.beginner),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: _getLevelColor(student?.level ?? StudentLevel.beginner),
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentStats(BuildContext context, Student? student, int coursesCount) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            'الدورات',
            coursesCount.toString(),
            Icons.book,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            context,
            'المحفوظات',
            student?.memorizedContent.length.toString() ?? '0',
            Icons.library_books,
            Colors.green,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            context,
            'الحضور',
            '92%',
            Icons.check_circle,
            Colors.orange,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            context,
            'الواجبات',
            '8/10',
            Icons.assignment,
            Colors.purple,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return CustomCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAcademicProgress(BuildContext context, Student? student) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'التقدم الأكاديمي',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          
          // Memorized Content
          _buildProgressItem(
            context,
            'المحفوظات',
            student?.memorizedContent ?? [],
            Icons.library_books,
            Colors.green,
          ),
          const SizedBox(height: 12),
          
          // Level Progress
          _buildLevelProgress(context, student?.level ?? StudentLevel.beginner),
          const SizedBox(height: 12),
          
          // Outstanding Balance
          if (student != null && student.hasOutstandingFees)
            _buildBalanceAlert(context, student.balance),
        ],
      ),
    );
  }

  Widget _buildProgressItem(
    BuildContext context,
    String title,
    List<String> items,
    IconData icon,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (items.isEmpty)
          Text(
            'لم يتم حفظ أي شيء بعد',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: items.map((item) {
              return Chip(
                label: Text(
                  item,
                  style: const TextStyle(fontSize: 12),
                ),
                backgroundColor: color.withOpacity(0.1),
                side: BorderSide.none,
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildLevelProgress(BuildContext context, StudentLevel level) {
    final levels = StudentLevel.values;
    final currentIndex = levels.indexOf(level);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.trending_up, size: 20, color: _getLevelColor(level)),
            const SizedBox(width: 8),
            Text(
              'المستوى الحالي',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: levels.map((l) {
            final index = levels.indexOf(l);
            final isActive = index <= currentIndex;
            return Expanded(
              child: Container(
                height: 4,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: isActive
                      ? _getLevelColor(level)
                      : Theme.of(context).colorScheme.outline.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 4),
        Text(
          _getLevelDisplayName(level),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: _getLevelColor(level),
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }

  Widget _buildBalanceAlert(BuildContext context, double balance) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning, color: Colors.orange, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'رصيد مستحق',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: Colors.orange[800],
                      ),
                ),
                Text(
                  '${balance.toStringAsFixed(0)} ج.م',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.orange[700],
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyCoursesSection(BuildContext context, List courses) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'دوراتي',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              TextButton(
                onPressed: () {
                  // Navigate to courses list
                },
                child: const Text('عرض الكل'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (courses.isEmpty)
            const EmptyStateWidget(
              icon: Icons.book,
              title: 'لا توجد دورات',
              subtitle: 'لم تسجل في أي دورات بعد',
            )
          else
            Column(
              children: courses.take(3).map<Widget>((course) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildCourseItem(context, course),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildCourseItem(BuildContext context, course) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.book,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.name,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  course.description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivitiesSection(BuildContext context) {
    final activities = [
      {
        'title': 'تم تسليم واجب سورة الفاتحة',
        'subtitle': 'حلقة تحفيظ القرآن - المستوى الأول',
        'time': 'منذ ساعة',
        'icon': Icons.assignment_turned_in,
        'color': Colors.green,
      },
      {
        'title': 'حضور حصة جديدة',
        'subtitle': 'مراجعة سورة البقرة',
        'time': 'منذ 3 ساعات',
        'icon': Icons.check_circle,
        'color': Colors.blue,
      },
      {
        'title': 'حفظ آية جديدة',
        'subtitle': 'آية الكرسي',
        'time': 'منذ يوم',
        'icon': Icons.library_books,
        'color': Colors.orange,
      },
    ];

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'الأنشطة الأخيرة',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              TextButton(
                onPressed: () {
                  // Navigate to activities
                },
                child: const Text('عرض الكل'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            children: activities.map<Widget>((activity) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: (activity['color'] as Color).withOpacity(0.1),
                      child: Icon(
                        activity['icon'] as IconData,
                        size: 16,
                        color: activity['color'] as Color,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activity['title'] as String,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                          Text(
                            activity['subtitle'] as String,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      activity['time'] as String,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                          ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeworkSection(BuildContext context) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'حالة الواجبات',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildHomeworkItem(
                  context,
                  'المكتملة',
                  '8',
                  Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildHomeworkItem(
                  context,
                  'المعلقة',
                  '2',
                  Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHomeworkItem(
    BuildContext context,
    String title,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceSection(BuildContext context) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'نظرة عامة على الحضور',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildAttendanceItem(
                  context,
                  'معدل الحضور',
                  '92%',
                  Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildAttendanceItem(
                  context,
                  'أيام الغياب',
                  '3',
                  Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceItem(
    BuildContext context,
    String title,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(BuildContext context) {
    final settingsItems = [
      {
        'title': 'إعدادات الحساب',
        'subtitle': 'تعديل البيانات الشخصية',
        'icon': Icons.settings,
        'onTap': () => Navigator.pushNamed(context, '/profile'),
      },
      {
        'title': 'إعدادات الإشعارات',
        'subtitle': 'تخصيص الإشعارات',
        'icon': Icons.notifications,
        'onTap': () {
          // Navigate to notifications settings
        },
      },
      {
        'title': 'المساعدة والدعم',
        'subtitle': 'الحصول على المساعدة',
        'icon': Icons.help,
        'onTap': () {
          // Navigate to help
        },
      },
    ];

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'الإعدادات',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Column(
            children: settingsItems.map<Widget>((item) {
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  radius: 20,
                  backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  child: Icon(
                    item['icon'] as IconData,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                title: Text(item['title'] as String),
                subtitle: Text(item['subtitle'] as String),
                trailing: const Icon(Icons.chevron_right),
                onTap: item['onTap'] as VoidCallback,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _getLevelDisplayName(StudentLevel level) {
    switch (level) {
      case StudentLevel.beginner:
        return 'مبتدئ';
      case StudentLevel.intermediate:
        return 'متوسط';
      case StudentLevel.advanced:
        return 'متقدم';
      case StudentLevel.excellent:
        return 'ممتاز';
    }
  }

  Color _getLevelColor(StudentLevel level) {
    switch (level) {
      case StudentLevel.beginner:
        return Colors.blue;
      case StudentLevel.intermediate:
        return Colors.orange;
      case StudentLevel.advanced:
        return Colors.green;
      case StudentLevel.excellent:
        return Colors.purple;
    }
  }
}