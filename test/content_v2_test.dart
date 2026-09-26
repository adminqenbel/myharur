import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myharur/core/l10n/locale_controller.dart';
import 'package:myharur/core/models/alert.dart';
import 'package:myharur/core/models/user_profile.dart';
import 'package:myharur/core/services/auth_service.dart';
import 'package:myharur/core/services/photo_service.dart';
import 'package:myharur/core/theme/app_theme.dart';
import 'package:myharur/features/account/my_posts_page.dart';
import 'package:myharur/features/alerts/submit_alert_page.dart';
import 'package:myharur/features/reports/alert_widgets.dart';
import 'package:myharur/features/reports/photo_widgets.dart';
import 'package:myharur/features/reports/post_actions.dart';
import 'package:myharur/features/security/suspended_page.dart';

Widget _app(Widget home, {Locale locale = const Locale('en')}) => MaterialApp(
      theme: AppTheme.light,
      locale: locale,
      supportedLocales: LocaleController.supported,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: home,
    );

UserProfile _me({List<String> roles = const ['resident']}) =>
    UserProfile(id: 'u1', mmid: '1', username: '@me', fullName: 'Me', email: 'm@example.com', roles: roles);

Alert _post({String by = 'u2', String kind = 'report', String status = 'published', List<String> images = const [], String? link}) => Alert(
      id: 'a1',
      kind: kind,
      category: kind == 'news' ? 'community' : 'road',
      title: 'Bypass road reopened',
      body: 'The Harur bypass reopened after repairs today.',
      source: 'community',
      status: status,
      createdByUid: by,
      createdAt: DateTime.now(),
      imagePaths: images,
      linkUrl: link,
    );

