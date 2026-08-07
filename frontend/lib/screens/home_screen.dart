import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
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
  double? _currentLat;
  double? _currentLng;
  Timer? _weatherTimer;
  Timer? _newsTimer;

  @override
  void initState() {
    super.initState();
    _determinePosition();
    _fetchLatestNews();
    NotificationService().requestPermission();
    _weatherTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _fetchWeatherOnly();
    });
    _newsTimer = Timer.periodic(const Duration(hours: 2), (timer) {
      _fetchLatestNews();
    });
  }

  @override
  void dispose() {
    _weatherTimer?.cancel();
    _newsTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchWeatherOnly() async {
    try {
      String url = '/news/weather';
      if (_currentLat != null && _currentLng != null) {
        url += '?lat=$_currentLat&lng=$_currentLng';
      }
      final w = await ApiClient.dio.get(url);
      if (mounted) setState(() => _weatherData = w.data);
    } catch (_) {}
  }

  Future<void> _fetchLatestNews() async {
    try {
      final r = await ApiClient.dio.get('/news/');
      await _fetchWeatherOnly();
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
          _currentLat = loc['lat'] as double?;
          _currentLng = loc['lng'] as double?;
        });
        _fetchWeatherOnly();
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

    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    bool inBounds = position.latitude >= 11.75 && position.latitude <= 12.35 &&
                    position.longitude >= 77.45 && position.longitude <= 78.75;

    if (mounted) {
      setState(() {
        _isInsideDharmapuri = inBounds;
        _currentLat = position.latitude;
        _currentLng = position.longitude;
        _locationName = 'GPS: ${position.latitude.toStringAsFixed(4)}°N, ${position.longitude.toStringAsFixed(4)}°E';
      });
      _fetchWeatherOnly();
      
      // Perform exact place reverse geocoding
      try {
        final geoRes = await ApiClient.dio.get('https://nominatim.openstreetmap.org/reverse', queryParameters: {
          'format': 'json',
          'lat': position.latitude,
          'lon': position.longitude,
        });
        if (mounted && geoRes.data != null && geoRes.data['address'] != null) {
          final addr = geoRes.data['address'];
          final place = addr['suburb'] ?? addr['town'] ?? addr['village'] ?? addr['city'] ?? addr['county'] ?? addr['state_district'] ?? 'Harur Region';
          setState(() {
            _locationName = '$place (${position.latitude.toStringAsFixed(3)}°, ${position.longitude.toStringAsFixed(3)}°)';
          });
        }
      } catch (_) {}

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
    final ScrollController scrollCtrl = ScrollController();
    final List<Map<String, dynamic>> messages = [
      {
        'sender': 'ai',
        'text': 'Hello! I am your MyHarur AI Support. How can I help you today?',
        'time': DateTime.now()
      }
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
            void sendMessage(String text) async {
              if (text.isEmpty) return;
              ctrl.clear();
              setModalState(() {
                messages.add({'sender': 'me', 'text': text, 'time': DateTime.now()});
                isLoading = true;
              });
              
              Future.delayed(const Duration(milliseconds: 100), () {
                scrollCtrl.animateTo(scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
              });

              try {
                final r = await ApiClient.dio.post('/community/ai/ask', data: {'query': text});
                setModalState(() {
                  messages.add({'sender': 'ai', 'text': r.data['response'], 'time': DateTime.now()});
                  isLoading = false;
                });
              } catch (e) {
                setModalState(() {
                  messages.add({'sender': 'ai', 'text': 'Error connecting to AI.', 'time': DateTime.now()});
                  isLoading = false;
                });
              }
              
              Future.delayed(const Duration(milliseconds: 100), () {
                scrollCtrl.animateTo(scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
              });
            }

            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.smart_toy_rounded, color: AppTheme.accent),
                      const SizedBox(width: 8),
                      Text("AI Support", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollCtrl,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        final isMe = msg['sender'] == 'me';
                        final time = msg['time'] as DateTime;
                        final timeStr = '${time.hour > 12 ? time.hour - 12 : time.hour == 0 ? 12 : time.hour}:${time.minute.toString().padLeft(2, '0')} ${time.hour >= 12 ? 'PM' : 'AM'}';
                        
                        return Align(
                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                            child: Column(
                              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: isMe ? AppTheme.accent : Theme.of(context).colorScheme.surface,
                                    borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(20),
                                      topRight: const Radius.circular(20),
                                      bottomLeft: isMe ? const Radius.circular(20) : Radius.zero,
                                      bottomRight: isMe ? Radius.zero : const Radius.circular(20),
                                    ),
                                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 4))],
                                  ),
                                  child: Text(
                                    msg['text'],
                                    style: TextStyle(color: isMe ? Colors.white : Theme.of(context).colorScheme.onSurface, fontSize: 15, height: 1.4),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  timeStr,
                                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4), fontSize: 10, fontWeight: FontWeight.bold),
                                )
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  if (isLoading) 
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Row(
                          children: [
                            SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accent)),
                            const SizedBox(width: 8),
                            Text('AI is typing...', style: TextStyle(color: AppTheme.accent, fontSize: 12, fontStyle: FontStyle.italic)),
                          ],
                        ),
                      ),
                    ),
                  Container(
                    padding: EdgeInsets.only(left: 16, right: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 16, top: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      border: Border(top: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.5))),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: ctrl,
                            textInputAction: TextInputAction.send,
                            decoration: InputDecoration(
                              hintText: "Message AI...",
                              hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4)),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                              filled: true,
                              fillColor: Theme.of(context).colorScheme.surface,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            ),
                            onSubmitted: (text) => sendMessage(text.trim()),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: AppTheme.accent,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: AppTheme.accent.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                            onPressed: () => sendMessage(ctrl.text.trim()),
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

  String _getGreeting() {
    var hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning,';
    if (hour < 17) return 'Good Afternoon,';
    return 'Good Evening,';
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

  void _showLocationOptionsSheet() {
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
              Icon(Icons.my_location_rounded, size: 48, color: _isInsideDharmapuri ? AppTheme.success : AppTheme.danger),
              SizedBox(height: 12),
              Text(_isInsideDharmapuri ? 'Dharmapuri Service Region' : 'Outside Service Area', style: Theme.of(context).textTheme.headlineMedium),
              SizedBox(height: 8),
              Text('Detected Location: $_locationName', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              SizedBox(height: 20),
              ListTile(
                leading: Icon(Icons.map_rounded, color: AppTheme.appleBlue),
                title: Text('View Exact Location on Google Maps', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Open Google Maps navigation'),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Theme.of(context).dividerColor)),
                onTap: () async {
                  Navigator.pop(context);
                  if (_currentLat != null && _currentLng != null) {
                    final url = Uri.parse('https://maps.google.com/?q=$_currentLat,$_currentLng');
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url, mode: LaunchMode.externalApplication);
                    }
                  }
                },
              ),
              SizedBox(height: 12),
              ListTile(
                leading: Icon(Icons.edit_location_alt_rounded, color: AppTheme.accent),
                title: Text('Select Manual Location', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Choose Harur Town or Dharmapuri City'),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Theme.of(context).dividerColor)),
                onTap: () {
                  Navigator.pop(context);
                  _showManualLocationPicker();
                },
              ),
              SizedBox(height: 24),
            ],
          ),
        );
      },
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
              expandedHeight: 110.0,
              floating: true,
              pinned: true,
              backgroundColor: theme.scaffoldBackgroundColor,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: EdgeInsets.only(left: 24, bottom: 12),
                title: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_getGreeting(), style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6), fontSize: 13, fontWeight: FontWeight.w500, letterSpacing: -0.3)),
                    Text(displayName, style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                  ],
                ),
              ),
              actions: [
                Container(
                  margin: EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                  ),
                  child: IconButton(
                    icon: Icon(Icons.notifications_none_rounded, color: theme.colorScheme.onSurface, size: 24),
                    onPressed: () => _navigateTo(const NotificationsScreen()),
                  ),
                ),
                GestureDetector(
                  onTap: () => context.go('/profile'),
                  child: Container(
                    margin: EdgeInsets.only(right: 24),
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: AppTheme.appleBlue.withOpacity(0.1),
                      child: Icon(Icons.person, color: AppTheme.appleBlue, size: 22),
                    ),
                  ),
                ),
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
                      onTap: _showLocationOptionsSheet,
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

                  // ── Quick Access (Apple-style 2x3 Grid) ─────────────────────────
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Quick Access', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface, letterSpacing: -0.3)),
                        SizedBox(height: 12),
                        GridView.count(
                          crossAxisCount: 3,
                          childAspectRatio: 0.95,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          children: [
                            _buildServiceIcon(Icons.newspaper_rounded, 'News', AppTheme.appleBlue, () => _navigateTo(const NewsScreen())),
                            _buildServiceIcon(Icons.sos_rounded, 'Emergency', AppTheme.danger, () => context.go('/report')),
                            _buildServiceIcon(Icons.storefront_rounded, 'Shops', AppTheme.success, () => _navigateTo(const ShopsScreen())),
                            _buildServiceIcon(Icons.shopping_bag_rounded, 'Market', AppTheme.appleBlue, () => context.go('/market')),
                            _buildServiceIcon(Icons.forum_rounded, 'Community', Color(0xFFFF9500), () => context.go('/community')),
                            _buildServiceIcon(Icons.emoji_events_rounded, 'Rankings', Color(0xFFAF52DE), () => _navigateTo(const LeaderboardScreen())),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),

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
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 110),
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
