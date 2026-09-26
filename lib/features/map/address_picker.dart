import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/l10n/locale_controller.dart';
import '../../core/models/place.dart';
import '../../core/theme/app_theme.dart';
import '../../core/util/safe_launch.dart';
import '../../core/widgets/ui.dart';
import 'location_services.dart';

// ==============================================================================
// LOCATION PICKER — one screen used for the optional profile address and for the location of
// reports (and later events and jobs). Everything is optional:
//   • drag the OpenStreetMap map under the fixed pin (opens on Harur), or
//   • search a place, or
//   • tap "use my current location", or
//   • just type the address (no pin).
// Returns the chosen [PickedLocation]; an EMPTY location means "remove it"; null = cancelled.
// ==============================================================================

Future<PickedLocation?> pickLocation(BuildContext context, {PickedLocation? initial, String? title}) {
  return Navigator.of(context).push<PickedLocation>(
    MaterialPageRoute(fullscreenDialog: true, builder: (_) => LocationPickerPage(initial: initial, title: title)),
  );
}

const _tileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
const _userAgentPackage = 'com.myharur.app';

class LocationPickerPage extends StatefulWidget {
  final PickedLocation? initial;
  final String? title;
  const LocationPickerPage({super.key, this.initial, this.title});

  @override
  State<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  final _map = MapController();
  final _search = TextEditingController();
  final _address = TextEditingController();
  Timer? _debounce;

  late LatLng _center;
  String _source = 'map';
  List<GeocodeResult> _results = const [];
  bool _searching = false;
  bool _locating = false;
  bool _saving = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    _center = i != null && i.hasCoordinates ? LatLng(i.lat!, i.lng!) : const LatLng(kHarurLat, kHarurLng);
    _address.text = i?.text ?? '';
    _source = i?.source ?? 'map';
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _address.dispose();
    _map.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    if (value.trim().length < 3) {
      setState(() {
        _results = const [];
        _message = null;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 800), _runSearch);
  }

  Future<void> _runSearch() async {
    setState(() {
      _searching = true;
      _message = null;
    });
    final r = await GeocodingService.search(_search.text);
    if (!mounted) return;
    setState(() {
      _searching = false;
      if (r == null) {
        _message = context.t.searchFailed;
        _results = const [];
      } else {
        _results = r;
        if (r.isEmpty) _message = context.t.noPlacesFound;
      }
    });
  }

  void _choose(GeocodeResult r) {
    FocusScope.of(context).unfocus();
    _map.move(LatLng(r.lat, r.lng), 17);
    setState(() {
      _center = LatLng(r.lat, r.lng);
      _address.text = r.label;
      _source = 'map';
      _results = const [];
      _message = null;
      _search.clear();
    });
  }

  Future<void> _useCurrentLocation() async {
    final t = context.t;
    setState(() {
      _locating = true;
      _message = null;
    });
    final res = await DeviceLocation.current();
    if (!mounted) return;
    if (res.position != null) {
      _map.move(res.position!, 17);
      final name = await GeocodingService.reverse(res.position!.latitude, res.position!.longitude);
      if (!mounted) return;
      setState(() {
        _locating = false;
        _center = res.position!;
        _source = 'gps';
        if (name != null && _address.text.trim().isEmpty) _address.text = name;
      });
    } else {
      setState(() {
        _locating = false;
        _message = switch (res.problem!) {
          LocationProblem.serviceDisabled => t.locationOff,
          LocationProblem.denied => t.locationDenied,
          LocationProblem.deniedForever => t.locationDeniedForever,
          LocationProblem.timeout => t.locationTimeout,
          LocationProblem.failed => t.locationTimeout,
        };
      });
    }
  }

  Future<void> _confirmPin() async {
    setState(() => _saving = true);
    var text = _address.text.trim();
    if (text.isEmpty) text = await GeocodingService.reverse(_center.latitude, _center.longitude) ?? '';
    if (!mounted) return;
    Navigator.of(context).pop(PickedLocation(
      lat: double.parse(_center.latitude.toStringAsFixed(6)),
      lng: double.parse(_center.longitude.toStringAsFixed(6)),
      text: text,
      source: _source == 'gps' ? 'gps' : 'map',
    ));
  }

