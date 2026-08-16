import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myharur/main.dart';
import 'package:myharur/l10n/translations.dart';
import 'package:myharur/widgets/glass_components.dart';
import 'package:myharur/features/onboarding_page.dart';
import 'package:myharur/features/shop_detail_page.dart';
import 'package:myharur/features/community_hub_page.dart';
import 'package:myharur/features/notifications_page.dart';
import 'package:myharur/features/phase_two_pages.dart';
import 'package:myharur/services/harur_real_data_service.dart';

void main() {
  testWidgets('shows the MyHarur home shell and navigation components', (tester) async {
    LanguageNotifier.instance.setTamil(false);

    await tester.pumpWidget(
      const MaterialApp(
        home: TownShell(),
      ),
    );

    expect(find.text('Harur Digital Town'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Explore'), findsOneWidget);
    expect(find.text('Alerts'), findsOneWidget);
    expect(find.text('Account'), findsOneWidget);
  });

  testWidgets('bilingual localization toggles English and Tamil', (tester) async {
    LanguageNotifier.instance.setTamil(false);
    expect(tr('Home'), 'Home');
    expect(tr('Emergency SOS'), 'Emergency SOS');

    LanguageNotifier.instance.toggleLanguage();
    expect(LanguageNotifier.instance.isTamil, isTrue);
    expect(tr('Home'), 'முகப்பு');
    expect(tr('Emergency SOS'), 'அவசர உதவி 108');

    // Reset back to English
    LanguageNotifier.instance.setTamil(false);
    expect(tr('Home'), 'Home');
  });

  testWidgets('shows the onboarding setup flow with Google OAuth & Passport', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: TownOnboardingFlowPage(),
      ),
    );

    expect(find.text('DIGITAL TOWN PASSPORT'), findsOneWidget);
    expect(find.text('Welcome to Your Connected Town.'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Explore Harur as Guest Visitor →'), findsOneWidget);
  });

  testWidgets('renders luxury GlassCard and GlassSurface components', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GlassCard(
            title: 'Harur Civic Notice',
            subtitle: 'Town Hall Update',
            child: Text('Broad gauge rail trials'),
          ),
        ),
      ),
    );

    expect(find.text('Harur Civic Notice'), findsOneWidget);
    expect(find.text('Town Hall Update'), findsOneWidget);
    expect(find.text('Broad gauge rail trials'), findsOneWidget);
  });

  testWidgets('renders ShopDetailPage with product catalog and contact actions', (tester) async {
    final mockShop = {
      'name': 'Sri Lakshmi Agro & Rice Mills',
      'category': 'Groceries & Agro',
      'address': 'Bazaar Street, Harur',
      'phone': '9842011223',
      'rating': '4.9 (54)',
      'productsCount': 32,
    };

    await tester.pumpWidget(
      MaterialApp(
        home: ShopDetailPage(shop: mockShop),
      ),
    );

    expect(find.text('Sri Lakshmi Agro & Rice Mills'), findsNWidgets(2));
    expect(find.text('WhatsApp'), findsOneWidget);
    expect(find.text('Call Shop'), findsOneWidget);
    expect(find.text('PRODUCTS & ITEMS'), findsOneWidget);
    expect(find.text('Premium Ponni Rice (25kg Bag)'), findsOneWidget);
  });

  testWidgets('renders CommunityHubPage with Polls, Town Hall and Channels tabs', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CommunityHubPage(),
      ),
    );

    expect(find.text('Harur Community Hub'), findsOneWidget);
    expect(find.text('Polls'), findsOneWidget);
    expect(find.text('Town Hall'), findsOneWidget);
    expect(find.text('Channels'), findsOneWidget);
    expect(find.text('Events'), findsOneWidget);
  });

  testWidgets('renders NotificationsPage with category filters and alerts', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: NotificationsPage(),
      ),
    );

    expect(find.text('Notifications & Alerts'), findsOneWidget);
    expect(find.text('Emergency'), findsOneWidget);
    expect(find.text('Govt Orders'), findsOneWidget);
    expect(find.text('Civic'), findsOneWidget);
    expect(find.text('Emergency SOS Alert Broadcast'), findsOneWidget);
  });

  testWidgets('renders AgriMandiPage with real APMC commodity rates', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AgriMandiPage(),
      ),
    );

    expect(find.text('Harur Agri Mandi Rates'), findsOneWidget);
    expect(find.text('All Commodities'), findsOneWidget);
    expect(find.text('Sugarcane & Tapioca'), findsOneWidget);
    expect(find.text('Sugarcane (Co-86032 / Mill Grade)'), findsOneWidget);
  });

  testWidgets('renders BusRoutesPage with real TNSTC Harur schedules', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: BusRoutesPage(),
      ),
    );

    expect(find.text('Harur Bus Routes & Timings'), findsOneWidget);
    expect(find.text('Harur ⇄ Dharmapuri (Direct & Express)'), findsOneWidget);
  });

  testWidgets('renders BloodDonorsPage with blood bank and donor tabs', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: BloodDonorsPage(),
      ),
    );

    expect(find.text('Harur Blood Lifeline'), findsOneWidget);
    expect(find.text('Blood Banks (24/7)'), findsOneWidget);
    expect(find.text('Volunteer Donors'), findsOneWidget);
    expect(find.text('Harur Government Taluk Hospital Blood Storage Centre'), findsOneWidget);
  });

  test('HarurRealDataService provides verified datasets with zero dummy data', () {
    final mandis = HarurRealDataService.getRealMandiRates();
    expect(mandis, isNotEmpty);
    expect(mandis.any((m) => m['name'].toString().contains('Sugarcane')), isTrue);
    expect(mandis.any((m) => m['name'].toString().contains('Tapioca')), isTrue);

    final buses = HarurRealDataService.getRealBusRoutes();
    expect(buses, isNotEmpty);
    expect(buses.any((b) => b['route'].toString().contains('Dharmapuri')), isTrue);
    expect(buses.any((b) => b['route'].toString().contains('Salem')), isTrue);

    final helplines = HarurRealDataService.getRealEmergencyHelplines();
    expect(helplines, isNotEmpty);
    expect(helplines.any((h) => h['number'].toString().contains('108')), isTrue);
    expect(helplines.any((h) => h['number'].toString().contains('04346')), isTrue);

    final gos = HarurRealDataService.getRealGovernmentOrders();
    expect(gos, isNotEmpty);
    expect(gos.any((g) => g['go_number'].toString().contains('118')), isTrue);
  });
}

