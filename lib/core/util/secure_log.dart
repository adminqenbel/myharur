import 'package:flutter/foundation.dart';

/// Debug-only logging.
///
/// `debugPrint` writes to the system log in RELEASE builds too, where any app with log access on an
/// older Android (or adb on a lost phone) can read it. Everything goes through this instead, which
/// prints nothing in release. Never log tokens, passwords, e-mail addresses or addresses.
void secureLog(String message) {
  if (kDebugMode) debugPrint(message);
}
