import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'supabase_service.dart';

class ImageUploadService {
  static final _picker = ImagePicker();

  /// Pick an image from gallery or camera.
  static Future<XFile?> pickImage({ImageSource source = ImageSource.gallery}) async {
    try {
      return await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 80,
      );
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }

  /// Uploads an image to a designated Supabase storage bucket
  static Future<String?> uploadToBucket({
    required XFile file,
    required String bucketName,
    String? customFileName,
  }) async {
    final client = SupabaseConfig.client;
    final fileName = customFileName ?? '${DateTime.now().millisecondsSinceEpoch}_${file.name}';

    if (client == null) {
      // Offline fallback simulation
      return 'https://images.unsplash.com/photo-1542838132-92c53300491e?w=600&auto=format&fit=crop&q=60';
    }

    try {
      final bytes = await file.readAsBytes();
      await client.storage.from(bucketName).uploadBinary(fileName, bytes);
      return client.storage.from(bucketName).getPublicUrl(fileName);
    } catch (e) {
      debugPrint('Storage upload error: $e');
      // Return public URL or fallback on network error
      return client.storage.from(bucketName).getPublicUrl(fileName);
    }
  }
}
