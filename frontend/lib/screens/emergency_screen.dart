import 'package:flutter/material.dart';
import '../api_client.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/design_system.dart';
import '../theme.dart';

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  late Future<List<dynamic>> _sosFuture;
  late Future<List<dynamic>> _govtFuture;

  @override
  void initState() {
    super.initState();
    _fetchEmergencies();
  }

  Future<void> _fetchEmergencies() async {
    setState(() {
      _sosFuture = ApiClient.dio.get('/emergency/', queryParameters: {'type': 'citizen_sos'}).then((r) => r.data);
      _govtFuture = ApiClient.dio.get('/emergency/', queryParameters: {'type': 'govt_grievance'}).then((r) => r.data);
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text('Emergency & Reports', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF081C2D))),
          backgroundColor: Colors.white,
          elevation: 0,
          bottom: const TabBar(
            labelColor: Color(0xFF3A86FF),
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color(0xFF3A86FF),
            tabs: [
              Tab(icon: Icon(Icons.emergency_rounded), text: 'SOS & Nearby'),
              Tab(icon: Icon(Icons.account_balance_rounded), text: 'Govt Grievance'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Color(0xFF081C2D)),
              onPressed: _fetchEmergencies,
            )
          ],
        ),
        floatingActionButton: Builder(
          builder: (ctx) {
            final tab = DefaultTabController.of(ctx);
            return FloatingActionButton.extended(
              onPressed: () {
                if (tab.index == 1) {
                  _showCreateGrievanceDialog();
                } else {
                  _showSosOptionsDialog();
                }
              },
              backgroundColor: const Color(0xFFEF233C),
              icon: const Icon(Icons.add_alert_rounded, color: Colors.white),
              label: Text(tab.index == 1 ? 'Report Issue' : 'Request Help', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            );
          }
        ),
        body: TabBarView(
          children: [
            _buildSosTab(),
            _buildGovtTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildSosTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 100),
      child: Column(
        children: [
          const SizedBox(height: 30),
          GestureDetector(
            onTap: _showSosOptionsDialog,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFFF4B4B), Color(0xFFD90429)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: const Color(0xFFEF233C).withOpacity(0.4), blurRadius: 40, spreadRadius: 15),
                ],
              ),
              child: const Center(
                child: Text('SOS', style: TextStyle(color: Colors.white, fontSize: 52, fontWeight: FontWeight.w900, letterSpacing: 2)),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Hold for 3 seconds for Auto-Dispatch', style: TextStyle(color: Color(0xFF64748B), fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 30),
          _buildHelpCategories(),
          const SizedBox(height: 30),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.0),
            child: Align(alignment: Alignment.centerLeft, child: Text('Nearby Help Requests', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF081C2D)))),
          ),
          const SizedBox(height: 12),
          _buildEmergencyList(_sosFuture, isGovt: false),
        ],
      ),
    );
  }

  Widget _buildHelpCategories() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildCircleAction(Icons.local_police_rounded, 'Police', Colors.blue),
          _buildCircleAction(Icons.medical_services_rounded, 'Medical', Colors.red),
          _buildCircleAction(Icons.bloodtype_rounded, 'Blood', Colors.redAccent),
          _buildCircleAction(Icons.fire_truck_rounded, 'Fire', Colors.orange),
        ],
      ),
    );
  }

  Widget _buildCircleAction(IconData icon, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
      ],
    );
  }

  Widget _buildGovtTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))]
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Report Local Issues', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF081C2D))),
                const SizedBox(height: 8),
                const Text('Report road damage, water supply, electricity, garbage dumping, and street light issues directly to the local panchayat.', style: TextStyle(color: Color(0xFF64748B), height: 1.4)),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.0),
            child: Text('Recent Grievances', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF081C2D))),
          ),
          const SizedBox(height: 12),
          _buildEmergencyList(_govtFuture, isGovt: true),
        ],
      ),
    );
  }

  Widget _buildEmergencyList(Future<List<dynamic>> future, {required bool isGovt}) {
    return FutureBuilder<List<dynamic>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
        if (snapshot.hasError) {
          final e = snapshot.error;
          return MHErrorState(message: e.toString(), onRetry: _fetchEmergencies);
        }
        final items = snapshot.data ?? [];
        if (items.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('No active records.', style: TextStyle(color: Colors.grey))));

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return MHEmergencyCard(item: item, isGovt: isGovt);
          },
        );
      },
    );
  }

  void _showSosOptionsDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Request Emergency Help', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.local_police, color: Colors.blue),
              title: const Text('Call Police (100)'),
              onTap: () async {
                Navigator.pop(ctx);
                final Uri url = Uri(scheme: 'tel', path: '100');
                if (await canLaunchUrl(url)) await launchUrl(url);
              },
            ),
            ListTile(
              leading: const Icon(Icons.medical_services, color: Colors.red),
              title: const Text('Call Ambulance (108)'),
              onTap: () async {
                Navigator.pop(ctx);
                final Uri url = Uri(scheme: 'tel', path: '108');
                if (await canLaunchUrl(url)) await launchUrl(url);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.broadcast_on_personal, color: Colors.orange),
              title: const Text('Notify Nearby Volunteers'),
              subtitle: const Text('Alerts people within 1km radius'),
              onTap: () {
                Navigator.pop(ctx);
                // Trigger API /emergency/ type: citizen_sos
                ApiClient.dio.post('/emergency/', data: {
                  'type': 'citizen_sos',
                  'category': 'medical',
                  'description': 'Immediate assistance needed!',
                  'lat': 12.0628,
                  'lng': 78.4950
                }).then((_) => _fetchEmergencies());
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateGrievanceDialog() {
    String selectedCategory = 'road';
    final descCtrl = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setMBS) => Padding(
          padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Report Government Grievance', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: const InputDecoration(labelText: 'Issue Category', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'road', child: Text('Road Damage')),
                  DropdownMenuItem(value: 'garbage', child: Text('Garbage / Illegal Dumping')),
                  DropdownMenuItem(value: 'light', child: Text('Street Light')),
                  DropdownMenuItem(value: 'water', child: Text('Water Supply')),
                  DropdownMenuItem(value: 'electricity', child: Text('Electricity')),
                  DropdownMenuItem(value: 'drainage', child: Text('Drainage')),
                  DropdownMenuItem(value: 'tree', child: Text('Tree Fall')),
                ],
                onChanged: (v) => setMBS(() => selectedCategory = v!),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder(), hintText: 'Explain the issue briefly...'),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: MHButton(
                  onPressed: isSubmitting ? null : () async {
                    if (descCtrl.text.isEmpty) return;
                    setMBS(() => isSubmitting = true);
                    try {
                      await ApiClient.dio.post('/emergency/', data: {
                        'type': 'govt_grievance',
                        'category': selectedCategory,
                        'description': descCtrl.text,
                        'lat': 12.0628,
                        'lng': 78.4950
                      });
                      if (ctx.mounted) Navigator.pop(ctx);
                      _fetchEmergencies();
                    } catch (e) {
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                      }
                      setMBS(() => isSubmitting = false);
                    }
                  },
                  isLoading: isSubmitting,
                  text: 'Submit Report',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
