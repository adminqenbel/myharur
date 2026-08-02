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
import 'notifications_screen.dart';
import '../services/notification_service.dart';

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
    NotificationService().requestPermission();
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
      useRootNavigator: true,
      builder: (context) {
        return MHBottomSheet(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_off_rounded, size: 56, color: AppTheme.danger),
              SizedBox(height: 16),
              Text(l(ref, 'Outside Service Area'), style: Theme.of(context).textTheme.headlineMedium),
              SizedBox(height: 8),
              Text('You seem to be outside the Dharmapuri/Harur region. You can continue as a guest or set a manual location to access local services.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
              SizedBox(height: 24),
              MHButton(
                text: 'Pick Manual Location',
                icon: Icons.map_rounded,
                onPressed: () {
                  Navigator.pop(context);
                  _showManualLocationPicker();
                },
              ),
              SizedBox(height: 16),
              MHOutlinedButton(
                text: 'Continue Anyway',
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(height: 100),
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
      useRootNavigator: true,
      builder: (context) {
        return MHBottomSheet(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Select Region', style: Theme.of(context).textTheme.headlineMedium),
              SizedBox(height: 24),
              ListTile(
                leading: Icon(Icons.location_city_rounded, color: AppTheme.info),
                title: Text('Harur Town', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('Dharmapuri District'),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Theme.of(context).dividerColor)),
                onTap: () async {
                  await LocationPrefs.saveManualLocation(12.0620, 78.4975, 'Harur Town');
                  if (context.mounted) Navigator.pop(context);
                  _determinePosition();
                },
              ),
              SizedBox(height: 16),
              ListTile(
                leading: Icon(Icons.location_city_rounded, color: AppTheme.success),
                title: Text('Dharmapuri City', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('Dharmapuri District'),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Theme.of(context).dividerColor)),
                onTap: () async {
                  await LocationPrefs.saveManualLocation(12.1211, 78.1582, 'Dharmapuri City');
                  if (context.mounted) Navigator.pop(context);
                  _determinePosition();
                },
              ),
              SizedBox(height: 24),
              TextButton(
                onPressed: () async {
                  await LocationPrefs.clearManualLocation();
                  if (context.mounted) Navigator.pop(context);
                  _determinePosition();
                },
                child: Text('Clear Manual Location', style: TextStyle(color: AppTheme.danger, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 100),
            ],
          ),
        );
      }
    );
  }

  void _showAIChatSheet() {
    final TextEditingController ctrl = TextEditingController();
    final List<Map<String, dynamic>> messages = [
      {'sender': 'ai', 'text': 'Hello! I am your MyHarur AI Support. How can I help you today?'}
    ];
    bool isLoading = false;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 16),
                    width: 40, height: 4,
                    decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(10)),
                  ),
                  Text("AI Support", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        final isMe = msg['sender'] == 'me';
                        return Align(
                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: isMe ? AppTheme.info : Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(16),
                                topRight: const Radius.circular(16),
                                bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
                                bottomRight: isMe ? Radius.zero : const Radius.circular(16),
                              ),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))],
                            ),
                            child: Text(
                              msg['text'],
                              style: TextStyle(color: isMe ? Colors.white : Theme.of(context).colorScheme.onSurface, fontSize: 14),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  if (isLoading) const Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()),
                  Container(
                    padding: EdgeInsets.only(left: 16, right: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 110, top: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: ctrl,
                            decoration: InputDecoration(
                              hintText: "Type your message...",
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                              filled: true,
                              fillColor: Theme.of(context).scaffoldBackgroundColor,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            ),
                            onSubmitted: (text) async {
                              final trimText = text.trim();
                              if (trimText.isEmpty) return;
                              ctrl.clear();
                              setModalState(() {
                                messages.add({'sender': 'me', 'text': trimText});
                                isLoading = true;
                              });
                              try {
                                final r = await ApiClient.dio.post('/community/ai/ask', data: {'query': trimText});
                                setModalState(() {
                                  messages.add({'sender': 'ai', 'text': r.data['response']});
                                  isLoading = false;
                                });
                              } catch (e) {
                                setModalState(() {
                                  messages.add({'sender': 'ai', 'text': 'Error connecting to AI.'});
                                  isLoading = false;
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        CircleAvatar(
                          backgroundColor: AppTheme.info,
                          child: IconButton(
                            icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                            onPressed: () async {
                              final text = ctrl.text.trim();
                              if (text.isEmpty) return;
                              ctrl.clear();
                              setModalState(() {
                                messages.add({'sender': 'me', 'text': text});
                                isLoading = true;
                              });
                              try {
                                final r = await ApiClient.dio.post('/community/ai/ask', data: {'query': text});
                                setModalState(() {
                                  messages.add({'sender': 'ai', 'text': r.data['response']});
                                  isLoading = false;
                                });
                              } catch (e) {
                                setModalState(() {
                                  messages.add({'sender': 'ai', 'text': 'Error connecting to AI.'});
                                  isLoading = false;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
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
        margin: EdgeInsets.only(right: 12),
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
            SizedBox(height: 10),
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
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          SizedBox(height: 8),
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
              expandedHeight: 120.0,
              floating: true,
              pinned: true,
              backgroundColor: theme.appBarTheme.backgroundColor,
              elevation: 0,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: EdgeInsets.only(left: 24, bottom: 16),
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
                  icon: Icon(Icons.notifications_none_rounded, color: theme.colorScheme.onSurface, size: 28),
                  onPressed: () {
                    _navigateTo(const NotificationsScreen());
                  },
                ),
                SizedBox(width: 8),
                GestureDetector(
                  onTap: () => context.go('/profile'),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: Color(0xFF16324F),
                    child: Icon(Icons.person, color: Theme.of(context).colorScheme.surface),
                  ),
                ),
                SizedBox(width: 24),
              ],
            ),
            
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 24),
                  
                  // ── Location Badge ──────────────────────────────────────────
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: MHCard(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      onTap: _showManualLocationPicker,
                      child: Row(
                        children: [
                          Icon(Icons.location_on_rounded, color: _isInsideDharmapuri ? AppTheme.success : AppTheme.danger, size: 28),
                          SizedBox(width: 16),
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
                          Icon(Icons.chevron_right_rounded, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  
                  // ── Weather Widget ──────────────────────────────────────────
                  if (_weatherData != null)
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [AppTheme.info, Color(0xFF00B4D8)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(color: AppTheme.info.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))
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
                                  style: TextStyle(color: Theme.of(context).colorScheme.surface, fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.water_drop_rounded, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), size: 14),
                                    SizedBox(width: 4),
                                    Text('Humidity: ${_weatherData!['humidity']}%', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), fontSize: 13)),
                                  ],
                                ),
                              ],
                            ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${_weatherData!['temperature']}',
                                  style: TextStyle(color: Theme.of(context).colorScheme.surface, fontSize: 42, fontWeight: FontWeight.w800, height: 1),
                                ),
                                Text('°C', style: TextStyle(color: Theme.of(context).colorScheme.surface, fontSize: 18, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  SizedBox(height: 24),

                  // ── Quick Access Bar ──────────────────────────────────────────
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        _buildQuickAction(Icons.newspaper_rounded, 'News', AppTheme.appleBlue, () => _navigateTo(const NewsScreen())),
                        _buildQuickAction(Icons.sos_rounded, 'Emergency', AppTheme.danger, () => _navigateTo(const EmergencyScreen())),
                        _buildQuickAction(Icons.storefront_rounded, 'Shops', AppTheme.appleBlue, () => _navigateTo(const ShopsScreen())),
                        _buildQuickAction(Icons.shopping_bag_rounded, 'Market', AppTheme.appleBlue, () => context.go('/market')),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),

                  // ── Top Banner (Emergency) ────────────────────────────────────
                  if (_latestNews.any((n) => n['is_breaking'] == true))
                    ..._latestNews.where((n) => n['is_breaking'] == true).map((news) => 
                      Container(
                        margin: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        padding: EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(colors: [AppTheme.danger, Color(0xFFD90429)]),
                          boxShadow: [BoxShadow(color: AppTheme.danger.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(news['title'] ?? 'Breaking Alert', style: TextStyle(color: Theme.of(context).colorScheme.surface, fontWeight: FontWeight.w800, fontSize: 18)),
                                  SizedBox(height: 6),
                                  Text(news['description'] ?? '', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), fontSize: 14)),
                                ],
                              ),
                            ),
                            Icon(Icons.warning_rounded, color: Theme.of(context).colorScheme.surface, size: 42),
                          ],
                        ),
                      )
                    ).toList(),
                  
                  // ── Services Grid ─────────────────────────────────────────────
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Discover', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface)),
                        SizedBox(height: 16),
                        GridView.count(
                          crossAxisCount: 3,
                          childAspectRatio: 0.9,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          children: [
                            _buildServiceIcon(Icons.work_rounded, 'Jobs', AppTheme.appleBlue, () => context.go('/market')),
                            _buildServiceIcon(Icons.festival_rounded, 'Events', AppTheme.appleBlue, () => context.go('/community')),
                            _buildServiceIcon(Icons.handyman_rounded, 'Services', AppTheme.appleBlue, () => _navigateTo(const ShopsScreen())),
                            _buildServiceIcon(Icons.emoji_events_rounded, 'Rankings', AppTheme.appleBlue, () => _navigateTo(const LeaderboardScreen())),
                            _buildServiceIcon(Icons.map_rounded, 'Map', AppTheme.appleBlue, () {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Town Map coming soon!')));
                            }),
                            _buildServiceIcon(Icons.forum_rounded, 'Community', AppTheme.appleBlue, () => context.go('/community')),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 32),
                  
                  // ── Latest News Section ───────────────────────────────────────
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l(ref, 'Trending News'),
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface),
                        ),
                        TextButton(
                          onPressed: () => _navigateTo(const NewsScreen()),
                          child: Text(l(ref, 'View All'), style: TextStyle(color: AppTheme.info, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 8),

                  if (_newsLoading)
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: 3,
                      itemBuilder: (context, index) => Padding(
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
                  SizedBox(height: 160), // padding for bottom nav and FAB
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 100),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: FloatingActionButton.extended(
              onPressed: _showAIChatSheet,
              backgroundColor: AppTheme.appleBlue.withOpacity(0.85),
              elevation: 0,
              highlightElevation: 0,
              icon: const Icon(Icons.support_agent_rounded, color: Colors.white),
              label: const Text("Ask AI", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ),
    );
  }
}
