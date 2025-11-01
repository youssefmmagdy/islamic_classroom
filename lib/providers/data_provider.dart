import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/course.dart';
import '../models/session.dart';
import '../models/homework.dart';
import '../models/student.dart';
import '../models/attendance.dart';
import '../models/homework_submission.dart';

class DataProvider with ChangeNotifier {
  List<Course> _courses = [];
  List<Session> _sessions = [];
  List<Homework> _homework = [];
  List<Student> _students = [];
  List<Attendance> _attendance = [];
  List<HomeworkSubmission> _submissions = [];

  List<Course> get courses => _courses;
  List<Session> get sessions => _sessions;
  List<Homework> get homework => _homework;
  List<Student> get students => _students;
  List<Attendance> get attendance => _attendance;
  List<HomeworkSubmission> get submissions => _submissions;

  // Load sample data
  Future<void> loadSampleData() async {
    await _loadDataFromPrefs();
    if (_courses.isEmpty) {
      _generateSampleData();
      await _saveDataToPrefs();
    }
  }

  void _generateSampleData() {
    // Sample Students
    final student1 = Student(
      id: 'user1',
      level: StudentLevel.intermediate,
      balance: 150.0,
      memorizedContent: ['الفاتحة', 'آية الكرسي', 'سورة الإخلاص'],
    );
    final student2 = Student(
      id: 'user2',
      level: StudentLevel.beginner,
      balance: 0.0,
      memorizedContent: ['الفاتحة'],
    );
    _students = [student1, student2];

    // Sample Courses
    final course1 = Course(
      name: 'تحفيظ القرآن - المستوى الأول',
      description: 'حلقة تحفيظ القرآن الكريم للمبتدئين',
      teacherId: 'teacher1',
      studentIds: [student1.id, student2.id],
    );
    _courses = [course1];

    // Sample Sessions
    final session1 = Session(
      courseId: course1.id,
      title: 'حفظ سورة الفاتحة',
      description: 'تعلم وحفظ سورة الفاتحة مع التجويد',
      dateTime: DateTime.now().subtract(const Duration(days: 1)),
      isCompleted: true,
    );
    final session2 = Session(
      courseId: course1.id,
      title: 'مراجعة سورة الفاتحة',
      description: 'مراجعة وتثبيت حفظ سورة الفاتحة',
      dateTime: DateTime.now().add(const Duration(days: 1)),
    );
    _sessions = [session1, session2];

    // Sample Homework
    final homework1 = Homework(
      sessionId: session1.id,
      title: 'حفظ سورة الفاتحة',
      description: 'احفظ سورة الفاتحة كاملة مع التجويد الصحيح',
      type: HomeworkType.new_content,
      dueDate: DateTime.now().add(const Duration(days: 3)),
    );
    _homework = [homework1];

    // Sample Attendance
    final attendance1 = Attendance(
      sessionId: session1.id,
      studentId: student1.id,
      status: AttendanceStatus.present,
    );
    final attendance2 = Attendance(
      sessionId: session1.id,
      studentId: student2.id,
      status: AttendanceStatus.absent,
      notes: 'مريض',
    );
    _attendance = [attendance1, attendance2];
  }

  // Course methods
  void addCourse(Course course) {
    _courses.add(course);
    _saveDataToPrefs();
    notifyListeners();
  }

  void updateCourse(Course course) {
    final index = _courses.indexWhere((c) => c.id == course.id);
    if (index != -1) {
      _courses[index] = course;
      _saveDataToPrefs();
      notifyListeners();
    }
  }

  void deleteCourse(String courseId) {
    _courses.removeWhere((c) => c.id == courseId);
    // Also delete related data
    _sessions.removeWhere((s) => s.courseId == courseId);
    // Remove homework related to deleted sessions (if needed)
    // Remove attendance related to deleted sessions (if needed)
    _saveDataToPrefs();
    notifyListeners();
  }

  List<Course> getCoursesByTeacher(String teacherId) {
    return _courses.where((course) => course.teacherId == teacherId).toList();
  }

  List<Course> getCoursesByStudent(String studentId) {
    return _courses
        .where((course) => course.studentIds.contains(studentId))
        .toList();
  }

