import 'package:flutter_test/flutter_test.dart';
import 'package:myharur/services/supabase_service.dart';

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
}
