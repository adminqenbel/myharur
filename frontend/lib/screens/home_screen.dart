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
import 'leaderboard_screen.dart';
import '../widgets/design_system.dart';
import '../theme.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static bool _hasAskedLocation = false;
  bool _isInsideDharmapuri = true;
  String _locationName = 'Fetching GPS...';
  List<dynamic> _latestNews = [];
  bool _newsLoading = true;
  Map<String, dynamic>? _weatherData;

  @override
  void initState() {
    super.initState();
    _determinePosition();
    _fetchLatestNews();
  }

  Future<void> _fetchLatestNews() async {
    try {
      final r = await ApiClient.dio.get('/news/');
      final w = await ApiClient.dio.get('/news/weather');
      if (mounted) {
        setState(() {
          _latestNews = (r.data as List).take(5).toList();
          _weatherData = w.data;
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
    if (!_hasAskedLocation && mounted) {
      _hasAskedLocation = true;
      _showLocationWarningSheet();
    }
  }

  void _showLocationWarningSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return MHBottomSheet(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_off_rounded, size: 56, color: AppTheme.danger),
              const SizedBox(height: 16),
              Text(l(ref, 'Outside Service Area'), style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text('You seem to be outside the Dharmapuri/Harur region. You can continue as a guest or set a manual location to access local services.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 24),
              MHButton(
                text: 'Pick Manual Location',
                icon: Icons.map_rounded,
                onPressed: () {
                  Navigator.pop(context);
                  _showManualLocationPicker();
                },
              ),
              const SizedBox(height: 16),
              MHOutlinedButton(
                text: 'Continue Anyway',
                onPressed: () => Navigator.pop(context),
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
      backgroundColor: Colors.transparent,
      builder: (context) {
        return MHBottomSheet(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Select Region', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(Icons.location_city_rounded, color: AppTheme.info),
                title: const Text('Harur Town', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Dharmapuri District'),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppTheme.divider)),
                onTap: () async {
                  await LocationPrefs.saveManualLocation(12.0620, 78.4975, 'Harur Town');
                  if (context.mounted) Navigator.pop(context);
                  _determinePosition();
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.location_city_rounded, color: AppTheme.success),
                title: const Text('Dharmapuri City', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Dharmapuri District'),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppTheme.divider)),
                onTap: () async {
                  await LocationPrefs.saveManualLocation(12.1211, 78.1582, 'Dharmapuri City');
                  if (context.mounted) Navigator.pop(context);
                  _determinePosition();
                },
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () async {
                  await LocationPrefs.clearManualLocation();
                  if (context.mounted) Navigator.pop(context);
                  _determinePosition();
                },
                child: const Text('Clear Manual Location', style: TextStyle(color: AppTheme.danger, fontWeight: FontWeight.w600)),
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
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withOpacity(0.2), width: 1.5),
                boxShadow: [
                  BoxShadow(color: color.withOpacity(0.15), blurRadius: 15, offset: const Offset(0, 8)),
                ],
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 10),
            Text(l(ref, label), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceIcon(IconData icon, String label, Color color, VoidCallback onTap) {
    return MHCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(l(ref, label), style: Theme.of(context).textTheme.labelLarge, textAlign: TextAlign.center),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final displayName = auth.user?['display_name'] ?? auth.user?['username'] ?? 'Citizen';
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: () async {
          await _fetchLatestNews();
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ── Custom Header (SliverAppBar) ───────────────────────────────
            SliverAppBar(
              expandedHeight: 70.0,
              floating: true,
              pinned: true,
              backgroundColor: theme.appBarTheme.backgroundColor,
              elevation: 0,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
                title: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Hello,", style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.w500)),
                    Text(displayName, style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.w800)),
                  ],
                ),
                background: Container(
                  decoration: BoxDecoration(
                    color: theme.appBarTheme.backgroundColor,
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 28),
                  onPressed: () {},
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => context.go('/profile'),
                  child: const CircleAvatar(
                    radius: 18,
                    backgroundColor: Color(0xFF16324F),
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 24),
              ],
            ),
            
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  
                  // ── Location Badge ──────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: MHCard(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      onTap: _showManualLocationPicker,
                      child: Row(
                        children: [
                          Icon(Icons.location_on_rounded, color: _isInsideDharmapuri ? AppTheme.success : AppTheme.danger, size: 28),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l(ref, _isInsideDharmapuri ? 'Dharmapuri Region' : 'Outside Service Area'),
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  _locationName,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // ── Weather Widget ──────────────────────────────────────────
                  if (_weatherData != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF3A86FF), Color(0xFF00B4D8)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(color: const Color(0xFF3A86FF).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _weatherData!['condition'] ?? 'Clear',
                                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.water_drop_rounded, color: Colors.white70, size: 14),
                                    const SizedBox(width: 4),
                                    Text('Humidity: ${_weatherData!['humidity']}%', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                                  ],
                                ),
                              ],
                            ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${_weatherData!['temperature']}',
                                  style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.w800, height: 1),
                                ),
                                const Text('°C', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),

                  // ── Quick Access Bar ──────────────────────────────────────────
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        _buildQuickAction(Icons.newspaper_rounded, 'News', AppTheme.info, () => _navigateTo(const NewsScreen())),
                        _buildQuickAction(Icons.sos_rounded, 'Emergency', AppTheme.danger, () => _navigateTo(const EmergencyScreen())),
                        _buildQuickAction(Icons.storefront_rounded, 'Shops', AppTheme.success, () => _navigateTo(const ShopsScreen())),
                        _buildQuickAction(Icons.shopping_bag_rounded, 'Market', AppTheme.accent, () => context.go('/market')),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Top Banner (Emergency) ────────────────────────────────────
                  if (_latestNews.any((n) => n['is_breaking'] == true))
                    ..._latestNews.where((n) => n['is_breaking'] == true).map((news) => 
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: const LinearGradient(colors: [Color(0xFFEF233C), Color(0xFFD90429)]),
                          boxShadow: [BoxShadow(color: const Color(0xFFEF233C).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(news['title'] ?? 'Breaking Alert', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
                                  const SizedBox(height: 6),
                                  Text(news['description'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                                ],
                              ),
                            ),
                            const Icon(Icons.warning_rounded, color: Colors.white, size: 42),
                          ],
                        ),
                      )
                    ).toList(),
                  
                  // ── Services Grid ─────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Discover', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF081C2D))),
                        const SizedBox(height: 16),
                        GridView.count(
                          crossAxisCount: 3,
                          childAspectRatio: 0.9,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          children: [
                            _buildServiceIcon(Icons.work_rounded, 'Jobs', const Color(0xFF3A86FF), () => context.go('/market')),
                            _buildServiceIcon(Icons.festival_rounded, 'Events', const Color(0xFF8338EC), () => context.go('/community')),
                            _buildServiceIcon(Icons.handyman_rounded, 'Services', const Color(0xFFFB5607), () => _navigateTo(const ShopsScreen())),
                            _buildServiceIcon(Icons.emoji_events_rounded, 'Rankings', const Color(0xFFFFBE0B), () => _navigateTo(const LeaderboardScreen())),
                            _buildServiceIcon(Icons.map_rounded, 'Map', const Color(0xFF06D6A0), () {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Town Map coming soon!')));
                            }),
                            _buildServiceIcon(Icons.forum_rounded, 'Community', const Color(0xFF3A86FF), () => context.go('/community')),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // ── Latest News Section ───────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l(ref, 'Trending News'),
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF081C2D)),
                        ),
                        TextButton(
                          onPressed: () => _navigateTo(const NewsScreen()),
                          child: Text(l(ref, 'View All'), style: const TextStyle(color: Color(0xFF3A86FF), fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  if (_newsLoading)
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: 3,
                      itemBuilder: (context, index) => const Padding(
                        padding: EdgeInsets.only(bottom: 16, left: 24, right: 24),
                        child: MHSkeletonLoader(width: double.infinity, height: 280, borderRadius: 16),
                      ),
                    )
                  else if (_latestNews.isEmpty)
                    const MHEmptyState(
                      icon: Icons.article_rounded, 
                      title: 'No News Available', 
                      description: 'Check back later for local updates.',
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _latestNews.length,
                      itemBuilder: (context, index) => MHNewsCard(
                        news: _latestNews[index],
                        onTap: () => _navigateTo(const NewsScreen()),
                      ),
                    ),
                  const SizedBox(height: 100), // padding for bottom nav
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
