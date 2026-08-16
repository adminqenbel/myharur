import 'package:flutter/material.dart';

class RankingsPage extends StatefulWidget {
  const RankingsPage({super.key});

  @override
  State<RankingsPage> createState() => _RankingsPageState();
}

class _RankingsPageState extends State<RankingsPage> {
  int selectedTab = 0;
  final tabs = [
    'Interaction Voice',
    'Helping Hands',
    'Shop Voting',
    'Top Restaurants',
    'Admin Appreciation',
    'Donation Patrons',
  ];

  final List<Map<String, dynamic>> interactionUsers = [
    {'name': 'Muthuvel K.', 'username': '@muthuvel', 'title': '#1 Local Legend', 'score': 1240, 'badge': '👑'},
    {'name': 'Selvam Agro', 'username': '@selvam_agro', 'title': '#1 in Interaction', 'score': 890, 'badge': '🌟'},
    {'name': 'Prakash R.', 'username': '@prakash_r', 'title': 'Active Resident', 'score': 450, 'badge': '🌱'},
    {'name': 'Anand M.', 'username': '@anand_m', 'title': 'Community Member', 'score': 210, 'badge': '🤝'},
  ];

  final List<Map<String, dynamic>> helpingHands = [
    {'name': 'Dr. K. Saravanan', 'mmid': '20260814-1029', 'title': '#1 Helping Hands', 'score': '48 Emergencies Attended', 'badge': '🥇'},
    {'name': 'Murugan V.', 'mmid': '20260814-8834', 'title': 'First Responder Hero', 'score': '36 Near-Help Responses', 'badge': '🥈'},
    {'name': 'Divya R.', 'mmid': '20260814-5512', 'title': 'Good Samaritan', 'score': '29 Assistance Badges', 'badge': '🥉'},
  ];

  List<Map<String, dynamic>> shops = [
    {'id': 's1', 'name': 'Sri Lakshmi Agro & Seeds', 'category': 'Agro & Fertilizers', 'votes': 342, 'rank': 1},
    {'id': 's2', 'name': 'Dharmapuri Handloom Silks', 'category': 'Textiles', 'votes': 289, 'rank': 2},
    {'id': 's3', 'name': 'Vasantham Digital & Mobile', 'category': 'Electronics', 'votes': 214, 'rank': 3},
    {'id': 's4', 'name': 'Harur Organic Jaggery Mart', 'category': 'Local Produce', 'votes': 178, 'rank': 4},
  ];

  final List<Map<String, dynamic>> restaurants = [
    {'name': 'Sri Muniyandi Vilas (Harur)', 'votes': 412, 'specialty': 'Authentic Chettinad & Parotta', 'stars': '4.9'},
    {'name': 'Aasife Biryani & Grills', 'votes': 328, 'specialty': 'Seeraga Samba Mutton Biryani', 'stars': '4.8'},
    {'name': 'Vasanta Bhavan Vegetarian', 'votes': 295, 'specialty': 'Ghee Roast Dosa & Filter Coffee', 'stars': '4.8'},
  ];

  final List<Map<String, dynamic>> adminApprovals = [
    {'name': 'District Collector Dharmapuri', 'role': 'Government Official', 'approval': '98.4%', 'votes': 520, 'badge': '⭐ Superb Service'},
    {'name': 'Harur Town Panchayat Officer', 'role': 'Town Admin', 'approval': '94.2%', 'votes': 410, 'badge': '✓ Fast Resolution'},
    {'name': 'KVK Agricultural Director', 'role': 'Agronomy Head', 'approval': '96.8%', 'votes': 380, 'badge': '🌾 Farmer Friendly'},
  ];

  List<Map<String, dynamic>> donors = [
    {'name': 'Harur Merchants Chamber', 'amount': '₹50,000', 'tier': 'Platinum Patron', 'badge': '💎'},
    {'name': 'Theerthagiri Farmer Syndicate', 'amount': '₹25,000', 'tier': 'Gold Patron', 'badge': '👑'},
    {'name': 'Sri Lakshmi Agro Agency', 'amount': '₹10,000', 'tier': 'Silver Patron', 'badge': '⭐'},
    {'name': 'Anonymous Resident', 'amount': '₹5,000', 'tier': 'Bronze Patron', 'badge': '🌱'},
  ];

