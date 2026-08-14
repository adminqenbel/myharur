import 'package:flutter/material.dart';

class JobsPage extends StatefulWidget {
  const JobsPage({super.key});

  @override
  State<JobsPage> createState() => _JobsPageState();
}

class _JobsPageState extends State<JobsPage> {
  int selectedCategory = 0;
  final categories = ['All', 'Full-time', 'Daily Wage', 'Farm & Harvest', 'Driver / Logistics', 'Retail'];

  final List<Map<String, dynamic>> jobs = [
    {
      'title': 'Senior Accounts & Billing Clerk',
      'company': 'Sri Murugan Agro Traders',
      'type': 'Full-time',
      'salary': '₹18,000 - ₹22,000 / mo',
      'location': 'Harur Town Bazaar',
      'phone': '9842099881',
      'posted': '1d ago',
      'color': const Color(0xFF007F63),
    },
    {
      'title': 'Sugarcane & Paddy Field Harvesting Team',
      'company': 'Theerthamalai Farming Collective',
      'type': 'Daily Wage',
      'salary': '₹750 / day + Meals',
      'location': 'Theerthamalai',
      'phone': '9443211224',
      'posted': '3h ago',
      'color': const Color(0xFFF59E0B),
    },
    {
      'title': 'Heavy Vehicle Driver (Eicher / Tipper)',
      'company': 'Dharmapuri Mineral Transports',
      'type': 'Driver / Logistics',
      'salary': '₹24,000 / mo + Trip Bata',
      'location': 'Morappur Road',
      'phone': '9789044556',
      'posted': '2d ago',
      'color': const Color(0xFF267AF4),
    },
    {
      'title': 'Store Supervisor & Billing Assistant',
      'company': 'Harur Supermarket',
      'type': 'Retail',
      'salary': '₹14,000 - ₹16,000 / mo',
      'location': 'Harur Bus Stand',
      'phone': '9944088990',
      'posted': '4h ago',
      'color': const Color(0xFF8B5CF6),
    },
  ];

  void _openPostJobSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => const _PostJobSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = selectedCategory == 0
        ? jobs
        : jobs.where((j) => j['type'] == categories[selectedCategory]).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Harur Jobs & Hiring',
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
                itemCount: categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final active = selectedCategory == i;
                  return ChoiceChip(
                    label: Text(categories[i]),
                    selected: active,
                    onSelected: (_) => setState(() => selectedCategory = i),
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
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, i) {
                  final job = filtered[i];
                  return Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFDCE5E1)),
                      boxShadow: const [
                        BoxShadow(color: Color(0x080F2922), blurRadius: 14, offset: Offset(0, 5))
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: (job['color'] as Color).withValues(alpha: .12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                job['type'].toString().toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: job['color'] as Color,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(job['posted'], style: const TextStyle(fontSize: 11, color: Color(0xFF697570), fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          job['title'],
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF15211F)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          job['company'],
                          style: const TextStyle(fontSize: 13, color: Color(0xFF697570), fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Text(
                              job['salary'],
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF007F63)),
                            ),
                            const Spacer(),
                            Row(
                              children: [
                                const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF697570)),
                                const SizedBox(width: 3),
                                Text(job['location'], style: const TextStyle(fontSize: 12, color: Color(0xFF697570))),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF15211F),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            icon: const Icon(Icons.phone_rounded, size: 18),
                            label: const Text('Contact Employer', style: TextStyle(fontWeight: FontWeight.w800)),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Contacting ${job['company']} (${job['phone']})...')),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF007F63),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Post Requirement', style: TextStyle(fontWeight: FontWeight.w800)),
        onPressed: _openPostJobSheet,
      ),
    );
  }
}

class _PostJobSheet extends StatefulWidget {
  const _PostJobSheet();

  @override
  State<_PostJobSheet> createState() => _PostJobSheetState();
}

class _PostJobSheetState extends State<_PostJobSheet> {
  final _titleCtrl = TextEditingController();
  final _orgCtrl = TextEditingController();
  final _salaryCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
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
            const SizedBox(height: 16),
            const Text(
              'Post Local Job Vacancy',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF15211F)),
            ),
            const SizedBox(height: 4),
            const Text(
              'Reach workers, drivers, store staff, and field labor across Harur taluk.',
              style: TextStyle(fontSize: 12, color: Color(0xFF697570)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleCtrl,
              decoration: InputDecoration(
                labelText: 'Job Role / Designation',
                filled: true,
                fillColor: const Color(0xFFF2F6F5),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _orgCtrl,
              decoration: InputDecoration(
                labelText: 'Shop / Farm / Business Name',
                filled: true,
                fillColor: const Color(0xFFF2F6F5),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _salaryCtrl,
              decoration: InputDecoration(
                labelText: 'Wages / Salary (e.g. ₹600/day or ₹15,000/mo)',
                filled: true,
                fillColor: const Color(0xFFF2F6F5),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Contact Phone Number',
                filled: true,
                fillColor: const Color(0xFFF2F6F5),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 20),
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
                    const SnackBar(content: Text('Job vacancy published to Harur community!')),
                  );
                },
                child: const Text('Publish Requirement', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
