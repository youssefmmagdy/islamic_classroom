import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user.dart';
import '../../models/course.dart';
import '../../providers/auth_provider.dart';
import '../../services/database_service.dart';

class StudentProfileScreen extends StatefulWidget {
  final Map<String, dynamic> student;
  final String courseId;
  final Course course;

  const StudentProfileScreen({
    super.key,
    required this.student,
    required this.courseId,
    required this.course,
  });

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  final DatabaseService _databaseService = DatabaseService();
  bool _isLoading = true;
  bool _isEditing = false;
  
  // Student data
  String? _payDeadlineDate;
  String? _quranLevel;
  String? _moralLevel;
  String? _revisionLevel;
  Map<String, dynamic>? _memorizedContent;

  // Controllers
  final _payDeadlineDateController = TextEditingController();
  String _selectedQuranLevel = 'ممتاز';
  String _selectedMoralLevel = 'محترم جدا';
  String _selectedRevisionLevel = 'راقي';
  
  // Level options
  static const List<String> quranLevelOptions = ['ممتاز', 'جيد جدا', 'جيد', 'ضعيف'];
  static const List<String> moralLevelOptions = ['محترم جدا', 'محترم', 'اعادة سلوك'];
  static const List<String> revisionLevelOptions = ['راقي', 'متوسط', 'اعادة الحفظ'];
  
  // Quran memorization ranges (chapter:verse to chapter:verse)
  List<Map<String, dynamic>> _memorizedRanges = [];
  
