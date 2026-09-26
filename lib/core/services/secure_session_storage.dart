import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Keeps the Supabase session (access + refresh token) in the Android Keystore-backed encrypted
/// store instead of plain SharedPreferences, which is readable on a rooted phone and by anyone
/// with a device backup. (Backups are also disabled in the manifest.)
class SecureSessionStorage extends LocalStorage {
  const SecureSessionStorage();

  static const _key = 'myharur.session.v1';
  static const _store = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true, resetOnError: true),
  );

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasAccessToken() async => (await _store.read(key: _key)) != null;

  @override
  Future<String?> accessToken() => _store.read(key: _key);

  @override
  Future<void> persistSession(String persistSessionString) => _store.write(key: _key, value: persistSessionString);

  @override
  Future<void> removePersistedSession() => _store.delete(key: _key);
}
