import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../components/custom_card.dart';
import '../../components/common_widgets.dart';
import 'courses_screen.dart';
import 'teacher_profile_enhanced.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const TeacherHomeTab(),
    const CoursesScreen(),
    const TeacherProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'الرئيسية',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school),
            label: 'الدورات',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'الملف الشخصي',
          ),
        ],
      ),
    );
  }
}

class TeacherHomeTab extends StatelessWidget {
  const TeacherHomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة المعلم'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // TODO: Show notifications
            },
          ),
        ],
      ),
      body: Consumer2<AuthProvider, DataProvider>(
        builder: (context, authProvider, dataProvider, child) {
          final user = authProvider.currentUser!;
          final courses = dataProvider.getCoursesByTeacher(user.id);
          final allSessions = dataProvider.sessions;
          final todaySessions = allSessions.where((session) {
            return session.isToday &&
                courses.any((course) => course.id == session.courseId);
          }).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWelcomeCard(context, user.name),
                const SizedBox(height: 16),
                _buildStatsCards(context, courses.length, todaySessions.length),
                const SizedBox(height: 16),
                _buildQuickActions(context),
                const SizedBox(height: 16),
                if (todaySessions.isNotEmpty) ...[
                  _buildTodaySessionsSection(context, todaySessions),
                  const SizedBox(height: 16),
                ],
                _buildRecentCoursesSection(context, courses.take(3).toList()),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context, String name) {
    return CustomCard(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'مرحباً، $name',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'نتمنى لك يوماً دراسياً مثمراً',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onPrimaryContainer
                            .withOpacity(0.8),
                      ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.waving_hand,
            size: 48,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards(BuildContext context, int coursesCount, int todaySessionsCount) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            'الدورات',
            coursesCount.toString(),
            Icons.school,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            context,
            'حصص اليوم',
            todaySessionsCount.toString(),
            Icons.today,
            Colors.green,
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
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
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

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الإجراءات السريعة',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                context,
                'إضافة حلقة',
                Icons.add_circle,
                Colors.blue,
                () {
                  // TODO: Navigate to add course
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                context,
                'إضافة حصة',
                Icons.event_note,
                Colors.green,
                () {
                  // TODO: Navigate to add session
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return CustomCard(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTodaySessionsSection(BuildContext context, List sessions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'حصص اليوم',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        ...sessions.map((session) => CustomCard(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const Icon(Icons.schedule),
                title: Text(session.title),
                subtitle: Text(
                  '${session.dateTime.hour.toString().padLeft(2, '0')}:${session.dateTime.minute.toString().padLeft(2, '0')}',
                ),
                trailing: session.isCompleted
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : null,
              ),
            )),
      ],
    );
  }

  Widget _buildRecentCoursesSection(BuildContext context, List courses) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'الدورات الحديثة',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            TextButton(
              onPressed: () {
                // TODO: Navigate to all courses
              },
              child: const Text('عرض الكل'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (courses.isEmpty)
          const EmptyStateWidget(
            icon: Icons.school,
            title: 'لا توجد دورات',
            subtitle: 'ابدأ بإنشاء دورتك الأولى',
          )
        else
          ...courses.map((course) => CustomCard(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Text(
                      course.name[0],
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(course.name),
                  subtitle: Text('${course.studentCount} طالب'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // TODO: Navigate to course details
                  },
                ),
              )),
      ],
    );
  }
}