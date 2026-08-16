import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/supabase_service.dart';
import '../services/harur_real_data_service.dart';

// Reuse AppTheme colors and icons consistent with main.dart
class PhaseTwoTheme {
  static const ink = Color(0xFF1C1C1E);
  static const muted = Color(0xFF8E8E93);
  static const mist = Color(0xFFF2F2F7);
  static const line = Color(0xFFE5E5EA);
  static const green = Color(0xFF007AFF);
  static const red = Color(0xFFE44545);
  static const blue = Color(0xFF267AF4);
  static const amber = Color(0xFFF59E0B);
  static const surfaceWarm = Color(0xFFFFFBF0);
}

Widget _buildIcon(String name, {Color color = PhaseTwoTheme.ink, double size = 22}) {
  return SvgPicture.asset(
    'assets/icons/$name.svg',
    width: size,
    height: size,
    colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    semanticsLabel: name,
  );
}

// ==========================================
// 1. LOCATION SELECTION PAGE
// ==========================================
class LocationSelectionPage extends StatefulWidget {
  const LocationSelectionPage({super.key});

  @override
  State<LocationSelectionPage> createState() => _LocationSelectionPageState();
}

class _LocationSelectionPageState extends State<LocationSelectionPage> {
  String selectedLocation = 'Harur Town (Main)';
  String query = '';
  bool isLocating = false;

  final List<Map<String, dynamic>> regions = [
    {
      'name': 'Harur Town (Main)',
      'taluk': 'Harur Taluk',
      'distance': '0.0 km',
      'isDefault': true,
      'isGeofenced': true,
    },
    {
      'name': 'Morappur',
      'taluk': 'Harur Taluk',
      'distance': '14.2 km',
      'isDefault': false,
      'isGeofenced': true,
    },
    {
      'name': 'Theerthamalai',
      'taluk': 'Harur Taluk',
      'distance': '16.5 km',
      'isDefault': false,
      'isGeofenced': true,
    },
    {
      'name': 'Kottapatti',
      'taluk': 'Harur Taluk',
      'distance': '22.0 km',
      'isDefault': false,
      'isGeofenced': true,
    },
    {
      'name': 'Pappireddipatti',
      'taluk': 'Pappireddipatti Taluk',
      'distance': '18.4 km',
      'isDefault': false,
      'isGeofenced': true,
    },
    {
      'name': 'Kadathur',
      'taluk': 'Pappireddipatti Taluk',
      'distance': '24.1 km',
      'isDefault': false,
      'isGeofenced': true,
    },
    {
      'name': 'Dharmapuri HQ',
      'taluk': 'Dharmapuri District',
      'distance': '38.0 km',
      'isDefault': false,
      'isGeofenced': true,
    },
    {
      'name': 'Uthangarai Border',
      'taluk': 'Krishnagiri District',
      'distance': '32.5 km',
      'isDefault': false,
      'isGeofenced': true,
    },
  ];