  void _confirmTextOnly() => Navigator.of(context).pop(PickedLocation(text: _address.text.trim(), source: 'typed'));

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final hasText = _address.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── map ────────────────────────────────────────────────────────────
          Positioned.fill(
            child: FlutterMap(
              mapController: _map,
              options: MapOptions(
                initialCenter: _center,
                initialZoom: widget.initial?.hasCoordinates == true ? 17 : 14,
                minZoom: 4,
                maxZoom: 19,
                interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
                onPositionChanged: (camera, hasGesture) {
                  if (hasGesture) {
                    _center = camera.center;
                    _source = 'map';
                  }
                },
              ),
              children: [
                TileLayer(urlTemplate: _tileUrl, userAgentPackageName: _userAgentPackage, maxNativeZoom: 19),
                RichAttributionWidget(
                  alignment: AttributionAlignment.bottomLeft,
                  attributions: [
                    TextSourceAttribution(t.mapCredit, onTap: () => safeLaunch('https://www.openstreetmap.org/copyright')),
                  ],
                ),
              ],
            ),
          ),

          // ── fixed centre pin ───────────────────────────────────────────────
          IgnorePointer(
            child: Center(
              child: Transform.translate(
                offset: const Offset(0, -22),
                child: const Icon(Icons.location_on_rounded, size: 46, color: AppColors.danger, shadows: [Shadow(color: Color(0x55000000), blurRadius: 8)]),
              ),
            ),
          ),

          // ── top bar: close + search ────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppCard(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    radius: 18,
                    child: Row(
                      children: [
                        IconButton(icon: const Icon(Icons.close_rounded), tooltip: t.cancel, onPressed: () => Navigator.of(context).pop()),
                        Expanded(
                          child: TextField(
                            controller: _search,
                            onChanged: _onSearchChanged,
                            textInputAction: TextInputAction.search,
                            onSubmitted: (_) => _runSearch(),
                            decoration: InputDecoration(
                              hintText: widget.title ?? t.searchPlace,
                              filled: false,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        if (_searching)
                          const Padding(padding: EdgeInsets.only(right: 12), child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)))
                        else
                          IconButton(icon: const Icon(Icons.search_rounded), onPressed: _runSearch),
                      ],
                    ),
                  ),
                  if (_results.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: AppCard(
                        padding: EdgeInsets.zero,
                        radius: 18,
                        child: Column(
                          children: [
                            for (final r in _results)
                              InkWell(
                                onTap: () => _choose(r),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  child: Row(children: [
                                    const Icon(Icons.place_outlined, size: 20, color: AppColors.tertiaryLabel),
                                    const SizedBox(width: 10),
                                    Expanded(child: Text(r.label, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTextStyles.subheadline)),
                                  ]),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  if (_message != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Banner2(icon: Icons.info_outline_rounded, text: _message!, color: AppColors.warning),
                    ),
                ],
              ),
            ),
          ),

          // ── "my location" button ───────────────────────────────────────────
          Positioned(
            right: 14,
            bottom: 250,
            child: Pressable(
              onTap: _locating ? null : _useCurrentLocation,
              haptic: true,
              child: Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Color(0x33000000), blurRadius: 10, offset: Offset(0, 3))]),
                child: _locating
                    ? const Padding(padding: EdgeInsets.all(15), child: CircularProgressIndicator(strokeWidth: 2.4))
                    : const Icon(Icons.my_location_rounded, color: AppColors.primary),
              ),
            ),
          ),

          // ── bottom sheet: address text + confirm ───────────────────────────
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(12, 0, 12, 10 + MediaQuery.viewInsetsOf(context).bottom),
                child: AppCard(
                  radius: 26,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _address,
                        onChanged: (_) => setState(() {}),
                        textCapitalization: TextCapitalization.sentences,
                        maxLength: 200,
                        decoration: InputDecoration(labelText: t.addressDetails, hintText: t.addressHint, counterText: ''),
                      ),
                      const SizedBox(height: 12),
                      PrimaryButton(label: t.useThisLocation, loading: _saving, icon: Icons.push_pin_rounded, onPressed: _confirmPin),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(child: TextButton(onPressed: hasText ? _confirmTextOnly : null, child: Text(t.saveTextOnly, textAlign: TextAlign.center))),
                          if (widget.initial != null && !widget.initial!.isEmpty)
                            Expanded(
                              child: TextButton(
                                onPressed: () => Navigator.of(context).pop(const PickedLocation()),
                                child: Text(t.removeLocation, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.danger)),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
