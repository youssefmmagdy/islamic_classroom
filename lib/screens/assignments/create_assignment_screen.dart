import 'package:flutter/material.dart';
import '../../models/course.dart';
import '../../services/database_service.dart';

class CreateAssignmentScreen extends StatefulWidget {
  final Course course;
  final String sessionId;

  const CreateAssignmentScreen({
    super.key,
    required this.course,
    required this.sessionId,
  });

  @override
  State<CreateAssignmentScreen> createState() => _CreateAssignmentScreenState();
}

class _CreateAssignmentScreenState extends State<CreateAssignmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _databaseService = DatabaseService();
  
  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createAssignment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final result = await _databaseService.createAssignment(
        courseId: widget.course.id,
        sessionId: widget.sessionId,
        description: _descriptionController.text.trim(),
        pdfUrl: null,  // No PDF upload
        deadlineDate: _dueDate,
      );

      if (result['success'] == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إنشاء الواجب بنجاح')),
        );
        Navigator.of(context).pop(true);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'فشل في إنشاء الواجب')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectDueDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _dueDate) {
      setState(() => _dueDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إنشاء واجب جديد'),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Title Field
            // TextFormField(
            //   controller: _titleController,
            //   decoration: const InputDecoration(
            //     labelText: 'عنوان الواجب',
            //     border: OutlineInputBorder(),
            //     prefixIcon: Icon(Icons.title),
            //   ),
            //   validator: (value) {
            //     if (value == null || value.trim().isEmpty) {
            //       return 'يرجى إدخال عنوان الواجب';
            //     }
            //     return null;
            //   },
            // ),
            // const SizedBox(height: 16),

            // Description Field
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'وصف الواجب',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 4,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'يرجى إدخال وصف الواجب';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Due Date Field
            InkWell(
              onTap: _selectDueDate,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today),
                    const SizedBox(width: 12),
                    Text(
                      'تاريخ الاستحقاق: ${_dueDate.day}/${_dueDate.month}/${_dueDate.year}',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Create Button
            ElevatedButton(
              onPressed: _isLoading ? null : _createAssignment,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('إنشاء الواجب'),
            ),
          ],
        ),
      ),
    );
  }
}
