import 'package:flutter_test/flutter_test.dart';
import 'package:myharur/services/supabase_service.dart';
import 'package:myharur/services/security_service.dart';

void main() {
  group('SecurityFilterService Normalization & Reserved Usernames', () {
    test('catches exact reserved handles', () {
      expect(SecurityFilterService.isReservedUsername('admin'), isTrue);
      expect(SecurityFilterService.isReservedUsername('@police'), isTrue);
      expect(SecurityFilterService.isReservedUsername('collector_dharmapuri'), isTrue);
      expect(SecurityFilterService.isReservedUsername('superadmin'), isTrue);
    });

    test('catches leetspeak evasion attempts', () {
      expect(SecurityFilterService.isReservedUsername('4dmin'), isTrue);
      expect(SecurityFilterService.isReservedUsername('p0l1ce'), isTrue);
      expect(SecurityFilterService.isReservedUsername('c0llect0r'), isTrue);
      expect(SecurityFilterService.isReservedUsername('sup3r4dm1n'), isTrue);
      expect(SecurityFilterService.isReservedUsername('g0vt'), isTrue);
    });

    test('catches zero-width character evasion', () {
      expect(SecurityFilterService.isReservedUsername('ad\u200Bmin'), isTrue);
      expect(SecurityFilterService.isReservedUsername('pol\uFEFFice'), isTrue);
    });

    test('catches separator-spaced evasion', () {
      expect(SecurityFilterService.isReservedUsername('p_o_l_i_c_e'), isTrue);
      expect(SecurityFilterService.isReservedUsername('a-d-m-i-n'), isTrue);
      expect(SecurityFilterService.isReservedUsername('s.u.p.e.r.a.d.m.i.n'), isTrue);
    });

    test('allows legitimate resident handles', () {
      expect(SecurityFilterService.isReservedUsername('muthuvel_k'), isFalse);
      expect(SecurityFilterService.isReservedUsername('selvam_agro'), isFalse);
      expect(SecurityFilterService.isReservedUsername('karthik2026'), isFalse);
    });
  });

  group('SecurityFilterService Profanity & Name Validation', () {
    test('catches multilingual bad words', () {
      expect(SecurityFilterService.containsBadWord('fuck'), isTrue);
      expect(SecurityFilterService.containsBadWord('thevidiya'), isTrue);
      expect(SecurityFilterService.containsBadWord('bhenchod'), isTrue);
      expect(SecurityFilterService.containsBadWord('f_u_c_k'), isTrue);
    });

    test('validates clean full name and username', () {
      final res = SecurityFilterService.evaluateSafety(
        username: 'muthuvel',
        fullName: 'Muthuvel K.',
      );
      expect(res.isValid, isTrue);
      expect(res.errorMessage, isNull);
    });

    test('rejects reserved username in validation helper', () {
      final err = SecurityFilterService.validateUsernameAndName(
        username: 'police_harur',
        fullName: 'Ramanathan',
      );
      expect(err, contains('reserved'));
    });
  });

  group('PasswordSecurityService & Entropy', () {
    test('rejects weak or short passwords', () {
      final res = PasswordSecurityService.evaluatePassword('123456');
      expect(res.isValid, isFalse);
      expect(res.strength, equals(PasswordStrengthLevel.weak));
      expect(res.missingRequirements, isNotEmpty);
    });

    test('identifies strong Apple-grade entropy passwords', () {
      final res = PasswordSecurityService.evaluatePassword('K@veri#T0wn99!Citiz3n');
      expect(res.isValid, isTrue);
      expect(res.score, greaterThanOrEqualTo(0.85));
      expect(res.strengthLabel, anyOf(contains('Apple-Grade'), contains('Strong')));
    });

    test('penalizes predictable dictionary patterns', () {
      final res = PasswordSecurityService.evaluatePassword('harur12345Password!');
      expect(res.missingRequirements, contains('Avoid common words or predictable sequences'));
    });
  });

  group('RateLimitSecurityService & Brute Force Defense', () {
    test('locks account after repeated failed attempts', () {
      const testEmail = 'attacker@badsite.com';
      expect(RateLimitSecurityService.isLockedOut(testEmail), isFalse);

      for (int i = 0; i < 5; i++) {
        RateLimitSecurityService.recordFailedAttempt(testEmail);
      }

      expect(RateLimitSecurityService.isLockedOut(testEmail), isTrue);
      expect(RateLimitSecurityService.remainingLockoutSeconds(testEmail), greaterThan(0));

      // Reset
      RateLimitSecurityService.recordSuccessfulLogin(testEmail);
      expect(RateLimitSecurityService.isLockedOut(testEmail), isFalse);
    });
  });

  group('IdentityCryptoService & Anti-Tamper Signatures', () {
    test('generates deterministic SHA-256 signatures and verifies tamper detection', () {
      final sig = IdentityCryptoService.generatePassportSignature(
        mmid: '202608151208218821',
        username: 'admin.qenbel',
        fullName: 'Root SuperAdmin Qenbel',
        bloodGroup: 'O+',
        aid: 'AID-ROOT-0001',
      );
      expect(sig, isNotEmpty);
      expect(sig.length, 16);

      final isValid = IdentityCryptoService.verifyPassportSignature(
        mmid: '202608151208218821',
        username: 'admin.qenbel',
        fullName: 'Root SuperAdmin Qenbel',
        bloodGroup: 'O+',
        aid: 'AID-ROOT-0001',
        signature: sig,
      );
      expect(isValid, isTrue);

      // Tampered data should fail
      final isTamperedValid = IdentityCryptoService.verifyPassportSignature(
        mmid: '202608151208218821',
        username: 'admin.qenbel',
        fullName: 'Imposter User', // Tampered!
        bloodGroup: 'O+',
        aid: 'AID-ROOT-0001',
        signature: sig,
      );
      expect(isTamperedValid, isFalse);
    });

    test('generates and verifies 6-digit TOTP MFA codes', () {
      const secret = 'HARUR_TEST_SECRET_KEY';
      final otp = IdentityCryptoService.generateMfaOtp(secret);
      expect(otp.length, 6);
      expect(int.tryParse(otp), isNotNull);

      final verified = IdentityCryptoService.verifyMfaOtp(secretSeed: secret, otpCode: otp);
      expect(verified, isTrue);
    });
  });

  group('InputSanitizerService', () {
    test('strips HTML, SQL comments, and dangerous escape chars', () {
      final clean = InputSanitizerService.sanitize("<script>alert('hack');</script> SELECT * FROM users --");
      expect(clean, isNot(contains('<script>')));
      expect(clean, isNot(contains("'")));
      expect(clean, isNot(contains('--')));
    });

    test('validates email and phone formats', () {
      expect(InputSanitizerService.isValidEmail('resident@harur.in'), isTrue);
      expect(InputSanitizerService.isValidEmail('invalid-email'), isFalse);
      expect(InputSanitizerService.isValidPhone('9842011000'), isTrue);
      expect(InputSanitizerService.isValidPhone('123'), isFalse);
    });
  });
}
