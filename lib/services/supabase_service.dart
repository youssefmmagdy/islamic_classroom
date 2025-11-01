import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart' as app_models;

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  SupabaseClient get client => Supabase.instance.client;

  /// Register a new user with inheritance-based design
  Future<Map<String, dynamic>> registerUser({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String countryCode,
    required DateTime birthDate,
    required String gender,
    required app_models.UserRole role,
    String? imageLink,
  }) async {
    try {
      // First, validate all input fields
      final validation = _validateRegistrationData(
        email: email,
        password: password,
        fullName: name,
        phone: phone,
        birthDate: birthDate,
      );

      if (validation['isValid'] != true) {
        return {
          'success': false,
          'message': validation['message'],
        };
      }

      // Check if email already exists in User table
      print('DEBUG: Checking if email exists...');
      print('DEBUG: Input email: "$email"');
      print('DEBUG: Lowercase email: "${email.toLowerCase()}"');
      try {
        final existingUser = await client
            .from('User')
            .select('email')
            .eq('email', email.toLowerCase())
            .maybeSingle();
        
        print('DEBUG: Existing user result: $existingUser');
        if (existingUser != null) {
          print('DEBUG: Found existing email: "${existingUser['email']}"');
          return {
            'success': false,
            'message': 'البريد الإلكتروني مسجل مسبقاً',
          };
        }
        print('DEBUG: Email is available');
      } catch (e) {
        // If table doesn't exist or other error, continue with registration
        print('Error checking existing email: $e');
      }

      // Check if phone number already exists in User table
      print('Checking if phone exists: $countryCode$phone');
      try {
        final existingPhoneList = await client
            .from('User')
            .select('id, phone, country_code, name, role')
            .eq('country_code', countryCode)
            .eq('phone', phone);
        
        print('Existing phone check result: $existingPhoneList');
        
        if (existingPhoneList.isNotEmpty) {
          print('Phone number already exists! Blocking registration.');
          return {
            'success': false,
            'message': 'رقم الهاتف مسجل مسبقاً',
          };
        }
        print('Phone number is available');
      } catch (e) {
        // If there's an error checking, we should still proceed carefully
        print('Error checking existing phone: $e');
        // Don't continue silently - this could be a real error
      }
      // Create user in Supabase Auth first
      print('DEBUG: About to create auth user...');
      print('DEBUG: Email for auth signup: "$email"');
      final AuthResponse authResponse = await client.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name,
          'role': role.toString().split('.').last,
          'country_code': countryCode,
          'phone': phone,
          'gender': gender,
          'birth_date': birthDate.toIso8601String().split('T')[0],
        },
      );
      print('DEBUG: Auth signup completed');
      
      print('Auth response: user=${authResponse.user?.id}, session=${authResponse.session != null}');
      
      if (authResponse.user == null) {
        print('Auth user is null!');
        return {
          'success': false,
          'message': 'فشل في إنشاء الحساب. يرجى المحاولة مرة أخرى.',
        };
      }

      final userId = authResponse.user!.id;
      print('Auth user created with ID: $userId');

      // Check for session - with email confirmation disabled, this should always be available
      final session = authResponse.session ?? client.auth.currentSession;
      if (session == null) {
        print('WARNING: No session available despite email confirmation being disabled!');
        print('This is unexpected. Email confirmation might still be enabled in Supabase.');
        // Store data in auth user metadata for later completion
        return {
          'success': false,
          'message': 'تم إنشاء الحساب في النظام ولكن فشل في إكمال التسجيل. يرجى تأكيد البريد الإلكتروني أولاً ثم تسجيل الدخول.',
        };
      }

      print('✓ Session is available, proceeding with database inserts');

      // Prepare user data
      var data = {
        'id': userId, // UUID should be sent as string
        'name': name,
        'email': email,
        'country_code': countryCode,
        'phone': phone,
        'gender': gender,
        'birth_date': birthDate.toIso8601String().split('T')[0],
        'role': role.toString().split('.').last,
      };
    
      // Insert into base user table
      print('Attempting to insert user data: $data');
      final userResponse = await client.from('User').insert(data).select();
      print('User insert response: $userResponse');
      if (userResponse.isEmpty) {
        // If user data insertion fails, clean up auth user
        print('User response is empty, cleaning up...');
        await client.auth.signOut();
        return {
          'success': false,
          'message': 'فشل في حفظ بيانات المستخدم الأساسية.',
        };
      }
      print('User data inserted successfully');

      // Insert into role-specific table based on user role
      print('Attempting to insert role: ${role.toString()}');
      Map<String, dynamic> roleResponse;
      switch (role) {
        case app_models.UserRole.student:
          print('Inserting student with userId: $userId');
          roleResponse = await _insertStudent(userId);
          break;
        case app_models.UserRole.teacher:
          print('Inserting teacher with userId: $userId');
          roleResponse = await _insertTeacher(userId);
          break;
      }

      print('Role response: $roleResponse');
      if (roleResponse['success'] != true) {
        // Clean up if role-specific insertion fails
        print('Role insertion failed, cleaning up...');
        await client.from('User').delete().eq('id', userId);
        await client.auth.signOut();
        return {
          'success': false,
          'message': roleResponse['message'] ?? 'فشل في حفظ بيانات الدور المحدد.',
        };
      }

      return {
        'success': true,
        'message': 'تم إنشاء الحساب بنجاح!.',
        'user': authResponse.user,
        'userData': userResponse.first,
        'roleData': roleResponse['data'],
      };
    } on AuthException catch (e) {
      print('DEBUG: AuthException caught during registration!');
      print('DEBUG: Error message: "${e.message}"');
      print('DEBUG: Error status code: ${e.statusCode}');
      print('DEBUG: Translated message will be: "${_getAuthErrorMessage(e.message)}"');
      return {
        'success': false,
        'message': _getAuthErrorMessage(e.message),
      };
    } catch (e, stackTrace) {
      print('Error during registration: $e');
      print('Stack trace: $stackTrace');
      // Try to clean up the auth user if it was created
      try {
        await client.auth.signOut();
      } catch (cleanupError) {
        print('Error cleaning up auth: $cleanupError');
      }
      return {
        'success': false,
        'message': 'حدث خطأ غير متوقع: ${e.toString()}',
      };
    }
  }

  /// Insert student record
  Future<Map<String, dynamic>> _insertStudent(String userId) async {
    try {
      final response = await client.from('Student').insert({
        'id': userId,
      }).select();

      return {
        'success': true,
        'data': response.isNotEmpty ? response.first : null,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'فشل في حفظ بيانات الطالب. ${e.toString()}',
      };
    }
  }

  /// Insert teacher record
  Future<Map<String, dynamic>> _insertTeacher(String userId) async {
    try {
      print('_insertTeacher called with userId: $userId');
      print('Attempting to insert into Teacher table...');
      
      final response = await client.from('Teacher').insert({
        'id': userId,
        // Don't include course_id - it will use default value or remain null if allowed
      }).select();

      print('Teacher insert response: $response');
      print('Response is empty: ${response.isEmpty}');

      if (response.isEmpty) {
        print('WARNING: Teacher insert returned empty response');
      }

      return {
        'success': true,
        'data': response.isNotEmpty ? response.first : null,
      };
    } catch (e, stackTrace) {
      print('==== ERROR INSERTING TEACHER ====');
      print('Error type: ${e.runtimeType}');
      print('Error message: ${e.toString()}');
      print('Stack trace: $stackTrace');
      print('================================');
      return {
        'success': false,
        'message': 'فشل في حفظ بيانات المعلم. ${e.toString()}',
      };
    }
  }

  /// Login user with new schema
  Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      final AuthResponse response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.user == null) {
        return {
          'success': false,
          'message': 'فشل في تسجيل الدخول. يرجى التحقق من البيانات.',
        };
      }
      print('Login response user: ${response.user}');
      final userId = response.user!.id;

      // Get user data from users table
      final userDataResponse = await client
          .from('User')
          .select()
          .eq('id', userId)
          .single();
      
      // Determine user role by checking which role table contains the user
      String role = 'Student'; // default
      Map<String, dynamic>? roleData;

      // Check if user is a student
      try {
        final studentData = await client
            .from('Student')
            .select()
            .eq('id', userId)
            .single();
        role = 'Student';
        roleData = studentData;
      } catch (e) {
        // User is not a student, continue checking
      }

      // Check if user is a teacher
      if (roleData == null) {
        try {
          final teacherData = await client
              .from('Teacher')
              .select()
              .eq('id', userId)
              .single();
          role = 'Teacher';
          roleData = teacherData;
        } catch (e) {
          // User is not a teacher
        }
      }
      
      return {
        'success': true,
        'message': 'تم تسجيل الدخول بنجاح!',
        'user': response.user,
        'userData': userDataResponse,
        'role': role,
        'roleData': roleData,
      };
    } on AuthException catch (e) {
      
      return {
        'success': false,
        'message': _getAuthErrorMessage(e.message),
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'حدث خطأ في تسجيل الدخول: ${e.toString()}',
      };
    }
  }

  /// Logout user
  Future<Map<String, dynamic>> logoutUser() async {
    try {
      await client.auth.signOut();
      return {
        'success': true,
        'message': 'تم تسجيل الخروج بنجاح!',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'حدث خطأ في تسجيل الخروج.',
      };
    }
  }

  /// Get current user
  User? getCurrentUser() {
    return client.auth.currentUser;
  }

  /// Check if user is logged in
  bool isLoggedIn() {
    return client.auth.currentUser != null;
  }

  /// Validate registration data
  Map<String, dynamic> _validateRegistrationData({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required DateTime birthDate,
  }) {
    // Email validation
    if (email.isEmpty) {
      return {'isValid': false, 'message': 'يرجى إدخال البريد الإلكتروني'};
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      return {'isValid': false, 'message': 'يرجى إدخال بريد إلكتروني صحيح'};
    }

    // Password validation
    if (password.isEmpty) {
      return {'isValid': false, 'message': 'يرجى إدخال كلمة المرور'};
    }
    if (password.length < 6) {
      return {'isValid': false, 'message': 'كلمة المرور يجب أن تكون 6 أحرف على الأقل'};
    }

    // Full name validation
    if (fullName.isEmpty) {
      return {'isValid': false, 'message': 'يرجى إدخال الاسم الكامل'};
    }
    if (fullName.length < 2) {
      return {'isValid': false, 'message': 'الاسم يجب أن يكون أكثر من حرفين'};
    }

    // Phone validation
    if (phone.isEmpty) {
      return {'isValid': false, 'message': 'يرجى إدخال رقم الهاتف'};
    }

    // Birth date validation
    final now = DateTime.now();
    final age = now.year - birthDate.year;
    if (age < 5) {
      return {'isValid': false, 'message': 'العمر يجب أن يكون 5 سنوات على الأقل'};
    }
    if (age > 100) {
      return {'isValid': false, 'message': 'يرجى إدخال تاريخ ميلاد صحيح'};
    }

    return {'isValid': true, 'message': 'البيانات صحيحة'};
  }

  /// Get localized error message
  /// Delete user account permanently
  Future<Map<String, dynamic>> deleteAccount() async {
    try {
      final user = client.auth.currentUser;
      if (user == null) {
        return {
          'success': false,
          'message': 'لا يوجد مستخدم مسجل حالياً',
        };
      }

      final userId = user.id;

      // Delete user data from all tables (role-specific tables will be deleted by cascade)
      await client.from('User').delete().eq('id', userId);
      
      // Sign out and delete auth user
      await client.auth.signOut();
      
      
      return {
        'success': true,
        'message': 'تم حذف الحساب بنجاح',
      };
    } catch (e) {
      print('Error deleting account: $e');
      return {
        'success': false,
        'message': 'فشل في حذف الحساب: ${e.toString()}',
      };
    }
  }

  String _getAuthErrorMessage(String error) {
    print('DEBUG: _getAuthErrorMessage called with: "$error"');
    final lowerError = error.toLowerCase();
    print('DEBUG: Lowercase error: "$lowerError"');
    
    // Check for duplicate email errors
    if (lowerError.contains('already') && (lowerError.contains('email') || lowerError.contains('user') || lowerError.contains('registered'))) {
      print('DEBUG: Matched duplicate email pattern!');
      return 'البريد الإلكتروني مسجل مسبقاً';
    }
    
    switch (lowerError) {
      case 'invalid login credentials':
        return 'بيانات الدخول غير صحيحة';
      case 'invalid email':
        return 'البريد الإلكتروني غير صحيح';
      case 'password too short':
        return 'كلمة المرور قصيرة جداً';
      case 'signup disabled':
        return 'التسجيل معطل حالياً';
      case 'email not confirmed':
        return 'يرجى تأكيد البريد الإلكتروني أولاً';
      case 'too many requests':
        return 'محاولات كثيرة. يرجى المحاولة لاحقاً';
      default:
        return 'حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى';
    }
  }
}