import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  bool _isAuthenticated = false;
  final TextEditingController _passkeyController = TextEditingController();
  String? _authError;
  int _failedAttempts = 0;

  int selectedTab = 0;
  final tabs = ['Moderation Queue', 'User Termination (3-Vote)', 'Staff & AIDs', 'System Logs'];

  final List<Map<String, dynamic>> pendingItems = [
    {
      'id': 'item-1',
      'type': 'News Story',
      'title': 'New Drinking Water Pipeline Sanctioned for Morappur Road',
      'author': 'Selvam (Resident)',
      'status': 'Pending Approval',
      'color': const Color(0xFF267AF4),
    },
    {
      'id': 'item-2',
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
  void dispose() {
    _passkeyController.dispose();
    super.dispose();
  }

  void _verifyPasskey() {
    final pin = _passkeyController.text.trim();
    if (AuthService.verifySuperAdminPasskey(pin)) {
      setState(() {
        _isAuthenticated = true;
        _authError = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF007F63),
          content: Text('✓ SuperAdmin Session Verified. Audit logging enabled.'),
        ),
      );
    } else {
      setState(() {
        _failedAttempts++;
        _authError = 'Invalid SuperAdmin Passkey. Attempt $_failedAttempts/5';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAuthenticated) {
      return Scaffold(
        backgroundColor: const Color(0xFF070B0A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF070B0A),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Security Verification',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
          ),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: const Color(0xFF121C19),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0xFF00D09C).withValues(alpha: 0.3)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF007F63).withValues(alpha: 0.2),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE44545).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE44545).withValues(alpha: 0.4)),
                    ),
                    child: const Icon(Icons.security_rounded, color: Color(0xFFE44545), size: 36),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'SuperAdmin Access',
                    style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Town Governance & Audit Console',
                    style: TextStyle(color: Color(0xFF8E9F98), fontSize: 13),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _passkeyController,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white, fontSize: 18, letterSpacing: 8, fontWeight: FontWeight.w900),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: '••••••',
                      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), letterSpacing: 8),
                      filled: true,
                      fillColor: Colors.black38,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFF00D09C)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFF00D09C), width: 2),
                      ),
                    ),
                    onSubmitted: (_) => _verifyPasskey(),
                  ),
                  if (_authError != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _authError!,
                      style: const TextStyle(color: Color(0xFFE44545), fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00D09C),
                        foregroundColor: const Color(0xFF070B0A),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      icon: const Icon(Icons.lock_open_rounded, size: 20),
                      label: const Text('Authenticate & Unlock', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                      onPressed: _verifyPasskey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '🔒 All actions in this console are recorded to the immutable town ledger.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF54655E), fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Row(
          children: [
            Text(
              'Super Admin Dashboard',
              style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF15211F)),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF15211F), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            tooltip: 'Lock Session',
            icon: const Icon(Icons.lock_rounded, color: Color(0xFFE44545)),
            onPressed: () {
              setState(() {
                _isAuthenticated = false;
                _passkeyController.clear();
              });
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Active Session Badge
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF81C784)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.verified_user_rounded, color: Color(0xFF2E7D32), size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'SuperAdmin Session Active • MMID-HQ-0001 • Consensus Verified',
                      style: TextStyle(color: Color(0xFF2E7D32), fontSize: 11, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
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
              child: IndexedStack(
                index: selectedTab,
                children: [
                  _buildModerationQueue(),
                  _buildTerminationQueue(),
                  _buildStaffManagement(),
                  _buildSystemLogs(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModerationQueue() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: pendingItems.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final item = pendingItems[i];
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFDCE5E1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (item['color'] as Color).withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item['type'],
                      style: TextStyle(color: item['color'] as Color, fontWeight: FontWeight.w800, fontSize: 11),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    item['status'],
                    style: const TextStyle(fontSize: 12, color: Color(0xFFF59E0B), fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                item['title'],
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF15211F)),
              ),
              const SizedBox(height: 6),
              Text(
                'Submitted by: ${item['author']}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF697570)),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF007F63),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.check_rounded, size: 16),
                      label: const Text('Approve & Publish', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                      onPressed: () {
                        setState(() => pendingItems.removeAt(i));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Approved "${item['title']}"')),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFE44545),
                      side: const BorderSide(color: Color(0xFFE44545)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Reject'),
                    onPressed: () {
                      setState(() => pendingItems.removeAt(i));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Rejected "${item['title']}"')),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTerminationQueue() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: terminationRequests.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final req = terminationRequests[i];
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE44545).withValues(alpha: .3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.gavel_rounded, color: Color(0xFFE44545), size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'Target MMID: ${req['mmid']}',
                    style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF15211F)),
                  ),
                  const Spacer(),
                  Text(
                    '${req['votesCount']}/${req['votesRequired']} Admin Votes',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFFE44545)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('Reason: ${req['reason']}', style: const TextStyle(fontSize: 13, color: Color(0xFF697570))),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE44545),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        await GovernanceService.superAdminTerminate(
                          targetUserId: req['mmid'],
                          reason: req['reason'],
                        );
                        setState(() => terminationRequests.removeAt(i));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Account ${req['mmid']} terminated by SuperAdmin override.')),
                          );
                        }
                      },
                      child: const Text('SuperAdmin Immediate Termination', style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStaffManagement() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF2F6F5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Appointed Town Admins (AIDs)', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
              SizedBox(height: 8),
              Text('1. AID-HR-0001 (K. Selvakumar - Executive Officer)'),
              SizedBox(height: 4),
              Text('2. AID-HR-0002 (Dr. R. Madhavan - Chief Health Inspector)'),
              SizedBox(height: 4),
              Text('3. AID-HR-0003 (M. Murugan - Town Infrastructure Engineer)'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSystemLogs() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      children: const [
        Text('• [11:15 AM] Weather service sync completed (Harur Station: 32.4°C)', style: TextStyle(fontSize: 12, color: Color(0xFF697570))),
        SizedBox(height: 6),
        Text('• [10:45 AM] 12 new marketplace listings approved by auto-heuristics', style: TextStyle(fontSize: 12, color: Color(0xFF697570))),
        SizedBox(height: 6),
        Text('• [09:30 AM] Southern Railway news approved for publication', style: TextStyle(fontSize: 12, color: Color(0xFF697570))),
      ],
    );
  }
}
