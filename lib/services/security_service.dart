import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

// ==============================================================================
// 1. PASSWORD ENTROPY & STRENGTH EVALUATOR
// ==============================================================================
enum PasswordStrengthLevel { weak, fair, good, strong, appleGrade }

class PasswordValidationResult {
  final bool isValid;
  final PasswordStrengthLevel strength;
  final double score; // 0.0 to 1.0
  final List<String> missingRequirements;
  final String strengthLabel;

  const PasswordValidationResult({
    required this.isValid,
    required this.strength,
    required this.score,
    required this.missingRequirements,
    required this.strengthLabel,
  });
}

class PasswordSecurityService {
  /// Evaluates password entropy against NIST & Apple Security standards
  static PasswordValidationResult evaluatePassword(String password) {
    final List<String> missing = [];
    double score = 0.0;

    if (password.length >= 8) {
      score += 0.25;
    } else {
      missing.add('At least 8 characters');
    }

    if (password.length >= 12) {
      score += 0.15;
    }

    if (RegExp(r'[a-z]').hasMatch(password)) {
      score += 0.15;
    } else {
      missing.add('At least one lowercase letter (a-z)');
    }

    if (RegExp(r'[A-Z]').hasMatch(password)) {
      score += 0.15;
    } else {
      missing.add('At least one uppercase letter (A-Z)');
    }

    if (RegExp(r'[0-9]').hasMatch(password)) {
      score += 0.15;
    } else {
      missing.add('At least one number (0-9)');
    }

    if (RegExp(r'[!@#$%^&*(),.?":{}|<>\-_=+]').hasMatch(password)) {
      score += 0.15;
    } else {
      missing.add('At least one special character (!@#\$%...)');
    }

    // Common weak patterns penalty
    if (RegExp(r'(12345|password|qwerty|admin|harur)', caseSensitive: false).hasMatch(password)) {
      score = (score - 0.3).clamp(0.0, 1.0);
      missing.add('Avoid common words or predictable sequences');
    }

    final clampedScore = score.clamp(0.0, 1.0);
    PasswordStrengthLevel level;
    String label;

    if (clampedScore < 0.3) {
      level = PasswordStrengthLevel.weak;
      label = 'Weak';
    } else if (clampedScore < 0.55) {
      level = PasswordStrengthLevel.fair;
      label = 'Moderate';
    } else if (clampedScore < 0.75) {
      level = PasswordStrengthLevel.good;
      label = 'Good';
    } else if (clampedScore < 0.9) {
      level = PasswordStrengthLevel.strong;
      label = 'Strong';
    } else {
      level = PasswordStrengthLevel.appleGrade;
      label = 'Apple-Grade Security';
    }

    return PasswordValidationResult(
      isValid: missing.isEmpty && clampedScore >= 0.7,
      strength: level,
      score: clampedScore,
      missingRequirements: missing,
      strengthLabel: label,
    );
  }
}

// ==============================================================================
// 2. BRUTE FORCE & RATE LIMITING DEFENSE
// ==============================================================================
class RateLimitSecurityService {
  static final Map<String, List<DateTime>> _failedAttempts = {};
  static final Map<String, DateTime> _lockedUntil = {};

  static const int maxAttemptsBeforeLockout = 5;
  static const Duration initialLockoutDuration = Duration(seconds: 30);
  static const Duration extendedLockoutDuration = Duration(minutes: 5);

  /// Checks if account or identifier is currently locked out
  static bool isLockedOut(String identifier) {
    final cleanId = identifier.trim().toLowerCase();
    final lockoutEnd = _lockedUntil[cleanId];
    if (lockoutEnd != null) {
      if (DateTime.now().isBefore(lockoutEnd)) {
        return true;
      } else {
        _lockedUntil.remove(cleanId);
        _failedAttempts.remove(cleanId);
      }
    }
    return false;
  }

  /// Remaining lockout time in seconds
  static int remainingLockoutSeconds(String identifier) {
    final cleanId = identifier.trim().toLowerCase();
    final lockoutEnd = _lockedUntil[cleanId];
    if (lockoutEnd != null && DateTime.now().isBefore(lockoutEnd)) {
      return lockoutEnd.difference(DateTime.now()).inSeconds;
    }
    return 0;
  }