void main() {
  setUp(() {
    AuthService.debugSetProfile(_me());
    PhotoService.debugUrlFor = (_) async => null; // no backend in widget tests
  });
  tearDown(() => PhotoService.debugUrlFor = null);

  group('model', () {
    test('reads kind, link and images; defaults to a plain report', () {
      final a = Alert.fromJson({
        'id': 'x', 'kind': 'news', 'category': 'traffic', 'title': 't', 'body': 'b', 'created_at': '2026-09-26T10:00:00Z',
        'link_url': 'https://example.com/a', 'image_paths': ['u/1.jpg', 'u/2.jpg'],
      });
      expect(a.isNews, isTrue);
      expect(a.linkUrl, 'https://example.com/a');
      expect(a.imagePaths, ['u/1.jpg', 'u/2.jpg']);
      final b = Alert.fromJson({'id': 'y', 'category': 'road', 'title': 't', 'body': 'b'});
      expect(b.isNews, isFalse);
      expect(b.imagePaths, isEmpty);
      expect(b.linkUrl, isNull);
    });

    test('generated photo names match what the database accepts', () {
      final path = 'b3f0c2a4-1111-4222-8333-444455556666/${PhotoService.uuid4()}.jpg';
      expect(path, matches(RegExp(r'^[0-9a-f-]{36}/[0-9a-f-]{36}\.(jpg|png|webp)$')));
      expect(PhotoService.uuid4(), matches(RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$')));
      expect(PhotoService.uuid4() == PhotoService.uuid4(), isFalse);
    });
  });

  group('who can do what', () {
    test('authors delete their own post but cannot report it', () {
      final p = PostPermissions.of(_post(by: 'u1'));
      expect(p.canDelete, isTrue);
      expect(p.canReport, isFalse);
    });

    test('a resident can report someone else\'s published post but not delete it', () {
      final p = PostPermissions.of(_post(by: 'u2'));
      expect(p.canReport, isTrue);
      expect(p.canDelete, isFalse);
    });

    test('a pending post cannot be reported (it is not public yet)', () {
      expect(PostPermissions.of(_post(by: 'u2', status: 'pending')).canReport, isFalse);
    });

    test('staff can delete any post', () {
      AuthService.debugSetProfile(_me(roles: const ['resident', 'moderator']));
      expect(PostPermissions.of(_post(by: 'u2')).canDelete, isTrue);
    });
  });

  group('post detail', () {
    testWidgets("someone else's post offers Report and Hide author, not Delete", (tester) async {
      await tester.pumpWidget(_app(Scaffold(body: AlertDetail(alert: _post()))));
      await tester.tap(find.byTooltip('More'));
      await tester.pumpAndSettle();
      expect(find.text('Report post'), findsOneWidget);
      expect(find.text('Hide posts from this author'), findsOneWidget);
      expect(find.text('Delete post'), findsNothing);
    });

    testWidgets('your own post offers Delete only', (tester) async {
      await tester.pumpWidget(_app(Scaffold(body: AlertDetail(alert: _post(by: 'u1')))));
      await tester.tap(find.byTooltip('More'));
      await tester.pumpAndSettle();
      expect(find.text('Delete post'), findsOneWidget);
      expect(find.text('Report post'), findsNothing);
    });

    testWidgets('deleting your own post asks first', (tester) async {
      await tester.pumpWidget(_app(Scaffold(body: AlertDetail(alert: _post(by: 'u1')))));
      await tester.tap(find.byTooltip('More'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete post'));
      await tester.pumpAndSettle();
      expect(find.text("Delete this post? This can't be undone."), findsOneWidget);
    });

    testWidgets('a signed-out guest gets no actions', (tester) async {
      AuthService.debugSetProfile(UserProfile.guest, loggedIn: false);
      await tester.pumpWidget(_app(Scaffold(body: AlertDetail(alert: _post()))));
      expect(find.byTooltip('More'), findsNothing);
    });

    testWidgets('shows the link button and photos for a news post', (tester) async {
      await tester.pumpWidget(_app(Scaffold(body: AlertDetail(alert: _post(kind: 'news', link: 'https://example.com/story', images: const ['u/1.jpg', 'u/2.jpg'])))));
      await tester.pump();
      expect(find.text('Open link'), findsOneWidget);
      expect(find.byType(NetworkPhoto), findsNWidgets(2));
    });

    testWidgets('a photo that cannot be loaded shows a quiet placeholder, not an error', (tester) async {
      await tester.pumpWidget(_app(const Scaffold(body: NetworkPhoto(path: 'u/x.jpg', width: 100, height: 100))));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.image_not_supported_outlined), findsOneWidget);
    });

    testWidgets('the card marks community news', (tester) async {
      await tester.pumpWidget(_app(Scaffold(body: AlertCard(alert: _post(kind: 'news')))));
      expect(find.text('Community'), findsWidgets);
    });
  });

  group('submit page', () {
    testWidgets('a report has emergency and no link field', (tester) async {
      await tester.pumpWidget(_app(const SubmitAlertPage()));
      expect(find.text('Link (optional)'), findsNothing);
      await tester.scrollUntilVisible(find.text('Mark as emergency'), 300, scrollable: find.byType(Scrollable).first);
      expect(find.text('Mark as emergency'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Add photo'), -300, scrollable: find.byType(Scrollable).first);
      expect(find.text('Photos (optional)'), findsOneWidget);
      expect(find.text('Add photo'), findsOneWidget);
    });

    testWidgets('news uses news categories, has a link field and no emergency switch', (tester) async {
      await tester.pumpWidget(_app(const SubmitAlertPage(kind: 'news')));
      expect(find.text('Share news'), findsOneWidget);
      expect(find.text('Community'), findsOneWidget);
      expect(find.text('Health'), findsOneWidget);
      expect(find.text('Link (optional)'), findsOneWidget);
      expect(find.text('Mark as emergency'), findsNothing);
      expect(find.text('Road'), findsNothing);
    });

    testWidgets('a link that is not https is refused before anything is sent', (tester) async {
      await tester.pumpWidget(_app(const SubmitAlertPage(kind: 'news')));
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'Bypass road reopened');
      await tester.enterText(fields.at(1), 'The Harur bypass reopened after repairs today.');
      await tester.enterText(fields.at(2), 'http://insecure.example/story');
      await tester.tap(find.text('Submit news'));
      await tester.pump();
      expect(find.text('Use a link that starts with https://'), findsOneWidget);
    });

    testWidgets('the whole page renders in Tamil', (tester) async {
      await tester.pumpWidget(_app(const SubmitAlertPage(kind: 'news'), locale: const Locale('ta')));
      expect(find.text('செய்தியைப் பகிர்'), findsOneWidget);
    });
  });

  group('account screens', () {
    testWidgets('My posts and Blocked authors have friendly empty states', (tester) async {
      await tester.pumpWidget(_app(const MyPostsPage()));
      await tester.pumpAndSettle();
      expect(find.text("You haven't posted anything yet."), findsOneWidget);
      await tester.pumpWidget(_app(const BlockedAuthorsPage()));
      await tester.pumpAndSettle();
      expect(find.text("You haven't blocked anyone."), findsOneWidget);
    });

    testWidgets('a banned account only sees the suspended page', (tester) async {
      await tester.pumpWidget(_app(const SuspendedPage()));
      expect(find.text('Account suspended'), findsOneWidget);
      expect(find.text('Contact support'), findsOneWidget);
      expect(find.text('Sign out'), findsOneWidget);
    });

    test('status labels', () {
      final a = _post(status: 'pending');
      expect(postStatusColor(a), AppColors.warning);
    });
  });
}
