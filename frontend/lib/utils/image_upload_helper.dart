import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../api_client.dart';

class LocalImageServer {
  static HttpServer? _server;
  static String? _localIp;
  static const int port = 8080;

  static Future<String> getLocalIp() async {
    if (_localIp != null) return _localIp!;
    try {
      for (var interface in await NetworkInterface.list()) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            _localIp = addr.address;
            return _localIp!;
          }
        }
      }
    } catch (e) {
      print('Failed to get IP: $e');
    }
    return '127.0.0.1';
  }

  static Future<void> start() async {
    if (_server != null) return;
    try {
      _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
      print('Local Image Server running on port $port');
      _server!.listen((HttpRequest request) async {
        final uri = request.uri;
        if (uri.path == '/serve') {
          final encodedPath = uri.queryParameters['path'];
          if (encodedPath != null) {
            try {
              String base64Str = encodedPath;
              // Add padding if missing
              while (base64Str.length % 4 != 0) {
                base64Str += '=';
              }
              final decodedBytes = base64Url.decode(base64Str);
              final decodedPath = utf8.decode(decodedBytes);
              final file = File(decodedPath);
              
              if (await file.exists()) {
                request.response.headers.contentType = ContentType('image', 'jpeg');
                await request.response.addStream(file.openRead());
                await request.response.close();
                return;
              }
            } catch (e) {
              print('Serve error: $e');
            }
          }
        }
        request.response.statusCode = 404;
        request.response.close();
      });
    } catch (e) {
      print('Local server error: $e');
    }
  }
}

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

  /// Uploads image to the FastAPI backend
  static Future<String?> uploadImage(XFile file) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: file.name),
      });
      final response = await ApiClient.dio.post('/upload/image', data: formData);
      return response.data['url'];
    } catch (e) {
      print('[ImageUpload] Error: \$e');
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
