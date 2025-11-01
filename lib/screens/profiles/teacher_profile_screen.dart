import 'package:flutter/material.dart';
import 'package:my_app/services/database_service.dart';

/// Teacher profile screen - allows students to view teacher information
class TeacherProfileScreen extends StatefulWidget {
  final String teacherId;

  const TeacherProfileScreen({
    super.key,
    required this.teacherId,
  });

  @override
  State<TeacherProfileScreen> createState() => _TeacherProfileScreenState();
}

class _TeacherProfileScreenState extends State<TeacherProfileScreen> {
  final DatabaseService _databaseService = DatabaseService();
  bool _isLoading = true;
  Map<String, dynamic>? _teacherData;
  List<Map<String, dynamic>> _courses = [];

  @override
  void initState() {
    super.initState();
    _loadTeacherData();
  }

  Future<void> _loadTeacherData() async {
    setState(() => _isLoading = true);

    try {
      // Get teacher basic information
      final teacherData = await _databaseService.getUserById(widget.teacherId);
      
      // Get courses taught by this teacher
      final courses = await _databaseService.getTeacherCourses(widget.teacherId);

      setState(() {
        _teacherData = teacherData;
        _courses = courses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل في تحميل بيانات المعلم: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('معلومات المعلم'),
        backgroundColor: const Color(0xFF5BA092),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _teacherData == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text(
                        'لم يتم العثور على بيانات المعلم',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadTeacherData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5BA092),
                        ),
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadTeacherData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Profile Header Card
                        Center(
                          child: Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                children: [
                                  // Profile Image
                                  CircleAvatar(
                                    radius: 60,
                                    backgroundColor: const Color(0xFF5BA092),
                                    backgroundImage: _teacherData!['image_link'] != null
                                        ? NetworkImage(_teacherData!['image_link'])
                                        : null,
                                    child: _teacherData!['image_link'] == null
                                        ? const Icon(Icons.person, size: 60, color: Colors.white)
                                        : null,
                                  ),
                                  const SizedBox(height: 16),
                                  // Name
                                  Text(
                                    _teacherData!['name'] ?? 'غير متوفر',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  // Role Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF5BA092),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Text(
                                      'معلم',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Contact Information Card
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'معلومات الاتصال',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF5BA092),
                                  ),
                                ),
                                const Divider(height: 24),
                                _buildInfoRow(
                                  Icons.email,
                                  'البريد الإلكتروني',
                                  _teacherData!['email'] ?? 'غير متوفر',
                                ),
                                const SizedBox(height: 12),
                                _buildInfoRow(
                                  Icons.phone,
                                  'رقم الهاتف',
                                  '${_teacherData!['phone']} ${_teacherData!['country_code'][1]}${_teacherData!['country_code'][2]}+',
                                ),
                                const SizedBox(height: 12),
                                _buildInfoRow(
                                  Icons.person_outline,
                                  'الجنس',
                                  _teacherData!['gender'] == 'male' ? 'ذكر' : 'أنثى',
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Courses Card
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Text(
                                      'الحلقات التي يدرسها',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF5BA092),
                                      ),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF5BA092).withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        '${_courses.length}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF5BA092),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 24),
                                if (_courses.isEmpty)
                                  const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Text(
                                        'لا توجد حلقات حالياً',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ),
                                  )
                                else
                                  ...List.generate(
                                    _courses.length,
                                    (index) => _buildCourseItem(_courses[index]),
                                  ),
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

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF5BA092), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCourseItem(Map<String, dynamic> course) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF5BA092).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF5BA092).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF5BA092),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.menu_book,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course['title'] ?? 'بدون عنوان',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (course['desc'] != null && course['desc'].toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      course['desc'],
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