  // Quran chapters (Surah) - 114 chapters
  static const List<Map<String, dynamic>> _quranChapters = [
    {'number': 1, 'name': 'الفاتحة', 'verses': 7},
    {'number': 2, 'name': 'البقرة', 'verses': 286},
    {'number': 3, 'name': 'آل عمران', 'verses': 200},
    {'number': 4, 'name': 'النساء', 'verses': 176},
    {'number': 5, 'name': 'المائدة', 'verses': 120},
    {'number': 6, 'name': 'الأنعام', 'verses': 165},
    {'number': 7, 'name': 'الأعراف', 'verses': 206},
    {'number': 8, 'name': 'الأنفال', 'verses': 75},
    {'number': 9, 'name': 'التوبة', 'verses': 129},
    {'number': 10, 'name': 'يونس', 'verses': 109},
    {'number': 11, 'name': 'هود', 'verses': 123},
    {'number': 12, 'name': 'يوسف', 'verses': 111},
    {'number': 13, 'name': 'الرعد', 'verses': 43},
    {'number': 14, 'name': 'إبراهيم', 'verses': 52},
    {'number': 15, 'name': 'الحجر', 'verses': 99},
    {'number': 16, 'name': 'النحل', 'verses': 128},
    {'number': 17, 'name': 'الإسراء', 'verses': 111},
    {'number': 18, 'name': 'الكهف', 'verses': 110},
    {'number': 19, 'name': 'مريم', 'verses': 98},
    {'number': 20, 'name': 'طه', 'verses': 135},
    {'number': 21, 'name': 'الأنبياء', 'verses': 112},
    {'number': 22, 'name': 'الحج', 'verses': 78},
    {'number': 23, 'name': 'المؤمنون', 'verses': 118},
    {'number': 24, 'name': 'النور', 'verses': 64},
    {'number': 25, 'name': 'الفرقان', 'verses': 77},
    {'number': 26, 'name': 'الشعراء', 'verses': 227},
    {'number': 27, 'name': 'النمل', 'verses': 93},
    {'number': 28, 'name': 'القصص', 'verses': 88},
    {'number': 29, 'name': 'العنكبوت', 'verses': 69},
    {'number': 30, 'name': 'الروم', 'verses': 60},
    {'number': 31, 'name': 'لقمان', 'verses': 34},
    {'number': 32, 'name': 'السجدة', 'verses': 30},
    {'number': 33, 'name': 'الأحزاب', 'verses': 73},
    {'number': 34, 'name': 'سبأ', 'verses': 54},
    {'number': 35, 'name': 'فاطر', 'verses': 45},
    {'number': 36, 'name': 'يس', 'verses': 83},
    {'number': 37, 'name': 'الصافات', 'verses': 182},
    {'number': 38, 'name': 'ص', 'verses': 88},
    {'number': 39, 'name': 'الزمر', 'verses': 75},
    {'number': 40, 'name': 'غافر', 'verses': 85},
    {'number': 41, 'name': 'فصلت', 'verses': 54},
    {'number': 42, 'name': 'الشورى', 'verses': 53},
    {'number': 43, 'name': 'الزخرف', 'verses': 89},
    {'number': 44, 'name': 'الدخان', 'verses': 59},
    {'number': 45, 'name': 'الجاثية', 'verses': 37},
    {'number': 46, 'name': 'الأحقاف', 'verses': 35},
    {'number': 47, 'name': 'محمد', 'verses': 38},
    {'number': 48, 'name': 'الفتح', 'verses': 29},
    {'number': 49, 'name': 'الحجرات', 'verses': 18},
    {'number': 50, 'name': 'ق', 'verses': 45},
    {'number': 51, 'name': 'الذاريات', 'verses': 60},
    {'number': 52, 'name': 'الطور', 'verses': 49},
    {'number': 53, 'name': 'النجم', 'verses': 62},
    {'number': 54, 'name': 'القمر', 'verses': 55},
    {'number': 55, 'name': 'الرحمن', 'verses': 78},
    {'number': 56, 'name': 'الواقعة', 'verses': 96},
    {'number': 57, 'name': 'الحديد', 'verses': 29},
    {'number': 58, 'name': 'المجادلة', 'verses': 22},
    {'number': 59, 'name': 'الحشر', 'verses': 24},
    {'number': 60, 'name': 'الممتحنة', 'verses': 13},
    {'number': 61, 'name': 'الصف', 'verses': 14},
    {'number': 62, 'name': 'الجمعة', 'verses': 11},
    {'number': 63, 'name': 'المنافقون', 'verses': 11},
    {'number': 64, 'name': 'التغابن', 'verses': 18},
    {'number': 65, 'name': 'الطلاق', 'verses': 12},
    {'number': 66, 'name': 'التحريم', 'verses': 12},
    {'number': 67, 'name': 'الملك', 'verses': 30},
    {'number': 68, 'name': 'القلم', 'verses': 52},
    {'number': 69, 'name': 'الحاقة', 'verses': 52},
    {'number': 70, 'name': 'المعارج', 'verses': 44},
    {'number': 71, 'name': 'نوح', 'verses': 28},
    {'number': 72, 'name': 'الجن', 'verses': 28},
    {'number': 73, 'name': 'المزمل', 'verses': 20},
    {'number': 74, 'name': 'المدثر', 'verses': 56},
    {'number': 75, 'name': 'القيامة', 'verses': 40},
    {'number': 76, 'name': 'الإنسان', 'verses': 31},
    {'number': 77, 'name': 'المرسلات', 'verses': 50},
    {'number': 78, 'name': 'النبأ', 'verses': 40},
    {'number': 79, 'name': 'النازعات', 'verses': 46},
    {'number': 80, 'name': 'عبس', 'verses': 42},
    {'number': 81, 'name': 'التكوير', 'verses': 29},
    {'number': 82, 'name': 'الإنفطار', 'verses': 19},
    {'number': 83, 'name': 'المطففين', 'verses': 36},
    {'number': 84, 'name': 'الإنشقاق', 'verses': 25},
    {'number': 85, 'name': 'البروج', 'verses': 22},
    {'number': 86, 'name': 'الطارق', 'verses': 17},
    {'number': 87, 'name': 'الأعلى', 'verses': 19},
    {'number': 88, 'name': 'الغاشية', 'verses': 26},
    {'number': 89, 'name': 'الفجر', 'verses': 30},
    {'number': 90, 'name': 'البلد', 'verses': 20},
    {'number': 91, 'name': 'الشمس', 'verses': 15},
    {'number': 92, 'name': 'الليل', 'verses': 21},
    {'number': 93, 'name': 'الضحى', 'verses': 11},
    {'number': 94, 'name': 'الشرح', 'verses': 8},
    {'number': 95, 'name': 'التين', 'verses': 8},
    {'number': 96, 'name': 'العلق', 'verses': 19},
    {'number': 97, 'name': 'القدر', 'verses': 5},
    {'number': 98, 'name': 'البينة', 'verses': 8},
    {'number': 99, 'name': 'الزلزلة', 'verses': 8},
    {'number': 100, 'name': 'العاديات', 'verses': 11},
    {'number': 101, 'name': 'القارعة', 'verses': 11},
    {'number': 102, 'name': 'التكاثر', 'verses': 8},
    {'number': 103, 'name': 'العصر', 'verses': 3},
    {'number': 104, 'name': 'الهمزة', 'verses': 9},
    {'number': 105, 'name': 'الفيل', 'verses': 5},
    {'number': 106, 'name': 'قريش', 'verses': 4},
    {'number': 107, 'name': 'الماعون', 'verses': 7},
    {'number': 108, 'name': 'الكوثر', 'verses': 3},
    {'number': 109, 'name': 'الكافرون', 'verses': 6},
    {'number': 110, 'name': 'النصر', 'verses': 3},
    {'number': 111, 'name': 'المسد', 'verses': 5},
    {'number': 112, 'name': 'الإخلاص', 'verses': 4},
    {'number': 113, 'name': 'الفلق', 'verses': 5},
    {'number': 114, 'name': 'الناس', 'verses': 6},
  ];