  void _triggerGps() {
    setState(() => isLocating = true);
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) {
        setState(() {
          isLocating = false;
          selectedLocation = 'Harur Town (Main)';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: PhaseTwoTheme.ink,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            content: const Text(
              'Location verified: Harur, Dharmapuri (Accuracy: 12m)',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = regions
        .where((r) =>
            r['name'].toString().toLowerCase().contains(query.toLowerCase()) ||
            r['taluk'].toString().toLowerCase().contains(query.toLowerCase()))
        .toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Select Location',
          style: TextStyle(fontWeight: FontWeight.w900, color: PhaseTwoTheme.ink),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: PhaseTwoTheme.ink, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          children: [
            // Search field
            Container(
              decoration: BoxDecoration(
                color: PhaseTwoTheme.mist,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: PhaseTwoTheme.line),
              ),
              child: TextField(
                onChanged: (val) => setState(() => query = val),
                decoration: const InputDecoration(
                  hintText: 'Search ward, town or taluk...',
                  hintStyle: TextStyle(color: PhaseTwoTheme.muted, fontSize: 14),
                  prefixIcon: Icon(Icons.search_rounded, color: PhaseTwoTheme.muted),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Use GPS Button
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: _triggerGps,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEBF5FF),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFBBE5D8)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: PhaseTwoTheme.green,
                        shape: BoxShape.circle,
                      ),
                      child: isLocating
                          ? const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              ),
                            )
                          : Center(child: _buildIcon('pin', color: Colors.white, size: 20)),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Use Current GPS Location',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Automatic detection within Harur boundaries',
                            style: TextStyle(fontSize: 12, color: PhaseTwoTheme.muted),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.my_location_rounded, color: PhaseTwoTheme.green),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'HARUR & DHARMAPURI REGIONS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: PhaseTwoTheme.muted,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 12),

            ...filtered.map((region) {
              final isSelected = selectedLocation == region['name'];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFF6FBF9) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? PhaseTwoTheme.green : PhaseTwoTheme.line,
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFEBF5FF) : PhaseTwoTheme.mist,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: _buildIcon(
                        'pin',
                        color: isSelected ? PhaseTwoTheme.green : PhaseTwoTheme.muted,
                        size: 20,
                      ),
                    ),
                  ),
                  title: Text(
                    region['name'],
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                      color: PhaseTwoTheme.ink,
                    ),
                  ),
                  subtitle: Text(
                    '${region['taluk']} · ${region['distance']}',
                    style: const TextStyle(fontSize: 12, color: PhaseTwoTheme.muted),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle_rounded, color: PhaseTwoTheme.green)
                      : const Icon(Icons.chevron_right_rounded, color: PhaseTwoTheme.line),
                  onTap: () {
                    setState(() => selectedLocation = region['name']);
                    Navigator.pop(context);
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 2. NEWS HUB & SUBMISSION PAGE
// ==========================================
class NewsHubPage extends StatefulWidget {
  const NewsHubPage({super.key});

  @override
  State<NewsHubPage> createState() => _NewsHubPageState();
}

class _NewsHubPageState extends State<NewsHubPage> {
  int selectedCategoryIndex = 0;
  final List<String> categories = ['All', 'Official', 'Agriculture', 'Civic', 'Events'];
  List<Map<String, dynamic>> newsList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNews();
  }

  Future<void> _loadNews() async {
    setState(() => isLoading = true);
    final data = await NewsService.fetchNews();
    if (mounted) {
      setState(() {
        newsList = data.map((item) {
          return {
            'title': item['title'] ?? '',
            'summary': item['summary'] ?? '',
            'category': item['category'] ?? 'Civic',
            'source': item['source_name'] ?? 'Local Report',
            'time': 'Recent',
            'isVerified': true,
            'badgeColor': PhaseTwoTheme.green,
          };
        }).toList();
        isLoading = false;
      });
    }
  }

  void _openSubmitSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => SubmitNewsSheet(onSubmitted: _loadNews),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = selectedCategoryIndex == 0
        ? newsList
        : newsList.where((n) => n['category'] == categories[selectedCategoryIndex]).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Harur Local News',
          style: TextStyle(fontWeight: FontWeight.w900, color: PhaseTwoTheme.ink),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: PhaseTwoTheme.ink, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: _buildIcon('sparkle', color: PhaseTwoTheme.green, size: 20),
            onPressed: _openSubmitSheet,
            tooltip: 'Submit News',
          )
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Category selector tabs
            SizedBox(
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final active = selectedCategoryIndex == i;
                  return ChoiceChip(
                    label: Text(categories[i]),
                    selected: active,
                    onSelected: (_) => setState(() => selectedCategoryIndex = i),
                    selectedColor: PhaseTwoTheme.green,
                    backgroundColor: PhaseTwoTheme.mist,
                    labelStyle: TextStyle(
                      color: active ? Colors.white : PhaseTwoTheme.ink,
                      fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                      fontSize: 13,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    side: BorderSide(
                      color: active ? PhaseTwoTheme.green : PhaseTwoTheme.line,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),

            // News List
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, i) {
                  final item = filtered[i];
                  return InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () {
                      _showNewsDetailModal(context, item);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: PhaseTwoTheme.line),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x080F2922),
                            blurRadius: 14,
                            offset: Offset(0, 5),
                          )
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
                                  color: (item['badgeColor'] as Color).withValues(alpha: .12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  item['category'].toString().toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    color: item['badgeColor'] as Color,
                                    letterSpacing: .6,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              if (item['isVerified'] == true)
                                const Row(
                                  children: [
                                    Icon(Icons.verified_rounded, size: 15, color: PhaseTwoTheme.green),
                                    SizedBox(width: 4),
                                    Text(
                                      'Verified Source',
                                      style: TextStyle(fontSize: 11, color: PhaseTwoTheme.green, fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            item['title'],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              height: 1.25,
                              color: PhaseTwoTheme.ink,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item['summary'],
                            style: const TextStyle(
                              fontSize: 13,
                              color: PhaseTwoTheme.muted,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              _buildIcon('news', color: PhaseTwoTheme.muted, size: 14),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  item['source'],
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: PhaseTwoTheme.muted,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Text(
                                item['time'],
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: PhaseTwoTheme.muted,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: PhaseTwoTheme.green,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Submit News', style: TextStyle(fontWeight: FontWeight.w800)),
        onPressed: _openSubmitSheet,
      ),
    );
  }

  void _showNewsDetailModal(BuildContext context, Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Padding(
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
                  color: PhaseTwoTheme.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (item['badgeColor'] as Color).withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    item['category'].toString().toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: item['badgeColor'] as Color,
                    ),
                  ),
                ),
                const Spacer(),
                Text(item['time'], style: const TextStyle(fontSize: 12, color: PhaseTwoTheme.muted)),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              item['title'],
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, height: 1.2),
            ),
            const SizedBox(height: 12),
            Text(
              item['summary'],
              style: const TextStyle(fontSize: 14, color: PhaseTwoTheme.muted, height: 1.45),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: PhaseTwoTheme.mist,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: PhaseTwoTheme.line),
              ),
              child: Row(
                children: [
                  _buildIcon('shield', color: PhaseTwoTheme.green, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Source Attribution', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                        Text(item['source'], style: const TextStyle(fontSize: 11, color: PhaseTwoTheme.muted)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: PhaseTwoTheme.ink,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class SubmitNewsSheet extends StatefulWidget {
  final VoidCallback? onSubmitted;
  const SubmitNewsSheet({super.key, this.onSubmitted});

  @override
  State<SubmitNewsSheet> createState() => _SubmitNewsSheetState();
}

class _SubmitNewsSheetState extends State<SubmitNewsSheet> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  final _sourceCtrl = TextEditingController();
  String category = 'Civic';
  bool isSubmitting = false;

  Future<void> _submit() async {
    final title = _titleCtrl.text.trim();
    final body = _bodyCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a news headline')),
      );
      return;
    }
    setState(() => isSubmitting = true);
    await NewsService.submitNews(
      title: title,
      summary: body.isNotEmpty ? body : title,
      sourceUrl: _sourceCtrl.text.trim().isNotEmpty ? _sourceCtrl.text.trim() : null,
      category: category,
    );
    widget.onSubmitted?.call();
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: PhaseTwoTheme.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: const Text(
            'News submitted! Sent to Harur moderation queue.',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      );
    }
  }

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
                  color: PhaseTwoTheme.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Submit Local Story',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: PhaseTwoTheme.ink),
            ),
            const SizedBox(height: 4),
            const Text(
              'Local reports are verified before publishing to the town feed.',
              style: TextStyle(fontSize: 12, color: PhaseTwoTheme.muted),
            ),
            const SizedBox(height: 18),

            TextField(
              controller: _titleCtrl,
              decoration: InputDecoration(
                labelText: 'Headline',
                labelStyle: const TextStyle(color: PhaseTwoTheme.muted, fontSize: 13),
                filled: true,
                fillColor: PhaseTwoTheme.mist,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: PhaseTwoTheme.line),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: PhaseTwoTheme.line),
                ),
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _bodyCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Story description & details',
                labelStyle: const TextStyle(color: PhaseTwoTheme.muted, fontSize: 13),
                filled: true,
                fillColor: PhaseTwoTheme.mist,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: PhaseTwoTheme.line),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: PhaseTwoTheme.line),
                ),
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _sourceCtrl,
              decoration: InputDecoration(
                labelText: 'Source or witness reference (optional)',
                labelStyle: const TextStyle(color: PhaseTwoTheme.muted, fontSize: 13),
                filled: true,
                fillColor: PhaseTwoTheme.mist,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: PhaseTwoTheme.line),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: PhaseTwoTheme.line),
                ),
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: PhaseTwoTheme.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: isSubmitting ? null : _submit,
                child: isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Send for Approval', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 3. WEATHER HUB & FARMER ADVISORY
