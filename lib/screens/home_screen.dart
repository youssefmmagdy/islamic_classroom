import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/data_provider.dart';
import '../models/user.dart';
import '../models/course.dart';
import '../services/database_service.dart';
import '../components/course_card.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'about_screen.dart';
import 'login_screen.dart';
import 'course_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Load sample data when the app starts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DataProvider>().loadSampleData();
    });
  }

  Future<void> _refreshData() async {
    await context.read<DataProvider>().loadSampleData();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (!authProvider.isLoggedIn) {
          return const LoginScreen();
        }

        final user = authProvider.currentUser!;

        return Scaffold(
          appBar: AppBar(
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'lib/assets/logo_flutter.jpg',
                    height: 40,
                    width: 40,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'دَارُ الْقُرْآنِ',
                  style: TextStyle(fontSize: 24),
                ),
              ],
            ),
            centerTitle: false, // align with start (right in RTL)
            titleSpacing: 0, // bring title closer to drawer icon
            actions: [
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 12.0),
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ProfileScreen()),
                    );
                  },
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    backgroundImage: user.imageLink != null
                        ? NetworkImage(user.imageLink!)
                        : null,
                    child: user.imageLink == null
                        ? Icon(
                            Icons.person,
                            size: 20,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          )
                        : null,
                  ),
                ),
              ),
            ],
          ),
          drawer: _buildDrawer(context, user),
          body: RefreshIndicator(
            onRefresh: _refreshData,
            child: Consumer<DataProvider>(
              builder: (context, data, _) {
                return _buildCoursesTab(context, data, user);
              },
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _onCoursesFabPressed(context, user.role),
            child: Icon(user.role == UserRole.teacher ? Icons.add : Icons.qr_code),
          ),
        );
      },
    );
  }

  Drawer _buildDrawer(BuildContext context, dynamic user) {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(user.name),
              accountEmail: Text(user.email),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: Text(
                  user.name.isNotEmpty ? user.name[0] : '?',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('الملف الشخصي'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('الإعدادات'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('من نحن'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AboutScreen()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('تسجيل الخروج'),
              onTap: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('تسجيل الخروج'),
                    content: const Text('هل أنت متأكد من رغبتك في تسجيل الخروج؟'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('إلغاء'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('تسجيل الخروج'),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  // Don't pop context, just logout and navigate directly
                  await Provider.of<AuthProvider>(context, listen: false).logout();
                  // The Consumer<AuthProvider> in build() will automatically show LoginScreen
                  // when isLoggedIn becomes false
                }
              },
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                'الإصدار 1.0.0',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
              ),
            )
          ],
        ),
      ),
    );
  }

  // Helper method to fetch courses with teacher names
  Future<List<Map<String, dynamic>>> _getCoursesWithTeacherNames(dynamic user) async {
    final dbService = DatabaseService();
    
    // Get courses
    final coursesData = user.role == UserRole.teacher
        ? await dbService.getTeacherCourses(user.id)
        : await dbService.getStudentCourses(user.id);
    
    // Create a new list with enriched data
    final enrichedCourses = <Map<String, dynamic>>[];
    
    // Fetch teacher names for each course
    for (var courseData in coursesData) {
      // Create a mutable copy of the course data
      final enrichedCourse = Map<String, dynamic>.from(courseData);
      
      try {
        final teacherId = courseData['teacher_id'];
        if (teacherId != null) {
          final userResponse = await dbService.client
              .from('User')
              .select('name')
              .eq('id', teacherId)
              .maybeSingle();
          
          if (userResponse != null && userResponse['name'] != null) {
            enrichedCourse['teacher_name'] = userResponse['name'];
          }
        }
      } catch (e) {
        print('Error fetching teacher name: $e');
      }
      
      enrichedCourses.add(enrichedCourse);
    }
    
    return enrichedCourses;
  }

  Widget _buildCoursesTab(BuildContext context, DataProvider data, dynamic user) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _getCoursesWithTeacherNames(user),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                'حدث خطأ في تحميل الدورات: ${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          );
        }

        final coursesData = snapshot.data ?? [];
        
        if (coursesData.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                user.role == UserRole.teacher
                    ? 'لم تقم بإنشاء أي حلقة بعد'
                    : 'لا توجد دورات بعد. استخدم الزر السفلي للانضمام إلى حلقة',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: coursesData.length,
          itemBuilder: (context, index) {
            final courseData = coursesData[index];
            
            // Create course object
            final course = Course(
              id: courseData['id'],
              name: courseData['title'] ?? '',
              description: courseData['desc'] ?? 'لا يوجد وصف',
              teacherId: courseData['teacher_id'],
              back: courseData['back'],
            );

            // Get teacher name from the enriched data
            String? teacherName = courseData['teacher_name'];

            return CourseCard(
              course: course,
              teacherName: teacherName,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CourseDetailsScreen(course: course),
                  ),
                );
              },
              trailing: PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  color: course.back != null ? Colors.black : Colors.white,
                ),
                onSelected: (value) => _handleCourseMenuAction(context, value, course, user),
                itemBuilder: (BuildContext context) => [
                  const PopupMenuItem<String>(
                    value: 'copy_id',
                    child: Row(
                      children: [
                        Icon(Icons.copy),
                        SizedBox(width: 8),
                        Text('نسخ رمز الحلقة'),
                      ],
                    ),
                  ),
                  
                  if (user.role == UserRole.teacher)
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('حذف الحلقة', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  if (user.role == UserRole.student)
                    const PopupMenuItem<String>(
                      value: 'unregister',
                      child: Row(
                        children: [
                          Icon(Icons.exit_to_app, color: Colors.orange),
                          SizedBox(width: 8),
                          Text('إلغاء التسجيل', style: TextStyle(color: Colors.orange)),
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _onCoursesFabPressed(BuildContext context, UserRole role) async {
    if (role == UserRole.teacher) {
      await _showCreateCourseDialog(context);
    } else {
      await _showJoinCourseDialog(context);
    }
  }

  Future<void> _handleCourseMenuAction(
    BuildContext context,
    String action,
    Course course,
    dynamic user,
  ) async {
    switch (action) {
      case 'copy_id':
        // Copy course ID to clipboard
        await _copyCourseId(context, course.id);
        break;

      case 'invite':
        // Invite user by email
        await _showInviteUserDialog(context, course);
        break;

      case 'delete':
        // Delete course (teachers only)
        if (user.role == UserRole.teacher) {
          await _showDeleteCourseDialog(context, course);
        }
        break;

      case 'unregister':
        // Unregister from course (students only)
        if (user.role == UserRole.student) {
          await _showUnregisterDialog(context, course, user.id);
        }
        break;
    }
  }

  Future<void> _copyCourseId(BuildContext context, String courseId) async {
    await Clipboard.setData(ClipboardData(text: courseId));
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم نسخ رمز الحلقة: $courseId'),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'موافق',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    }
  }

  Future<void> _showInviteUserDialog(BuildContext context, Course course) async {
    final emailCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('دعوة مستخدم'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'حلقة: ${course.name}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(
                    labelText: 'البريد الإلكتروني',
                    hintText: 'example@email.com',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'يرجى إدخال البريد الإلكتروني';
                    }
                    // Basic email validation
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v.trim())) {
                      return 'البريد الإلكتروني غير صحيح';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.5)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'سيتم إرسال دعوة للانضمام إلى هذه الحلقة',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: isLoading ? null : () async {
                if (!formKey.currentState!.validate()) return;
                
                setState(() => isLoading = true);
                
                try {
                  final email = emailCtrl.text.trim().toLowerCase();
                  
                  // TODO: In a real app, this would:
                  // 1. Check if user exists with this email in database
                  // 2. Add user to course studentIds
                  // 3. Send email notification
                  // 4. Update database
                  
                  // For now, simulate the invitation
                  await Future.delayed(const Duration(seconds: 1));
                  
                  setState(() => isLoading = false);
                  
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('تم إرسال دعوة إلى: $email'),
                          backgroundColor: Colors.green,
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    }
                  }
                } catch (e) {
                  setState(() => isLoading = false);
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('حدث خطأ: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('إرسال دعوة'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeleteCourseDialog(BuildContext context, Course course) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الحلقة'),
        content: Text(
          'هل أنت متأكد من رغبتك في حذف حلقة "${course.name}"؟\n\n'
          'سيتم حذف جميع البيانات المرتبطة بالحلقة (الواجبات، الحضور، إلخ).\n'
          'هذا الإجراء لا يمكن التراجع عنه.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 16),
              Text('جاري حذف الحلقة...'),
            ],
          ),
          duration: Duration(seconds: 30),
        ),
      );
      
      final dbService = DatabaseService();
      final result = await dbService.deleteCourse(course.id);
      
      if (context.mounted) {
        // Hide loading indicator
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        
        if (result['success'] == true) {
          // Also remove from local DataProvider for immediate UI update
          final data = context.read<DataProvider>();
          data.deleteCourse(course.id);
          
          // Refresh the screen by calling setState
          setState(() {});
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('تم حذف الحلقة "${course.name}" بنجاح'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'فشل في حذف الحلقة'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _showUnregisterDialog(
    BuildContext context,
    Course course,
    String studentId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إلغاء التسجيل'),
        content: Text(
          'هل أنت متأكد من رغبتك في إلغاء تسجيلك من حلقة "${course.name}"؟\n\n'
          'سيتم إلغاء وصولك إلى محتوى الحلقة والواجبات.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('إلغاء التسجيل'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 16),
              Text('جاري إلغاء التسجيل...'),
            ],
          ),
          duration: Duration(seconds: 30),
        ),
      );
      
      final dbService = DatabaseService();
      final result = await dbService.leaveCourse(course.id, studentId);
      
      if (context.mounted) {
        // Hide loading indicator
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        
        if (result['success'] == true) {
          // Refresh the screen by calling setState
          setState(() {});
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('تم إلغاء تسجيلك من حلقة "${course.name}"'),
              backgroundColor: Colors.orange,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'فشل في إلغاء التسجيل'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _showCreateCourseDialog(BuildContext context) async {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final auth = context.read<AuthProvider>();
    final data = context.read<DataProvider>();
    final dbService = DatabaseService();
    
    bool isLoading = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('إنشاء حلقة جديدة'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'عنوان الحلقة *',
                    hintText: 'ادخل عنوان الحلقة',
                    prefixIcon: Icon(Icons.title),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'يرجى إدخال عنوان الحلقة' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: descCtrl,
                  decoration: const InputDecoration(
                    labelText: 'الوصف (اختياري)',
                    hintText: 'وصف مختصر عن الحلقة',
                    prefixIcon: Icon(Icons.description),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: isLoading ? null : () async {
                if (!formKey.currentState!.validate()) return;
                
                setState(() => isLoading = true);
                
                try {
                  final userId = auth.currentUser!.id;
                  // Create course in database
                  final result = await dbService.createCourse(
                    title: titleCtrl.text.trim(),
                    teacherId: userId,
                    desc: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                  );
                  
                  setState(() => isLoading = false);
                  
                  if (result['success'] == true && ctx.mounted) {
                    // Also add to local DataProvider for immediate UI update
                    final course = Course(
                      name: titleCtrl.text.trim(),
                      description: descCtrl.text.trim().isEmpty 
                          ? 'لا يوجد وصف'
                          : descCtrl.text.trim(),
                      teacherId: userId,
                      back: result['data']?['back'], // Get the back value from server
                    );
                    data.addCourse(course);
                    
                    Navigator.pop(ctx);
                    
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('تم إنشاء الحلقة بنجاح\nرمز الانضمام: ${course.id}'),
                          duration: const Duration(seconds: 5),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } else if (ctx.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(result['message'] ?? 'فشل في إنشاء الحلقة'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } catch (e) {
                  setState(() => isLoading = false);
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('حدث خطأ: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: isLoading 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('إنشاء الحلقة'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showJoinCourseDialog(BuildContext context) async {
    final codeCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final auth = context.read<AuthProvider>();
    final dbService = DatabaseService();
    
    bool isLoading = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('الانضمام إلى حلقة'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: codeCtrl,
              decoration: const InputDecoration(labelText: 'أدخل رمز الحلقة'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'ادخل رمز الحلقة' : null,
              enabled: !isLoading,
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: isLoading ? null : () async {
                if (!formKey.currentState!.validate()) return;
                
                setState(() => isLoading = true);
                
                try {
                  final courseId = codeCtrl.text.trim();
                  final userId = auth.currentUser!.id;
                  
                  // Check if course exists in database
                  final courseData = await dbService.getCourseById(courseId);
                  
                  if (courseData == null) {
                    setState(() => isLoading = false);
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('رمز الحلقة غير صحيح'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                    return;
                  }
                  
                  // Join the course
                  final result = await dbService.joinCourse(courseId, userId);
                  
                  setState(() => isLoading = false);
                  
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    
                    if (context.mounted) {
                      if (result['success'] == true) {
                        // Refresh the UI
                        this.setState(() {});
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('تم الانضمام إلى حلقة "${courseData['title']}"'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(result['message'] ?? 'فشل في الانضمام إلى الحلقة'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  }
                } catch (e) {
                  setState(() => isLoading = false);
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('حدث خطأ: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('انضمام'),
            ),
          ],
        ),
      ),
    );
  }
}