import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/auth_provider.dart';
import '../models/user.dart';
import '../components/custom_card.dart';
import '../services/cloudinary_service.dart';
import '../services/database_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isEditing = false;
  bool _isUploadingImage = false;
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final ImagePicker _imagePicker = ImagePicker();
  int _imageKey = 0; // Key to force image rebuild
  final DatabaseService _databaseService = DatabaseService();
  
  // Country code for phone
  String _selectedCountryCode = '+20';
  final List<Map<String, String>> _countryCodes = [
    {'code': '+966', 'country': 'السعودية', 'flag': '🇸🇦', 'example': '501234567'},
    {'code': '+971', 'country': 'الإمارات', 'flag': '🇦🇪', 'example': '501234567'},
    {'code': '+20', 'country': 'مصر', 'flag': '🇪🇬', 'example': '1012345678'},
    {'code': '+965', 'country': 'الكويت', 'flag': '🇰🇼', 'example': '50012345'},
    {'code': '+974', 'country': 'قطر', 'flag': '🇶🇦', 'example': '33123456'},
    {'code': '+973', 'country': 'البحرين', 'flag': '🇧🇭', 'example': '36001234'},
    {'code': '+968', 'country': 'عمان', 'flag': '🇴🇲', 'example': '92123456'},
    {'code': '+962', 'country': 'الأردن', 'flag': '🇯🇴', 'example': '790123456'},
    {'code': '+961', 'country': 'لبنان', 'flag': '🇱🇧', 'example': '71123456'},
    {'code': '+212', 'country': 'المغرب', 'flag': '🇲🇦', 'example': '612345678'},
  ];
  
  // Student data
  Map<String, dynamic>? _studentData;
  bool _isLoadingStudentData = false;
  
  // Teacher data
  int _coursesCount = 0;
  int _studentsCount = 0;
  bool _isLoadingTeacherData = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    if (user != null) {
      _nameController.text = user.name;
      _phoneController.text = user.phone;
      _selectedCountryCode = user.countryCode;
      
      // Load student data if user is a student
      if (user.role == UserRole.student) {
        _loadStudentData(user.id);
      }
      
      // Load teacher data if user is a teacher
      if (user.role == UserRole.teacher) {
        _loadTeacherData(user.id);
      }
    }
  }
  
  Future<void> _loadTeacherData(String teacherId) async {
    setState(() => _isLoadingTeacherData = true);
    try {
      // Get teacher's courses
      final courses = await _databaseService.getTeacherCourses(teacherId);
      
      // Count unique students across all courses
      final Set<String> uniqueStudents = {};
      for (var course in courses) {
        final courseId = course['id'] as String;
        final students = await _databaseService.getCourseStudents(courseId);
        for (var student in students) {
          uniqueStudents.add(student['id'] as String);
        }
      }
      
      if (mounted) {
        setState(() {
          _coursesCount = courses.length;
          _studentsCount = uniqueStudents.length;
          _isLoadingTeacherData = false;
        });
      }
    } catch (e) {
      print('Error loading teacher data: $e');
      if (mounted) {
        setState(() => _isLoadingTeacherData = false);
      }
    }
  }
  
  Future<void> _loadStudentData(String studentId) async {
    setState(() => _isLoadingStudentData = true);
    try {
      final data = await _databaseService.getStudentProfile(studentId);
      if (mounted) {
        setState(() {
          _studentData = data;
          _isLoadingStudentData = false;
        });
      }
    } catch (e) {
      print('Error loading student data: $e');
      if (mounted) {
        setState(() => _isLoadingStudentData = false);
      }
    }
  }

  Future<void> _refreshProfile() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user != null) {
      if (user.role == UserRole.student) {
        await _loadStudentData(user.id);
      }
      if (user.role == UserRole.teacher) {
        await _loadTeacherData(user.id);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الملف الشخصي'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
              tooltip: 'تعديل',
            ),
          if (_isEditing) ...[
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _isEditing = false;
                  // Reset controllers
                  final user = context.read<AuthProvider>().currentUser;
                  if (user != null) {
                    _nameController.text = user.name;
                    _phoneController.text = user.phone;
                  }
                });
              },
              tooltip: 'إلغاء',
            ),
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveProfile,
              tooltip: 'حفظ',
            ),
          ],
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshProfile,
        child: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            final user = authProvider.currentUser;
            if (user == null) {
              return const Center(
                child: Text('لم يتم العثور على بيانات المستخدم'),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Profile Picture
                    _buildProfilePicture(user),
                    const SizedBox(height: 24),

                    // User Info Card
                    _buildUserInfoCard(user),
                    const SizedBox(height: 16),

                    // Personal Details Card
                    _buildPersonalDetailsCard(user),
                    const SizedBox(height: 16),

                    // Role-specific Information
                    _buildRoleSpecificInfo(user),
                    const SizedBox(height: 24),

                    // Delete Account Button
                    _buildDeleteAccountButton(authProvider),
                    const SizedBox(height: 8),

                    // Logout Button
                    _buildLogoutButton(authProvider),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfilePicture(User user) {
    
    // Add cache-busting parameter to force image reload
    final imageUrl = user.imageLink != null && user.imageLink!.isNotEmpty
        ? '${user.imageLink!}?v=$_imageKey'
        : null;

    return Stack(
      key: ValueKey(_imageKey), // Force rebuild when key changes
      children: [
        GestureDetector(
          onTap: user.imageLink != null && user.imageLink!.isNotEmpty
              ? () => _showFullScreenImage(user.imageLink!)
              : null,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).colorScheme.primary,
                width: 3,
              ),
            ),
            child: CircleAvatar(
              radius: 60,
              backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              backgroundImage: imageUrl != null
                  ? NetworkImage(imageUrl)
                  : null,
              child: _isUploadingImage
                  ? const CircularProgressIndicator()
                  : (imageUrl == null)
                      ? Icon(
                          Icons.person,
                          size: 60,
                          color: Theme.of(context).colorScheme.primary,
                        )
                      : null,
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: CircleAvatar(
            radius: 20,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: IconButton(
              icon: const Icon(
                Icons.camera_alt,
                size: 18,
                color: Colors.white,
              ),
              onPressed: _isUploadingImage ? null : () => _showImageSourceDialog(user),
              padding: EdgeInsets.zero,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showImageSourceDialog(User user) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تحديث الصورة الشخصية'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('الكاميرا'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadImage(ImageSource.camera, user);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('المعرض'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadImage(ImageSource.gallery, user);
              },
            ),
            if (user.imageLink != null && user.imageLink!.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('حذف الصورة', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _deleteProfileImage(user);
                },
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndUploadImage(ImageSource source, User user) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      setState(() {
        _isUploadingImage = true;
      });

      // Upload to Cloudinary
      final imageUrl = await _cloudinaryService.uploadImage(
        File(pickedFile.path),
        user.id,
      );

      if (imageUrl == null) {
        throw Exception('فشل في رفع الصورة');
      }

      // Update user profile in database
      final dbService = DatabaseService();
      await dbService.updateUserProfileImage(user.id, imageUrl);

      // Update user image directly in AuthProvider
      if (mounted) {
        final authProvider = context.read<AuthProvider>();
        authProvider.updateUserImage(imageUrl);

        setState(() {
          _imageKey++; // Increment key to force image reload
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تحديث الصورة الشخصية بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
      }
    }
  }

  Future<void> _deleteProfileImage(User user) async {
    try {
      setState(() {
        _isUploadingImage = true;
      });

      // Update user profile in database
      final dbService = DatabaseService();
      await dbService.updateUserProfileImage(user.id, null);

      // Update user image directly in AuthProvider
      if (mounted) {
        final authProvider = context.read<AuthProvider>();
        authProvider.updateUserImage(null);

        setState(() {
          _imageKey++; // Increment key to force image reload
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حذف الصورة الشخصية'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
      }
    }
  }

  /// Show full-screen image viewer
  void _showFullScreenImage(String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(
                      Icons.error,
                      color: Colors.white,
                      size: 64,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfoCard(User user) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name Field with icon
          Row(
            children: [
              Icon(
                Icons.person,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _isEditing
                    ? TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'الاسم',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'الرجاء إدخال الاسم';
                          }
                          return null;
                        },
                      )
                    : Text(
                        user.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                      ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Email Field with icon
          Row(
            children: [
              Icon(
                Icons.email,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  user.email,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Phone Field with icon
          Row(
            children: [
              if (!_isEditing)
                Icon(
                  Icons.phone,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
              const SizedBox(width: 12),
              Expanded(
                child: _isEditing
                    ? Row(
                        textDirection: TextDirection.ltr,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Country Code Dropdown (Left side)
                          SizedBox(
                            width: 120,
                            child: Container(
                              height: 56,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedCountryCode,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                  items: _countryCodes.map((country) {
                                    return DropdownMenuItem<String>(
                                      value: country['code'],
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            country['flag']!,
                                            style: const TextStyle(fontSize: 18),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            country['code']!,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                            ),
                                            textDirection: TextDirection.ltr,
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    if (newValue != null) {
                                      setState(() {
                                        _selectedCountryCode = newValue;
                                      });
                                    }
                                  },
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Phone Number Input (Right side)
                          Expanded(
                            child: TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              textDirection: TextDirection.ltr,
                              decoration: const InputDecoration(
                                labelText: 'رقم الهاتف',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'الرجاء إدخال رقم الهاتف';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      )
                    : Text(
                        '${user.countryCode} ${user.phone}',
                        style: Theme.of(context).textTheme.bodyLarge,
                        textDirection: TextDirection.ltr,
                        textAlign: TextAlign.right,
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalDetailsCard(User user) {
    return CustomCard(
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.info,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Text(
                'تفاصيل الحساب',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          _buildReadOnlyField(
            label: 'نوع الحساب',
            value: _getRoleDisplayName(user.role),
            icon: _getRoleIcon(user.role),
          ),
          const SizedBox(height: 12),
          
          _buildReadOnlyField(
            label: 'تاريخ الإنشاء',
            value: _formatDate(user.createdAt),
            icon: Icons.calendar_today,
          ),
        ],
      ),
    );
  }

  Widget _buildRoleSpecificInfo(User user) {
    switch (user.role) {
      case UserRole.teacher:
        return _buildTeacherInfo();
      case UserRole.student:
        return _buildStudentInfo();
      
    }
  }

  Widget _buildTeacherInfo() {
    if (_isLoadingTeacherData) {
      return const CustomCard(
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    return CustomCard(
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.school,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Text(
                'معلومات المعلم',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          _buildReadOnlyField(
            label: 'عدد الدورات',
            value: _coursesCount > 0 ? '$_coursesCount ${_coursesCount == 1 ? 'دورة' : _coursesCount == 2 ? 'دورتان' : 'دورات'}' : 'لا توجد دورات',
            icon: Icons.book,
          ),
          const SizedBox(height: 12),
          
          _buildReadOnlyField(
            label: 'عدد الطلاب',
            value: _studentsCount > 0 ? '$_studentsCount ${_studentsCount == 1 ? 'طالب' : _studentsCount == 2 ? 'طالبان' : 'طلاب'}' : 'لا يوجد طلاب',
            icon: Icons.group,
          ),
          const SizedBox(height: 12),
          
          _buildReadOnlyField(
            label: 'التخصص',
            value: 'تحفيظ القرآن الكريم',
            icon: Icons.library_books,
          ),
        ],
      ),
    );
  }

  Widget _buildStudentInfo() {
    if (_isLoadingStudentData) {
      return const CustomCard(
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Get student data
    final quranLevel = _studentData?['Student']['quran_level'] as String?;
    final moralLevel = _studentData?['Student']['moral_level'] as String?;
    final revisionLevel = _studentData?['Student']['revision_level'] as String?;
    final payDeadlineDate = _studentData?['Student']['pay_deadline_date'] as String?;
    final memorizedContent = _studentData?['Student']['memorized_content'] as Map<String, dynamic>?;
    
    // Convert levels to text
    final quranLevelText = _getQuranLevelText(quranLevel);
    final moralLevelText = _getMoralLevelText(moralLevel);
    final revisionLevelText = _getRevisionLevelText(revisionLevel);
    
    // Format pay deadline date
    final payDeadlineText = payDeadlineDate != null ? _formatDate(DateTime.parse(payDeadlineDate)) : 'غير محدد';
    
    return CustomCard(
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.school,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Text(
                'معلومات الطالب',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          _buildReadOnlyField(
            label: 'مستوى القرآن',
            value: quranLevelText,
            icon: Icons.menu_book,
          ),
          const SizedBox(height: 12),
          
          _buildReadOnlyField(
            label: 'المستوى الأخلاقي',
            value: moralLevelText,
            icon: Icons.favorite,
          ),
          const SizedBox(height: 12),
          
          _buildReadOnlyField(
            label: 'مستوى المراجعة',
            value: revisionLevelText,
            icon: Icons.refresh,
          ),
          const SizedBox(height: 12),
          
          // Memorized content - show detailed list
          _buildMemorizedContentSection(memorizedContent),
          const SizedBox(height: 12),
          
          _buildReadOnlyField(
            label: 'الموعد النهائي للدفع',
            value: payDeadlineText,
            icon: Icons.calendar_today,
            valueColor: payDeadlineDate != null && DateTime.parse(payDeadlineDate).isBefore(DateTime.now()) ? Colors.red : null,
          ),
        ],
      ),
    );
  }
  
  String _getQuranLevelText(String? level) {
    if (level == null) return 'غير محدد';
    switch (level) {
      case 'ممتاز': return 'ممتاز';
      case 'جيد جدا': return 'جيد جداً';
      case 'جيد': return 'جيد';
      case 'ضعيف': return 'ضعيف';
      default: return level;
    }
  }
  
  String _getMoralLevelText(String? level) {
    if (level == null) return 'غير محدد';
    switch (level) {
      case 'محترم جدا': return 'محترم جداً';
      case 'محترم': return 'محترم';
      case 'اعادة سلوك': return 'إعادة سلوك';
      default: return level;
    }
  }
  
  String _getRevisionLevelText(String? level) {
    if (level == null) return 'غير محدد';
    switch (level) {
      case 'راقي': return 'راقي';
      case 'متوسط': return 'متوسط';
      case 'اعادة الحفظ': return 'إعادة الحفظ';
      default: return level;
    }
  }
  
  /// Build the memorized content section with expandable list
  Widget _buildMemorizedContentSection(Map<String, dynamic>? memorizedContent) {
    final ranges = memorizedContent?['ranges'] as List<dynamic>?;
    
    if (ranges == null || ranges.isEmpty) {
      return _buildReadOnlyField(
        label: 'المحفوظات من القرآن',
        value: 'لا توجد محفوظات مسجلة',
        icon: Icons.library_books,
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.library_books,
              size: 20,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'المحفوظات من القرآن',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
              ),
            ),
            Text(
              '${ranges.length} نطاق',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: ranges.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
            ),
            itemBuilder: (context, index) {
              final range = ranges[index] as Map<String, dynamic>;
              final rangeText = _formatMemorizedRange(range);
              
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        rangeText,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
  
  /// Map chapter number to Arabic name
  String _getChapterName(int chapterNumber) {
    const chapters = [
      'الفاتحة', 'البقرة', 'آل عمران', 'النساء', 'المائدة', 'الأنعام', 'الأعراف',
      'الأنفال', 'التوبة', 'يونس', 'هود', 'يوسف', 'الرعد', 'إبراهيم', 'الحجر',
      'النحل', 'الإسراء', 'الكهف', 'مريم', 'طه', 'الأنبياء', 'الحج', 'المؤمنون',
      'النور', 'الفرقان', 'الشعراء', 'النمل', 'القصص', 'العنكبوت', 'الروم',
      'لقمان', 'السجدة', 'الأحزاب', 'سبأ', 'فاطر', 'يس', 'الصافات', 'ص',
      'الزمر', 'غافر', 'فصلت', 'الشورى', 'الزخرف', 'الدخان', 'الجاثية',
      'الأحقاف', 'محمد', 'الفتح', 'الحجرات', 'ق', 'الذاريات', 'الطور',
      'النجم', 'القمر', 'الرحمن', 'الواقعة', 'الحديد', 'المجادلة', 'الحشر',
      'الممتحنة', 'الصف', 'الجمعة', 'المنافقون', 'التغابن', 'الطلاق', 'التحريم',
      'الملك', 'القلم', 'الحاقة', 'المعارج', 'نوح', 'الجن', 'المزمل',
      'المدثر', 'القيامة', 'الإنسان', 'المرسلات', 'النبأ', 'النازعات', 'عبس',
      'التكوير', 'الانفطار', 'المطففين', 'الانشقاق', 'البروج', 'الطارق',
      'الأعلى', 'الغاشية', 'الفجر', 'البلد', 'الشمس', 'الليل', 'الضحى',
      'الشرح', 'التين', 'العلق', 'القدر', 'البينة', 'الزلزلة', 'العاديات',
      'القارعة', 'التكاثر', 'العصر', 'الهمزة', 'الفيل', 'قريش', 'الماعون',
      'الكوثر', 'الكافرون', 'النصر', 'المسد', 'الإخلاص', 'الفلق', 'الناس'
    ];
    
    if (chapterNumber >= 1 && chapterNumber <= 114) {
      return chapters[chapterNumber - 1];
    }
    return 'سورة $chapterNumber';
  }
  
  /// Format a single memorization range
  String _formatMemorizedRange(Map<String, dynamic> range) {
    final fromChapter = range['fromChapter'] as int?;
    final toChapter = range['toChapter'] as int?;
    final fromVerse = range['fromVerse'] as int?;
    final toVerse = range['toVerse'] as int?;
    
    if (fromChapter == null || toChapter == null || fromVerse == null || toVerse == null) {
      return 'نطاق غير صالح';
    }
    
    final fromChapterName = _getChapterName(fromChapter);
    final toChapterName = _getChapterName(toChapter);
    
    // Same chapter
    if (fromChapter == toChapter) {
      if (fromVerse == toVerse) {
        return 'سورة $fromChapterName - الآية $fromVerse';
      } else {
        return 'سورة $fromChapterName - من الآية $fromVerse إلى $toVerse';
      }
    } else {
      // Different chapters
      return 'من سورة $fromChapterName ($fromVerse) إلى سورة $toChapterName ($toVerse)';
    }
  }

  Widget _buildReadOnlyField({
    required String label,
    required String value,
    IconData? icon,
    Color? valueColor,
  }) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: valueColor,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDeleteAccountButton(AuthProvider authProvider) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () async {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('حذف الحساب'),
              content: const Text('هل أنت متأكد من رغبتك في حذف حسابك نهائياً؟ \n\nهذه العملية لا يمكن التراجع عنها.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                  ),
                  child: const Text('حذف الحساب'),
                ),
              ],
            ),
          );

          if (confirmed == true) {
            try {
              await authProvider.deleteAccount();
              // Navigate to login screen and clear the navigation stack
              if (mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/',
                  (route) => false,
                );
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(e.toString()),
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                );
              }
            }
          }
        },
        icon: const Icon(Icons.delete_forever),
        label: const Text('حذف الحساب'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.error,
          side: BorderSide(color: Theme.of(context).colorScheme.error),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(AuthProvider authProvider) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () async {
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
            await authProvider.logout();
            // Navigate to login screen and clear the navigation stack
            if (mounted) {
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/',
                (route) => false,
              );
            }
          }
        },
        icon: const Icon(Icons.logout),
        label: const Text('تسجيل الخروج'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.error,
          side: BorderSide(color: Theme.of(context).colorScheme.error),
        ),
      ),
    );
  }

  void _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      try {
        await context.read<AuthProvider>().updateProfile(
              name: _nameController.text.trim(),
              phone: _phoneController.text.trim(),
              countryCode: _selectedCountryCode,
            );

        setState(() {
          _isEditing = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم حفظ البيانات بنجاح'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطأ في حفظ البيانات: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  String _getRoleDisplayName(UserRole role) {
    switch (role) {
      case UserRole.teacher:
        return 'معلم';
      case UserRole.student:
        return 'طالب';
      
      
    }
  }

  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.teacher:
        return Icons.school;
      case UserRole.student:
        return Icons.person;
      
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}