  void _voteShop(String shopId) {
    setState(() {
      for (final s in shops) {
        if (s['id'] == shopId) {
          s['votes'] = (s['votes'] as int) + 1;
        }
      }
      shops.sort((a, b) => (b['votes'] as int).compareTo(a['votes'] as int));
      for (int i = 0; i < shops.length; i++) {
        shops[i]['rank'] = i + 1;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Color(0xFF007AFF),
        content: Text('✓ Vote recorded! Live shop ranking updated.'),
      ),
    );
  }

  void _openDonationModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => _DonationModal(
        onDonated: (name, amount, tier) {
          setState(() {
            donors.insert(0, {
              'name': name,
              'amount': "₹$amount",
              'tier': tier,
              'badge': tier.contains('Gold') ? '👑' : '⭐',
            });
          });
        },
      ),
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
          style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1C1C1E)),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1C1C1E), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            tooltip: 'Support App',
            icon: const Icon(Icons.volunteer_activism_rounded, color: Color(0xFF007AFF)),
            onPressed: _openDonationModal,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                itemCount: tabs.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final active = selectedTab == i;
                  return ChoiceChip(
                    label: Text(tabs[i]),
                    selected: active,
                    onSelected: (_) => setState(() => selectedTab = i),
                    selectedColor: const Color(0xFF007AFF),
                    backgroundColor: const Color(0xFFF2F2F7),
                    labelStyle: TextStyle(
                      color: active ? Colors.white : const Color(0xFF1C1C1E),
                      fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                      fontSize: 12,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    side: BorderSide(
                      color: active ? const Color(0xFF007AFF) : const Color(0xFFE5E5EA),
                    ),
                  );
                },
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE5E5EA)),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                children: [
                  if (selectedTab == 0) _buildInteractionTab(),
                  if (selectedTab == 1) _buildHelpingHandsTab(),
                  if (selectedTab == 2) _buildShopVotingTab(),
                  if (selectedTab == 3) _buildRestaurantsTab(),
                  if (selectedTab == 4) _buildAdminAppreciationTab(),
                  if (selectedTab == 5) _buildDonationWallTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractionTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('TOP TOWN VOICES & COMMUNITY INTERACTIONS', style: TextStyle(color: Color(0xFF8E8E93), fontSize: 11, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        ...interactionUsers.map((person) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FBFA),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE5E5EA)),
            ),
            child: Row(
              children: [
                Text(person['badge'] as String, style: const TextStyle(fontSize: 26)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(person['name'] as String, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF1C1C1E))),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: const Color(0xFFEBF5FF), borderRadius: BorderRadius.circular(6)),
                            child: Text(person['title'] as String, style: const TextStyle(color: Color(0xFF007AFF), fontSize: 10, fontWeight: FontWeight.w900)),
                          ),
                          const SizedBox(width: 6),
                          Text(person['username'] as String, style: const TextStyle(fontSize: 11, color: Color(0xFF8E8E93))),
                        ],
                      ),
                    ],
                  ),
                ),
                Text("${person['score']} pts", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF007AFF))),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildHelpingHandsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('FIRST RESPONDERS & @HELP SOS HEROES', style: TextStyle(color: Color(0xFF8E8E93), fontSize: 11, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        ...helpingHands.map((person) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FBFA),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE5E5EA)),
            ),
            child: Row(
              children: [
                Text(person['badge'] as String, style: const TextStyle(fontSize: 26)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(person['name'] as String, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF1C1C1E))),
                      const SizedBox(height: 2),
                      Text(person['title'] as String, style: const TextStyle(color: Color(0xFF007AFF), fontSize: 11, fontWeight: FontWeight.w800)),
                      Text(person['score'] as String, style: const TextStyle(fontSize: 11, color: Color(0xFF8E8E93))),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildShopVotingTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('COMMUNITY SHOP RANKINGS & VOTING', style: TextStyle(color: Color(0xFF8E8E93), fontSize: 11, fontWeight: FontWeight.w800)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: const Color(0xFFEBF5FF), borderRadius: BorderRadius.circular(8)),
              child: const Text('All-Time Leaderboard', style: TextStyle(color: Color(0xFF007AFF), fontSize: 10, fontWeight: FontWeight.w900)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...shops.map((shop) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FBFA),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE5E5EA)),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: shop['rank'] == 1 ? const Color(0xFFF59E0B) : const Color(0xFF007AFF),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      "#${shop['rank']}",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(shop['name'] as String, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF1C1C1E))),
                      const SizedBox(height: 2),
                      Text("${shop['category']} · ${shop['votes']} community votes", style: const TextStyle(fontSize: 11, color: Color(0xFF8E8E93))),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF007AFF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  icon: const Icon(Icons.thumb_up_rounded, size: 14),
                  label: const Text('Vote', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11)),
                  onPressed: () => _voteShop(shop['id'] as String),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildRestaurantsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('HARUR & DHARMAPURI BEST RATED EATERIES', style: TextStyle(color: Color(0xFF8E8E93), fontSize: 11, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        ...restaurants.map((rest) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FBFA),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE5E5EA)),
            ),
            child: Row(
              children: [
                const Icon(Icons.restaurant_rounded, color: Color(0xFFF59E0B), size: 28),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(rest['name'] as String, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF1C1C1E))),
                      const SizedBox(height: 2),
                      Text(rest['specialty'] as String, style: const TextStyle(fontSize: 11, color: Color(0xFF8E8E93))),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFFEBF5FF), borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded, size: 14, color: Color(0xFF007AFF)),
                      const SizedBox(width: 2),
                      Text(rest['stars'] as String, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Color(0xFF007AFF))),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildAdminAppreciationTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('RESIDENT APPROVAL & OFFICIAL PERFORMANCE', style: TextStyle(color: Color(0xFF8E8E93), fontSize: 11, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        ...adminApprovals.map((adm) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FBFA),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE5E5EA)),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_user_rounded, color: Color(0xFF007AFF), size: 28),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(adm['name'] as String, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF1C1C1E))),
                      const SizedBox(height: 2),
                      Text("${adm['role']} · ${adm['badge']}", style: const TextStyle(fontSize: 11, color: Color(0xFF007AFF), fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                Text(adm['approval'] as String, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF007AFF))),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildDonationWallTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF1C1C1E), Color(0xFF070B0A)]),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Support MyHarur Server Fund', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900)),
                    SizedBox(height: 4),
                    Text('Keep Harur digital infrastructure free, fast & independent.', style: TextStyle(color: Color(0xFF8E8E93), fontSize: 11)),
                  ],
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF007AFF),
                  foregroundColor: const Color(0xFF070B0A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _openDonationModal,
                child: const Text('Donate', style: TextStyle(fontWeight: FontWeight.w900)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const Text('PATRON LEADERBOARD', style: TextStyle(color: Color(0xFF8E8E93), fontSize: 11, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        ...donors.map((donor) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FBFA),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE5E5EA)),
            ),
            child: Row(
              children: [
                Text(donor['badge'] as String, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(donor['name'] as String, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF1C1C1E))),
                      const SizedBox(height: 2),
                      Text(donor['tier'] as String, style: const TextStyle(fontSize: 11, color: Color(0xFF007AFF), fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                Text(donor['amount'] as String, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF1C1C1E))),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _DonationModal extends StatefulWidget {
  final Function(String name, String amount, String tier) onDonated;
  const _DonationModal({required this.onDonated});

  @override
  State<_DonationModal> createState() => _DonationModalState();
}

class _DonationModalState extends State<_DonationModal> {
  final _amountCtrl = TextEditingController(text: '500');
  final _nameCtrl = TextEditingController(text: 'Muthuvel K.');

  @override
  void dispose() {
    _amountCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Support Town Digital Infrastructure', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1C1C1E))),
          const SizedBox(height: 4),
          const Text('Direct contribution to Harur server uptime and emergency relay.', style: TextStyle(fontSize: 12, color: Color(0xFF8E8E93))),
          const SizedBox(height: 18),
          TextField(
            controller: _nameCtrl,
            decoration: InputDecoration(
              labelText: 'Donor Name / Business Name',
              filled: true,
              fillColor: const Color(0xFFF2F2F7),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Contribution Amount (₹)',
              prefixText: '₹ ',
              filled: true,
              fillColor: const Color(0xFFF2F2F7),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF007AFF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.favorite_rounded, size: 18),
              label: const Text('Complete Patron Contribution', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
              onPressed: () {
                final amt = _amountCtrl.text.trim();
                final name = _nameCtrl.text.trim();
                final tier = (double.tryParse(amt) ?? 0) >= 5000 ? 'Platinum Patron' : 'Gold Patron';
                widget.onDonated(name, amt, tier);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: const Color(0xFF007AFF),
                    content: Text('✓ Thank you $name for supporting MyHarur ($tier)!'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
