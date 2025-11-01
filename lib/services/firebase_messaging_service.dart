import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'database_service.dart';

/// Background message handler - must be a top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling a background message: ${message.messageId}');
  print('Message data: ${message.data}');
  print('Message notification: ${message.notification?.title}');
}

class FirebaseMessagingService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final DatabaseService _databaseService = DatabaseService();
  
  static final FirebaseMessagingService _instance = FirebaseMessagingService._internal();
  factory FirebaseMessagingService() => _instance;
  FirebaseMessagingService._internal();

  /// Initialize Firebase Messaging
  Future<void> initialize() async {
    // Set background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Request permission for iOS
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    await _firebaseMessaging.subscribeToTopic('my_app');
    print('User granted permission: ${settings.authorizationStatus}');

    // Get FCM token
    String? token = await _firebaseMessaging.getToken();
    print('FCM Token: $token');
    
    // Save token to database (you'll implement this)
    if (token != null) {
      await _saveTokenToDatabase(token);
    }

    // Listen for token refresh
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      print('FCM Token refreshed: $newToken');
      _saveTokenToDatabase(newToken);
    });

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle when app is opened from a notification
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Check if app was opened from a terminated state
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    print('Received foreground message: ${message.messageId}');
    print('Title: ${message.notification?.title}');
    print('Body: ${message.notification?.body}');
    print('Data: ${message.data}');
    
    // You can show a local notification here or update UI
  }

  /// Handle when user taps on notification
  void _handleMessageOpenedApp(RemoteMessage message) {
    print('Message clicked: ${message.messageId}');
    print('Data: ${message.data}');
    
    // Navigate based on notification type
    final type = message.data['type'];
    final id = message.data['id'];
    
    switch (type) {
      case 'post':
        // Navigate to post details
        print('Navigate to post: $id');
        break;
      case 'assignment':
        // Navigate to assignment details
        print('Navigate to assignment: $id');
        break;
      case 'session':
        // Navigate to session details
        print('Navigate to session: $id');
        break;
      default:
        print('Unknown notification type: $type');
    }
  }

  /// Save FCM token to database
  Future<void> _saveTokenToDatabase(String token) async {
    try {
      // TODO: Implement saving token to User table
      // You'll need to add a fcm_token column to your User table
      print('Saving token to database: $token');
      
      // Example implementation:
      // await _databaseService.updateUserFCMToken(userId, token);
    } catch (e) {
      print('Error saving token: $e');
    }
  }

  /// Get current FCM token
  Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }

  /// Subscribe to topic (e.g., course-specific notifications)
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      print('Subscribed to topic: $topic');
    } catch (e) {
      print('Error subscribing to topic: $e');
    }
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      print('Unsubscribed from topic: $topic');
    } catch (e) {
      print('Error unsubscribing from topic: $e');
    }
  }

  /// Send notification to specific users (server-side)
  /// This is just a helper method - actual sending should be done from your backend
  Future<void> notifyStudentsAboutPost({
    required String courseId,
    required String postTitle,
    required String postId,
    required List<String> studentTokens,
  }) async {
    // This should be called from your backend/cloud function
    // Here we just demonstrate the data structure
    
    final notification = {
      'title': 'منشور جديد',
      'body': postTitle,
      'data': {
        'type': 'post',
        'id': postId,
        'course_id': courseId,
      },
    };
    
    print('Notification to send: $notification');
    print('To tokens: $studentTokens');
    
    // In a real implementation, you'd call your backend API here
    // which would use Firebase Admin SDK to send notifications
  }
}
