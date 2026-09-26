import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:myharur/core/services/photo_service.dart';
import 'exif_fixture.dart';

// A throwaway entry point (not part of the app): build with
//   flutter build apk --debug -t integration_test/exif_selfcheck_main.dart
// and read the result from `adb logcat | grep EXIF_SELFCHECK`. It runs the app's real photo pipeline on the
// phone against a GPS-tagged JPEG and reports whether the metadata survived. Same checks as photo_exif_test.dart.

bool _contains(Uint8List h, List<int> n) {
  for (var i = 0; i <= h.length - n.length; i++) {
    var ok = true;
    for (var j = 0; j < n.length; j++) {
      if (h[i + j] != n[j]) {
        ok = false;
        break;
      }
    }
    if (ok) return true;
  }
  return false;
}

bool _hasExif(Uint8List b) => _contains(b, [0xFF, 0xE1]) && _contains(b, ascii.encode('Exif'));

Future<String> _run() async {
  final original = base64Decode(exifFixtureBase64);
  final controlExif = _hasExif(original);
  final controlMake = _contains(original, ascii.encode('TestCameraMaker'));
  final out = await PhotoService.prepare(XFile.fromData(original, name: 'phone.jpg', mimeType: 'image/jpeg'));
  if (out == null) return 'FAIL prepare() returned null';
  final isJpeg = out[0] == 0xFF && out[1] == 0xD8;
  final make = _contains(out, ascii.encode('TestCameraMaker'));
  final model = _contains(out, ascii.encode('TestModel-9000'));
  final exif = _hasExif(out);
  final pass = controlExif && controlMake && isJpeg && !make && !model && !exif && out.length <= 2 * 1024 * 1024;
  return '${pass ? 'PASS' : 'FAIL'} control(exif=$controlExif make=$controlMake) original=${original.length}B '
      'prepared=${out.length}B jpeg=$isJpeg exifBlock=$exif cameraMake=$make cameraModel=$model';
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  String result;
  try {
    result = await _run();
  } catch (e) {
    result = 'FAIL exception: $e';
  }
  // ignore: avoid_print
  print('EXIF_SELFCHECK $result');
  runApp(MaterialApp(home: Scaffold(body: Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(result))))));
}
