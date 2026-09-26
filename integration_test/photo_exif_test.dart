import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:integration_test/integration_test.dart';
import 'package:myharur/core/services/photo_service.dart';
import 'exif_fixture.dart';

// Runs ON THE PHONE (flutter test integration_test -d <device>): proves that the real compressor removes
// the camera make/model and the GPS position that a phone photo carries, and still produces a valid,
// smaller JPEG. The plugins are native, so this cannot be checked in a normal widget test.

bool _contains(Uint8List haystack, List<int> needle) {
  for (var i = 0; i <= haystack.length - needle.length; i++) {
    var ok = true;
    for (var j = 0; j < needle.length; j++) {
      if (haystack[i + j] != needle[j]) {
        ok = false;
        break;
      }
    }
    if (ok) return true;
  }
  return false;
}

/// True when the JPEG carries an EXIF block (APP1 "Exif").
bool _hasExif(Uint8List b) => _contains(b, [0xFF, 0xE1]) && _contains(b, ascii.encode('Exif'));

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the photo pipeline strips EXIF and GPS from a phone photo', (tester) async {
    final original = base64Decode(exifFixtureBase64);

    // positive control: the fixture really does carry the metadata we claim to remove
    expect(_hasExif(original), isTrue, reason: 'fixture must contain EXIF');
    expect(_contains(original, ascii.encode('TestCameraMaker')), isTrue, reason: 'fixture must contain the camera make');

    final out = await PhotoService.prepare(XFile.fromData(original, name: 'phone.jpg', mimeType: 'image/jpeg'));
    expect(out, isNotNull, reason: 'prepare() must return a JPEG');

    // still a JPEG
    expect(out![0], 0xFF);
    expect(out[1], 0xD8);
    // metadata gone
    expect(_contains(out, ascii.encode('TestCameraMaker')), isFalse, reason: 'camera make must be removed');
    expect(_contains(out, ascii.encode('TestModel-9000')), isFalse, reason: 'camera model must be removed');
    expect(_hasExif(out), isFalse, reason: 'no EXIF block may remain (this is where GPS lives)');
    // within the upload limit
    expect(out.length, lessThanOrEqualTo(2 * 1024 * 1024));
    // ignore: avoid_print
    print('EXIF_TEST original=${original.length}B exif=${_hasExif(original)} -> prepared=${out.length}B exif=${_hasExif(out)}');
  });
}
