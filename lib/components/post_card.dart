import 'package:flutter/material.dart';
import '../models/user.dart';

class PostCard extends StatelessWidget {
  final Map<String, dynamic> post;
  final User currentUser;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const PostCard({
    super.key,
    required this.post,
    required this.currentUser,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final title = post['title'] ?? 'بدون عنوان';
    final desc = post['desc'] ?? '';
    final createdAt = post['created_at'];
    
    // Extract teacher information
    final teacher = post['Teacher'];
    final teacherUser = teacher != null ? teacher['User'] : null;
    final teacherName = teacherUser != null ? teacherUser['name'] ?? 'معلم' : 'معلم';
    final teacherInitial = teacherName.isNotEmpty ? teacherName[0] : 'م';
    final teacherImageLink = teacherUser != null ? teacherUser['image_link'] : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  backgroundImage: teacherImageLink != null
                      ? NetworkImage(teacherImageLink)
                      : null,
                  child: teacherImageLink == null
                      ? Text(
                          teacherInitial,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        teacherName,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                      if (createdAt != null)
                        Text(
                          _formatDate(createdAt),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              ),
                        ),
                    ],
                  ),
                ),
                if (currentUser.role == UserRole.teacher)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) {
                      if (value == 'edit' && onEdit != null) {
                        onEdit!();
                      } else if (value == 'delete' && onDelete != null) {
                        onDelete!();
                      }
                    },
                    itemBuilder: (BuildContext context) => [
                      const PopupMenuItem<String>(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit),
                            SizedBox(width: 8),
                            Text('تعديل'),
                          ],
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('حذف', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (desc.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                desc,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);
      
      if (diff.inMinutes < 1) {
        return 'الآن';
      } else if (diff.inHours < 1) {
        return 'منذ ${diff.inMinutes} دقيقة';
      } else if (diff.inDays < 1) {
        return 'منذ ${diff.inHours} ساعة';
      } else if (diff.inDays < 7) {
        return 'منذ ${diff.inDays} يوم';
      } else {
        return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      return '';
    }
  }
}
