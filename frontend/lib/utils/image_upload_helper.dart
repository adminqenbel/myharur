import 'dart:io';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../api_client.dart';

/// Helper class for picking and uploading images.
class ImageUploadHelper {
  static final _picker = ImagePicker();

  /// Pick an image from gallery or camera and return the XFile.
  static Future<XFile?> pickImage({ImageSource source = ImageSource.gallery}) async {
    return await _picker.pickImage(
      source: source,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 80,
    );
  }

  /// Upload an XFile to the server and return the image URL.
  /// Returns null if upload fails.
  static Future<String?> uploadImage(XFile file) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: file.name,
        ),
      });

      final response = await ApiClient.dio.post(
        '/upload/image',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final url = response.data['url'] as String?;
        if (url != null) {
          // Convert relative URL to absolute
          return 'https://myharur.onrender.com$url';
        }
      }
      return null;
    } catch (e) {
      print('[ImageUpload] Error: $e');
      return null;
    }
  }

  /// Pick from gallery and upload in one step. Returns the uploaded URL.
  static Future<String?> pickAndUpload({ImageSource source = ImageSource.gallery}) async {
    final file = await pickImage(source: source);
    if (file == null) return null;
    return await uploadImage(file);
  }
}
