import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user.dart';
import '../services/supabase_service.dart';
import '../services/database_service.dart';

class AuthProvider with ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;
  bool get isTeacher => _currentUser?.role == UserRole.teacher;
  bool get isStudent => _currentUser?.role == UserRole.student;

  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Use Supabase service for authentication
      final result = await SupabaseService().loginUser(
        email: email,
        password: password,
      );

      if (result['success'] == true) {
        final userData = result['userData'];
        final role = result['role'];
        _currentUser = User(
          id: userData['id'], // Use the actual User table ID from database
          name: userData['name'] ?? 'مستخدم', // Using phone as name since name is not in the new schema
          email: email,
          phone: '${userData['phone']}',
          role: _parseUserRole(role ?? 'Student'),
          gender: _parseGender(userData['gender']),
          birthDate: DateTime.parse(userData['birth_date']),
          countryCode: userData['country_code'],
          imageLink: userData['image_link'],
          createdAt: DateTime.parse(userData['created_at']),
        );
        
        // Save user data to local storage
        await _saveUserData();
      } else {
        throw Exception(result['message']);
      }
    } catch (e) {
      throw Exception('فشل في تسجيل الدخول: ${e.toString()}');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  UserRole _parseUserRole(String role) {
    switch (role) {
      case 'Teacher':
        return UserRole.teacher;
      case 'Student':
      default:
        return UserRole.student;
    }
  }

  Gender _parseGender(dynamic value) {
    if (value is Gender) return value;
    if (value is String) {
      final v = value.toLowerCase().trim();
      if (v == 'male') return Gender.male;
      if (v == 'female') return Gender.female;
    }
    // Fallback to a sensible default
    return Gender.male;
  }

  Future<void> logout() async {
    try {
      // Logout from Supabase
      await SupabaseService().logoutUser();
      
      // Clear local data
      _currentUser = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_data');
      notifyListeners();
    } catch (e) {
      debugPrint('Error during logout: $e');
      // Even if Supabase logout fails, clear local data
      _currentUser = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_data');
      notifyListeners();
    }
  }

  Future<void> deleteAccount() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Delete account from Supabase
      final result = await SupabaseService().deleteAccount();
      
      if (result['success'] == true) {
        // Clear local data
        _currentUser = null;
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('user_data');
      } else {
        throw Exception(result['message']);
      }
    } catch (e) {
      throw Exception('فشل في حذف الحساب: ${e.toString()}');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadUserData() async {
    try {
      // Check if user is logged in with Supabase
      if (SupabaseService().isLoggedIn()) {
        // Try to load from local storage first for faster startup
        final prefs = await SharedPreferences.getInstance();
        final userData = prefs.getString('user_data');
        if (userData != null) {
          final Map<String, dynamic> userMap = json.decode(userData);
          _currentUser = User.fromJson(userMap);
          notifyListeners();
        }
      } else {
        // If not logged in with Supabase, clear local data
        _currentUser = null;
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('user_data');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  Future<void> _saveUserData() async {
    if (_currentUser != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_data', json.encode(_currentUser!.toJson()));
    }
  }

  Future<void> updateProfile({
    String? name,
    String? phone,
    String? countryCode,
    String? profileImage,
  }) async {
    if (_currentUser == null) return;

    // Update in database first
    try {
      final dbService = DatabaseService();
      final updates = <String, dynamic>{};
      
      if (name != null) {
        updates['name'] = name;
      }
      
      if (phone != null) {
        updates['phone'] = phone;
      }
      
      if (countryCode != null) {
        updates['country_code'] = countryCode;
      }
      
      if (profileImage != null) {
        updates['image_link'] = profileImage;
      }
      
      if (updates.isNotEmpty) {
        await dbService.client
            .from('User')
            .update(updates)
            .eq('id', _currentUser!.id);
      }
      
      // Update local state
      _currentUser = _currentUser!.copyWith(
        name: name,
        phone: phone,
        countryCode: countryCode,
        imageLink: profileImage,
      );

      await _saveUserData();
      notifyListeners();
    } catch (e) {
      print('Error updating profile in database: $e');
      throw Exception('فشل في تحديث الملف الشخصي');
    }
  }

  /// Update user with a new user object
  void updateUser(User user) {
    _currentUser = user;
    _saveUserData();
    notifyListeners();
  }

  /// Refresh user data from database
  Future<void> refreshUserData() async {
    if (_currentUser == null) return;

    try {
      final userData = await DatabaseService().getUserById(_currentUser!.id);
      
      if (userData != null) {
        
        _currentUser = User(
          id: userData['id'],
          name: userData['name'] ?? userData['phone'] ?? 'مستخدم',
          email: _currentUser!.email,
          phone: '${userData['country_code']}${userData['phone']}',
          role: _currentUser!.role,
          gender: _parseGender(userData['gender']),
          birthDate: DateTime.parse(userData['birth_date']),
          countryCode: userData['country_code'],
          imageLink: userData['image_link'], // Fetch fresh image_link from database
          createdAt: DateTime.parse(userData['created_at']),
        );

        await _saveUserData();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error refreshing user data: $e');
    }
  }

  /// Update user profile image link directly
  void updateUserImage(String? imageUrl) {
    if (_currentUser != null) {
      _currentUser = User(
        id: _currentUser!.id,
        name: _currentUser!.name,
        email: _currentUser!.email,
        phone: _currentUser!.phone,
        role: _currentUser!.role,
        gender: _currentUser!.gender,
        birthDate: _currentUser!.birthDate,
        countryCode: _currentUser!.countryCode,
        imageLink: imageUrl,
        createdAt: _currentUser!.createdAt,
      );
      _saveUserData();
      notifyListeners();
    }
  }
}