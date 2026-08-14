import 'package:flutter/material.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int selectedTab = 0;
  final tabs = ['Moderation Queue', 'User Termination (3-Vote)', 'Staff & AIDs', 'System Logs'];

  final List<Map<String, dynamic>> pendingItems = [
    {
      'type': 'News Story',
      'title': 'New Drinking Water Pipeline Sanctioned for Morappur Road',
      'author': 'Selvam (Resident)',
      'status': 'Pending Approval',
      'color': const Color(0xFF267AF4),
    },
    {
      'type': 'Event',
      'title': 'Harur Town Badminton Open Championship',
      'author': 'Rajesh K. (Applicant for Event Head)',
      'status': 'Pending Verification',
      'color': const Color(0xFF007F63),
    },
  ];

  final List<Map<String, dynamic>> terminationRequests = [
    {
      'username': 'spammer_account_99',
      'mmid': '20260814-9912',
      'reason': 'Repeated abusive broadcasts & fake news submission',
      'votesCount': 2,
      'votesRequired': 3,
      'superAdminBypass': 'Super Admin can delete immediately without 3 votes',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Super Admin Dashboard',
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
                  if (selectedTab == 0) ...[
                    ...pendingItems.map((item) => Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: const Color(0xFFDCE5E1)),
                            boxShadow: const [
                              BoxShadow(color: Color(0x080F2922), blurRadius: 12, offset: Offset(0, 4))
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: (item['color'] as Color).withValues(alpha: .12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      item['type'],
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: item['color'] as Color),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(item['status'], style: const TextStyle(fontSize: 11, color: Color(0xFFF59E0B), fontWeight: FontWeight.w700)),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(item['title'], style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                              const SizedBox(height: 4),
                              Text('Submitted by: ${item['author']}', style: const TextStyle(fontSize: 12, color: Color(0xFF697570))),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF007F63),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      onPressed: () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Approved ${item['type']} and published!')),
                                        );
                                      },
                                      child: const Text('Approve & Publish', style: TextStyle(fontWeight: FontWeight.w800)),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFFE44545),
                                      side: const BorderSide(color: Color(0xFFE44545)),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    onPressed: () {},
                                    child: const Text('Reject'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )),
                  ] else if (selectedTab == 1) ...[
                    ...terminationRequests.map((req) => Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFECEB),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: const Color(0xFFF8C9C5)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.warning_rounded, color: Color(0xFFE44545)),
                                  const SizedBox(width: 8),
                                  Text('@${req['username']}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFFE44545))),
                                  const Spacer(),
                                  Text('${req['votesCount']}/${req['votesRequired']} Admin Votes', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFF15211F))),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text('Reason: ${req['reason']}', style: const TextStyle(fontSize: 13, color: Color(0xFF15211F))),
                              const SizedBox(height: 6),
                              Text(req['superAdminBypass'] as String, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF697570))),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFE44545),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      onPressed: () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Super Admin override: Account terminated immediately!')),
                                        );
                                      },
                                      child: const Text('Super Admin Terminate (Instant)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F6F5),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: const Color(0xFFDCE5E1)),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Active Admin IDs (AIDs)', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                          SizedBox(height: 10),
                          Text('• Primary Super Admin: AID-HR-0001 (MFA Active, Root non-deletable)', style: TextStyle(fontSize: 12)),
                          SizedBox(height: 6),
                          Text('• Super Admin 2: AID-HR-0002 (MFA Active)', style: TextStyle(fontSize: 12)),
                          SizedBox(height: 6),
                          Text('• Harur Police Official: AID-HR-0010 (Govt Role)', style: TextStyle(fontSize: 12)),
                          SizedBox(height: 6),
                          Text('• Harur Tahsildar: AID-HR-0011 (Govt Role)', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
