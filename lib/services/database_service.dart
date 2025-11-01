import 'dart:convert';
import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Database operations helper for the new inheritance-based schema
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  // Random number generator for background images
  final _random = Random();

  SupabaseClient get client => Supabase.instance.client;

  // Course Management

  /// Create a new course (teachers only)
  Future<Map<String, dynamic>> createCourse({
    required String title,
    required String teacherId,
    String? desc,
  }) async {
    try {
      // First, check if user exists in User table
      final userCheck = await client
          .from('User')
          .select('id')
          .eq('id', teacherId)
          .maybeSingle();

      if (userCheck == null) {
        return {
          'success': false,
          'message':
              'المستخدم غير موجود. يرجى تسجيل الخروج ثم الدخول مرة أخرى.',
        };
      }

      // Then check if teacher exists in Teacher table
      final teacherCheck = await client
          .from('Teacher')
          .select('id')
          .eq('id', teacherId)
          .maybeSingle();

      // If teacher doesn't exist, create the teacher record
      if (teacherCheck == null) {
        try {
          await client.from('Teacher').insert({'id': teacherId});
        } catch (e) {
          return {
            'success': false,
            'message': 'فشل في إنشاء سجل المعلم: ${e.toString()}',
          };
        }
      }

      // Generate random background image (back1 through back7)
      final randomBack = 'back${_random.nextInt(7) + 1}';

      // Now create the course
      final response = await client.from('Course').insert({
        'teacher_id': teacherId,
        'title': title,
        'desc': desc ?? '',
        'back': randomBack,
      }).select();

      return {
        'success': true,
        'data': response.isNotEmpty ? response.first : null,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'فشل في إنشاء الحلقة: ${e.toString()}',
      };
    }
  }

  /// Get courses for a teacher
  Future<List<Map<String, dynamic>>> getTeacherCourses(String teacherId) async {
    try {
      final response = await client
          .from('Course')
          .select()
          .eq('teacher_id', teacherId);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching courses: $e');
      return [];
    }
  }

  /// Delete a course (teachers only)
  Future<Map<String, dynamic>> deleteCourse(String courseId) async {
    try {

      await client.from('Course').delete().eq('id', courseId);


      return {'success': true, 'message': 'تم حذف الحلقة بنجاح'};
    } catch (e) {
      print('Error deleting course: $e');
      return {
        'success': false,
        'message': 'فشل في حذف الحلقة: ${e.toString()}',
      };
    }
  }

  /// Get a course by ID
  Future<Map<String, dynamic>?> getCourseById(String courseId) async {
    try {
      final response = await client
          .from('Course')
          .select()
          .eq('id', courseId)
          .maybeSingle();
      return response;
    } catch (e) {
      print('Error fetching course: $e');
      return null;
    }
  }

  /// Join a course (students only)
  Future<Map<String, dynamic>> joinCourse(
    String courseId,
    String studentId,
  ) async {
    try {

      // Check if student already enrolled
      final existingEnrollment = await client
          .from('Student_Course')
          .select()
          .eq('student_id', studentId)
          .eq('course_id', courseId)
          .maybeSingle();

      if (existingEnrollment != null) {
        return {'success': false, 'message': 'أنت مسجل بالفعل في هذه الحلقة'};
      }

      // First, check if student exists in Student table
      final studentCheck = await client
          .from('Student')
          .select('id')
          .eq('id', studentId)
          .maybeSingle();

      // If student doesn't exist, create the student record
      if (studentCheck == null) {
        try {
          await client.from('Student').insert({'id': studentId});
        } catch (e) {
          print('Error creating student record: $e');
          return {
            'success': false,
            'message': 'فشل في إنشاء سجل الطالب: ${e.toString()}',
          };
        }
      }
      
      // Insert into Student_Course junction table
      await client.from('Student_Course').insert({
        'student_id': studentId,
        'course_id': courseId,
      });


      return {'success': true, 'message': 'تم الانضمام إلى الحلقة بنجاح'};
    } catch (e) {
      print('Error joining course: $e');
      return {
        'success': false,
        'message': 'فشل في الانضمام إلى الحلقة: ${e.toString()}',
      };
    }
  }

  /// Get courses for a student
  Future<List<Map<String, dynamic>>> getStudentCourses(String studentId) async {
    try {
      final response = await client
          .from('Student_Course')
          .select('course_id, Course(id, title, desc, teacher_id, back)')
          .eq('student_id', studentId);

      // Extract course data from nested structure
      final courses = <Map<String, dynamic>>[];
      for (var item in response) {
        if (item['Course'] != null) {
          courses.add(item['Course'] as Map<String, dynamic>);
        }
      }

      return courses;
    } catch (e) {
      print('Error fetching student courses: $e');
      return [];
    }
  }

  /// Unenroll from a course (students only)
  Future<Map<String, dynamic>> leaveCourse(
    String courseId,
    String studentId,
  ) async {
    try {
      print('Student $studentId leaving course $courseId');

      await client
          .from('Student_Course')
          .delete()
          .eq('student_id', studentId)
          .eq('course_id', courseId);

      print('Student unenrolled from course successfully');

      return {'success': true, 'message': 'تم إلغاء التسجيل من الحلقة بنجاح'};
    } catch (e) {
      print('Error leaving course: $e');
      return {
        'success': false,
        'message': 'فشل في إلغاء التسجيل من الحلقة: ${e.toString()}',
      };
    }
  }

  /// Get students enrolled in a course from Student_Course table
  Future<List<Map<String, dynamic>>> getCourseStudents(String courseId) async {
    try {
      // Get student IDs from Student_Course table
      final studentCourseData = await client
          .from('Student_Course')
          .select('student_id')
          .eq('course_id', courseId);

      // Extract student IDs
      final studentIds = studentCourseData
          .map((sc) => sc['student_id'] as String)
          .toList();

      if (studentIds.isEmpty) {
        return [];
      }

      // Get full user data for these students
      final studentsData = await client
          .from('User')
          .select('*')
          .inFilter('id', studentIds);

      return List<Map<String, dynamic>>.from(studentsData);
    } catch (e) {
      print('Error getting course students: $e');
      return [];
    }
  }

  /// Get all courses
  Future<List<Map<String, dynamic>>> getAllCourses() async {
    try {
      final response = await client
          .from('courses')
          .select('*, teachers!inner(id, users!inner(phone, gender))');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  // Post Management

  /// Create a post in a course (teachers only)
  Future<Map<String, dynamic>> createPost({
    required String courseId,
    required String teacherId,
    required String title,
    String? desc,
  }) async {
    try {
      print('Creating post in course: $courseId by teacher: $teacherId');

      // First, verify the course exists
      final courseCheck = await client
          .from('Course')
          .select('id')
          .eq('id', courseId)
          .maybeSingle();

      if (courseCheck == null) {
        return {'success': false, 'message': 'الحلقة غير موجودة'};
      }

      // Check if teacher exists, if not create it
      final teacherCheck = await client
          .from('Teacher')
          .select('id')
          .eq('id', teacherId)
          .maybeSingle();

      if (teacherCheck == null) {
        print('Teacher not found, creating teacher record...');
        try {
          await client.from('Teacher').insert({'id': teacherId});
          print('Teacher record created successfully');
        } catch (e) {
          print('Error creating teacher record: $e');
          return {
            'success': false,
            'message': 'فشل في إنشاء سجل المعلم: ${e.toString()}',
          };
        }
      }

      final response = await client.from('Post_In_Course').insert({
        'course_id': courseId,
        'teacher_id': teacherId,
        'title': title,
        'desc': desc ?? '',
      }).select();

      print('Post created successfully: $response');

      return {
        'success': true,
        'data': response.isNotEmpty ? response.first : null,
        'message': 'تم إنشاء المنشور بنجاح',
      };
    } catch (e) {
      print('Error creating post: $e');
      return {
        'success': false,
        'message': 'فشل في إنشاء المنشور: ${e.toString()}',
      };
    }
  }

  /// Get all posts in a course with teacher information
  Future<List<Map<String, dynamic>>> getCoursePosts(String courseId) async {
    try {
      final response = await client
          .from('Post_In_Course')
          .select('*, Teacher(id, User(id, name, email, image_link))')
          .eq('course_id', courseId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching posts: $e');
      return [];
    }
  }

  /// Update a post (teachers only)
  Future<Map<String, dynamic>> updatePost({
    required String postId,
    required String courseId,
    String? title,
    String? desc,
  }) async {
    try {
      print('Updating post: $postId in course: $courseId');

      final updateData = <String, dynamic>{};
      if (title != null) updateData['title'] = title;
      if (desc != null) updateData['desc'] = desc;

      if (updateData.isEmpty) {
        return {'success': false, 'message': 'لا توجد بيانات للتحديث'};
      }

      await client
          .from('Post_In_Course')
          .update(updateData)
          .eq('id', postId)
          .eq('course_id', courseId);

      print('Post updated successfully');

      return {'success': true, 'message': 'تم تحديث المنشور بنجاح'};
    } catch (e) {
      print('Error updating post: $e');
      return {
        'success': false,
        'message': 'فشل في تحديث المنشور: ${e.toString()}',
      };
    }
  }

  /// Delete a post (teachers only)
  Future<Map<String, dynamic>> deletePost(
    String postId,
    String courseId,
  ) async {
    try {
      print('Deleting post: $postId from course: $courseId');

      await client
          .from('Post_In_Course')
          .delete()
          .eq('id', postId)
          .eq('course_id', courseId);

      print('Post deleted successfully');

      return {'success': true, 'message': 'تم حذف المنشور بنجاح'};
    } catch (e) {
      print('Error deleting post: $e');
      return {
        'success': false,
        'message': 'فشل في حذف المنشور: ${e.toString()}',
      };
    }
  }

  // Session Management

  /// Create a new session
  Future<Map<String, dynamic>> createSession({
    required String teacherId,
    required String courseId,
    required String description,
    required DateTime date,
  }) async {
    try {
      // Create the session
      final sessionResponse = await client.from('Session').insert({
        'teacher_id': teacherId,
        'course_id': courseId,
        'desc': description,
        'date': date.toIso8601String(),
      }).select();
      if (sessionResponse.isEmpty) {
        return {
          'success': false,
          'message': 'فشل في إنشاء الجلسة',
        };
      }

      final sessionId = sessionResponse.first['id'] as String;

      // Create the Attendance record for this session
      final attendanceResponse = await client.from('Attendance').insert({
        'session_id': sessionId,
        'course_id': courseId,
      }).select();

      if (attendanceResponse.isEmpty) {
        return {
          'success': false,
          'message': 'فشل في إنشاء سجل الحضور',
        };
      }

      // NOTE: Student_Attendance records are NOT created here
      // Students not in Student_Attendance table = absent
      // Students will be added when marked as attended

      return {
        'success': true,
        'data': sessionResponse.first,
        'message': 'تم إنشاء الجلسة وسجل الحضور بنجاح',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'فشل في إنشاء الجلسة: ${e.toString()}',
      };
    }
  }

  /// Update a session
  Future<Map<String, dynamic>> updateSession({
    required String sessionId,
    String? description,
    DateTime? date,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      
      if (description != null) {
        updateData['desc'] = description;
      }
      
      if (date != null) {
        updateData['date'] = date.toIso8601String();
      }

      if (updateData.isEmpty) {
        return {
          'success': false,
          'message': 'لا توجد بيانات للتحديث',
        };
      }

      final response = await client
          .from('Session')
          .update(updateData)
          .eq('id', sessionId)
          .select();

      return {
        'success': true,
        'data': response.isNotEmpty ? response.first : null,
        'message': 'تم تحديث الجلسة بنجاح',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'فشل في تحديث الجلسة: ${e.toString()}',
      };
    }
  }

  /// Delete a session and all related records
  Future<Map<String, dynamic>> deleteSession(String sessionId) async {
    try {
      // First, delete all Student_Attendance records for this session
      await client
          .from('Student_Attendance')
          .delete()
          .eq('session_id', sessionId);

      // Delete the Attendance record for this session
      await client
          .from('Attendance')
          .delete()
          .eq('session_id', sessionId);

      // Delete all assignments for this session
      await client
          .from('Assignment')
          .delete()
          .eq('session_id', sessionId);

      // Finally, delete the session itself
      await client
          .from('Session')
          .delete()
          .eq('id', sessionId);

      return {
        'success': true,
        'message': 'تم حذف الجلسة وجميع البيانات المرتبطة بها بنجاح',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'فشل في حذف الجلسة: ${e.toString()}',
      };
    }
  }

  /// Get sessions for a course
  Future<List<Map<String, dynamic>>> getCourseSessions(String courseId) async {
    try {
      final response = await client
          .from('Session')
          .select('id, date, desc, teacher_id, course_id')
          .eq('course_id', courseId)
          .order('date', ascending: false);
      final sessions = List<Map<String, dynamic>>.from(response);

      // Attach teacher_name by fetching all teacher ids in one query
      final Set<String> teacherIds = sessions
          .map((s) => s['teacher_id'])
          .whereType<String>()
          .toSet();

      if (teacherIds.isEmpty) return sessions;

      final Map<String, String> teacherIdToName = {};
      for (final tid in teacherIds) {
        try {
          final u = await client
              .from('User')
              .select('id, name')
              .eq('id', tid)
              .maybeSingle();
          if (u != null && u['id'] != null) {
            teacherIdToName[u['id'] as String] = (u['name'] as String?) ?? '';
          }
        } catch (_) {}
      }

      for (final s in sessions) {
        final tid = s['teacher_id'] as String?;
        if (tid != null && teacherIdToName.containsKey(tid)) {
          s['teacher_name'] = teacherIdToName[tid];
        }
      }

      return sessions;
    } catch (e) {
      print('Error fetching sessions: $e');
      return [];
    }
  }

  // Assignment Management

  /// Create a new assignment
  /// Assignment table columns: id, course_id, session_id, desc, deadline_date, pdf_url
  Future<Map<String, dynamic>> createAssignment({
    required String courseId,
    required String sessionId,
    required String description,
    String? pdfUrl,
    required DateTime deadlineDate,
  }) async {
    try {
      final data = {
        'course_id': courseId,
        'session_id': sessionId,
        'desc': description,
        'assignment_link': pdfUrl,
        'deadline_date': deadlineDate.toIso8601String(),
      };
      print('data1 is $data');
      final response = await client.from('Assignment').insert(data).select();

      return {
        'success': true,
        'data': response.isNotEmpty ? response.first : null,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'فشل في إنشاء الواجب: ${e.toString()}',
      };
    }
  }

  /// Get assignments for a course
  Future<List<Map<String, dynamic>>> getCourseAssignments(
    String courseId,
  ) async {
    try {
      final response = await client
          .from('Assignment')
          .select('*, sessions!inner(desc)')
          .eq('course_id', courseId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  /// Get assignments for a specific session
  Future<List<Map<String, dynamic>>> getSessionAssignments(
    String sessionId,
  ) async {
    try {
      final response = await client
          .from('Assignment')
          .select('*, sessions!inner(desc)')
          .eq('session_id', sessionId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  /// Get assignment by ID
  Future<Map<String, dynamic>?> getAssignmentById(String assignmentId) async {
    try {
      final response = await client
          .from('Assignment')
          .select('*, sessions!inner(desc)')
          .eq('id', assignmentId)
          .single();
      return response;
    } catch (e) {
      return null;
    }
  }

  /// Get assignments for a specific course and session
  Future<List<Map<String, dynamic>>> getAssignments({
    required String courseId,
    required String sessionId,
  }) async {
    try {
      final response = await client
          .from('Assignment')
          .select('*')
          .eq('course_id', courseId)
          .eq('session_id', sessionId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching assignments: $e');
      return [];
    }
  }

  // Assignment Submission Management

  /// Submit assignment
  Future<Map<String, dynamic>> submitAssignment({
    required String assignmentId,
    required String studentId,
    String? content,
    List<String>? attachments,
  }) async {
    try {
      final response = await client.from('Assignment_Submission').upsert({
        'assignment_id': assignmentId,
        'student_id': studentId,
        'content': content,
        'attachments': attachments ?? [],
        'status': 'submitted',
        'submitted_at': DateTime.now().toIso8601String(),
      }).select();

      return {
        'success': true,
        'data': response.isNotEmpty ? response.first : null,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'فشل في تسليم الواجب: ${e.toString()}',
      };
    }
  }

  /// Get assignment submissions for a specific assignment
  Future<List<Map<String, dynamic>>> getAssignmentSubmissions(
    String assignmentId, String courseId, String sessionId
  ) async {
    try {
      final response = await client
          .from('Assignment_Submission')
          .select('*, Student!inner(id, User!inner(name, email))')
          .eq('assignment_id', assignmentId)
          .eq('course_id', courseId)
          .eq('session_id', sessionId);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching assignment submissions: $e');
      return [];
    }
  }

  /// Get student's submission for a specific assignment
  Future<Map<String, dynamic>?> getStudentSubmission(
    String assignmentId,
    String studentId,
  ) async {
    try {
      final response = await client
          .from('Assignment_Submission')
          .select()
          .eq('assignment_id', assignmentId)
          .eq('student_id', studentId)
          .single();
      return response;
    } catch (e) {
      return null;
    }
  }

  /// Grade assignment submission
  Future<Map<String, dynamic>> gradeSubmission({
    required String submissionId,
    required double grade,
    String? feedback,
  }) async {
    try {
      final response = await client
          .from('Assignment_Submission')
          .update({
            'grade': grade,
            'feedback': feedback,
            'status': 'graded',
            'graded_at': DateTime.now().toIso8601String(),
          })
          .eq('id', submissionId)
          .select();

      return {
        'success': true,
        'data': response.isNotEmpty ? response.first : null,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'فشل في تقييم الواجب: ${e.toString()}',
      };
    }
  }

  /// Create assignment submission (checkbox marking)
  Future<Map<String, dynamic>> createAssignmentSubmission({
    required String assignmentId,
    required String studentId,
    required String courseId,
    required String sessionId,
  }) async {
    try {
      print('Creating assignment submission for assignmentId: $assignmentId, studentId: $studentId');
      final response = await client
          .from('Assignment_Submission')
          .insert({
            'assignment_id': assignmentId,
            'student_id': studentId,
            'course_id': courseId,
            'session_id': sessionId,
          })
          .select();
      print('Assignment submission created: $response');

      return {
        'success': true,
        'data': response.isNotEmpty ? response.first : null,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'فشل في تسجيل إكمال الواجب: ${e.toString()}',
      };
    }
  }

  /// Delete assignment submission
  Future<Map<String, dynamic>> deleteAssignmentSubmission({
    required String assignmentId,
    required String studentId,
  }) async {
    try {
      await client
          .from('Assignment_Submission')
          .delete()
          .eq('assignment_id', assignmentId)
          .eq('student_id', studentId);

      return {
        'success': true,
        'message': 'تم إلغاء تسجيل إكمال الواجب',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'فشل في إلغاء تسجيل الواجب: ${e.toString()}',
      };
    }
  }

  /// Update an assignment
  Future<Map<String, dynamic>> updateAssignment({
    required String assignmentId,
    String? description,
    String? assignmentLink,
    DateTime? deadlineDate,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      
      if (description != null) {
        updateData['desc'] = description;
      }
      
      if (assignmentLink != null) {
        updateData['assignment_link'] = assignmentLink;
      }
      
      if (deadlineDate != null) {
        updateData['deadline_date'] = deadlineDate.toIso8601String();
      }

      if (updateData.isEmpty) {
        return {
          'success': false,
          'message': 'لا توجد بيانات للتحديث',
        };
      }

      final response = await client
          .from('Assignment')
          .update(updateData)
          .eq('id', assignmentId)
          .select();

      return {
        'success': true,
        'data': response.isNotEmpty ? response.first : null,
        'message': 'تم تحديث الواجب بنجاح',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'فشل في تحديث الواجب: ${e.toString()}',
      };
    }
  }

  /// Delete an assignment and all its submissions
  Future<Map<String, dynamic>> deleteAssignment(String assignmentId) async {
    try {
      // First, delete all submissions for this assignment
      // (This should happen automatically if you have CASCADE delete set up in your database)
      await client
          .from('Assignment_Submission')
          .delete()
          .eq('assignment_id', assignmentId);

      // Delete the assignment
      await client
          .from('Assignment')
          .delete()
          .eq('id', assignmentId);

      return {
        'success': true,
        'message': 'تم حذف الواجب بنجاح',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'فشل في حذف الواجب: ${e.toString()}',
      };
    }
  }

  // Attendance Management

  /// Mark attendance for a session
  Future<Map<String, dynamic>> markAttendance({
    required String sessionId,
    required String courseId,
    required DateTime date,
  }) async {
    try {
      final response = await client.from('attendance').insert({
        'session_id': sessionId,
        'course_id': courseId,
        'date': date.toIso8601String().split('T')[0],
      }).select();

      return {
        'success': true,
        'data': response.isNotEmpty ? response.first : null,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'فشل في تسجيل الحضور: ${e.toString()}',
      };
    }
  }

  /// Get attendance for a course
  Future<List<Map<String, dynamic>>> getCourseAttendance(
    String courseId,
  ) async {
    try {
      final response = await client
          .from('attendance')
          .select('*, sessions!inner(desc)')
          .eq('course_id', courseId)
          .order('date', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  // User Management

  /// Get user details by ID
  Future<Map<String, dynamic>?> getUserById(String userId) async {
    try {
      final response = await client
          .from('User')
          .select()
          .eq('id', userId)
          .single();
      print('Fetched user: $response');
      return response;
    } catch (e) {
      return null;
    }
  }

  /// Get student with parent information
  Future<Map<String, dynamic>?> getStudentWithParent(String studentId) async {
    try {
      final response = await client
          .from('students')
          .select(
            '*, users!inner(*), parents!students_parent_id_fkey(*, users!inner(*))',
          )
          .eq('id', studentId)
          .single();
      return response;
    } catch (e) {
      return null;
    }
  }

  /// Get parent with student information
  Future<Map<String, dynamic>?> getParentWithStudent(String parentId) async {
    try {
      final response = await client
          .from('parents')
          .select(
            '*, users!inner(*), students!parents_student_id_fkey(*, users!inner(*))',
          )
          .eq('id', parentId)
          .single();
      return response;
    } catch (e) {
      return null;
    }
  }

  /// Get teacher with course information
  Future<Map<String, dynamic>?> getTeacherWithCourse(String teacherId) async {
    try {
      final response = await client
          .from('teachers')
          .select('*, users!inner(*), courses!teachers_course_id_fkey(*)')
          .eq('id', teacherId)
          .single();
      return response;
    } catch (e) {
      return null;
    }
  }

  /// Link parent to student
  Future<Map<String, dynamic>> linkParentToStudent({
    required String parentId,
    required String studentId,
  }) async {
    try {
      // Update parent record
      await client
          .from('parents')
          .update({'student_id': studentId})
          .eq('id', parentId);

      // Update student record
      await client
          .from('students')
          .update({'parent_id': parentId})
          .eq('id', studentId);

      return {'success': true, 'message': 'تم ربط ولي الأمر بالطالب بنجاح'};
    } catch (e) {
      return {
        'success': false,
        'message': 'فشل في ربط ولي الأمر بالطالب: ${e.toString()}',
      };
    }
  }

  /// Assign course to teacher
  Future<Map<String, dynamic>> assignCourseToTeacher({
    required String teacherId,
    required String courseId,
  }) async {
    try {
      await client
          .from('teachers')
          .update({'course_id': courseId})
          .eq('id', teacherId);

      return {'success': true, 'message': 'تم تعيين الحلقة للمعلم بنجاح'};
    } catch (e) {
      return {
        'success': false,
        'message': 'فشل في تعيين الحلقة للمعلم: ${e.toString()}',
      };
    }
  }

  // User Profile Management

  /// Update user profile image in the image_link column
  Future<void> updateUserProfileImage(String userId, String? imageUrl) async {
    try {
      await client
          .from('User')
          .update({'image_link': imageUrl})
          .eq('id', userId);
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString('user_data');
      if (userData != null) {
        final Map<String, dynamic> userMap = json.decode(userData);
        userMap['image_link'] = imageUrl;
        await prefs.setString('user_data', json.encode(userMap));
        
      }
      print('User profile image updated successfully: $userData');
    } catch (e) {
      print('Error updating user profile image: $e');
      rethrow;
    }
  }

  // Student Attendance Management

  /// Mark a student as attended for a session by inserting into Student_Attendance
  Future<Map<String, dynamic>> markStudentAttendance({
    required String sessionId,
    required String studentId,
    required String courseId,
  }) async {
    try {
      // First, get the attendance_id for this session
      final attendanceResponse = await client
          .from('Attendance')
          .select('id')
          .eq('session_id', sessionId)
          .eq('course_id', courseId)
          .maybeSingle();

      if (attendanceResponse == null) {
        return {
          'success': false,
          'message': 'سجل الحضور للجلسة غير موجود',
        };
      }

      final attendanceId = attendanceResponse['id'] as String;

      // Insert the student into Student_Attendance (being in table = attended)
      final response = await client
          .from('Student_Attendance')
          .insert({
            'attendance_id': attendanceId,
            'session_id': sessionId,
            'student_id': studentId,
            'course_id': courseId,
          })
          .select();

      return {
        'success': true,
        'data': response.isNotEmpty ? response.first : null,
        'message': 'تم تسجيل الحضور بنجاح',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'فشل في تسجيل الحضور: ${e.toString()}',
      };
    }
  }

  /// Unmark a student's attendance for a session by deleting from Student_Attendance
  Future<Map<String, dynamic>> unmarkStudentAttendance({
    required String sessionId,
    required String studentId,
    required String courseId,
  }) async {
    try {
      // First, get the attendance_id for this session
      final attendanceResponse = await client
          .from('Attendance')
          .select('id')
          .eq('session_id', sessionId)
          .eq('course_id', courseId)
          .maybeSingle();

      if (attendanceResponse == null) {
        return {
          'success': false,
          'message': 'سجل الحضور للجلسة غير موجود',
        };
      }

      final attendanceId = attendanceResponse['id'] as String;

      // Delete the student from Student_Attendance (not in table = absent)
      await client
          .from('Student_Attendance')
          .delete()
          .eq('attendance_id', attendanceId)
          .eq('session_id', sessionId)
          .eq('student_id', studentId)
          .eq('course_id', courseId);

      return {
        'success': true,
        'message': 'تم إلغاء تسجيل الحضور بنجاح',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'فشل في إلغاء تسجيل الحضور: ${e.toString()}',
      };
    }
  }

  /// Get all student IDs who attended a session (present in Student_Attendance table)
  Future<List<String>> getSessionAttendance(String sessionId) async {
    try {
      final response = await client
          .from('Student_Attendance')
          .select('student_id')
          .eq('session_id', sessionId);
      
      return List<String>.from(
        response.map((record) => record['student_id'] as String),
      );
    } catch (e) {
      print('Error getting session attendance: $e');
      return [];
    }
  }

  /// Batch update attendance - save all attendance changes at once
  Future<Map<String, dynamic>> saveAttendanceBatch({
    required String sessionId,
    required String courseId,
    required Set<String> attendedStudentIds,
    required Set<String> originalAttendedIds,
  }) async {
    try {
      // Get the attendance_id for this session
      final attendanceResponse = await client
          .from('Attendance')
          .select('id')
          .eq('session_id', sessionId)
          .eq('course_id', courseId)
          .maybeSingle();

      if (attendanceResponse == null) {
        return {
          'success': false,
          'message': 'سجل الحضور للجلسة غير موجود',
        };
      }

      final attendanceId = attendanceResponse['id'] as String;

      // Find students to add (newly marked as attended)
      final studentsToAdd = attendedStudentIds.difference(originalAttendedIds);
      
      // Find students to remove (unmarked from attended)
      final studentsToRemove = originalAttendedIds.difference(attendedStudentIds);

      // Insert new attendees
      if (studentsToAdd.isNotEmpty) {
        final insertRecords = studentsToAdd.map((studentId) => {
          'attendance_id': attendanceId,
          'session_id': sessionId,
          'student_id': studentId,
          'course_id': courseId,
        }).toList();
        
        await client.from('Student_Attendance').insert(insertRecords);
      }

      // Delete removed attendees
      if (studentsToRemove.isNotEmpty) {
        for (final studentId in studentsToRemove) {
          await client
              .from('Student_Attendance')
              .delete()
              .eq('attendance_id', attendanceId)
              .eq('session_id', sessionId)
              .eq('student_id', studentId)
              .eq('course_id', courseId);
        }
      }

      return {
        'success': true,
        'message': 'تم حفظ الحضور بنجاح',
        'added': studentsToAdd.length,
        'removed': studentsToRemove.length,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'فشل في حفظ الحضور: ${e.toString()}',
      };
    }
  }

  /// Get all students with their attendance status for a session
  Future<List<Map<String, dynamic>>> getSessionAttendanceDetails({
    required String sessionId,
    required String courseId,
  }) async {
    try {
      // Get the attendance_id for this session
      final attendanceResponse = await client
          .from('Attendance')
          .select('id')
          .eq('session_id', sessionId)
          .eq('course_id', courseId)
          .maybeSingle();

      if (attendanceResponse == null) {
        return [];
      }

      final attendanceId = attendanceResponse['id'] as String;

      // Get all student attendance records with user details
      final response = await client
          .from('Student_Attendance')
          .select('*, User!inner(*)')
          .eq('attendance_id', attendanceId)
          .eq('session_id', sessionId)
          .eq('course_id', courseId);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting session attendance details: $e');
      return [];
    }
  }

  // Student Profile Management (Teacher-editable fields)

  /// Get student profile with balance, level, and memorized content
  Future<Map<String, dynamic>?> getStudentProfile(String studentId) async {
    try {
      final response = await client
        .from('User')
        .select('*, Student(*)') // Join User with Student
        .eq('id', studentId)
        .single();
      return response;
    } catch (e) {
      print('Error getting student profile: $e');
      return null;
    }
  }

  /// Update student profile (balance, level, memorized_content)
  /// Only teachers can update these fields
  Future<Map<String, dynamic>> updateStudentProfile({
    required String studentId,
    required String payDeadlineDate,
    required String quranLevel,
    required String moralLevel,
    required String revisionLevel,
    required Map<String, dynamic> memorizedContent,
  }) async {
    try {
      await client
          .from('Student')
          .update({
            'pay_deadline_date': payDeadlineDate,
            'quran_level': quranLevel,
            'moral_level': moralLevel,
            'revision_level': revisionLevel,
            'memorized_content': memorizedContent,
          })
          .eq('id', studentId);

      return {
        'success': true,
        'message': 'تم تحديث بيانات الطالب بنجاح',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'فشل في تحديث بيانات الطالب: ${e.toString()}',
      };
    }
  }
}
