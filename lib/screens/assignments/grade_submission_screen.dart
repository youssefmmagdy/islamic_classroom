import 'package:flutter/material.dart';
import '../../models/assignment.dart';

class GradeSubmissionScreen extends StatefulWidget {
  final Map<String, dynamic> submission;
  final Map<String, dynamic> student;
  final Assignment assignment;

  const GradeSubmissionScreen({
    super.key,
    required this.submission,
    required this.student,
    required this.assignment,
  });

  @override
  State<GradeSubmissionScreen> createState() => _GradeSubmissionScreenState();
}

class _GradeSubmissionScreenState extends State<GradeSubmissionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _gradeController = TextEditingController();
  final _feedbackController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.submission['grade'] != null) {
      _gradeController.text = widget.submission['grade'].toString();
    }
    if (widget.submission['feedback'] != null) {
      _feedbackController.text = widget.submission['feedback'];
    }
  }

  @override
  void dispose() {
    _gradeController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _saveGrade() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // In a real app, you would call the database service here
      // await _databaseService.gradeSubmission(...)
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ التقييم بنجاح')),
      );
      Navigator.of(context).pop();
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
    return Scaffold(
      appBar: AppBar(
        title: Text('تقييم ${widget.student['name']}'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveGrade,
            child: const Text('حفظ'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Student Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'معلومات الطالب',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text('الاسم: ${widget.student['name'] ?? 'غير محدد'}'),
                    Text('الهاتف: ${widget.student['phone'] ?? 'غير محدد'}'),
                    Text('تاريخ التسليم: ${widget.submission['submitted_at'] ?? 'غير محدد'}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Assignment Info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'معلومات الواجب',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text('العنوان: ${widget.assignment.title}'),
                    Text('الوصف: ${widget.assignment.description}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Submission Content
            if (widget.submission['content'] != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'إجابة الطالب',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(widget.submission['content']),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Attachments
            if (widget.submission['attachments'] != null && 
                (widget.submission['attachments'] as List).isNotEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'المرفقات',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      ...(widget.submission['attachments'] as List).map((attachment) => 
                        ListTile(
                          leading: const Icon(Icons.attachment),
                          title: Text(attachment),
                          onTap: () {
                            // In a real app, you would open the file here
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Grade Input
            TextFormField(
              controller: _gradeController,
              decoration: const InputDecoration(
                labelText: 'الدرجة',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.grade),
                suffixText: '/100',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'يرجى إدخال الدرجة';
                }
                final grade = double.tryParse(value);
                if (grade == null || grade < 0 || grade > 100) {
                  return 'الدرجة يجب أن تكون بين 0 و 100';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Feedback Input
            TextFormField(
              controller: _feedbackController,
              decoration: const InputDecoration(
                labelText: 'التعليقات (اختياري)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.comment),
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 24),

            // Save Button
            ElevatedButton(
              onPressed: _isLoading ? null : _saveGrade,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('حفظ التقييم'),
            ),
          ],
        ),
      ),
    );
  }
}
