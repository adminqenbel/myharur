import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import '../providers/locale_provider.dart';
import '../providers/auth_provider.dart';
import '../l10n/translations.dart';
import '../api_client.dart';
import '../utils/location_prefs.dart';
import 'news_screen.dart';
import 'emergency_screen.dart';
import 'shops_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isInsideDharmapuri = true;
  String _locationName = 'Fetching GPS...';
  List<dynamic> _latestNews = [];
  bool _newsLoading = true;

  @override
  void initState() {
    super.initState();
    _determinePosition();
    _fetchLatestNews();
  }

  Future<void> _fetchLatestNews() async {
    try {
      final r = await ApiClient.dio.get('/news/');
      if (mounted) {
        setState(() {
          _latestNews = (r.data as List).take(5).toList();
          _newsLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _newsLoading = false);
    }
  }

  Future<void> _determinePosition() async {
    final hasManual = await LocationPrefs.hasManualLocation();
    if (hasManual) {
      final loc = await LocationPrefs.getManualLocation();
      if (mounted && loc != null) {
        setState(() {
          _isInsideDharmapuri = true;
          _locationName = loc['name'] as String;
        });
      }
      return;
    }

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) setState(() => _locationName = 'Location Disabled');
      _checkWarning();
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) setState(() => _locationName = 'Permission Denied');
        _checkWarning();
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) setState(() => _locationName = 'Permission Denied');
      _checkWarning();
      return;
    }

    Position position = await Geolocator.getCurrentPosition();
    bool inBounds = position.latitude >= 11.75 && position.latitude <= 12.35 &&
                    position.longitude >= 77.45 && position.longitude <= 78.75;

    if (mounted) {
      setState(() {
        _isInsideDharmapuri = inBounds;
        _locationName = inBounds ? 'Dharmapuri Region' : 'Outside Service Area';
      });
      if (!inBounds) {
        _checkWarning();
      }
    }
  }

  Future<void> _checkWarning() async {
    final shown = await LocationPrefs.wasWarningShown();
    if (!shown && mounted) {
      await LocationPrefs.markWarningShown();
      _showLocationWarningSheet();
    }
  }

  void _showLocationWarningSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_off, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(l(ref, 'Outside Service Area'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('You seem to be outside the Dharmapuri/Harur region. You can continue as a guest or set a manual location to access local services.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 14)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.map, color: Colors.white),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    _showManualLocationPicker();
                  },
                  label: const Text('Pick Manual Location', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Continue Anyway', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              )
            ],
          ),
        );
      }
    );
  }

  void _showManualLocationPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Select Region', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.location_city, color: Colors.blue),
                title: const Text('Harur Town'),
                subtitle: const Text('Dharmapuri District'),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)),
                onTap: () async {
                  await LocationPrefs.saveManualLocation(12.0620, 78.4975, 'Harur Town');
                  if (context.mounted) Navigator.pop(context);
                  _determinePosition();
                },
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.location_city, color: Colors.green),
                title: const Text('Dharmapuri City'),
                subtitle: const Text('Dharmapuri District'),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)),
                onTap: () async {
                  await LocationPrefs.saveManualLocation(12.1211, 78.1582, 'Dharmapuri City');
                  if (context.mounted) Navigator.pop(context);
                  _determinePosition();
                },
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () async {
                  await LocationPrefs.clearManualLocation();
                  if (context.mounted) Navigator.pop(context);
                  _determinePosition();
                },
                child: const Text('Clear Manual Location'),
              )
            ],
          ),
        );
      }
    );
  }

  void _navigateTo(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  Widget _buildQuickAction(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.8), color],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4)),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
            const SizedBox(height: 8),
            Text(l(ref, label), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceIcon(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(l(ref, label), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        toolbarHeight: 70,
        backgroundColor: Colors.white,
        elevation: 1,
        title: InkWell(
          onTap: _showManualLocationPicker,
          child: Row(
            children: [
              Icon(Icons.location_on, color: _isInsideDharmapuri ? Colors.green : Colors.red, size: 28),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      l(ref, _isInsideDharmapuri ? 'Dharmapuri Region' : 'Outside Service Area'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                    ),
                    Row(
                      children: [
                        Text(
                          _locationName,
                          style: const TextStyle(color: Colors.black54, fontSize: 12),
                        ),
                        const Icon(Icons.arrow_drop_down, color: Colors.black54, size: 16),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          // Tamil/English Toggle
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(ref.watch(isEnglishProvider) ? 'அ' : 'A', style: const TextStyle(fontWeight: FontWeight.bold)),
              selected: true,
              selectedColor: Colors.blue.shade50,
              onSelected: (_) {
                ref.read(isEnglishProvider.notifier).state = !ref.read(isEnglishProvider.notifier).state;
              },
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _fetchLatestNews();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Quick Access Bar ──────────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                color: Colors.white,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _buildQuickAction(Icons.newspaper, 'News', Colors.deepOrange, () => _navigateTo(const NewsScreen())),
                      _buildQuickAction(Icons.chat_bubble, 'Chats', Colors.blue, () => context.go('/community')),
                      _buildQuickAction(Icons.emergency, 'SOS', Colors.red, () => _navigateTo(const EmergencyScreen())),
                      _buildQuickAction(Icons.storefront, 'Shops', Colors.teal, () => _navigateTo(const ShopsScreen())),
                      _buildQuickAction(Icons.how_to_vote, 'Polls', Colors.purple, () => context.go('/community')),
                      _buildQuickAction(Icons.local_mall, 'Market', Colors.green, () => context.go('/market')),
                    ],
                  ),
                ),
              ),

              // ── Top Banner ────────────────────────────────────────────────
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(colors: [Colors.blue, Colors.indigo]),
                ),
                child: const Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Rain Alert', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                          SizedBox(height: 4),
                          Text('Heavy rain expected in Harur at 5 PM', style: TextStyle(color: Colors.white70, fontSize: 14)),
                        ],
                      ),
                    ),
                    Icon(Icons.cloudy_snowing, color: Colors.white, size: 48),
                  ],
                ),
              ),
              
              // ── Services Grid ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: GridView.count(
                  crossAxisCount: 4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 8,
                  children: [
                    _buildServiceIcon(Icons.local_offer, 'Daily Deals', Colors.orange, () => context.go('/market')),
                    _buildServiceIcon(Icons.work, 'Jobs Nearby', Colors.blue, () => context.go('/market')),
                    _buildServiceIcon(Icons.handshake, 'Buy/Sell', Colors.green, () => context.go('/market')),
                    _buildServiceIcon(Icons.festival, 'Events', Colors.purple, () => context.go('/community')),
                    _buildServiceIcon(Icons.how_to_vote, 'Polls', Colors.teal, () => context.go('/community')),
                    _buildServiceIcon(Icons.handyman, 'Services', Colors.brown, () => _navigateTo(const ShopsScreen())),
                    _buildServiceIcon(Icons.emoji_events, 'Leaderboard', Colors.amber, () {}),
                    _buildServiceIcon(Icons.map, 'Town Map', Colors.indigo, () {}),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // ── Latest News Section ───────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l(ref, 'Latest News'),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    TextButton.icon(
                      onPressed: () => _navigateTo(const NewsScreen()),
                      icon: const Icon(Icons.arrow_forward, size: 16),
                      label: Text(l(ref, 'View All')),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              if (_newsLoading)
                const Center(child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ))
              else if (_latestNews.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(Icons.article, size: 48, color: Colors.grey.shade300),
                        const SizedBox(height: 8),
                        const Text('No news available', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _latestNews.length,
                  itemBuilder: (context, index) {
                    final news = _latestNews[index];
                    return _buildNewsCard(news);
                  },
                ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNewsCard(Map<String, dynamic> news) {
    final hasImage = news['image_url'] != null && (news['image_url'] as String).isNotEmpty;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // If it's an RSS link, could open externally; for now navigate to NewsScreen
          _navigateTo(const NewsScreen());
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasImage)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.network(
                  news['image_url'],
                  width: double.infinity,
                  height: 160,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox(),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    news['title'] ?? 'News Update',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    news['content'] ?? '',
                    style: const TextStyle(color: Colors.black54, fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        news['source'] ?? 'Local News',
                        style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.w600, fontSize: 12),
                      ),
                      Text(
                        news['created_at'] != null ? news['created_at'].toString().substring(0, 10) : '',
                        style: const TextStyle(color: Colors.grey, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