  // Session methods
  void addSession(Session session) {
    _sessions.add(session);
    _saveDataToPrefs();
    notifyListeners();
  }

  void updateSession(Session session) {
    final index = _sessions.indexWhere((s) => s.id == session.id);
    if (index != -1) {
      _sessions[index] = session;
      _saveDataToPrefs();
      notifyListeners();
    }
  }

  List<Session> getSessionsByCourse(String courseId) {
    return _sessions.where((session) => session.courseId == courseId).toList();
  }

  // Homework methods
  void addHomework(Homework hw) {
    _homework.add(hw);
    _saveDataToPrefs();
    notifyListeners();
  }

  List<Homework> getHomeworkBySession(String sessionId) {
    return _homework.where((hw) => hw.sessionId == sessionId).toList();
  }

  // Student methods
  void addStudent(Student student) {
    _students.add(student);
    _saveDataToPrefs();
    notifyListeners();
  }

  void updateStudent(Student student) {
    final index = _students.indexWhere((s) => s.id == student.id);
    if (index != -1) {
      _students[index] = student;
      _saveDataToPrefs();
      notifyListeners();
    }
  }

  List<Student> getStudentsByCourse(String courseId) {
  final matches = _courses.where((c) => c.id == courseId).toList();
  if (matches.isEmpty) return const [];
  final course = matches.first;
  return _students
    .where((student) => course.studentIds.contains(student.id))
    .toList();
  }

  // Attendance methods
  void markAttendance(Attendance attendance) {
    final existingIndex = _attendance.indexWhere(
      (a) =>
          a.sessionId == attendance.sessionId &&
          a.studentId == attendance.studentId,
    );

    if (existingIndex != -1) {
      _attendance[existingIndex] = attendance;
    } else {
      _attendance.add(attendance);
    }
    _saveDataToPrefs();
    notifyListeners();
  }

  List<Attendance> getAttendanceBySession(String sessionId) {
    return _attendance
        .where((attendance) => attendance.sessionId == sessionId)
        .toList();
  }

  List<Attendance> getAttendanceByStudent(String studentId) {
    return _attendance
        .where((attendance) => attendance.studentId == studentId)
        .toList();
  }

  // Data persistence
  Future<void> _saveDataToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('courses', json.encode(_courses.map((e) => e.toJson()).toList()));
    await prefs.setString('sessions', json.encode(_sessions.map((e) => e.toJson()).toList()));
    await prefs.setString('homework', json.encode(_homework.map((e) => e.toJson()).toList()));
    await prefs.setString('students', json.encode(_students.map((e) => e.toJson()).toList()));
    await prefs.setString('attendance', json.encode(_attendance.map((e) => e.toJson()).toList()));
    await prefs.setString('submissions', json.encode(_submissions.map((e) => e.toJson()).toList()));
  }

  Future<void> _loadDataFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final coursesData = prefs.getString('courses');
      if (coursesData != null) {
        final List<dynamic> coursesList = json.decode(coursesData);
        _courses = coursesList.map((e) => Course.fromJson(e)).toList();
      }

      final sessionsData = prefs.getString('sessions');
      if (sessionsData != null) {
        final List<dynamic> sessionsList = json.decode(sessionsData);
        _sessions = sessionsList.map((e) => Session.fromJson(e)).toList();
      }

      final homeworkData = prefs.getString('homework');
      if (homeworkData != null) {
        final List<dynamic> homeworkList = json.decode(homeworkData);
        _homework = homeworkList.map((e) => Homework.fromJson(e)).toList();
      }

      final studentsData = prefs.getString('students');
      if (studentsData != null) {
        final List<dynamic> studentsList = json.decode(studentsData);
        _students = studentsList.map((e) => Student.fromJson(e)).toList();
      }

      final attendanceData = prefs.getString('attendance');
      if (attendanceData != null) {
        final List<dynamic> attendanceList = json.decode(attendanceData);
        _attendance = attendanceList.map((e) => Attendance.fromJson(e)).toList();
      }

      final submissionsData = prefs.getString('submissions');
      if (submissionsData != null) {
        final List<dynamic> submissionsList = json.decode(submissionsData);
        _submissions = submissionsList.map((e) => HomeworkSubmission.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
    }
  }
}