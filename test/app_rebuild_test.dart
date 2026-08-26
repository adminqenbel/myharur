import 'package:flutter_test/flutter_test.dart';
import 'package:myharur/core/models/alert.dart';
import 'package:myharur/core/models/user_profile.dart';
import 'package:myharur/core/theme/app_theme.dart';
import 'package:myharur/core/services/feature_flag_service.dart';

void main() {
  group('Core Models & Validation', () {
    test('Alert model parses correctly and formats timeAgo', () {
      final now = DateTime.now();
      final alert = Alert(
        id: 'alert-001',
        category: 'road',
        title: 'Morappur Road Maintenance',
        body: 'Lane work near the bypass junction.',
        source: 'official',
        status: 'published',
        createdAt: now.subtract(const Duration(minutes: 5)),
      );

      expect(alert.isOfficial, isTrue);
      expect(alert.isPublished, isTrue);
      expect(alert.isPending, isFalse);
      expect(alert.category.categoryLabel, equals('Road'));
      expect(alert.timeAgo, equals('5m ago'));
    });

    test('UserProfile authentication bug is fixed (guest sentinel != authenticated)', () {
      final guest = UserProfile.guest;
      expect(guest.isGuest, isTrue);
      expect(guest.isOnboardingComplete, isFalse);
      expect(guest.roles, contains('resident'));

      const realUser = UserProfile(
        id: 'user-123',
        mmid: '202608250001',
        username: 'testuser',
        fullName: 'Test Resident',
        email: 'test@example.com',
        onboardingState: 'COMPLETE',
        roles: ['resident'],
      );

      expect(realUser.isGuest, isFalse);
      expect(realUser.isOnboardingComplete, isTrue);
      expect(realUser.isAdmin, isFalse);
      expect(realUser.isSuperAdmin, isFalse);
    });

    test('FeatureFlagService defaults all non-alert modules to false', () {
      expect(FeatureFlagService.isEnabled('jobs'), isFalse);
      expect(FeatureFlagService.isEnabled('events'), isFalse);
      expect(FeatureFlagService.isEnabled('tournaments'), isFalse);
      expect(FeatureFlagService.isEnabled('chat'), isFalse);
    });

    test('AppTheme provides valid Material 3 theme', () {
      final theme = AppTheme.light;
      expect(theme.useMaterial3, isTrue);
      expect(theme.colorScheme.primary, equals(AppColors.primary));
    });
  });
}
