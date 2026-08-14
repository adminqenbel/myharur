import 'package:flutter/material.dart';

class RankingsPage extends StatefulWidget {
  const RankingsPage({super.key});

  @override
  State<RankingsPage> createState() => _RankingsPageState();
}

class _RankingsPageState extends State<RankingsPage> {
  int selectedTab = 0;
  final tabs = ['Helping Hands', 'Town Voice', 'Top Restaurants', 'Donation Wall'];

  final List<Map<String, dynamic>> helpingHands = [
    {'name': 'Dr. K. Saravanan', 'mmid': '20260814-1029', 'title': '#1 Helping Hands', 'score': '48 Emergencies Attended', 'badge': '🥇'},
    {'name': 'Murugan V.', 'mmid': '20260814-8834', 'title': '#2 Rapid Responder', 'score': '36 Near-Help Responses', 'badge': '🥈'},
    {'name': 'Divya R.', 'mmid': '20260814-5512', 'title': '#3 Local Hero', 'score': '29 Assistance Badges', 'badge': '🥉'},
  ];

  final List<Map<String, dynamic>> restaurants = [
    {'name': 'Sri Muniyandi Vilas (Harur)', 'votes': 412, 'specialty': 'Authentic Chettinad & Parotta', 'stars': '4.9'},
    {'name': 'Aasife Biryani & Grills', 'votes': 328, 'specialty': 'Seeraga Samba Mutton Biryani', 'stars': '4.8'},
    {'name': 'Vasanta Bhavan Vegetarian', 'votes': 295, 'specialty': 'Ghee Roast Dosa & Filter Coffee', 'stars': '4.8'},
  ];

  final List<Map<String, dynamic>> donors = [
    {'name': 'Harur Merchants Chamber', 'amount': '₹50,000', 'cause': 'Town Digital Infrastructure', 'badge': 'Platinum Donor'},
    {'name': 'Theerthagiri Farmer Syndicate', 'amount': '₹25,000', 'cause': 'KVK Weather Advisory Server', 'badge': 'Gold Donor'},
    {'name': 'Anonymous Resident', 'amount': '₹10,000', 'cause': 'Community Emergency Pool', 'badge': 'Silver Donor'},
  ];

  void _openDonationModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => const _DonationModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Rankings & Recognition',
          style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF15211F)),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF15211F), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 46,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: tabs.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final active = selectedTab == i;
                  return ChoiceChip(
                    label: Text(tabs[i]),
                    selected: active,
                    onSelected: (_) => setState(() => selectedTab = i),
                    selectedColor: const Color(0xFF007F63),
                    backgroundColor: const Color(0xFFF2F6F5),
                    labelStyle: TextStyle(
                      color: active ? Colors.white : const Color(0xFF15211F),
                      fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                      fontSize: 13,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    side: BorderSide(
                      color: active ? const Color(0xFF007F63) : const Color(0xFFDCE5E1),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                children: [
                  if (selectedTab == 0 || selectedTab == 1) ...[
                    ...helpingHands.map((person) => Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: const Color(0xFFDCE5E1)),
                            boxShadow: const [
                              BoxShadow(color: Color(0x080F2922), blurRadius: 12, offset: Offset(0, 4))
                            ],
                          ),
                          child: Row(
                            children: [
                              Text(person['badge'] as String, style: const TextStyle(fontSize: 26)),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      person['name'] as String,
                                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF15211F)),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      person['title'] as String,
                                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFF007F63)),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      person['score'] as String,
                                      style: const TextStyle(fontSize: 11, color: Color(0xFF697570)),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE9F6F1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text('Top Helper', style: TextStyle(color: Color(0xFF007F63), fontWeight: FontWeight.w800, fontSize: 11)),
                              ),
                            ],
                          ),
                        )),
                  ] else if (selectedTab == 2) ...[
                    ...restaurants.map((rest) => Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: const Color(0xFFDCE5E1)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF7E8),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Center(child: Icon(Icons.restaurant_rounded, color: Color(0xFFF59E0B))),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(rest['name'] as String, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                                    Text(rest['specialty'] as String, style: const TextStyle(fontSize: 11, color: Color(0xFF697570))),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.star_rounded, size: 14, color: Color(0xFFF59E0B)),
                                        const SizedBox(width: 2),
                                        Text(rest['stars'] as String, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11)),
                                        const SizedBox(width: 8),
                                        Text('${rest['votes']} votes', style: const TextStyle(fontSize: 11, color: Color(0xFF007F63), fontWeight: FontWeight.w700)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.thumb_up_alt_outlined, color: Color(0xFF007F63)),
                                tooltip: 'Vote for this place',
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Your vote recorded for ${rest['name']}!')),
                                  );
                                },
                              ),
                            ],
                          ),
                        )),
                  ] else ...[
                    ...donors.map((d) => Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFBF0),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: const Color(0xFFF1E0BE)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.favorite_rounded, color: Color(0xFFE44545), size: 24),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(d['name'] as String, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                                    Text(d['cause'] as String, style: const TextStyle(fontSize: 11, color: Color(0xFF697570))),
                                    const SizedBox(height: 4),
                                    Text(d['badge'] as String, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: Color(0xFFC17600))),
                                  ],
                                ),
                              ),
                              Text(
                                d['amount'] as String,
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF007F63)),
                              ),
                            ],
                          ),
                        )),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF007F63),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        icon: const Icon(Icons.volunteer_activism_rounded),
        label: const Text('Support App & Town', style: TextStyle(fontWeight: FontWeight.w800)),
        onPressed: _openDonationModal,
      ),
    );
  }
}

class _DonationModal extends StatelessWidget {
  const _DonationModal();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFDCE5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Contribute to MyHarur Infrastructure',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF15211F)),
          ),
          const SizedBox(height: 6),
          const Text(
            'Donations directly support continuous 2-hour news scraping, dedicated emergency volunteer servers, and free digital town services.',
            style: TextStyle(fontSize: 12, color: Color(0xFF697570), height: 1.35),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['₹100', '₹500', '₹1,000', '₹5,000'].map((amt) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F6F5),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFDCE5E1)),
                ),
                child: Text(amt, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF007F63))),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF007F63),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Thank you! Redirecting to secure UPI / payment portal...')),
                );
              },
              child: const Text('Proceed to Payment Portal', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }
}
