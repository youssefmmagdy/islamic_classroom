import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../../models/assignment.dart';
import '../../models/course.dart';
import '../../providers/auth_provider.dart';
import '../../services/database_service.dart';

class SubmitAssignmentScreen extends StatefulWidget {
  final Assignment assignment;
  final Course course;

  const SubmitAssignmentScreen({
    super.key,
    required this.assignment,
    required this.course,
  });

  @override
  State<SubmitAssignmentScreen> createState() => _SubmitAssignmentScreenState();
}

class _SubmitAssignmentScreenState extends State<SubmitAssignmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _contentController = TextEditingController();
  final _databaseService = DatabaseService();
  
  List<String> _attachments = [];
  bool _isLoading = false;
  Map<String, dynamic>? _existingSubmission;

  @override
  void initState() {
    super.initState();
    _loadExistingSubmission();
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingSubmission() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;
    
    if (currentUser != null) {
      try {
        final submission = await _databaseService.getStudentSubmission(
          widget.assignment.id,
          currentUser.id,
        );
        
        if (submission != null) {
          setState(() {
            _existingSubmission = submission;
            _contentController.text = submission['content'] ?? '';
            _attachments = List<String>.from(submission['attachments'] ?? []);
          });
        }
      } catch (e) {
        print('Error loading existing submission: $e');
      }
    }
  }

  Future<void> _pickFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
      );

      if (result != null) {
        setState(() {
          _attachments.addAll(result.files.map((file) => file.path!).toList());
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في اختيار الملفات: $e')),
      );
    }
  }

  void _removeAttachment(int index) {
    setState(() {
      _attachments.removeAt(index);
    });
  }

  Future<void> _submitAssignment() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;
    
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى تسجيل الدخول أولاً')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await _databaseService.submitAssignment(
        assignmentId: widget.assignment.id,
        studentId: currentUser.id,
        content: _contentController.text.trim(),
        attachments: _attachments,
      );

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تسليم الواجب بنجاح')),
        );
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'فشل في تسليم الواجب')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOverdue = widget.assignment.isOverdue;
    final isSubmitted = _existingSubmission != null && 
        (_existingSubmission!['status'] == 'submitted' || 
         _existingSubmission!['status'] == 'graded');

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.assignment.title),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Assignment Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.assignment.title,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.assignment.description,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          isOverdue ? Icons.warning : Icons.calendar_today,
                          size: 16,
                          color: isOverdue ? Colors.red : null,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'تاريخ الاستحقاق: ${widget.assignment.dueDate.day}/${widget.assignment.dueDate.month}/${widget.assignment.dueDate.year}',
                          style: TextStyle(
                            color: isOverdue ? Colors.red : null,
                          ),
                        ),
                      ],
                    ),
                    if (isOverdue)
                      const Text(
                        'انتهت مهلة التسليم',
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Submission Status
            if (isSubmitted) ...[
              Card(
                color: Colors.green.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 8),
                      Text(
                        'تم تسليم الواجب',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Content Field
            TextFormField(
              controller: _contentController,
              decoration: const InputDecoration(
                labelText: 'إجابة الواجب',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.edit),
                hintText: 'اكتب إجابتك هنا...',
              ),
              maxLines: 8,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'يرجى إدخال إجابة الواجب';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // File Attachments
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.attachment),
                        const SizedBox(width: 8),
                        Text(
                          'المرفقات',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _pickFiles,
                      icon: const Icon(Icons.add),
                      label: const Text('إضافة ملفات'),
                    ),
                    if (_attachments.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      ...List.generate(_attachments.length, (index) {
                        return ListTile(
                          leading: const Icon(Icons.insert_drive_file),
                          title: Text(_attachments[index].split('/').last),
                          trailing: IconButton(
                            onPressed: () => _removeAttachment(index),
                            icon: const Icon(Icons.close),
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            ElevatedButton(
              onPressed: _isLoading ? null : _submitAssignment,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: isSubmitted ? Colors.green : null,
              ),
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : Text(isSubmitted ? 'تحديث التسليم' : 'تسليم الواجب'),
            ),
          ],
        ),
      ),
    );
  }
}
