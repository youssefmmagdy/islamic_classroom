import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:crypto/crypto.dart';

/// Service class for uploading images to Cloudinary
/// Reads credentials from .env file
class CloudinaryService {
  late final String cloudName;
  late final String apiKey;
  late final String apiSecret;

  CloudinaryService() {
    // Get credentials from .env file (similar to process.env in Node.js)
    cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';
    apiKey = dotenv.env['CLOUDINARY_API_KEY'] ?? '';
    apiSecret = dotenv.env['CLOUDINARY_API_SECRET'] ?? '';
    
    // Debug: Print credentials (remove in production)
    
  }

  /// Uploads an image to Cloudinary and returns the image URL
  /// [imageFile] - The image file to upload
  /// [userId] - User ID to use as public ID for the image
  Future<String?> uploadImage(File imageFile, String userId) async {
    try {
      final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');

      // Create multipart request for authenticated upload
      var request = http.MultipartRequest('POST', url);
      
      // Add timestamp for signature
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      
      // Add fields
      request.fields['folder'] = 'profile_images';
      request.fields['public_id'] = 'user_$userId';
      request.fields['timestamp'] = timestamp.toString();
      request.fields['api_key'] = apiKey;
      
      // Generate signature (for authenticated upload)
      final signature = _generateSignature(
        folder: 'profile_images',
        publicId: 'user_$userId',
        timestamp: timestamp,
      );
      request.fields['signature'] = signature;
      
      // Add the image file
      request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      // Send request
      var response = await request.send();
      var responseData = await http.Response.fromStream(response);

      
      if (response.statusCode == 200) {
        final data = jsonDecode(responseData.body);
        final secureUrl = data['secure_url'] as String?;
        return secureUrl;
      } else {
        return null;
      }
    } catch (e, stackTrace) {
      print('❌ Error uploading to Cloudinary: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }
  Future<String?> deleteImage(File imageFile, String userId) async {
    try {
      final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/destroy');

      // Create multipart request for authenticated upload
      var request = http.MultipartRequest('POST', url);
      
      // Add timestamp for signature
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      
      // Add fields
      request.fields['folder'] = 'profile_images';
      request.fields['public_id'] = 'user_$userId';
      request.fields['timestamp'] = timestamp.toString();
      request.fields['api_key'] = apiKey;
      
      // Generate signature (for authenticated upload)
      final signature = _generateSignature(
        folder: 'profile_images',
        publicId: 'user_$userId',
        timestamp: timestamp,
      );
      request.fields['signature'] = signature;
      
      // Add the image file
      request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      // Send request
      var response = await request.send();
      var responseData = await http.Response.fromStream(response);

      
      if (response.statusCode == 200) {
        final data = jsonDecode(responseData.body);
        final secureUrl = data['secure_url'] as String?;
        return secureUrl;
      } else {
        return null;
      }
    } catch (e, stackTrace) {
      print('❌ Error deleting from Cloudinary: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  /// Uploads a PDF file to Cloudinary and returns the PDF URL
  /// [pdfFile] - The PDF file to upload
  /// [assignmentId] - Assignment ID to use as public ID for the PDF
  /// Note: PDFs are uploaded as image resource type by default to support transformations
  Future<String?> uploadPDF(File pdfFile, String assignmentId) async {
    try {
      // Use image/upload endpoint - PDFs are treated as images by default for transformations
      final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');

      // Create multipart request with signed upload
      var request = http.MultipartRequest('POST', url);
      
      // Add timestamp for signature
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      
      // Add fields - ONLY these fields should be in the signature
      request.fields['folder'] = 'assignment_pdfs';
      request.fields['public_id'] = 'assignment_$assignmentId';
      request.fields['timestamp'] = timestamp.toString();
      // Note: No need for access_mode with image uploads - they're public by default
      
      // Generate signature
      final signature = _generateSignature(
        folder: 'assignment_pdfs',
        publicId: 'assignment_$assignmentId',
        timestamp: timestamp,
      );
      
      // Add api_key and signature AFTER generating signature
      request.fields['api_key'] = apiKey;
      request.fields['signature'] = signature;
      
      // Add the PDF file
      request.files.add(await http.MultipartFile.fromPath('file', pdfFile.path));

      // Send request
      var response = await request.send();
      var responseData = await http.Response.fromStream(response);

      
      if (response.statusCode == 200) {
        final data = jsonDecode(responseData.body);
        final secureUrl = data['secure_url'] as String?;
        return secureUrl;
      } else {
        print('❌ Cloudinary PDF upload failed with status: ${response.statusCode}');
        print('Response body: ${responseData.body}');
        return null;
      }
    } catch (e, stackTrace) {
      print('❌ Error uploading PDF to Cloudinary: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  /// Generate signature for authenticated Cloudinary upload
  /// Uses SHA-1 hash as required by Cloudinary
  String _generateSignature({
    required String folder,
    required String publicId,
    required int timestamp,
    String? resourceType,
    String? accessMode,
  }) {
    // Build parameters string (sorted alphabetically)
    final params = <String, String>{
      'folder': folder,
      'public_id': publicId,
      'timestamp': timestamp.toString(),
    };
    
    // Add resource_type if provided
    if (resourceType != null) {
      params['resource_type'] = resourceType;
    }
    
    // Add access_mode if provided
    if (accessMode != null) {
      params['access_mode'] = accessMode;
    }

    // Sort and join parameters
    final sortedKeys = params.keys.toList()..sort();
    final paramsString = sortedKeys
        .map((key) => '$key=${params[key]}')
        .join('&');

    // Append API secret
    final toSign = '$paramsString$apiSecret';

    // Generate SHA-1 hash (required by Cloudinary)
    final bytes = utf8.encode(toSign);
    final digest = sha1.convert(bytes);
    return digest.toString();
  }
}
