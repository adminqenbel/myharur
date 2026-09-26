import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../util/secure_log.dart';
import 'supabase_config.dart';

// ==============================================================================
// PHOTOS for reports and news.
//   pick -> re-encode (JPEG, max 1600 px, EXIF/GPS removed) -> upload to the private `content-images` bucket
//   show -> short-lived signed URLs; storage only signs files of posts the caller may see
// Re-encoding is what removes the location and camera data inside a photo: the pixels are copied, nothing else.
// The database also caps a post at 3 photos and requires the path to be {your user id}/{uuid}.jpg.
// ==============================================================================
class PhotoService {
  static const bucket = 'content-images';
  static const maxPhotos = 3;
  static const _maxEdge = 1600;
  static const _maxBytes = 2 * 1024 * 1024;

  static final ImagePicker _picker = ImagePicker();

  /// Test hooks (plugins are not available in widget tests).
  @visibleForTesting
  static Future<String?> Function(String path)? debugUrlFor;

  // ── choose ───────────────────────────────────────────────────────────────────

  static Future<List<XFile>> pickFromGallery({required int limit}) async {
    if (limit <= 0) return const [];
    try {
      final picked = limit == 1 ? [await _picker.pickImage(source: ImageSource.gallery)] : await _picker.pickMultiImage(limit: limit);
      return picked.whereType<XFile>().take(limit).toList();
    } catch (e) {
      secureLog('[PHOTO] gallery pick failed: $e');
      return const [];
    }
  }

  static Future<XFile?> takePhoto() async {
    try {
      return await _picker.pickImage(source: ImageSource.camera);
    } catch (e) {
      secureLog('[PHOTO] camera failed: $e');
      return null;
    }
  }

  // ── prepare + upload ─────────────────────────────────────────────────────────

  /// JPEG bytes, at most 1600 px on the long side and 2 MB, with no EXIF/GPS. Null if it cannot be made small enough.
  static Future<Uint8List?> prepare(XFile file) async {
    try {
      final raw = await file.readAsBytes();
      for (final quality in const [82, 65, 50]) {
        final out = await FlutterImageCompress.compressWithList(
          raw,
          minWidth: _maxEdge,
          minHeight: _maxEdge,
          quality: quality,
          format: CompressFormat.jpeg,
          keepExif: false, // explicit: nothing from the original metadata survives
          autoCorrectionAngle: true, // apply the camera rotation before the metadata is dropped
        );
        if (out.length <= _maxBytes) return out;
      }
    } catch (e) {
      secureLog('[PHOTO] prepare failed: $e');
    }
    return null;
  }

  /// Uploads prepared JPEG bytes. Returns the storage path to put in the post, or null on failure.
  static Future<String?> upload(Uint8List jpeg) async {
    final client = SupabaseConfig.client;
    final uid = client?.auth.currentUser?.id;
    if (client == null || uid == null) return null;
    final path = '$uid/${uuid4()}.jpg';
    try {
      await client.storage.from(bucket).uploadBinary(
            path,
            jpeg,
            fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: false),
          );
      return path;
    } catch (e) {
      secureLog('[PHOTO] upload failed: $e');
      return null;
    }
  }

  /// Best-effort removal of an upload that was never attached to a post (the nightly purge is the safety net).
  static Future<void> discard(String path) async {
    try {
      await SupabaseConfig.client?.storage.from(bucket).remove([path]);
    } catch (_) {}
  }

  // ── show ─────────────────────────────────────────────────────────────────────

  static final Map<String, _CachedUrl> _urls = {};
  static const _urlLife = Duration(minutes: 50); // signed for 1 h

  /// A short-lived URL for [path], or null when the caller may not see it / offline.
  static Future<String?> urlFor(String path) async {
    final hook = debugUrlFor;
    if (hook != null) return hook(path);
    final hit = _urls[path];
    if (hit != null && hit.expires.isAfter(DateTime.now())) return hit.url;
    final client = SupabaseConfig.client;
    if (client == null) return null;
    try {
      final url = await client.storage.from(bucket).createSignedUrl(path, 3600);
      _urls[path] = _CachedUrl(url, DateTime.now().add(_urlLife));
      return url;
    } catch (e) {
      secureLog('[PHOTO] sign failed');
      return null;
    }
  }

  static void clearCache() => _urls.clear();

  /// RFC 4122 version 4 UUID from a secure random source (lowercase hex, as the database expects).
  static String uuid4() {
    final r = Random.secure();
    final b = List<int>.generate(16, (_) => r.nextInt(256));
    b[6] = (b[6] & 0x0f) | 0x40;
    b[8] = (b[8] & 0x3f) | 0x80;
    final h = b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
    return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
  }
}

class _CachedUrl {
  final String url;
  final DateTime expires;
  const _CachedUrl(this.url, this.expires);
}
