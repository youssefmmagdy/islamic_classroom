import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/notification_provider.dart';
import '../providers/auth_provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final authProvider = context.read<AuthProvider>();
    final notificationProvider = context.read<NotificationProvider>();
    
    if (authProvider.currentUser != null) {
      await notificationProvider.loadNotifications(authProvider.currentUser!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإشعارات'),
        centerTitle: true,
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, provider, child) {
              if (provider.unreadCount > 0) {
                return IconButton(
                  icon: const Icon(Icons.done_all),
                  onPressed: () async {
                    final userId = context.read<AuthProvider>().currentUser?.id;
                    if (userId != null) {
                      await provider.markAllAsRead(userId);
                    }
                  },
                  tooltip: 'تحديد الكل كمقروء',
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, child) {
          if (provider.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'لا توجد إشعارات',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadNotifications,
            child: ListView.builder(
              itemCount: provider.notifications.length,
              itemBuilder: (context, index) {
                final notification = provider.notifications[index];
                return _buildNotificationItem(context, notification, provider);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotificationItem(
    BuildContext context,
    Map<String, dynamic> notification,
    NotificationProvider provider,
  ) {
    final isRead = notification['is_read'] as bool? ?? false;
    final title = notification['title'] as String? ?? '';
    final body = notification['body'] as String? ?? '';
    final type = notification['type'] as String? ?? '';
    final createdAt = notification['created_at'] != null
        ? DateTime.parse(notification['created_at'] as String)
        : DateTime.now();
    
    final dateFormat = DateFormat('dd/MM/yyyy - HH:mm');

    IconData icon;
    Color iconColor;
    
    switch (type) {
      case 'post':
        icon = Icons.article;
        iconColor = Colors.blue;
        break;
      case 'assignment':
        icon = Icons.assignment;
        iconColor = Colors.orange;
        break;
      case 'session':
        icon = Icons.event;
        iconColor = Colors.green;
        break;
      default:
        icon = Icons.notifications;
        iconColor = Theme.of(context).colorScheme.primary;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: isRead ? null : Theme.of(context).colorScheme.primaryContainer.withOpacity(0.1),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: iconColor.withOpacity(0.2),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              dateFormat.format(createdAt),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  ),
            ),
          ],
        ),
        trailing: !isRead
            ? Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              )
            : null,
        onTap: () async {
          // Mark as read
          if (!isRead) {
            await provider.markAsRead(notification['id'] as String);
          }
          
          // Navigate based on type
          // You can implement navigation logic here
          _handleNotificationTap(context, notification);
        },
      ),
    );
  }

  void _handleNotificationTap(BuildContext context, Map<String, dynamic> notification) {
    final type = notification['type'] as String? ?? '';
    final referenceId = notification['reference_id'] as String?;
    final courseId = notification['course_id'] as String?;
    
    // TODO: Implement navigation based on notification type
    print('Tapped notification: type=$type, referenceId=$referenceId, courseId=$courseId');
    
    // Example:
    // if (type == 'post' && referenceId != null) {
    //   Navigator.push(context, MaterialPageRoute(
    //     builder: (context) => PostDetailsScreen(postId: referenceId),
    //   ));
    // }
  }
}
