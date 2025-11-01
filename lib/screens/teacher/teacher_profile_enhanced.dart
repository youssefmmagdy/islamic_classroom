import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../components/custom_card.dart';
import '../../components/common_widgets.dart';

class TeacherProfileScreen extends StatelessWidget {
  const TeacherProfileScreen({super.key});

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

          final teacherCourses = dataProvider.getCoursesByTeacher(user.id);
          final totalStudents = teacherCourses
              .fold<int>(0, (sum, course) => sum + course.studentCount);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Teacher Profile Header
                _buildProfileHeader(context, user),
                const SizedBox(height: 16),

                // Statistics Cards
                _buildStatisticsRow(context, teacherCourses.length, totalStudents),
                const SizedBox(height: 16),

                // My Courses
                _buildMyCoursesSection(context, teacherCourses),
                const SizedBox(height: 16),

                // Recent Activities
                _buildRecentActivitiesSection(context),
                const SizedBox(height: 16),

                // Performance Overview
                _buildPerformanceSection(context),
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

  Widget _buildProfileHeader(BuildContext context, user) {
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
                  'معلم قرآن كريم',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.star,
                      size: 16,
                      color: Colors.amber,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '4.8',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '(124 تقييم)',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
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

  Widget _buildStatisticsRow(BuildContext context, int coursesCount, int studentsCount) {
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
            'الطلاب',
            studentsCount.toString(),
            Icons.group,
            Colors.green,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            context,
            'الحصص',
            '24',
            Icons.schedule,
            Colors.orange,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            context,
            'الواجبات',
            '18',
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
              subtitle: 'لم تقم بإنشاء أي دورات بعد',
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
                  '${course.studentCount} طالب',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
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
        'title': 'تم تصحيح واجب سورة الفاتحة',
        'subtitle': 'حلقة تحفيظ القرآن - المستوى الأول',
        'time': 'منذ ساعتين',
        'icon': Icons.assignment_turned_in,
        'color': Colors.green,
      },
      {
        'title': 'تم إضافة حصة جديدة',
        'subtitle': 'مراجعة سورة البقرة',
        'time': 'منذ 4 ساعات',
        'icon': Icons.add_circle,
        'color': Colors.blue,
      },
      {
        'title': 'تم تسجيل حضور الطلاب',
        'subtitle': 'حصة اليوم - 18 طالب حاضر',
        'time': 'منذ 6 ساعات',
        'icon': Icons.check_circle,
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

  Widget _buildPerformanceSection(BuildContext context) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'نظرة عامة على الأداء',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildPerformanceItem(
                  context,
                  'معدل الحضور',
                  '92%',
                  Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildPerformanceItem(
                  context,
                  'الواجبات المصححة',
                  '18/20',
                  Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildPerformanceItem(
                  context,
                  'تقييم الطلاب',
                  '4.8/5',
                  Colors.amber,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildPerformanceItem(
                  context,
                  'الحصص هذا الشهر',
                  '24',
                  Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceItem(
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
      {
        'title': 'حول التطبيق',
        'subtitle': 'معلومات التطبيق والإصدار',
        'icon': Icons.info,
        'onTap': () {
          // Show about dialog
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
}