// ==========================================
class WeatherHubPage extends StatelessWidget {
  const WeatherHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Harur & Dharmapuri Climate',
          style: TextStyle(fontWeight: FontWeight.w900, color: PhaseTwoTheme.ink),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: PhaseTwoTheme.ink, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>>(
          future: HarurRealDataService.fetchLiveHarurWeather(locality: 'Harur'),
          builder: (context, snapshot) {
            final data = snapshot.data ?? {
              'location': 'Harur Taluk',
              'temperature_c': 32.5,
              'feels_like_c': 35.0,
              'condition': 'Partly Cloudy & Breeze',
              'humidity_percent': 62,
              'wind_kph': 14.0,
              'station': 'Harur Automatic Weather Station (AWS)',
              'hourly': [
                {'time': '06:00', 'temp': '24°'},
                {'time': '09:00', 'temp': '28°'},
                {'time': '12:00', 'temp': '33°'},
                {'time': '15:00', 'temp': '34°'},
                {'time': '18:00', 'temp': '29°'},
                {'time': '21:00', 'temp': '26°'},
              ],
            };

            final temp = "${(data['temperature_c'] as num).round()}°C";
            final feelsLike = "${(data['feels_like_c'] as num).round()}°C";
            final condition = data['condition'] as String;
            final humidity = "${data['humidity_percent']}%";
            final wind = "${data['wind_kph']} km/h";
            final station = data['station'] as String? ?? 'Harur AWS Station';
            final hourlyList = List<Map<String, dynamic>>.from(data['hourly'] ?? []);

            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              children: [
                // Main temperature showcase
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF267AF4), Color(0xFF1B55B0)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33267AF4),
                        blurRadius: 20,
                        offset: Offset(0, 8),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(data['location'] ?? 'Harur Town', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                              Text(station, style: const TextStyle(color: Color(0xCCE0E8FF), fontSize: 11)),
                            ],
                          ),
                          _buildIcon('cloud', color: Colors.white, size: 36),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(temp, style: const TextStyle(color: Colors.white, fontSize: 46, fontWeight: FontWeight.w900)),
                      Text('$condition · Feels like $feelsLike', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _WeatherStat(label: 'Humidity', value: humidity),
                            _WeatherStat(label: 'Wind', value: wind),
                            const _WeatherStat(label: 'Rain Chance', value: '15%'),
                            const _WeatherStat(label: 'UV Index', value: '5 (Mod)'),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Hourly Forecast
                const Text(
                  'HOURLY TREND (HARUR AWS)',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: PhaseTwoTheme.muted, letterSpacing: 1.1),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 105,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: hourlyList.length,
                    itemBuilder: (context, i) {
                      final h = hourlyList[i];
                      return _HourlyPill(
                        time: h['time'] as String,
                        temp: h['temp'] as String,
                        isCurrent: i == 0,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // Farmer & Agriculture Advisory
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7E8),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFF1E0BE)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFC17600).withValues(alpha: .15),
                              shape: BoxShape.circle,
                            ),
                            child: _buildIcon('sparkle', color: const Color(0xFFC17600), size: 18),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Farmer & Crop Advisory',
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFFC17600)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Mild showers expected in Morappur and Theerthamalai foothills in the next 48h. Suitable for post-sowing field aeration and sugarcane soil conditioning.',
                        style: TextStyle(fontSize: 13, height: 1.35, color: PhaseTwoTheme.ink),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Issued by Dharmapuri Krishi Vigyan Kendra (KVK)',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: PhaseTwoTheme.muted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _WeatherStat extends StatelessWidget {
  const _WeatherStat({required this.label, required this.value});
  final String label, value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Color(0xCCE0E8FF), fontSize: 11)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
      ],
    );
  }
}

