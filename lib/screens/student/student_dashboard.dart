import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../components/custom_card.dart';
import '../../components/common_widgets.dart';
import 'student_profile_screen.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const StudentHomeTab(),
    const StudentCoursesTab(),
    const StudentProfileScreen(),
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
            label: 'دوراتي',
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

class StudentHomeTab extends StatelessWidget {
  const StudentHomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة الطالب'),
      ),
      body: Consumer2<AuthProvider, DataProvider>(
        builder: (context, authProvider, dataProvider, child) {
          final user = authProvider.currentUser!;
          // Guard: handle empty students list to avoid Bad state: No element
          final students = dataProvider.students;
          if (students.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.info_outline, size: 48),
                    const SizedBox(height: 12),
                    const Text('لا توجد بيانات طلاب حتى الآن.'),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () async {
                        await context.read<DataProvider>().loadSampleData();
                      },
                      child: const Text('تحميل بيانات تجريبية'),
                    ),
                  ],
                ),
              ),
            );
          }

          // Find student data (safe because list is not empty now)
          final student = students.firstWhere(
            (s) => s.id == user.id,
            orElse: () => students.first, // fallback demo
          );
          
          final courses = dataProvider.getCoursesByStudent(student.id);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWelcomeCard(context, user.name),
                const SizedBox(height: 16),
                _buildProgressCard(context, student),
                const SizedBox(height: 16),
                _buildQuickStats(context, courses.length, student.memorizedContent.length),
                const SizedBox(height: 16),
                _buildRecentCoursesSection(context, courses),
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
                  'استمر في التعلم والتقدم',
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
            Icons.star,
            size: 48,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(BuildContext context, student) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.trending_up,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'تقدمك الأكاديمي',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'المستوى الحالي',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getLevelText(student.level),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'المحفوظات',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${student.memorizedContent.length} سورة/آية',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context, int coursesCount, int memorizedCount) {
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
            'المحفوظات',
            memorizedCount.toString(),
            Icons.menu_book,
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

  Widget _buildRecentCoursesSection(BuildContext context, List courses) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'دوراتي',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        if (courses.isEmpty)
          const EmptyStateWidget(
            icon: Icons.school,
            title: 'لا توجد دورات',
            subtitle: 'لم يتم تسجيلك في أي حلقة بعد',
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
                  subtitle: Text(course.description),
                  trailing: const Icon(Icons.arrow_forward_ios),
                ),
              )),
      ],
    );
  }

  String _getLevelText(level) {
    switch (level.toString()) {
      case 'StudentLevel.beginner':
        return 'مبتدئ';
      case 'StudentLevel.intermediate':
        return 'متوسط';
      case 'StudentLevel.advanced':
        return 'متقدم';
      case 'StudentLevel.excellent':
        return 'ممتاز';
      default:
        return 'مبتدئ';
    }
  }
}

class StudentCoursesTab extends StatelessWidget {
  const StudentCoursesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('دوراتي'),
      ),
      body: const Center(
        child: Text('دورات الطالب قيد التطوير'),
      ),
    );
  }
}

class StudentProfileTab extends StatelessWidget {
  const StudentProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الملف الشخصي'),
      ),
      body: const Center(
        child: Text('ملف الطالب الشخصي قيد التطوير'),
      ),
    );
  }
}