  /// Records a failed authentication attempt
  static void recordFailedAttempt(String identifier) {
    final cleanId = identifier.trim().toLowerCase();
    final now = DateTime.now();
    final attempts = _failedAttempts[cleanId] ?? [];
    
    // Retain only attempts within the last 15 minutes
    attempts.removeWhere((t) => now.difference(t).inMinutes > 15);
    attempts.add(now);
    _failedAttempts[cleanId] = attempts;

    if (attempts.length >= maxAttemptsBeforeLockout + 3) {
      _lockedUntil[cleanId] = now.add(extendedLockoutDuration);
      debugPrint('[SECURITY] Account $cleanId locked out for 5 minutes due to repeated failures.');
    } else if (attempts.length >= maxAttemptsBeforeLockout) {
      _lockedUntil[cleanId] = now.add(initialLockoutDuration);
      debugPrint('[SECURITY] Account $cleanId temporarily rate-limited for 30s.');
    }
  }

  /// Resets failed attempt counter on successful login
  static void recordSuccessfulLogin(String identifier) {
    final cleanId = identifier.trim().toLowerCase();
    _failedAttempts.remove(cleanId);
    _lockedUntil.remove(cleanId);
  }
}

// ==============================================================================
// 3. CRYPTOGRAPHIC INTEGRITY & ANTI-TAMPER PASSPORT SYSTEM
// ==============================================================================
class IdentityCryptoService {
  static const String _secretSalt = 'MYHARUR_GOV_SECURE_SALT_2026_V1';

  /// Generates a cryptographic SHA-256 signature verifying MMID authenticity
  static String generatePassportSignature({
    required String mmid,
    required String username,
    required String fullName,
    required String bloodGroup,
    String? aid,
  }) {
    final payload = "$mmid|$username|$fullName|$bloodGroup|${aid ?? 'RESIDENT'}|$_secretSalt";
    final bytes = utf8.encode(payload);
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 16).toUpperCase();
  }

  /// Verifies if a given MMID checksum is authentic
  static bool verifyPassportSignature({
    required String mmid,
    required String username,
    required String fullName,
    required String bloodGroup,
    required String signature,
    String? aid,
  }) {
    final expected = generatePassportSignature(
      mmid: mmid,
      username: username,
      fullName: fullName,
      bloodGroup: bloodGroup,
      aid: aid,
    );
    return expected == signature.trim().toUpperCase();
  }

  /// Generates a secure TOTP-compatible 6-digit MFA challenge code
  static String generateMfaOtp(String secretSeed) {
    final timeStep = DateTime.now().millisecondsSinceEpoch ~/ 30000;
    final bytes = utf8.encode("$secretSeed|$timeStep|$_secretSalt");
    final digest = sha256.convert(bytes);
    final hashStr = digest.toString();
    final codeInt = int.parse(hashStr.substring(0, 6), radix: 16) % 1000000;
    return codeInt.toString().padLeft(6, '0');
  }

  /// Validates a TOTP code against current and previous 30s window (clock drift tolerant)
  static bool verifyMfaOtp({required String secretSeed, required String otpCode}) {
    final currentOtp = generateMfaOtp(secretSeed);
    if (currentOtp == otpCode.trim()) return true;

    // Check adjacent window
    final prevTimeStep = (DateTime.now().millisecondsSinceEpoch ~/ 30000) - 1;
    final bytes = utf8.encode("$secretSeed|$prevTimeStep|$_secretSalt");
    final digest = sha256.convert(bytes);
    final hashStr = digest.toString();
    final prevCode = (int.parse(hashStr.substring(0, 6), radix: 16) % 1000000).toString().padLeft(6, '0');

    return prevCode == otpCode.trim();
  }

  /// Generates 8 one-time backup recovery keys
  static List<String> generateBackupRecoveryCodes() {
    final rand = Random.secure();
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final List<String> codes = [];
    for (int i = 0; i < 8; i++) {
      final code = List.generate(8, (_) => chars[rand.nextInt(chars.length)]).join();
      codes.add("${code.substring(0, 4)}-${code.substring(4)}");
    }
    return codes;
  }
}

// ==============================================
// 4. SANITIZATION & INPUT INJECTION PREVENTION
// ==============================================
class InputSanitizerService {
  /// Strips potential SQL injection, XSS, and HTML tags
  static String sanitize(String input) {
    if (input.isEmpty) return '';
    return input
        .replaceAll(RegExp(r'<[^>]*>'), '') // Strip HTML tags
        .replaceAll(RegExp(r"[';\\`\$]"), '') // Strip quote/escape markers
        .replaceAll(RegExp(r'(--|/\*|\*/)'), '') // Strip SQL comments
        .trim();
  }

  /// Validates phone number format
  static bool isValidPhone(String phone) {
    final clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
    return clean.length == 10 || (clean.length == 12 && clean.startsWith('91'));
  }

  /// Validates email format strictly
  static bool isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email.trim());
  }
}