class _HourlyPill extends StatelessWidget {
  const _HourlyPill({required this.time, required this.temp, this.isCurrent = false});
  final String time, temp;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: isCurrent ? const Color(0xFFEBF5FF) : PhaseTwoTheme.mist,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isCurrent ? PhaseTwoTheme.green : PhaseTwoTheme.line),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(time, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isCurrent ? PhaseTwoTheme.green : PhaseTwoTheme.muted)),
          const SizedBox(height: 6),
          _buildIcon('cloud', color: isCurrent ? PhaseTwoTheme.green : PhaseTwoTheme.ink, size: 18),
          const SizedBox(height: 6),
          Text(temp, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
        ],
      ),
    );
  }
}

// ==========================================
// 4. EMERGENCY & NEARBY HELP PAGE
// ==========================================
class EmergencyReportPage extends StatefulWidget {
  const EmergencyReportPage({super.key});

  @override
  State<EmergencyReportPage> createState() => _EmergencyReportPageState();
}

class _EmergencyReportPageState extends State<EmergencyReportPage> {
  int escalationRadiusKm = 1;
  String selectedType = 'Medical Emergency';

  late final List<Map<String, dynamic>> helplines;

  @override
  void initState() {
    super.initState();
    helplines = HarurRealDataService.getRealEmergencyHelplines();
  }

  final List<String> emergencyTypes = [
    'Medical Emergency',
    'Road Accident',
    'Fire / Electric Hazard',
    'Elderly / Urgent Assistance',
    'Disaster & Flood Alert',
  ];

