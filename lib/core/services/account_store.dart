import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../util/secure_log.dart';

// ==============================================================================
// SAVED ACCOUNTS for "Switch account". Up to [maxAccounts] people who signed in on this phone.
// Only what is needed to switch is kept (name, @username, photo link, refresh token), in the same
// Android Keystore-backed store as the live session. Signing out or deleting an account removes its entry.
// Not used on the web build: browser storage is not a safe place for other people's refresh tokens.
// ==============================================================================
class SavedAccount {
  final String id;
  final String name;
  final String username;
  final String? avatarUrl;
  final String refreshToken;

  const SavedAccount({required this.id, required this.name, required this.username, this.avatarUrl, required this.refreshToken});

  SavedAccount copyWith({String? name, String? username, String? avatarUrl, String? refreshToken}) => SavedAccount(
        id: id,
        name: name ?? this.name,
        username: username ?? this.username,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        refreshToken: refreshToken ?? this.refreshToken,
      );

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'username': username, 'avatar': avatarUrl, 'rt': refreshToken};

  static SavedAccount? tryParse(Object? j) {
    if (j is! Map) return null;
    final id = j['id'], rt = j['rt'];
    if (id is! String || rt is! String || rt.isEmpty) return null;
    return SavedAccount(
      id: id,
      name: j['name'] as String? ?? '',
      username: j['username'] as String? ?? '',
      avatarUrl: j['avatar'] as String?,
      refreshToken: rt,
    );
  }
}

class AccountStore {
  static const maxAccounts = 3;
  static const _key = 'myharur.accounts.v1';
  static const _store = FlutterSecureStorage(aOptions: AndroidOptions(encryptedSharedPreferences: true, resetOnError: true));

  /// Most recently used first.
  static final ValueNotifier<List<SavedAccount>> accounts = ValueNotifier(const []);

  static bool get supported => !kIsWeb;

  static Future<void>? _loading;

  /// Loads once; every writer waits for it so a fast sign-in cannot overwrite the saved list.
  static Future<void> load() => _loading ??= _load();

  static Future<void> _load() async {
    if (!supported) return;
    try {
      final raw = await _store.read(key: _key);
      if (raw == null) return;
      final list = (jsonDecode(raw) as List).map(SavedAccount.tryParse).whereType<SavedAccount>().take(maxAccounts).toList();
      accounts.value = list;
    } catch (e) {
      secureLog('[ACCOUNTS] load failed, starting empty');
      accounts.value = const [];
    }
  }

  static Future<void> _save() async {
    try {
      await _store.write(key: _key, value: jsonEncode(accounts.value.map((a) => a.toJson()).toList()));
    } catch (e) {
      secureLog('[ACCOUNTS] save failed');
    }
  }

  /// Adds or refreshes an account and makes it the most recent. Returns false when the phone already
  /// holds [maxAccounts] other accounts (the person must sign one out first).
  static Future<bool> remember(SavedAccount a) async {
    if (!supported) return true;
    await load();
    final others = accounts.value.where((x) => x.id != a.id).toList();
    if (others.length >= maxAccounts) return false;
    accounts.value = [a, ...others];
    await _save();
    return true;
  }

  /// Refresh tokens rotate; keep the stored one current so a later switch still works.
  static Future<void> updateToken(String id, String refreshToken) async {
    if (!supported) return;
    await load();
    final list = accounts.value;
    final i = list.indexWhere((x) => x.id == id);
    if (i < 0 || list[i].refreshToken == refreshToken) return;
    final next = [...list];
    next[i] = list[i].copyWith(refreshToken: refreshToken);
    accounts.value = next;
    await _save();
  }

  static Future<void> remove(String id) async {
    if (!supported) return;
    accounts.value = accounts.value.where((x) => x.id != id).toList();
    await _save();
  }

  static Future<void> clear() async {
    accounts.value = const [];
    try {
      await _store.delete(key: _key);
    } catch (_) {}
  }

  @visibleForTesting
  static void debugSet(List<SavedAccount> list) => accounts.value = list;
}
