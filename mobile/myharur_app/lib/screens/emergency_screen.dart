import 'package:flutter/material.dart';
import '../api_client.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import '../widgets/design_system.dart';
import '../theme.dart';
import '../utils/image_upload_helper.dart';

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
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text('Emergency & Reports', style: TextStyle(fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface)),
          backgroundColor: Theme.of(context).colorScheme.surface,
          elevation: 0,
          bottom: TabBar(
            labelColor: AppTheme.info,
            unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            indicatorColor: AppTheme.info,
            tabs: [
              Tab(icon: Icon(Icons.emergency_rounded), text: 'SOS & Nearby'),
              Tab(icon: Icon(Icons.account_balance_rounded), text: 'Govt Grievance'),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh_rounded, color: Theme.of(context).colorScheme.onSurface),
              onPressed: _fetchEmergencies,
            )
          ],
        ),
        floatingActionButton: Builder(
          builder: (ctx) {
            final tabController = DefaultTabController.of(ctx);
            return AnimatedBuilder(
              animation: tabController,
              builder: (context, _) {
                final isGovt = tabController.index == 1;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 140),
                  child: FloatingActionButton.extended(
                    onPressed: () {
                      if (isGovt) {
                        _showCreateGrievanceDialog();
                      } else {
                        _showSosOptionsDialog();
                      }
                    },
                    backgroundColor: AppTheme.danger,
                    icon: Icon(Icons.add_alert_rounded, color: Theme.of(context).colorScheme.surface),
                    label: Text(isGovt ? 'Report Issue' : 'Request Help', style: TextStyle(color: Theme.of(context).colorScheme.surface, fontWeight: FontWeight.bold)),
                  ),
                );
              }
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
      padding: EdgeInsets.only(bottom: 100),
      child: Column(
        children: [
          SizedBox(height: 30),
          GestureDetector(
            onTap: _showSosOptionsDialog,
            onLongPress: () async {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Auto-Dispatching Emergency SOS...'), backgroundColor: AppTheme.danger));
              try {
                final position = await _getLocationWithConsent();
                if (position == null) return;
                await ApiClient.dio.post('/emergency/', data: {
                  'type': 'citizen_sos',
                  'category': 'police',
                  'description': 'EMERGENCY AUTO-DISPATCH (Hold SOS Button)',
                  'lat': position.latitude,
                  'lng': position.longitude,
                });
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Emergency SOS Auto-Dispatched! Help is on the way.'), backgroundColor: AppTheme.success));
                _fetchEmergencies();
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
              }
            },
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFFFF4B4B), Color(0xFFD90429)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: AppTheme.danger.withOpacity(0.4), blurRadius: 40, spreadRadius: 15),
                ],
              ),
              child: Center(
                child: Text('SOS', style: TextStyle(color: Theme.of(context).colorScheme.surface, fontSize: 52, fontWeight: FontWeight.w900, letterSpacing: 2)),
              ),
            ),
          ),
          SizedBox(height: 20),
          Text('Hold for 3 seconds for Auto-Dispatch', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 14, fontWeight: FontWeight.bold)),
          SizedBox(height: 30),
          _buildHelpCategories(),
          SizedBox(height: 30),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.0),
            child: Align(alignment: Alignment.centerLeft, child: Text('Nearby Help Requests', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface))),
          ),
          SizedBox(height: 12),
          _buildEmergencyList(_sosFuture, isGovt: false),
        ],
      ),
    );
  }

  Widget _buildHelpCategories() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildCircleAction(Icons.local_police_rounded, 'Police', Colors.blue),
              _buildCircleAction(Icons.medical_services_rounded, 'Medical', AppTheme.danger),
              _buildCircleAction(Icons.bloodtype_rounded, 'Blood', AppTheme.danger),
              _buildCircleAction(Icons.fire_truck_rounded, 'Fire', Colors.orange),
            ],
          ),
          SizedBox(height: 24),
          Align(alignment: Alignment.centerLeft, child: Text('Local Emergency Contacts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface))),
          SizedBox(height: 12),
          _buildContactCard('Harur Police Station', '100', Icons.local_police_rounded, Colors.blue),
          SizedBox(height: 8),
          _buildContactCard('Govt Hospital Ambulance', '108', Icons.medical_services_rounded, AppTheme.danger),
          SizedBox(height: 8),
          _buildContactCard('Fire & Rescue Services', '101', Icons.fire_truck_rounded, Colors.orange),
        ],
      ),
    );
  }

  Widget _buildContactCard(String title, String number, IconData icon, Color color) {
    return InkWell(
      onTap: () async {
        final url = Uri.parse('tel:$number');
        if (await canLaunchUrl(url)) await launchUrl(url);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 24),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).colorScheme.onSurface)),
                  SizedBox(height: 4),
                  Text('Call $number', style: TextStyle(fontWeight: FontWeight.w600, color: color)),
                ],
              ),
            ),
            Icon(Icons.call_rounded, color: color),
          ],
        ),
      ),
    );
  }

  Widget _buildCircleAction(IconData icon, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 28),
        ),
        SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
      ],
    );
  }

  Widget _buildGovtTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(20),
            margin: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))]
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Report Local Issues', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                SizedBox(height: 8),
                Text('Report road damage, water supply, electricity, garbage dumping, and street light issues directly to the local panchayat.', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), height: 1.4)),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.0),
            child: Text('Recent Grievances', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
          ),
          SizedBox(height: 12),
          _buildEmergencyList(_govtFuture, isGovt: true),
        ],
      ),
    );
  }

  Widget _buildEmergencyList(Future<List<dynamic>> future, {required bool isGovt}) {
    return FutureBuilder<List<dynamic>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
        if (snapshot.hasError) {
          final e = snapshot.error;
          return MHErrorState(message: e.toString(), onRetry: _fetchEmergencies);
        }
        final items = snapshot.data ?? [];
        if (items.isEmpty) return Center(child: Padding(padding: EdgeInsets.all(24), child: Text('No active records.', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)))));

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 16),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return MHEmergencyCard(
              item: item, 
              isGovt: isGovt,
              onStatusUpdate: (newStatus) async {
                try {
                  await ApiClient.dio.put('/emergency/${item['id']}/status', queryParameters: {'status': newStatus});
                  _fetchEmergencies();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status updated to $newStatus')));
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update: $e')));
                  }
                }
              },
            );
          },
        );
      },
    );
  }

  Future<Position?> _getLocationWithConsent() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enable location services to report.')));
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      final bool? consent = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Location Access Needed'),
          content: Text('To report an emergency, we need your exact GPS location. This will be shared with authorities and nearby responders.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Allow')),
          ],
        ),
      );
      if (consent != true) return null;
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permission denied.')));
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permissions are permanently denied.')));
      return null;
    }

    try {
      return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to get location: $e')));
      return null;
    }
  }

  Widget _buildCategoryChip(String value, String label, IconData icon, String selectedValue, Function(String) onSelect) {
    final isSelected = value == selectedValue;
    return ChoiceChip(
      label: Text(label),
      avatar: Icon(icon, color: isSelected ? Colors.white : Theme.of(context).colorScheme.primary, size: 18),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) onSelect(value);
      },
      selectedColor: Theme.of(context).colorScheme.primary,
      labelStyle: TextStyle(color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface),
    );
  }

  void _showSosOptionsDialog() {
    String selectedCategory = 'police';
    final descCtrl = TextEditingController();
    bool isSubmitting = false;
    String? imageUrl;
    bool isUploadingImage = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setMBS) => Padding(
          padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 100),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Request Emergency Help', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 16),
              
              GestureDetector(
                onTap: () async {
                  if (isUploadingImage) return;
                  setMBS(() => isUploadingImage = true);
                  final url = await ImageUploadHelper.pickAndUpload();
                  setMBS(() {
                    if (url != null) imageUrl = url;
                    isUploadingImage = false;
                  });
                },
                child: Container(
                  height: 100,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    image: imageUrl != null ? DecorationImage(image: NetworkImage(imageUrl!), fit: BoxFit.cover) : null,
                  ),
                  child: isUploadingImage
                      ? Center(child: CircularProgressIndicator())
                      : imageUrl == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo, size: 30, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                                SizedBox(height: 4),
                                Text('Add Photo (Optional)', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
                              ],
                            )
                          : SizedBox(),
                ),
              ),
              SizedBox(height: 16),

              Text('Help Category', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildCategoryChip('police', 'Police', Icons.local_police_rounded, selectedCategory, (v) => setMBS(() => selectedCategory = v)),
                  _buildCategoryChip('fire', 'Fire', Icons.fire_truck_rounded, selectedCategory, (v) => setMBS(() => selectedCategory = v)),
                  _buildCategoryChip('ambulance', 'Medical', Icons.medical_services_rounded, selectedCategory, (v) => setMBS(() => selectedCategory = v)),
                  _buildCategoryChip('blood', 'Blood', Icons.bloodtype_rounded, selectedCategory, (v) => setMBS(() => selectedCategory = v)),
                  _buildCategoryChip('custom_help', 'Other', Icons.help_outline_rounded, selectedCategory, (v) => setMBS(() => selectedCategory = v)),
                ],
              ),
              SizedBox(height: 16),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Custom Problem / Details', border: OutlineInputBorder(), hintText: 'Explain the emergency...'),
                maxLines: 3,
              ),
              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: MHButton(
                  onPressed: isSubmitting ? null : () async {
                    if (descCtrl.text.isEmpty && selectedCategory == 'custom_help') {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please describe the custom problem.')));
                      return;
                    }
                    setMBS(() => isSubmitting = true);
                    try {
                      final position = await _getLocationWithConsent();
                      if (position == null) {
                        setMBS(() => isSubmitting = false);
                        return;
                      }
                      
                      await ApiClient.dio.post('/emergency/', data: {
                        'type': 'citizen_sos',
                        'category': selectedCategory,
                        'description': descCtrl.text,
                        'lat': position.latitude,
                        'lng': position.longitude,
                        'photo_url': imageUrl,
                      });
                      if (ctx.mounted) Navigator.pop(ctx);
                      _fetchEmergencies();
                    } catch (e) {
                      if (ctx.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                      setMBS(() => isSubmitting = false);
                    }
                  },
                  isLoading: isSubmitting,
                  text: 'Submit Request',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateGrievanceDialog() {
    String selectedCategory = 'electricity';
    final descCtrl = TextEditingController();
    bool isSubmitting = false;
    String? imageUrl;
    bool isUploadingImage = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setMBS) => Padding(
          padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 100),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Report Government Grievance', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 16),
              
              GestureDetector(
                onTap: () async {
                  if (isUploadingImage) return;
                  setMBS(() => isUploadingImage = true);
                  final url = await ImageUploadHelper.pickAndUpload();
                  setMBS(() {
                    if (url != null) imageUrl = url;
                    isUploadingImage = false;
                  });
                },
                child: Container(
                  height: 100,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    image: imageUrl != null ? DecorationImage(image: NetworkImage(imageUrl!), fit: BoxFit.cover) : null,
                  ),
                  child: isUploadingImage
                      ? Center(child: CircularProgressIndicator())
                      : imageUrl == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo, size: 30, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                                SizedBox(height: 4),
                                Text('Add Photo (Optional)', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
                              ],
                            )
                          : SizedBox(),
                ),
              ),
              SizedBox(height: 16),

              Text('Issue Category', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildCategoryChip('electricity', 'Electricity', Icons.electric_bolt_rounded, selectedCategory, (v) => setMBS(() => selectedCategory = v)),
                  _buildCategoryChip('light', 'Street Light', Icons.lightbulb_rounded, selectedCategory, (v) => setMBS(() => selectedCategory = v)),
                  _buildCategoryChip('pothole', 'Pothole', Icons.add_road_rounded, selectedCategory, (v) => setMBS(() => selectedCategory = v)),
                  _buildCategoryChip('water', 'Water Supply', Icons.water_drop_rounded, selectedCategory, (v) => setMBS(() => selectedCategory = v)),
                  _buildCategoryChip('water_stagnation', 'Stagnation', Icons.waves_rounded, selectedCategory, (v) => setMBS(() => selectedCategory = v)),
                ],
              ),
              SizedBox(height: 16),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder(), hintText: 'Explain the issue briefly...'),
                maxLines: 3,
              ),
              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: MHButton(
                  onPressed: isSubmitting ? null : () async {
                    if (descCtrl.text.isEmpty) return;
                    setMBS(() => isSubmitting = true);
                    try {
                      final position = await _getLocationWithConsent();
                      if (position == null) {
                        setMBS(() => isSubmitting = false);
                        return;
                      }
                      
                      await ApiClient.dio.post('/emergency/', data: {
                        'type': 'govt_grievance',
                        'category': selectedCategory,
                        'description': descCtrl.text,
                        'lat': position.latitude,
                        'lng': position.longitude,
                        'photo_url': imageUrl,
                      });
                      if (ctx.mounted) Navigator.pop(ctx);
                      _fetchEmergencies();
                    } catch (e) {
                      if (ctx.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
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