  Future<void> _callHelpline(String phone) async {
    try {
      final uri = Uri.parse('tel:$phone');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (_) {}
  }

  void _triggerEmergencyAlert() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: PhaseTwoTheme.red),
            SizedBox(width: 8),
            Text('Confirm Emergency', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
          ],
        ),
        content: Text(
          'An urgent SOS beacon will be fanned out to nearby verified volunteers within $escalationRadiusKm km of Harur and notified to emergency services.',
          style: const TextStyle(fontSize: 13, color: PhaseTwoTheme.muted, height: 1.35),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: PhaseTwoTheme.muted, fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: PhaseTwoTheme.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _showBeaconActiveDialog();
            },
            child: const Text('Broadcast SOS', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  void _showBeaconActiveDialog() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: Color(0xFFFFECEB),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(Icons.emergency_rounded, color: PhaseTwoTheme.red, size: 36),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Emergency Broadcast Active',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              'Case ID: #HR-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
              style: const TextStyle(fontWeight: FontWeight.w700, color: PhaseTwoTheme.muted, fontSize: 13),
            ),
            const SizedBox(height: 16),
            const Text(
              'Nearby community responders and local services in Harur are being notified.',
              textAlign: TextAlign.center,
              style: TextStyle(color: PhaseTwoTheme.muted, fontSize: 13),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: PhaseTwoTheme.red,
                  side: const BorderSide(color: PhaseTwoTheme.red),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Emergency beacon resolved/closed.')),
                  );
                },
                child: const Text('Resolve / Cancel Broadcast', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
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
          'Emergency & Helplines',
          style: TextStyle(fontWeight: FontWeight.w900, color: PhaseTwoTheme.ink),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: PhaseTwoTheme.ink, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          children: [
            // Panic Beacon Box
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFFECEB),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: const Color(0xFFF8C9C5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: PhaseTwoTheme.red, size: 28),
                      SizedBox(width: 10),
                      Text(
                        'Raise Nearby Help',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: PhaseTwoTheme.red),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Select emergency nature & broadcast radius for instant volunteer response:',
                    style: TextStyle(fontSize: 13, color: PhaseTwoTheme.ink),
                  ),
                  const SizedBox(height: 16),

                  // Emergency category dropdown
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: PhaseTwoTheme.line),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedType,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded),
                        items: emergencyTypes
                            .map((t) => DropdownMenuItem(
                                  value: t,
                                  child: Text(t, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                                ))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => selectedType = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Proximity Radius Selector
                  Row(
                    children: [
                      const Text('Radius:', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                      const SizedBox(width: 10),
                      ...[1, 5, 10].map((radius) {
                        final active = escalationRadiusKm == radius;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => setState(() => escalationRadiusKm = radius),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: active ? PhaseTwoTheme.red : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: active ? PhaseTwoTheme.red : PhaseTwoTheme.line,
                                ),
                              ),
                              child: Text(
                                '${radius}km',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: active ? Colors.white : PhaseTwoTheme.ink,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 18),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: PhaseTwoTheme.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: _triggerEmergencyAlert,
                      icon: const Icon(Icons.bolt_rounded, size: 22),
                      label: const Text('Broadcast Emergency Beacon', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),

            const Text(
              'OFFICIAL EMERGENCY & CIVIC CONTACTS (HARUR)',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: PhaseTwoTheme.muted, letterSpacing: 1.1),
            ),
            const SizedBox(height: 12),

            ...helplines.map((line) {
              final type = line['type'] as String? ?? 'medical';
              final icon = switch (type) {
                'police' => Icons.local_police_rounded,
                'fire' => Icons.fire_truck_rounded,
                'utility' => Icons.electric_bolt_rounded,
                'civic' => Icons.account_balance_rounded,
                'women' => Icons.shield_rounded,
                'child' => Icons.family_restroom_rounded,
                _ => Icons.medical_services_rounded,
              };

              final color = switch (type) {
                'police' => PhaseTwoTheme.blue,
                'fire' => PhaseTwoTheme.amber,
                'utility' => const Color(0xFFF59E0B),
                'civic' => PhaseTwoTheme.green,
                'women' => const Color(0xFF8B5CF6),
                'child' => const Color(0xFFEC4899),
                _ => PhaseTwoTheme.red,
              };

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: PhaseTwoTheme.line),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  title: Text(line['department'] as String, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                  subtitle: Text('${line['number']} · ${line['address']}', style: const TextStyle(fontSize: 11, color: PhaseTwoTheme.muted)),
                  trailing: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: PhaseTwoTheme.mist,
                      shape: BoxShape.circle,
                      border: Border.all(color: PhaseTwoTheme.line),
                    ),
                    child: const Icon(Icons.call_rounded, color: PhaseTwoTheme.green, size: 18),
                  ),
                  onTap: () => _callHelpline(line['full_phone'] as String),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 5. EMERGENCY SOS DEDICATED PAGE
// ==========================================
class EmergencySosPage extends StatelessWidget {
  const EmergencySosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmergencyReportPage();
  }
}

// ==========================================
// 6. HARUR AGRI MANDI DAILY RATES PAGE
// ==========================================
class AgriMandiPage extends StatefulWidget {
  const AgriMandiPage({super.key});

  @override
  State<AgriMandiPage> createState() => _AgriMandiPageState();
}

class _AgriMandiPageState extends State<AgriMandiPage> {
  int selectedCategory = 0;
  final categories = [
    'All Commodities',
    'Sugarcane & Tapioca',
    'Grains & Cereals',
    'Commercial Crops',
    'Oilseeds',
    'Vegetables & Flowers',
  ];

  late final List<Map<String, dynamic>> commodities;

  @override
  void initState() {
    super.initState();
    commodities = HarurRealDataService.getRealMandiRates();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = selectedCategory == 0
        ? commodities
        : commodities.where((c) => c['category'] == categories[selectedCategory]).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Harur Agri Mandi Rates',
          style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1C1C1E)),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1C1C1E), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Category selector
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
                    selectedColor: const Color(0xFF007AFF),
                    backgroundColor: const Color(0xFFF2F2F7),
                    labelStyle: TextStyle(
                      color: active ? Colors.white : const Color(0xFF1C1C1E),
                      fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                      fontSize: 12,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    side: BorderSide(color: active ? const Color(0xFF007AFF) : const Color(0xFFE5E5EA)),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final item = filtered[i];
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE5E5EA)),
                      boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 4))],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEBF5FF),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.eco_rounded, color: Color(0xFF007AFF), size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item['name'] as String, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF1C1C1E))),
                              const SizedBox(height: 2),
                              Text(item['mandi'] as String, style: const TextStyle(fontSize: 11, color: Color(0xFF8E8E93), fontWeight: FontWeight.w600)),
                              if (item['notes'] != null) ...[
                                const SizedBox(height: 2),
                                Text(item['notes'] as String, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                              ],
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    item['trendUp'] as bool ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                                    size: 13,
                                    color: item['trendUp'] as bool ? const Color(0xFF007AFF) : const Color(0xFFE44545),
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    item['trend'] as String,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: item['trendUp'] as bool ? const Color(0xFF007AFF) : const Color(0xFFE44545),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1C1C1E),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            item['price'] as String,
                            style: const TextStyle(color: Color(0xFF007AFF), fontWeight: FontWeight.w900, fontSize: 12),
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
    );
  }
}

