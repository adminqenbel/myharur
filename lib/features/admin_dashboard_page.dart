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
  final tabs = [
    'Moderation',
    'User Termination (3-Vote)',
    'Admin & MFA Management',
    'Create Official User',
    'Government Orders (G.O.)',
    'AI Support Escalations',
  ];

  // Official user creation controllers
  final _createUsernameCtrl = TextEditingController();
  final _createPasswordCtrl = TextEditingController();
  final _createNameCtrl = TextEditingController();
  final _createPhoneCtrl = TextEditingController();
  String _createSelectedRole = 'govt_official';
  String? _createValidationError;

  // G.O. controllers
  final _goNumberCtrl = TextEditingController(text: 'G.O. Ms. No. 143/2026');
  final _goDeptCtrl = TextEditingController(text: 'Revenue & Disaster Management');
  final _goTitleCtrl = TextEditingController();
  final _goSummaryCtrl = TextEditingController();

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
      'type': 'Tournament',
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
      'superAdminBypass': 'SuperAdmin can delete immediately without 3 votes',
    },
    {
      'username': 'commercial_bot_7',
      'mmid': '20260815-4411',
      'reason': 'Automated unauthorized SMS scraping',
      'votesCount': 1,
      'votesRequired': 3,
      'superAdminBypass': 'SuperAdmin can delete immediately without 3 votes',
    },
  ];

  final List<Map<String, dynamic>> adminAccounts = [
    {
      'name': 'Root SuperAdmin Qenbel',
      'email': 'admin.qenbel@gmail.com',
      'username': '@admin.qenbel',
      'mmid': '202608151208218821',
      'aid': 'AID-ROOT-0001',
      'role': 'Primary SuperAdmin',
      'isMfa': true,
      'isProtected': true, // Cannot be deleted
      'phone': '+91 99440 05500',
    },
    {
      'name': 'District Collector Dharmapuri',
      'email': 'collector.dharmapuri@gov.in',
      'username': '@collector_dharmapuri',
      'mmid': '20260812-1002',
      'aid': 'AID-20260812-77XA',
      'role': 'Government Official / Admin',
      'isMfa': true,
      'isProtected': false,
      'phone': '+91 94432 00100',
    },
    {
      'name': 'Harur Town Panchayat Officer',
      'email': 'officer.harur@gov.in',
      'username': '@panchayat_officer',
      'mmid': '20260814-0012',
      'aid': 'AID-20260814-88KP',
      'role': 'Town Admin',
      'isMfa': true,
      'isProtected': false,
      'phone': '+91 94432 11002',
    },
  ];

  final List<Map<String, dynamic>> escalationTickets = [
    {
      'ticketId': 'ESC-8821',
      'user': 'Muthuvel K. (20260814-4821)',
      'query': 'Drinking water pipeline leaking near Ward 4 transformer.',
      'strikes': 3,
      'status': 'Awaiting Admin Response',
      'time': '10 mins ago',
    },
  ];

  @override
  void dispose() {
    _passkeyController.dispose();
    _createUsernameCtrl.dispose();
    _createPasswordCtrl.dispose();
    _createNameCtrl.dispose();
    _createPhoneCtrl.dispose();
    _goNumberCtrl.dispose();
    _goDeptCtrl.dispose();
    _goTitleCtrl.dispose();
    _goSummaryCtrl.dispose();
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
          content: Text('✓ SuperAdmin Session Verified. Mandatory MFA active.'),
        ),
      );
    } else {
      setState(() {
        _failedAttempts++;
        _authError = 'Invalid SuperAdmin Passkey. Attempt $_failedAttempts/5';
      });
    }
  }

  void _handleCreateOfficialUser() {
    final username = _createUsernameCtrl.text.trim();
    final name = _createNameCtrl.text.trim();
    final pwd = _createPasswordCtrl.text.trim();
    final phone = _createPhoneCtrl.text.trim();

    final validationErr = SecurityFilterService.validateUsernameAndName(username: username, fullName: name);
    if (validationErr != null) {
      setState(() => _createValidationError = validationErr);
      return;
    }

    if (pwd.length < 6) {
      setState(() => _createValidationError = 'Password must be at least 6 characters.');
      return;
    }

    setState(() {
      _createValidationError = null;
      adminAccounts.add({
        'name': name,
        'email': "$username@myharur.town",
        'username': "@$username",
        'mmid': AuthService.generateMmid(),
        'aid': AuthService.generateAid(),
        'role': _createSelectedRole == 'govt_official' ? 'Government Official' : 'Town Admin',
        'isMfa': true,
        'isProtected': false,
        'phone': phone.isNotEmpty ? phone : '+91 98420 11000',
      });
      _createUsernameCtrl.clear();
      _createPasswordCtrl.clear();
      _createNameCtrl.clear();
      _createPhoneCtrl.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF007F63),
        content: Text('✓ Created official user @$username with AID assigned!'),
      ),
    );
  }

  Future<void> _handlePublishGo() async {
    final goNo = _goNumberCtrl.text.trim();
    final dept = _goDeptCtrl.text.trim();
    final title = _goTitleCtrl.text.trim();
    final summary = _goSummaryCtrl.text.trim();

    if (title.isEmpty || summary.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter G.O. title and summary.')),
      );
      return;
    }

    await GovtService.publishGovernmentOrder(
      goNumber: goNo,
      department: dept,
      title: title,
      summary: summary,
    );

    _goTitleCtrl.clear();
    _goSummaryCtrl.clear();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF007F63),
          content: Text('✓ Government Order published and broadcast to Harur ledger!'),
        ),
      );
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
            'Security & MFA Verification',
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
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: const Color(0xFF00D09C).withValues(alpha: 0.3)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00D09C).withValues(alpha: 0.15),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00D09C).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.security_rounded, color: Color(0xFF00D09C), size: 34),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'SuperAdmin Passkey / MFA',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Chief Administrator Consensus Security Gate.\nMandatory MFA active for all SuperAdmins.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF8E9F98), fontSize: 12),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _passkeyController,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white, letterSpacing: 6, fontSize: 22, fontWeight: FontWeight.w900),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: '••••••',
                      hintStyle: const TextStyle(color: Color(0xFF52615B)),
                      filled: true,
                      fillColor: const Color(0xFF0A1210),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFF2A3D36)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFF2A3D36)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFF00D09C)),
                      ),
                    ),
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
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00D09C),
                        foregroundColor: const Color(0xFF070B0A),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: _verifyPasskey,
                      child: const Text('Unlock Console', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0F0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0F0D),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Row(
          children: [
            Icon(Icons.shield_rounded, color: Color(0xFF00D09C), size: 20),
            SizedBox(width: 8),
            Text(
              'SuperAdmin Master Console',
              style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 16),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Lock Session',
            icon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF00D09C)),
            onPressed: () => setState(() => _isAuthenticated = false),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Tabs Strip
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              color: const Color(0xFF121C19),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: tabs.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final active = selectedTab == i;
                  return ChoiceChip(
                    label: Text(tabs[i]),
                    selected: active,
                    onSelected: (_) => setState(() => selectedTab = i),
                    selectedColor: const Color(0xFF00D09C),
                    backgroundColor: const Color(0xFF1E2D28),
                    labelStyle: TextStyle(
                      color: active ? const Color(0xFF070B0A) : Colors.white,
                      fontWeight: active ? FontWeight.w900 : FontWeight.w600,
                      fontSize: 11,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  );
                },
              ),
            ),

            // Tab View Body
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  if (selectedTab == 0) _buildModerationTab(),
                  if (selectedTab == 1) _buildTerminationTab(),
                  if (selectedTab == 2) _buildAdminManagementTab(),
                  if (selectedTab == 3) _buildCreateOfficialUserTab(),
                  if (selectedTab == 4) _buildGovOrdersTab(),
                  if (selectedTab == 5) _buildAiSupportTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModerationTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('CONTENT APPROVAL & EVENT HEAD ASSIGNMENT', style: TextStyle(color: Color(0xFF8E9F98), fontSize: 11, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        ...pendingItems.map((item) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF14221E),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF233630)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: item['color'] as Color, borderRadius: BorderRadius.circular(6)),
                      child: Text(item['type'] as String, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
                    ),
                    Text(item['status'] as String, style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 11, fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 10),
                Text(item['title'] as String, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text("Submitted by: ${item['author']}", style: const TextStyle(color: Color(0xFF8E9F98), fontSize: 12)),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00D09C),
                          foregroundColor: const Color(0xFF070B0A),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.check_circle_rounded, size: 16),
                        label: Text(item['type'] == 'Tournament' ? 'Approve & Assign Event Head' : 'Approve & Publish', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
                        onPressed: () {
                          setState(() => pendingItems.remove(item));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('✓ Item approved! Creator assigned Event Head role.')),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFE44545),
                        side: const BorderSide(color: Color(0xFFE44545)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => setState(() => pendingItems.remove(item)),
                      child: const Text('Reject', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11)),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTerminationTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1E2012),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF524F18)),
          ),
          child: const Row(
            children: [
              Icon(Icons.gavel_rounded, color: Color(0xFFF59E0B), size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Democratic 3-Admin confirmation rule active for standard admins.\nSuperAdmin bypasses rule and can terminate immediately.',
                  style: TextStyle(color: Color(0xFFE8DEB5), fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...terminationRequests.map((req) {
          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1414),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF3B2424)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("@${req['username']}", style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
                    Text("MMID: ${req['mmid']}", style: const TextStyle(color: Color(0xFFE44545), fontSize: 11, fontWeight: FontWeight.w800)),
                  ],
                ),
                const SizedBox(height: 6),
                Text("Reason: ${req['reason']}", style: const TextStyle(color: Color(0xFFB09898), fontSize: 12)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text("Consensus Confirmations: ${req['votesCount']}/${req['votesRequired']}", style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 12, fontWeight: FontWeight.w800)),
                    const Spacer(),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE44545),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        setState(() => terminationRequests.remove(req));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('✓ Account terminated via SuperAdmin immediate override.')),
                        );
                      },
                      child: const Text('SuperAdmin Terminate', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildAdminManagementTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('REGISTERED TOWN OFFICIALS & AIDs', style: TextStyle(color: Color(0xFF8E9F98), fontSize: 11, fontWeight: FontWeight.w800)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: const Color(0xFF00D09C).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
              child: const Text('Max 3 SuperAdmins Limit Active', style: TextStyle(color: Color(0xFF00D09C), fontSize: 10, fontWeight: FontWeight.w900)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...adminAccounts.map((admin) {
          final isProtected = admin['isProtected'] == true;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF14221E),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: isProtected ? const Color(0xFF00D09C).withValues(alpha: 0.4) : const Color(0xFF233630)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(admin['name'] as String, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900)),
                              if (isProtected) ...[
                                const SizedBox(width: 6),
                                const Icon(Icons.verified_user_rounded, color: Color(0xFF00D09C), size: 16),
                              ],
                            ],
                          ),
                          Text("${admin['role']} · AID: ${admin['aid']}", style: const TextStyle(color: Color(0xFF00D09C), fontSize: 11, fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0E3025),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF00D09C)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lock_clock_rounded, color: Color(0xFF00D09C), size: 12),
                          SizedBox(width: 4),
                          Text('MFA REQUIRED', style: TextStyle(color: Color(0xFF00D09C), fontSize: 9, fontWeight: FontWeight.w900)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text("Username: ${admin['username']} · MMID: ${admin['mmid']}", style: const TextStyle(color: Color(0xFF8E9F98), fontSize: 11)),
                if (!isProtected) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          setState(() => adminAccounts.remove(admin));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Demoted ${admin['name']} and revoked ${admin['aid']}")),
                          );
                        },
                        child: const Text('Demote & Revoke AID', style: TextStyle(color: Color(0xFFE44545), fontWeight: FontWeight.w800, fontSize: 11)),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildCreateOfficialUserTab() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF14221E),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF233630)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('CREATE OFFICIAL STAFF / GOVT ACCOUNT', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          const Text('Protected with reserved username checks and Tamil/Hindi bad word filter.', style: TextStyle(color: Color(0xFF8E9F98), fontSize: 11)),
          const SizedBox(height: 16),

          _buildConsoleInput('Full Official Name', _createNameCtrl, Icons.badge_rounded),
          const SizedBox(height: 12),
          _buildConsoleInput('Reserved / Official Username (e.g. police_harur)', _createUsernameCtrl, Icons.alternate_email_rounded),
          const SizedBox(height: 12),
          _buildConsoleInput('Password', _createPasswordCtrl, Icons.lock_rounded, obscureText: true),
          const SizedBox(height: 12),
          _buildConsoleInput('Phone Number', _createPhoneCtrl, Icons.phone_rounded),
          const SizedBox(height: 14),

          const Text('Role Allocation', style: TextStyle(color: Color(0xFF8E9F98), fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: _createSelectedRole,
            dropdownColor: const Color(0xFF121C19),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF0A1210),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            ),
            items: const [
              DropdownMenuItem(value: 'govt_official', child: Text('Government Official (Announcements + G.O.)')),
              DropdownMenuItem(value: 'admin', child: Text('Town Admin (Moderation + Approvals)')),
              DropdownMenuItem(value: 'moderator', child: Text('Content Moderator')),
              DropdownMenuItem(value: 'shop_admin', child: Text('Shop Admin (Max 2 Shops)')),
            ],
            onChanged: (val) => setState(() => _createSelectedRole = val ?? 'govt_official'),
          ),

          if (_createValidationError != null) ...[
            const SizedBox(height: 12),
            Text(_createValidationError!, style: const TextStyle(color: Color(0xFFE44545), fontSize: 12, fontWeight: FontWeight.w800)),
          ],

          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00D09C),
                foregroundColor: const Color(0xFF070B0A),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.person_add_rounded, size: 18),
              label: const Text('Create User & Assign AID', style: TextStyle(fontWeight: FontWeight.w900)),
              onPressed: _handleCreateOfficialUser,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGovOrdersTab() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF14221E),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF233630)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('PUBLISH OFFICIAL GOVERNMENT ORDER (G.O.)', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          const Text('Publishes official gazette / order with instant town notification.', style: TextStyle(color: Color(0xFF8E9F98), fontSize: 11)),
          const SizedBox(height: 16),

          _buildConsoleInput('G.O. Number (e.g. G.O. Ms. No. 143/2026)', _goNumberCtrl, Icons.numbers_rounded),
          const SizedBox(height: 12),
          _buildConsoleInput('Department (e.g. Revenue, Agriculture, Public Works)', _goDeptCtrl, Icons.account_balance_rounded),
          const SizedBox(height: 12),
          _buildConsoleInput('Title / Subject', _goTitleCtrl, Icons.title_rounded),
          const SizedBox(height: 12),
          _buildConsoleInput('Summary & Directives', _goSummaryCtrl, Icons.description_rounded, maxLines: 3),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF267AF4),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.send_rounded, size: 18),
              label: const Text('Publish & Broadcast G.O.', style: TextStyle(fontWeight: FontWeight.w900)),
              onPressed: _handlePublishGo,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiSupportTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('GEMINI AI ESCALATION QUEUE (3-STRIKE TICKETS)', style: TextStyle(color: Color(0xFF8E9F98), fontSize: 11, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        ...escalationTickets.map((ticket) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF14221E),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF233630)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Ticket #${ticket['ticketId']}", style: const TextStyle(color: Color(0xFF00D09C), fontWeight: FontWeight.w900)),
                    Text(ticket['time'] as String, style: const TextStyle(color: Color(0xFF8E9F98), fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 6),
                Text("Resident: ${ticket['user']}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
                const SizedBox(height: 4),
                Text("Query: ${ticket['query']}", style: const TextStyle(color: Color(0xFF8E9F98), fontSize: 12)),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00D09C),
                          foregroundColor: const Color(0xFF070B0A),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          setState(() => escalationTickets.remove(ticket));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('✓ Responded to resident and resolved ticket.')),
                          );
                        },
                        child: const Text('Send Official WhatsApp Response', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildConsoleInput(String label, TextEditingController ctrl, IconData icon, {bool obscureText = false, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF8E9F98), fontSize: 11, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          obscureText: obscureText,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: const Color(0xFF00D09C), size: 18),
            filled: true,
            fillColor: const Color(0xFF0A1210),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }
}