  @override
  void initState() {
    super.initState();
    _loadStudentData();
  }

  @override
  void dispose() {
    _payDeadlineDateController.dispose();
    super.dispose();
  }

  Future<void> _loadStudentData() async {
    setState(() => _isLoading = true);

    try {
      final studentData = await _databaseService.getStudentProfile(
        widget.student['id'] as String,
      );
      if (studentData == null) {
        throw Exception('فشل في تحميل بيانات الطالب');
      }

      setState(() {
        _payDeadlineDate = studentData['Student']['pay_deadline_date'];
        _quranLevel = studentData['Student']['quran_level'] ?? 'ممتاز';
        _moralLevel = studentData['Student']['moral_level'] ?? 'محترم جدا';
        _revisionLevel = studentData['Student']['revision_level'] ?? 'راقي';
        _memorizedContent = (studentData['Student']['memorized_content'] as Map<String, dynamic>?) ?? {};

        _payDeadlineDateController.text = _payDeadlineDate ?? '';
        _selectedQuranLevel = _quranLevel ?? 'ممتاز';
        _selectedMoralLevel = _moralLevel ?? 'محترم جدا';
        _selectedRevisionLevel = _revisionLevel ?? 'راقي';
        
        // Load memorized ranges
        if (_memorizedContent?['ranges'] is List) {
          _memorizedRanges = List<Map<String, dynamic>>.from(
            (_memorizedContent!['ranges'] as List).map((range) => Map<String, dynamic>.from(range)),
          );
        } else {
          _memorizedRanges = [];
        }
        
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading student data: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل في تحميل بيانات الطالب: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveChanges() async {
    try {
      setState(() => _isLoading = true);

      final payDeadlineDate = _payDeadlineDateController.text.trim();

      final result = await _databaseService.updateStudentProfile(
        studentId: widget.student['id'] as String,
        payDeadlineDate: payDeadlineDate,
        quranLevel: _selectedQuranLevel,
        moralLevel: _selectedMoralLevel,
        revisionLevel: _selectedRevisionLevel,
        memorizedContent: {'ranges': _memorizedRanges},
      );

      if (mounted) {
        if (result['success']) {
          setState(() {
            _isEditing = false;
            _payDeadlineDate = payDeadlineDate;
            _quranLevel = _selectedQuranLevel;
            _moralLevel = _selectedMoralLevel;
            _revisionLevel = _selectedRevisionLevel;
            _memorizedContent = {'ranges': _memorizedRanges};
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم حفظ التغييرات بنجاح'),
              backgroundColor: Colors.green,
            ),
          );
          
          await _loadStudentData();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'فشل في حفظ التغييرات'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.read<AuthProvider>().currentUser!;
    final isTeacher = currentUser.role == UserRole.teacher;
    
    final profileImage = widget.student['image_link'] as String?;
    final name = widget.student['name'] as String? ?? 'طالب';
    final email = widget.student['email'] as String?;
    final phone = widget.student['phone'] as String?;
    final countryCode = widget.student['country_code'] as String? ?? '+966';

    return Scaffold(
      appBar: AppBar(
        title: const Text('ملف الطالب'),
        centerTitle: true,
        actions: [
          if (isTeacher && !_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
              tooltip: 'تعديل',
            ),
          if (isTeacher && _isEditing) ...[
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                // Reload data to reset any changes
                _loadStudentData();
                setState(() {
                  _isEditing = false;
                });
              },
              tooltip: 'إلغاء',
            ),
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _isLoading ? null : _saveChanges,
              tooltip: 'حفظ',
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStudentData,
              child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Profile Header
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                            backgroundImage: profileImage != null && profileImage.isNotEmpty
                                ? NetworkImage(profileImage)
                                : null,
                            child: profileImage == null || profileImage.isEmpty
                                ? Text(
                                    name[0].toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 40,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (email != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.email, size: 16),
                                const SizedBox(width: 4),
                                Text(email),
                              ],
                            ),
                          ],
                          if (phone != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.phone, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  '$countryCode $phone',
                                  textDirection: TextDirection.ltr,
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Pay Deadline Date Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'الموعد النهائي للدفع',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (_isEditing)
                            TextField(
                              controller: _payDeadlineDateController,
                              decoration: const InputDecoration(
                                labelText: 'الموعد النهائي للدفع',
                                hintText: 'YYYY-MM-DD',
                                border: OutlineInputBorder(),
                              ),
                              readOnly: true,
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: _payDeadlineDate != null 
                                      ? DateTime.parse(_payDeadlineDate!)
                                      : DateTime.now(),
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(const Duration(days: 365)),
                                );
                                if (date != null) {
                                  setState(() {
                                    _payDeadlineDateController.text = date.toString().split(' ')[0];
                                  });
                                }
                              },
                            )
                          else
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _payDeadlineDate != null && DateTime.parse(_payDeadlineDate!).isBefore(DateTime.now())
                                    ? Colors.red.withOpacity(0.1)
                                    : Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _payDeadlineDate ?? 'غير محدد',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: _payDeadlineDate != null && DateTime.parse(_payDeadlineDate!).isBefore(DateTime.now())
                                          ? Colors.red
                                          : Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Levels Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.stars,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'المستويات',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          
                          // Quran Level
                          Text(
                            'مستوى القرآن',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (_isEditing)
                            DropdownButtonFormField<String>(
                              value: _selectedQuranLevel,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                              ),
                              items: quranLevelOptions.map((level) {
                                return DropdownMenuItem(
                                  value: level,
                                  child: Text(level),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _selectedQuranLevel = value);
                                }
                              },
                            )
                          else
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _quranLevel ?? 'ممتاز',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 16),
                          
                          // Moral Level
                          Text(
                            'المستوى الأخلاقي',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (_isEditing)
                            DropdownButtonFormField<String>(
                              value: _selectedMoralLevel,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                              ),
                              items: moralLevelOptions.map((level) {
                                return DropdownMenuItem(
                                  value: level,
                                  child: Text(level),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _selectedMoralLevel = value);
                                }
                              },
                            )
                          else
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _moralLevel ?? 'محترم جدا',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 16),
                          
                          // Revision Level
                          Text(
                            'مستوى المراجعة',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (_isEditing)
                            DropdownButtonFormField<String>(
                              value: _selectedRevisionLevel,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                              ),
                              items: revisionLevelOptions.map((level) {
                                return DropdownMenuItem(
                                  value: level,
                                  child: Text(level),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _selectedRevisionLevel = value);
                                }
                              },
                            )
                          else
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.tertiaryContainer.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _revisionLevel ?? 'راقي',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.onTertiaryContainer,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Memorized Content Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.menu_book,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'المحفوظات من القرآن',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (_isEditing)
                                IconButton(
                                  icon: const Icon(Icons.add_circle, color: Colors.green),
                                  onPressed: () {
                                    setState(() {
                                      _memorizedRanges.add({
                                        'fromChapter': 1,
                                        'fromVerse': 1,
                                        'toChapter': 1,
                                        'toVerse': 1,
                                      });
                                    });
                                  },
                                  tooltip: 'إضافة نطاق جديد',
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'عدد النطاقات: ${_memorizedRanges.length}',
                            style: TextStyle(
                              fontSize: 16,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (_memorizedRanges.isEmpty)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Text(
                                  _isEditing
                                      ? 'اضغط + لإضافة نطاق محفوظ'
                                      : 'لا توجد محفوظات مسجلة',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                  ),
                                ),
                              ),
                            )
                          else
                            ...List.generate(_memorizedRanges.length, (index) {
                              final range = _memorizedRanges[index];
                              return _buildMemorizedRangeItem(context, range, index);
                            }),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildMemorizedRangeItem(BuildContext context, Map<String, dynamic> range, int index) {
    final fromChapter = range['fromChapter'] as int? ?? 1;
    final fromVerse = range['fromVerse'] as int? ?? 1;
    final toChapter = range['toChapter'] as int? ?? 1;
    final toVerse = range['toVerse'] as int? ?? 1;

    final fromChapterName = _quranChapters.firstWhere(
      (c) => c['number'] == fromChapter,
      orElse: () => {'name': 'غير معروف'},
    )['name'];
    
    final toChapterName = _quranChapters.firstWhere(
      (c) => c['number'] == toChapter,
      orElse: () => {'name': 'غير معروف'},
    )['name'];

    if (_isEditing) {
      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'النطاق ${index + 1}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                    onPressed: () {
                      setState(() {
                        _memorizedRanges.removeAt(index);
                      });
                    },
                    tooltip: 'حذف',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text('من:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<int>(
                      value: fromChapter,
                      decoration: const InputDecoration(
                        labelText: 'السورة',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        isDense: true,
                      ),
                      items: _quranChapters.map((chapter) {
                        return DropdownMenuItem<int>(
                          value: chapter['number'] as int,
                          child: Text(
                            '${chapter['number']}. ${chapter['name']}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _memorizedRanges[index]['fromChapter'] = value;
                            _memorizedRanges[index]['fromVerse'] = 1;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: fromVerse.clamp(
                        1,
                        (_quranChapters.firstWhere((c) => c['number'] == fromChapter)['verses'] as int),
                      ),
                      decoration: const InputDecoration(
                        labelText: 'الآية',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        isDense: true,
                      ),
                      items: List.generate(
                        _quranChapters.firstWhere((c) => c['number'] == fromChapter)['verses'] as int,
                        (i) => DropdownMenuItem<int>(
                          value: i + 1,
                          child: Text('${i + 1}', style: const TextStyle(fontSize: 12)),
                        ),
                      ),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _memorizedRanges[index]['fromVerse'] = value;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text('إلى:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<int>(
                      value: toChapter,
                      decoration: const InputDecoration(
                        labelText: 'السورة',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        isDense: true,
                      ),
                      items: _quranChapters.map((chapter) {
                        return DropdownMenuItem<int>(
                          value: chapter['number'] as int,
                          child: Text(
                            '${chapter['number']}. ${chapter['name']}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _memorizedRanges[index]['toChapter'] = value;
                            _memorizedRanges[index]['toVerse'] = 1;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: toVerse.clamp(
                        1,
                        (_quranChapters.firstWhere((c) => c['number'] == toChapter)['verses'] as int),
                      ),
                      decoration: const InputDecoration(
                        labelText: 'الآية',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        isDense: true,
                      ),
                      items: List.generate(
                        _quranChapters.firstWhere((c) => c['number'] == toChapter)['verses'] as int,
                        (i) => DropdownMenuItem<int>(
                          value: i + 1,
                          child: Text('${i + 1}', style: const TextStyle(fontSize: 12)),
                        ),
                      ),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _memorizedRanges[index]['toVerse'] = value;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    } else {
      // View mode - show summary
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'من: $fromChapterName ($fromChapter:$fromVerse)',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'إلى: $toChapterName ($toChapter:$toVerse)',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }
}