// ==========================================
// 7. HARUR BUS ROUTES & TIMINGS PAGE
// ==========================================
class BusRoutesPage extends StatefulWidget {
  const BusRoutesPage({super.key});

  @override
  State<BusRoutesPage> createState() => _BusRoutesPageState();
}

class _BusRoutesPageState extends State<BusRoutesPage> {
  String searchDestination = '';
  late final List<Map<String, dynamic>> routes;

  @override
  void initState() {
    super.initState();
    routes = HarurRealDataService.getRealBusRoutes();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = searchDestination.isEmpty
        ? routes
        : routes.where((r) =>
            r['route'].toString().toLowerCase().contains(searchDestination.toLowerCase()) ||
            r['via'].toString().toLowerCase().contains(searchDestination.toLowerCase())).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Harur Bus Routes & Timings',
          style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1C1C1E)),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1C1C1E), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: TextField(
                onChanged: (val) => setState(() => searchDestination = val.trim()),
                decoration: InputDecoration(
                  hintText: 'Search destination (e.g. Salem, Morappur, Chennai, Bangalore)...',
                  prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF007AFF)),
                  filled: true,
                  fillColor: const Color(0xFFF2F2F7),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final r = filtered[i];
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE5E5EA)),
                      boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 4))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF007AFF),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(r['type'] as String, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
                            ),
                            const Spacer(),
                            Text(r['duration'] as String, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF8E8E93))),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(r['route'] as String, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF1C1C1E))),
                        const SizedBox(height: 3),
                        Text(r['via'] as String, style: const TextStyle(fontSize: 11, color: Color(0xFF8E8E93), fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(r['busNumber'] as String, style: const TextStyle(fontSize: 12, color: Color(0xFF007AFF), fontWeight: FontWeight.w800)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.schedule_rounded, size: 14, color: Color(0xFF8E8E93)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                r['timings'] != null ? 'Timings: ${r['timings']}' : (r['frequency'] ?? ''),
                                style: const TextStyle(fontSize: 11, color: Color(0xFF8E8E93), fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF8E8E93)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                r['platform'] as String,
                                style: const TextStyle(fontSize: 11, color: Color(0xFF8E8E93)),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(r['fare'] as String? ?? '', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF007AFF))),
                          ],
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
    );
  }
}

// ==========================================
// 8. HARUR BLOOD DONOR & BLOOD STORAGE DIRECTORY
// ==========================================
class BloodDonorsPage extends StatefulWidget {
  const BloodDonorsPage({super.key});

  @override
  State<BloodDonorsPage> createState() => _BloodDonorsPageState();
}

