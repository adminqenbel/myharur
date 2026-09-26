import 'package:flutter_test/flutter_test.dart';
import 'package:myharur/core/models/alert.dart';
import 'package:myharur/core/models/user_profile.dart';
import 'package:myharur/core/services/alerts_service.dart';

UserProfile _user(List<String> roles) => UserProfile(
      id: 'u1',
      mmid: '1',
      username: 'u',
      fullName: 'U',
      email: 'u@example.com',
      onboardingState: 'COMPLETE',
      roles: roles,
    );

void main() {
  group('Roles', () {
    test('moderator, admin and superadmin can review; others cannot', () {
      expect(_user(['resident']).isStaff, isFalse);
      expect(_user(['resident', 'govt_official']).isStaff, isFalse);
      expect(_user(['resident', 'moderator']).isStaff, isTrue);
      expect(_user(['resident', 'admin']).isStaff, isTrue);
      expect(_user(['resident', 'superadmin']).isStaff, isTrue);
    });

    test('primaryRole ranks superadmin > admin > moderator > govt > resident', () {
      expect(_user(['resident', 'moderator', 'govt_official']).primaryRole, 'Moderator');
      expect(_user(['resident', 'admin', 'moderator']).primaryRole, 'Admin');
      expect(_user(['resident']).primaryRole, 'Resident');
    });

    test('emergency privilege is lost at 2 strikes', () {
      expect(_user(['resident']).copyWith(emergencyStrikes: 1).hasEmergencyPrivilege, isTrue);
      expect(_user(['resident']).copyWith(emergencyStrikes: 2).hasEmergencyPrivilege, isFalse);
    });
  });

  group('Alert model', () {
    test('parses moderation fields from the database row', () {
      final alert = Alert.fromJson({
        'id': 'a1',
        'category': 'water',
        'title': 'Pipe burst',
        'body': 'Main pipe burst near the bus stand',
        'source': 'community',
        'status': 'pending',
        'created_at': '2026-09-26T10:00:00Z',
        'moderation_flags': ['dangerous_terms', 'link'],
        'flagged_by_system': true,
        'moderation_reason': null,
      });
      expect(alert.moderationFlags, ['dangerous_terms', 'link']);
      expect(alert.flaggedBySystem, isTrue);
      expect(alert.isPending, isTrue);
    });

    test('defaults are safe when moderation columns are absent', () {
      final alert = Alert.fromJson({'id': 'a2', 'created_at': '2026-09-26T10:00:00Z'});
      expect(alert.moderationFlags, isEmpty);
      expect(alert.flaggedBySystem, isFalse);
    });
  });

  group('AlertsService without a backend', () {
    test('feed returns null (error state), never a silent empty list', () async {
      expect(await AlertsService.fetchFeedAlerts(), isNull);
    });

    test('submit reports an account problem instead of throwing', () async {
      final outcome = await AlertsService.submitAlert(
        category: 'road',
        title: 'Pothole on main road',
        body: 'Large pothole near the bus stand',
      );
      expect(outcome, SubmitOutcome.accountIssue);
    });

    test('review actions fail closed', () async {
      expect(await AlertsService.approve('x'), isFalse);
      expect(await AlertsService.reject('x', 'spam'), isFalse);
      expect(await AlertsService.fetchReviewQueue(), isNull);
    });
  });
}
