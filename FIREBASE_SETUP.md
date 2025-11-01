# Firebase Cloud Messaging Setup Guide

## Overview
This implementation provides a complete notification system using Firebase Cloud Messaging (FCM) for your Flutter app.

## Features Implemented
✅ Firebase Messaging integration
✅ FCM token management
✅ Background and foreground message handling
✅ Notification storage in Supabase database
✅ Notification screen with read/unread status
✅ Topic-based subscriptions (for courses)
✅ Teacher can notify students about new posts

## Setup Instructions

### 1. Firebase Project Setup

1. **Create a Firebase Project**:
   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Click "Add project"
   - Follow the setup wizard

2. **Add Android App**:
   - In Firebase Console, click "Add app" → Android
   - Package name: `com.example.my_app` (or your package name)
   - Download `google-services.json`
   - Place it in `android/app/` directory

3. **Add iOS App** (if needed):
   - Click "Add app" → iOS
   - Bundle ID: from your `ios/Runner.xcodeproj`
   - Download `GoogleService-Info.plist`
   - Add to `ios/Runner/` directory

4. **Enable Cloud Messaging**:
   - In Firebase Console, go to Project Settings
   - Navigate to "Cloud Messaging" tab
   - Enable Cloud Messaging API

### 2. Android Configuration

Add to `android/app/build.gradle`:
```gradle
dependencies {
    // ... existing dependencies
    implementation platform('com.google.firebase:firebase-bom:32.0.0')
    implementation 'com.google.firebase:firebase-messaging'
}
```

Add to `android/build.gradle`:
```gradle
buildscript {
    dependencies {
        // ... existing dependencies
        classpath 'com.google.gms:google-services:4.4.0'
    }
}
```

Add to end of `android/app/build.gradle`:
```gradle
apply plugin: 'com.google.gms.google-services'
```

### 3. iOS Configuration (if supporting iOS)

1. Add to `ios/Podfile`:
```ruby
target 'Runner' do
  use_frameworks!
  use_modular_headers!
  
  pod 'Firebase/Messaging'
end
```

2. Run: `cd ios && pod install`

3. Enable Push Notifications in Xcode:
   - Open `ios/Runner.xcworkspace` in Xcode
   - Select Runner target → Signing & Capabilities
   - Click "+ Capability" → Push Notifications
   - Click "+ Capability" → Background Modes
   - Check "Remote notifications"

### 4. Database Migration

Run the SQL migration in your Supabase dashboard:
```sql
-- See database/notifications_migration.sql
```

This creates:
- `fcm_token` column in User table
- `Notification` table
- Indexes and triggers

### 5. Backend API (Optional but Recommended)

For production, you should create a backend API (Node.js/Python/etc.) with Firebase Admin SDK to send notifications:

```javascript
// Example Node.js function
const admin = require('firebase-admin');

admin.initializeApp({
  credential: admin.credential.applicationDefault()
});

async function sendNotificationToTokens(tokens, title, body, data) {
  const message = {
    notification: {
      title: title,
      body: body
    },
    data: data,
    tokens: tokens
  };
  
  const response = await admin.messaging().sendMulticast(message);
  console.log(`${response.successCount} messages sent successfully`);
}
```

## Usage

### Initialize Notifications (Already done in main.dart)
```dart
await Firebase.initializeApp();
await FirebaseMessagingService().initialize();
```

### Send Notification When Teacher Posts
```dart
final notificationProvider = context.read<NotificationProvider>();

await notificationProvider.notifyStudentsAboutNewPost(
  courseId: course.id,
  postTitle: 'منشور جديد',
  postContent: 'محتوى المنشور',
  postId: postId,
);
```

### Subscribe to Course Notifications
```dart
final notificationProvider = context.read<NotificationProvider>();
await notificationProvider.subscribeToCourse(courseId);
```

### Display Notifications
```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => const NotificationsScreen()),
);
```

### Add Notification Bell Icon
```dart
Consumer<NotificationProvider>(
  builder: (context, provider, child) {
    return Badge(
      label: Text('${provider.unreadCount}'),
      isLabelVisible: provider.unreadCount > 0,
      child: IconButton(
        icon: const Icon(Icons.notifications),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NotificationsScreen()),
          );
        },
      ),
    );
  },
)
```

## Testing

1. **Test Foreground Notifications**:
   - App is open
   - Send a test message from Firebase Console
   - Should print in console

2. **Test Background Notifications**:
   - App is in background
   - Send a test message
   - Should receive notification in system tray

3. **Test Notification Tap**:
   - Tap on notification
   - Should open app and navigate

## Troubleshooting

### Android Issues
- Ensure `google-services.json` is in correct location
- Check package name matches Firebase configuration
- Verify internet permission in `AndroidManifest.xml`

### iOS Issues
- Ensure provisioning profile includes Push Notifications
- Check `GoogleService-Info.plist` is added to Xcode project
- Verify APNS certificates in Firebase Console

### Token Issues
- Token might be null initially - check after a few seconds
- Token refreshes periodically - handle in `onTokenRefresh`
- Token is device-specific and app-specific

## Next Steps

1. ✅ Run the database migration
2. ✅ Configure Firebase for your app
3. ✅ Test notifications
4. 🔜 Add notification bell icon to AppBar
5. 🔜 Implement navigation when notification is tapped
6. 🔜 Create backend API for sending push notifications (recommended)
7. 🔜 Add notification preferences for users

## Files Created

- `lib/services/firebase_messaging_service.dart` - FCM service
- `lib/providers/notification_provider.dart` - Notification state management
- `lib/screens/notifications_screen.dart` - Notifications UI
- `database/notifications_migration.sql` - Database schema

## Notes

- Notifications are stored in database (works even without push notifications)
- Push notifications require backend API for production
- Topics allow sending to groups (e.g., all students in a course)
- FCM tokens are saved in User table for targeted notifications