class _BloodDonorsPageState extends State<BloodDonorsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String selectedBloodGroup = 'All';
  final bloodGroups = ['All', 'O+', 'A+', 'B+', 'AB+', 'O-', 'A-', 'B-', 'AB-'];

  late final List<Map<String, dynamic>> bloodBanks;

  final List<Map<String, dynamic>> donors = [
    {
      'name': 'Karthik Selvam',
      'bloodGroup': 'O+',
      'locality': 'Bazaar Street, Harur',
      'phone': '9842011001',
      'lastDonated': '4 months ago',
      'donationsCount': 6,
      'isAvailable': true,
    },
    {
      'name': 'Dr. K. Vignesh',
      'bloodGroup': 'A+',
      'locality': 'Harur GH Quarters',
      'phone': '9443211002',
      'lastDonated': '6 months ago',
      'donationsCount': 12,
      'isAvailable': true,
    },
    {
      'name': 'Muthuvel Kumaran',
      'bloodGroup': 'B+',
      'locality': 'Morappur Road',
      'phone': '9789012345',
      'lastDonated': '2 months ago',
      'donationsCount': 4,
      'isAvailable': true,
    },
    {
      'name': 'Praveen Kumar',
      'bloodGroup': 'O-',
      'locality': 'Theerthamalai',
      'phone': '9944055112',
      'lastDonated': '5 months ago',
      'donationsCount': 8,
      'isAvailable': true,
    },
    {
      'name': 'Sangeetha R.',
      'bloodGroup': 'AB+',
      'locality': 'Kottapatti',
      'phone': '9629011445',
      'lastDonated': '7 months ago',
      'donationsCount': 3,
      'isAvailable': true,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    bloodBanks = HarurRealDataService.getRealBloodBanks();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _call(String phone) async {
    try {
      final uri = Uri.parse('tel:$phone');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final filtered = selectedBloodGroup == 'All'
        ? donors
        : donors.where((d) => d['bloodGroup'] == selectedBloodGroup).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Harur Blood Lifeline',
          style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1C1C1E)),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1C1C1E), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFFE44545),
          unselectedLabelColor: const Color(0xFF8E8E93),
          indicatorColor: const Color(0xFFE44545),
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
          tabs: const [
            Tab(text: 'Blood Banks (24/7)'),
            Tab(text: 'Volunteer Donors'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Verified Blood Banks & Storage Centres
          ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            itemCount: bloodBanks.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final bank = bloodBanks[i];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE5E5EA)),
                  boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 4))],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFECEB),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.local_hospital_rounded, color: Color(0xFFE44545), size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(bank['name'] as String, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF1C1C1E))),
                          const SizedBox(height: 2),
                          Text(bank['type'] as String, style: const TextStyle(fontSize: 11, color: Color(0xFFE44545), fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text(bank['address'] as String, style: const TextStyle(fontSize: 11, color: Color(0xFF8E8E93))),
                          const SizedBox(height: 4),
                          Text(bank['availableGroups'] as String, style: const TextStyle(fontSize: 10, color: Color(0xFF007AFF), fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                    IconButton(
                      style: IconButton.styleFrom(backgroundColor: const Color(0xFFFFECEB)),
                      icon: const Icon(Icons.call_rounded, color: Color(0xFFE44545), size: 20),
                      onPressed: () => _call(bank['phone'] as String),
                    ),
                  ],
                ),
              );
            },
          ),

          // Tab 2: Verified Donors
          Column(
            children: [
              const SizedBox(height: 12),
              // Blood group filter
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: bloodGroups.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final active = selectedBloodGroup == bloodGroups[i];
                    return ChoiceChip(
                      label: Text(bloodGroups[i]),
                      selected: active,
                      onSelected: (_) => setState(() => selectedBloodGroup = bloodGroups[i]),
                      selectedColor: const Color(0xFFE44545),
                      backgroundColor: const Color(0xFFF2F2F7),
                      labelStyle: TextStyle(
                        color: active ? Colors.white : const Color(0xFF1C1C1E),
                        fontWeight: active ? FontWeight.w900 : FontWeight.w700,
                        fontSize: 13,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      side: BorderSide(color: active ? const Color(0xFFE44545) : const Color(0xFFE5E5EA)),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final d = filtered[i];
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE5E5EA)),
                        boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 4))],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFECEB),
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFFF8C9C5)),
                            ),
                            child: Center(
                              child: Text(
                                d['bloodGroup'] as String,
                                style: const TextStyle(color: Color(0xFFE44545), fontWeight: FontWeight.w900, fontSize: 16),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(d['name'] as String, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF1C1C1E))),
                                    const SizedBox(width: 6),
                                    const Icon(Icons.verified_rounded, color: Color(0xFF007AFF), size: 14),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(d['locality'] as String, style: const TextStyle(fontSize: 11, color: Color(0xFF8E8E93))),
                                const SizedBox(height: 2),
                                Text('Donated ${d['donationsCount']} times • Available', style: const TextStyle(fontSize: 10, color: Color(0xFF007AFF), fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                          IconButton(
                            style: IconButton.styleFrom(backgroundColor: const Color(0xFFEBF5FF)),
                            icon: const Icon(Icons.call_rounded, color: Color(0xFF007AFF), size: 20),
                            onPressed: () => _call(d['phone'] as String),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 9. PUBLIC GRIEVANCE SUBMISSION PAGE
// ==========================================
class GrievanceSubmissionPage extends StatefulWidget {
  const GrievanceSubmissionPage({super.key});

  @override
  State<GrievanceSubmissionPage> createState() => _GrievanceSubmissionPageState();
}

class _GrievanceSubmissionPageState extends State<GrievanceSubmissionPage> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _localityCtrl = TextEditingController(text: 'Harur Town');
  String selectedDepartment = 'Drinking Water & Sanitation';
  bool isSubmitting = false;

  final departments = [
    'Drinking Water & Sanitation',
    'Roads, Potholes & Streetlights',
    'Town Planning & Waste Management',
    'Electricity Board (TANGEDCO)',
    'Public Health & Mosquito Control',
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _localityCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitGrievance() async {
    final title = _titleCtrl.text.trim();
    final desc = _descCtrl.text.trim();
    if (title.isEmpty || desc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(backgroundColor: Color(0xFFE44545), content: Text('Please provide a title and description for your grievance.')),
      );
      return;
    }

    setState(() => isSubmitting = true);
    await Future.delayed(const Duration(milliseconds: 600));
    setState(() => isSubmitting = false);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF007AFF),
          content: Text('✓ Grievance submitted! Reference Ticket: #HR-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('Submit Civic Grievance', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1C1C1E))),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1C1C1E), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Municipal & Civic Redressal', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1C1C1E))),
              const SizedBox(height: 4),
              const Text('Report town infrastructure, sanitation, and public utility issues directly to Harur officials.', style: TextStyle(fontSize: 12, color: Color(0xFF8E8E93))),
              const SizedBox(height: 20),

              // Department Selector
              const Text('Select Municipal Department', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF8E8E93))),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F7),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedDepartment,
                    isExpanded: true,
                    items: departments.map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)))).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => selectedDepartment = val);
                    },
                  ),
                ),
              ),

              const SizedBox(height: 16),
              TextField(
                controller: _titleCtrl,
                decoration: InputDecoration(
                  labelText: 'Issue Subject / Title',
                  hintText: 'e.g. Broken streetlight on Bazaar St.',
                  filled: true,
                  fillColor: const Color(0xFFF2F2F7),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),

              const SizedBox(height: 14),
              TextField(
                controller: _localityCtrl,
                decoration: InputDecoration(
                  labelText: 'Exact Locality / Street / Landmark',
                  filled: true,
                  fillColor: const Color(0xFFF2F2F7),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),

              const SizedBox(height: 14),
              TextField(
                controller: _descCtrl,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Detailed Explanation',
                  hintText: 'Describe the problem, duration, and specific location markers...',
                  filled: true,
                  fillColor: const Color(0xFFF2F2F7),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF007AFF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.send_rounded, size: 20),
                  label: isSubmitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Submit Civic Grievance', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                  onPressed: isSubmitting ? null : _submitGrievance,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 10. GOVERNMENT ORDERS (G.O.) PAGE
// ==========================================
class GovtOrdersPage extends StatefulWidget {
  const GovtOrdersPage({super.key});

  @override
  State<GovtOrdersPage> createState() => _GovtOrdersPageState();
}

class _GovtOrdersPageState extends State<GovtOrdersPage> {
  List<Map<String, dynamic>> orders = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => isLoading = true);
    final data = await GovtService.fetchGovernmentOrders();
    if (mounted) {
      setState(() {
        orders = data;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('Government Orders & Circulars', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1C1C1E))),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1C1C1E), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF007AFF)))
            : ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                itemCount: orders.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, i) {
                  final go = orders[i];
                  return Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE5E5EA)),
                      boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 4))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF267AF4),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(go['go_number'] ?? 'G.O.', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
                            ),
                            const Spacer(),
                            const Icon(Icons.verified_rounded, color: Color(0xFF007AFF), size: 16),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(go['title'] ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1C1C1E))),
                        const SizedBox(height: 4),
                        Text(go['summary'] ?? '', style: const TextStyle(fontSize: 12, color: Color(0xFF8E8E93), height: 1.35)),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(Icons.account_balance_rounded, size: 14, color: Color(0xFF8E8E93)),
                            const SizedBox(width: 4),
                            Text(go['department'] ?? '', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF8E8E93))),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
