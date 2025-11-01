import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user.dart';
import '../services/supabase_service.dart';
import '../services/cloudinary_service.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  UserRole _selectedRole = UserRole.student;
  DateTime? _selectedBirthDate;
  String _selectedGender = '';
  String _selectedCountryCode = '+20'; // Default to Egypt
  
  // Profile image handling
  File? _profileImage;
  String? _uploadedImageUrl;
  final bool _isUploadingImage = false;
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final ImagePicker _imagePicker = ImagePicker();
  
  // Common country codes for the region
  final List<Map<String, String>> _countryCodes = [
    {'code': '+966', 'country': 'السعودية', 'flag': '🇸🇦', 'example': '501234567'},
    {'code': '+971', 'country': 'الإمارات', 'flag': '🇦🇪', 'example': '501234567'},
    {'code': '+965', 'country': 'الكويت', 'flag': '🇰🇼', 'example': '51234567'},
    {'code': '+973', 'country': 'البحرين', 'flag': '🇧🇭', 'example': '36123456'},
    {'code': '+974', 'country': 'قطر', 'flag': '🇶🇦', 'example': '33123456'},
    {'code': '+968', 'country': 'عُمان', 'flag': '🇴🇲', 'example': '91234567'},
    {'code': '+962', 'country': 'الأردن', 'flag': '🇯🇴', 'example': '791234567'},
    {'code': '+961', 'country': 'لبنان', 'flag': '🇱🇧', 'example': '71123456'},
    {'code': '+20', 'country': 'مصر', 'flag': '🇪🇬', 'example': '1012345678'},
    {'code': '+212', 'country': 'المغرب', 'flag': '🇲🇦', 'example': '612345678'},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _selectBirthDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      helpText: 'اختر تاريخ الميلاد',
      cancelText: 'إلغاء',
      confirmText: 'تأكيد',
    );
    if (picked != null && picked != _selectedBirthDate) {
      setState(() {
        _selectedBirthDate = picked;
      });
    }
  }

  String _getCurrentCountryExample() {
    final country = _countryCodes.firstWhere(
      (country) => country['code'] == _selectedCountryCode,
      orElse: () => _countryCodes[0],
    );
    return country['example'] ?? '501234567';
  }

  String _validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'يرجى إدخال رقم الهاتف';
    }
    
    // Remove any spaces or special characters for validation
    String cleanNumber = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    
    // Basic validation based on selected country
    switch (_selectedCountryCode) {
      case '+966': // Saudi Arabia
        if (cleanNumber.length != 9 || !cleanNumber.startsWith('5')) {
          return 'رقم سعودي غير صحيح (يجب أن يبدأ بـ 5 ويحتوي على 9 أرقام)';
        }
        break;
      case '+971': // UAE
        if (cleanNumber.length != 9 || !['50', '52', '54', '55', '56', '58'].any((prefix) => cleanNumber.startsWith(prefix))) {
          return 'رقم إماراتي غير صحيح';
        }
        break;
      case '+965': // Kuwait
        if (cleanNumber.length != 8) {
          return 'رقم كويتي غير صحيح (8 أرقام)';
        }
        break;
      default:
        if (cleanNumber.length < 7 || cleanNumber.length > 15) {
          return 'رقم هاتف غير صحيح';
        }
    }
    
    return '';
  }

  Future<void> _pickImage() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('اختر صورة الملف الشخصي'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('الكاميرا'),
              onTap: () {
                Navigator.pop(context);
                _pickAndSetImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('المعرض'),
              onTap: () {
                Navigator.pop(context);
                _pickAndSetImage(ImageSource.gallery);
              },
            ),
            if (_profileImage != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('حذف الصورة', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _profileImage = null;
                    _uploadedImageUrl = null;
                  });
                },
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndSetImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      setState(() {
        _profileImage = File(pickedFile.path);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في اختيار الصورة: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedBirthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('يرجى اختيار تاريخ الميلاد'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    // Additional phone validation
    String phoneValidation = _validatePhoneNumber(_phoneController.text);
    if (phoneValidation.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(phoneValidation),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Upload profile image if selected
      if (_profileImage != null && !_isUploadingImage) {
        try {
          // Generate temporary ID for image upload (will be replaced with actual user ID after registration)
          final tempId = DateTime.now().millisecondsSinceEpoch.toString();
          _uploadedImageUrl = await _cloudinaryService.uploadImage(
            _profileImage!,
            tempId,
          );
        } catch (e) {
          print('Image upload failed: $e');
          // Continue registration even if image upload fails
        }
      }

      // Register user with Supabase
      final result = await SupabaseService().registerUser(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        countryCode: _selectedCountryCode,
        phone: _phoneController.text.trim(),
        gender: _selectedGender,
        birthDate: _selectedBirthDate!,
        role: _selectedRole,
        password: _passwordController.text.trim(),
        imageLink: _uploadedImageUrl,
      );

      // Hide loading indicator
      if (mounted) Navigator.of(context).pop();

      if (result['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Theme.of(context).colorScheme.primary,
              duration: const Duration(seconds: 5),
            ),
          );
          
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Theme.of(context).colorScheme.error,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      // Hide loading indicator
      if (mounted) Navigator.of(context).pop();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ غير متوقع: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إنشاء حساب جديد'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Profile Picture (Optional)
                Center(
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary,
                            width: 3,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          backgroundImage: _profileImage != null
                              ? FileImage(_profileImage!)
                              : null,
                          child: _profileImage == null
                              ? Icon(
                                  Icons.person_add,
                                  size: 60,
                                  color: Theme.of(context).colorScheme.primary,
                                )
                              : null,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          child: IconButton(
                            icon: const Icon(
                              Icons.camera_alt,
                              size: 18,
                              color: Colors.white,
                            ),
                            onPressed: _pickImage,
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'صورة الملف الشخصي (اختياري)',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                
                // Role Selection
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'نوع الحساب',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: RadioListTile<UserRole>(
                                title: const Text('طالب'),
                                subtitle: const Text('للطلاب'),
                                value: UserRole.student,
                                groupValue: _selectedRole,
                                onChanged: (value) {
                                  setState(() {
                                    _selectedRole = value!;
                                  });
                                },
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                            Expanded(
                              child: RadioListTile<UserRole>(
                                title: const Text('معلم'),
                                subtitle: const Text('للمعلمين'),
                                value: UserRole.teacher,
                                groupValue: _selectedRole,
                                onChanged: (value) {
                                  setState(() {
                                    _selectedRole = value!;
                                  });
                                },
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Name Field
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'الاسم الكامل',
                    hintText: 'أدخل اسمك الكامل',
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'يرجى إدخال الاسم الكامل';
                    }
                    if (value.length < 2) {
                      return 'الاسم يجب أن يكون أكثر من حرفين';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Email Field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textDirection: TextDirection.ltr,
                  decoration: const InputDecoration(
                    labelText: 'البريد الإلكتروني',
                    hintText: 'example@email.com',
                    prefixIcon: Icon(Icons.email),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'يرجى إدخال البريد الإلكتروني';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'يرجى إدخال بريد إلكتروني صحيح';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Phone Field with Country Code
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'رقم الهاتف',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      textDirection: TextDirection.ltr, // Ensure left-to-right layout
                      children: [
                        // Country Code Dropdown (Left side)
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedCountryCode,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                              items: _countryCodes.map((country) {
                                return DropdownMenuItem<String>(
                                  value: country['code'],
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        country['flag']!,
                                        style: const TextStyle(fontSize: 18),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        country['code']!,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                        ),
                                        textDirection: TextDirection.ltr,
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    _selectedCountryCode = newValue;
                                    _phoneController.clear(); // Clear when country changes
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Phone Number Input (Right side)
                        Expanded(
                          child: TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            textDirection: TextDirection.ltr,
                            decoration: InputDecoration(
                              hintText: _getCurrentCountryExample(),
                              hintStyle: TextStyle(
                                color: Theme.of(context).hintColor,
                              ),
                              prefixIcon: const Icon(Icons.phone),
                              border: const OutlineInputBorder(),
                            ),
                            validator: (value) {
                              String validation = _validatePhoneNumber(value);
                              return validation.isEmpty ? null : validation;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Example text below the fields
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Text(
                        'مثال: $_selectedCountryCode ${_getCurrentCountryExample()}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          fontSize: 12,
                        ),
                        textDirection: TextDirection.ltr,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Birth Date Field
                InkWell(
                  onTap: _selectBirthDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'تاريخ الميلاد',
                      hintText: 'اختر تاريخ الميلاد',
                      prefixIcon: Icon(Icons.calendar_today),
                      suffixIcon: Icon(Icons.arrow_drop_down),
                    ),
                    child: Text(
                      _selectedBirthDate == null
                          ? 'اختر تاريخ الميلاد'
                          : '${_selectedBirthDate!.day}/${_selectedBirthDate!.month}/${_selectedBirthDate!.year}',
                      style: TextStyle(
                        color: _selectedBirthDate == null
                            ? Theme.of(context).hintColor
                            : Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Gender Field
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'الجنس',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: RadioListTile<String>(
                                title: const Text('ذكر'),
                                value: 'male',
                                groupValue: _selectedGender,
                                onChanged: (value) {
                                  setState(() {
                                    _selectedGender = value!;
                                  });
                                },
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                            Expanded(
                              child: RadioListTile<String>(
                                title: const Text('أنثى'),
                                value: 'female',
                                groupValue: _selectedGender,
                                onChanged: (value) {
                                  setState(() {
                                    _selectedGender = value!;
                                  });
                                },
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Password Field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'كلمة المرور',
                    hintText: 'أدخل كلمة مرور قوية',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'يرجى إدخال كلمة المرور';
                    }
                    if (value.length < 6) {
                      return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Confirm Password Field
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'تأكيد كلمة المرور',
                    hintText: 'أعد إدخال كلمة المرور',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'يرجى تأكيد كلمة المرور';
                    }
                    if (value != _passwordController.text) {
                      return 'كلمة المرور غير متطابقة';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                
                // Register Button
                ElevatedButton(
                  onPressed: _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    foregroundColor: Theme.of(context).colorScheme.onSecondary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'إنشاء الحساب',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Login Link
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                    );
                  },
                  child: const Text('لديك حساب بالفعل؟ تسجيل الدخول'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}