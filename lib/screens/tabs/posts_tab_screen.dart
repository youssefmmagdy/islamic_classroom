import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/course.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../services/database_service.dart';
import '../../components/post_card.dart';

class PostsTabScreen extends StatefulWidget {
  final Course course;

  const PostsTabScreen({super.key, required this.course});

  @override
  State<PostsTabScreen> createState() => _PostsTabScreenState();
}

class _PostsTabScreenState extends State<PostsTabScreen> {
  final _dbService = DatabaseService();
  List<Map<String, dynamic>>? _posts;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    final posts = await _dbService.getCoursePosts(widget.course.id);
    if (mounted) {
      setState(() => _posts = posts);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().currentUser!;

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _loadPosts,
          child: _buildPostsList(context, user),
        ),
        if (user.role == UserRole.teacher)
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton(
              onPressed: () => _showCreatePostDialog(context),
              child: const Icon(Icons.add),
            ),
          ),
      ],
    );
  }

  Widget _buildPostsList(BuildContext context, User user) {
    if (_posts == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_posts!.isEmpty) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height - 200,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.campaign_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'لا توجد منشورات بعد',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user.role == UserRole.teacher
                        ? 'انقر على زر + لإضافة منشور جديد'
                        : 'لم يقم المعلم بنشر أي منشورات بعد',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _posts!.length,
      itemBuilder: (context, index) {
        final post = _posts![index];
        return PostCard(
          post: post,
          currentUser: user,
          onEdit: () => _showEditPostDialog(context, post),
          onDelete: () => _showDeletePostDialog(context, post),
        );
      },
    );
  }

  Future<void> _showCreatePostDialog(BuildContext context) async {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final user = context.read<AuthProvider>().currentUser!;
    bool isLoading = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('إنشاء منشور جديد'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'العنوان *',
                    hintText: 'أدخل عنوان المنشور',
                    prefixIcon: Icon(Icons.title),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) 
                      ? 'يرجى إدخال عنوان المنشور' 
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: descCtrl,
                  decoration: const InputDecoration(
                    labelText: 'المحتوى',
                    hintText: 'أدخل محتوى المنشور (اختياري)',
                    prefixIcon: Icon(Icons.description),
                  ),
                  maxLines: 5,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: isLoading ? null : () async {
                if (!formKey.currentState!.validate()) return;
                
                setState(() => isLoading = true);
                
                try {
                  final result = await _dbService.createPost(
                    courseId: widget.course.id,
                    teacherId: user.id,
                    title: titleCtrl.text.trim(),
                    desc: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                  );
                  
                  setState(() => isLoading = false);
                  
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    
                    if (context.mounted) {
                      if (result['success'] == true) {
                        // Refresh the posts list
                        this.setState(() {});
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(result['message'] ?? 'تم إنشاء المنشور بنجاح'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(result['message'] ?? 'فشل في إنشاء المنشور'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  }
                } catch (e) {
                  setState(() => isLoading = false);
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('حدث خطأ: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('إنشاء'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditPostDialog(BuildContext context, Map<String, dynamic> post) async {
    final titleCtrl = TextEditingController(text: post['title']);
    final descCtrl = TextEditingController(text: post['desc']);
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('تعديل المنشور'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'العنوان *',
                    prefixIcon: Icon(Icons.title),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) 
                      ? 'يرجى إدخال عنوان المنشور' 
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: descCtrl,
                  decoration: const InputDecoration(
                    labelText: 'المحتوى',
                    prefixIcon: Icon(Icons.description),
                  ),
                  maxLines: 5,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: isLoading ? null : () async {
                if (!formKey.currentState!.validate()) return;
                
                setState(() => isLoading = true);
                
                try {
                  final result = await _dbService.updatePost(
                    postId: post['id'],
                    courseId: widget.course.id,
                    title: titleCtrl.text.trim(),
                    desc: descCtrl.text.trim(),
                  );
                  
                  setState(() => isLoading = false);
                  
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    
                    if (context.mounted) {
                      if (result['success'] == true) {
                        // Refresh the posts list
                        this.setState(() {});
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(result['message'] ?? 'تم تحديث المنشور بنجاح'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(result['message'] ?? 'فشل في تحديث المنشور'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  }
                } catch (e) {
                  setState(() => isLoading = false);
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('حدث خطأ: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeletePostDialog(BuildContext context, Map<String, dynamic> post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف المنشور'),
        content: Text('هل أنت متأكد من رغبتك في حذف المنشور "${post['title']}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final result = await _dbService.deletePost(post['id'], widget.course.id);
        
        if (context.mounted) {
          if (result['success'] == true) {
            // Refresh the posts list
            setState(() {});
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message'] ?? 'تم حذف المنشور بنجاح'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message'] ?? 'فشل في حذف المنشور'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('حدث خطأ: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
