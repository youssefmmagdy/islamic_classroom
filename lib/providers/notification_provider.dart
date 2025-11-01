import 'package:flutter/material.dart';
import '../services/firebase_messaging_service.dart';
import '../services/database_service.dart';

class NotificationProvider extends ChangeNotifier {
  final FirebaseMessagingService _messagingService = FirebaseMessagingService();
  final DatabaseService _databaseService = DatabaseService();
  
  String? _fcmToken;
  String? get fcmToken => _fcmToken;
  
  List<Map<String, dynamic>> _notifications = [];
  List<Map<String, dynamic>> get notifications => _notifications;
  
  int get unreadCount => _notifications.where((n) => !(n['is_read'] as bool? ?? false)).length;
  
  /// Initialize notifications
  Future<void> initialize(String userId) async {
    // Get FCM token
    _fcmToken = await _messagingService.getToken();
    
    // Save token to database
    if (_fcmToken != null) {
      await _saveTokenToDatabase(userId, _fcmToken!);
    }
    
    // Load notifications from database
    await loadNotifications(userId);
  }
  
  /// Save FCM token to database
  Future<void> _saveTokenToDatabase(String userId, String token) async {
    try {
      await _databaseService.client
          .from('User')
          .update({'fcm_token': token})
          .eq('id', userId);
    } catch (e) {
      print('Error saving FCM token: $e');
    }
  }
  
  /// Load notifications from database
  Future<void> loadNotifications(String userId) async {
    try {
      // You'll need to create a Notification table in your database
      final response = await _databaseService.client
          .from('Notification')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(50);
      
      _notifications = List<Map<String, dynamic>>.from(response as List);
      notifyListeners();
    } catch (e) {
      print('Error loading notifications: $e');
    }
  }
  
  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _databaseService.client
          .from('Notification')
          .update({'is_read': true})
          .eq('id', notificationId);
      
      // Update local state
      final index = _notifications.indexWhere((n) => n['id'] == notificationId);
      if (index != -1) {
        _notifications[index]['is_read'] = true;
        notifyListeners();
      }
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }
  
  /// Mark all notifications as read
  Future<void> markAllAsRead(String userId) async {
    try {
      await _databaseService.client
          .from('Notification')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);
      
      // Update local state
      for (var notification in _notifications) {
        notification['is_read'] = true;
      }
      notifyListeners();
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }
  
  /// Subscribe to course notifications
  Future<void> subscribeToCourse(String courseId) async {
    await _messagingService.subscribeToTopic('course_$courseId');
  }
  
  /// Unsubscribe from course notifications
  Future<void> unsubscribeFromCourse(String courseId) async {
    await _messagingService.unsubscribeFromTopic('course_$courseId');
  }
  
  /// Send notification about new post (called by teacher)
  Future<void> notifyStudentsAboutNewPost({
    required String courseId,
    required String postTitle,
    required String postContent,
    required String postId,
  }) async {
    try {
      // Get all students enrolled in the course
      final students = await _databaseService.getCourseStudents(courseId);
      
      // Create notifications in database for each student
      for (var student in students) {
        final studentId = student['id'] as String;
        
        await _databaseService.client.from('Notification').insert({
          'user_id': studentId,
          'title': 'منشور جديد',
          'body': postTitle,
          'type': 'post',
          'reference_id': postId,
          'course_id': courseId,
          'is_read': false,
          'created_at': DateTime.now().toIso8601String(),
        });
      }
      
      // In a real implementation, you would also call your backend API
      // to send push notifications via Firebase Cloud Messaging
      print('Notifications created for ${students.length} students');
      
    } catch (e) {
      print('Error notifying students: $e');
      rethrow;
    }
  }
}
