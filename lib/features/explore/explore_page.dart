import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass_components.dart';

// ==============================================================================
// EXPLORE PAGE â€” Harur Civic Directory, Emergency Hotlines & Town Wards
// ==============================================================================
class ExplorePage extends StatelessWidget {
  const ExplorePage({super.key});

  Future<void> _makeCall(String number) async {
    final uri = Uri.parse('tel:$number');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (_) {}
  }

  static const List<Map<String, String>> _emergencyContacts = [
    {
      'title': 'Emergency SOS / Ambulance',
      'number': '108',
      'category': 'Medical',
      'icon': '\u{1F691}',
      'desc': '24/7 State Emergency Response Service',
    },
    {
      'title': 'Harur Police Station',
      'number': '04346-222022',
      'category': 'Police',
      'icon': '\u{1F46E}',
      'desc': 'Harur Town Police Station, Bazaar St',
    },
    {
      'title': 'Harur Fire & Rescue',
      'number': '101',
      'category': 'Fire',
      'icon': '\u{1F692}',
      'desc': 'Fire Station, Morappur Road',
    },
    {
      'title': 'Harur Government Hospital',
      'number': '04346-222033',
      'category': 'Hospital',
      'icon': '\u{1F3E5}',
      'desc': 'Taluk HQ Hospital, Hospital Road',
    },
    {
      'title': 'TANGEDCO Electricity Helpline',
      'number': '1912',
      'category': 'Power',
      'icon': '\u26A1',
      'desc': 'Power Outage & Line Breakdown',
    },
    {
      'title': 'Dharmapuri Collectorate Control Room',
      'number': '04342-230500',
      'category': 'Govt',
      'icon': '\u{1F3DB}',
      'desc': 'District Disaster & Grievance Helpline',
    },
    {
      'title': 'Harur Town Panchayat Office',
      'number': '04346-222044',
      'category': 'Civic',
      'icon': '\u{1F3E2}',
      'desc': 'Sanitation, Water Supply & Civic Services',
    },
  ];

  static const List<Map<String, dynamic>> _wards = [
    {'id': 1, 'name': 'Ward 1', 'locality': 'Bazaar Street & Old Market'},
    {'id': 2, 'name': 'Ward 2', 'locality': 'Town Hall Area & Post Office'},
    {'id': 3, 'name': 'Ward 3', 'locality': 'Bus Stand South & Clock Tower'},
    {'id': 4, 'name': 'Ward 4', 'locality': 'Hospital Road & GH Colony'},
    {'id': 5, 'name': 'Ward 5', 'locality': 'Anna Nagar & School Zone'},
    {'id': 6, 'name': 'Ward 6', 'locality': 'Nethaji Nagar & Teachers Colony'},
    {'id': 7, 'name': 'Ward 7', 'locality': 'Gandhi Nagar & East Extension'},
    {'id': 8, 'name': 'Ward 8', 'locality': 'Theerthamalai Road & Temple Zone'},
    {'id': 9, 'name': 'Ward 9', 'locality': 'Morappur Road Junction'},
    {'id': 10, 'name': 'Ward 10', 'locality': 'Kottapatti Road Area'},
    {'id': 11, 'name': 'Ward 11', 'locality': 'Palacode Road & West Gate'},
    {'id': 12, 'name': 'Ward 12', 'locality': 'Court & Taluk Office Zone'},
    {'id': 13, 'name': 'Ward 13', 'locality': 'Railway Line Extension Area'},
    {'id': 14, 'name': 'Ward 14', 'locality': 'Industrial & Warehouse Zone'},
    {'id': 15, 'name': 'Ward 15', 'locality': 'Regulated Agri Market Yard'},
    {'id': 16, 'name': 'Ward 16', 'locality': 'North Extension & Housing Unit'},
    {'id': 17, 'name': 'Ward 17', 'locality': 'South Colony & Farmers Market'},
    {'id': 18, 'name': 'Ward 18', 'locality': 'Rural Fringe & Outskirts'},
  ];

  @override
  Widget build(BuildContext context) {
    return AtmosphericBackground(
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Explore Harur', style: AppTextStyles.largeTitle),
                    const SizedBox(height: 4),
                    Text(
                      'Civic Directory, Emergency Hotlines & Wards',
                      style: AppTextStyles.footnote,
                    ),
                  ],
                ),
              ),
            ),

            // Emergency Helplines Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: SectionHeader(
                  label: 'EMERGENCY & HELPLINES (TAP TO CALL)',
                  action: '${_emergencyContacts.length} Contacts',
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) {
                    final contact = _emergencyContacts[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: SurfaceCard(
                        onTap: () => _makeCall(contact['number']!),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.primarySurface,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(contact['icon']!, style: const TextStyle(fontSize: 18)),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    contact['title']!,
                                    style: AppTextStyles.headline.copyWith(fontSize: 15),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    contact['desc']!,
                                    style: AppTextStyles.caption1,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.call_rounded, color: Colors.white, size: 12),
                                  const SizedBox(width: 4),
                                  Text(
                                    contact['number']!,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: _emergencyContacts.length,
                ),
              ),
            ),

            // 18 Harur Wards Section
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: SectionHeader(
                  label: 'HARUR TOWN WARDS (18 WARDS)',
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 2.2,
                ),
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) {
                    final ward = _wards[i];
                    return GlassCard(
                      padding: const EdgeInsets.all(12),
                      borderRadius: 14,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            ward['name'] as String,
                            style: AppTextStyles.headline.copyWith(
                              fontSize: 14,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            ward['locality'] as String,
                            style: AppTextStyles.caption2,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    );
                  },
                  childCount: _wards.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

