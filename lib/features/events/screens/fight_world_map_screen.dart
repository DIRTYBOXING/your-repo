import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'fight_event_gym_finder.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// FIGHT WORLD MAP — Satellite hybrid map with DFC-branded event markers.
/// Accepts an optional [focusEvent] to zoom to on load.
/// ═══════════════════════════════════════════════════════════════════════════
class FightWorldMapScreen extends StatefulWidget {
  /// If provided, the map will zoom to this event on first render.
  final FightEvent? focusEvent;

  const FightWorldMapScreen({this.focusEvent, super.key});

  @override
  State<FightWorldMapScreen> createState() => _FightWorldMapScreenState();
}

class _FightWorldMapScreenState extends State<FightWorldMapScreen> {
  // ── Palette ───────────────────────────────────────────────────────────────
  static const _bg = Color(0xFF030810);
  static const _cyan = Color(0xFF00E5FF);
  static const _red = Color(0xFFFF1744);
  static const _amber = Color(0xFFFFD600);

  // ── State ─────────────────────────────────────────────────────────────────
  // ignore: unused_field
  GoogleMapController? _mapController;
  Set<Marker> _markers = const {};
  FightEvent? _selectedEvent;

  BitmapDescriptor _upcomingIcon = BitmapDescriptor.defaultMarkerWithHue(
    BitmapDescriptor.hueAzure,
  );
  final BitmapDescriptor _liveIcon = BitmapDescriptor.defaultMarkerWithHue(
    BitmapDescriptor.hueRed,
  );

  List<FightEvent> get _events => FightEventGymFinder.defaultEvents;

  // ── Lifecycle ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _buildMarkers();
    if (widget.focusEvent != null) {
      _selectedEvent = widget.focusEvent;
    }
  }

  Future<void> _buildMarkers() async {
    BitmapDescriptor? dfcIcon;
    try {
      dfcIcon = await BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(40, 40)),
        'assets/logos/dfc_app_icon.png',
      );
    } catch (_) {
      // Use hue-based default on asset failure
    }

    final markers = <Marker>{};
    for (final e in _events) {
      markers.add(
        Marker(
          markerId: MarkerId(e.name),
          position: LatLng(e.latitude, e.longitude),
          icon: e.isLive ? _liveIcon : (dfcIcon ?? _upcomingIcon),
          infoWindow: InfoWindow(
            title: e.name,
            snippet: '${e.venue} · ${e.date}',
          ),
          onTap: () {
            setState(() => _selectedEvent = e);
            _mapController?.animateCamera(
              CameraUpdate.newLatLngZoom(LatLng(e.latitude, e.longitude), 9),
            );
          },
        ),
      );
    }

    if (mounted) {
      setState(() {
        if (dfcIcon != null) _upcomingIcon = dfcIcon;
        _markers = markers;
      });
    }
  }

  void _onMapCreated(GoogleMapController ctrl) {
    _mapController = ctrl;
    // Zoom to focus event if one was passed in
    if (widget.focusEvent != null) {
      ctrl.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(widget.focusEvent!.latitude, widget.focusEvent!.longitude),
          9,
        ),
      );
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg.withValues(alpha: 0.95),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'FIGHT WORLD MAP',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              'LIVE & UPCOMING EVENTS GLOBALLY',
              style: TextStyle(
                fontSize: 7,
                color: Color(0xFF607090),
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        actions: [
          // Live count badge
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: _LiveEventBadge(
                count: _events.where((e) => e.isLive).length,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // ── Map ──────────────────────────────────────────────────────────
          GoogleMap(
            mapType: MapType.hybrid,
            initialCameraPosition: const CameraPosition(
              target: LatLng(20.0, 10.0),
              zoom: 2.2,
            ),
            markers: _markers,
            onMapCreated: _onMapCreated,
            myLocationButtonEnabled: false,
            compassEnabled: false,
          ),
          // ── Legend ───────────────────────────────────────────────────────
          Positioned(top: 12, right: 12, child: _buildLegend()),
          // ── Disclaimer strip ─────────────────────────────────────────────
          Positioned(top: 12, left: 12, child: _buildDisclaimer()),
          // ── Selected event panel ─────────────────────────────────────────
          if (_selectedEvent != null)
            Positioned(
              bottom: 20,
              left: 16,
              right: 16,
              child: _EventInfoPanel(
                event: _selectedEvent!,
                onClose: () => setState(() => _selectedEvent = null),
                onZoom: () => _mapController?.animateCamera(
                  CameraUpdate.newLatLngZoom(
                    LatLng(_selectedEvent!.latitude, _selectedEvent!.longitude),
                    12,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: _bg.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _legendRow(_red, '● LIVE NOW'),
          const SizedBox(height: 4),
          _legendRow(_cyan, '○ UPCOMING'),
        ],
      ),
    );
  }

  Widget _legendRow(Color c, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: c, shape: BoxShape.circle),
      ),
      const SizedBox(width: 6),
      Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: c,
          letterSpacing: 0.5,
        ),
      ),
    ],
  );

  Widget _buildDisclaimer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: _bg.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _amber.withValues(alpha: 0.2)),
      ),
      child: Text(
        'Event data illustrative only',
        style: TextStyle(
          fontSize: 8,
          color: _amber.withValues(alpha: 0.6),
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// SUBWIDGETS
// ═════════════════════════════════════════════════════════════════════════════

class _LiveEventBadge extends StatelessWidget {
  final int count;
  const _LiveEventBadge({required this.count});

  static const _red = Color(0xFFFF1744);

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _red.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _red.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: _red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            '$count LIVE',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: _red,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _EventInfoPanel extends StatelessWidget {
  final FightEvent event;
  final VoidCallback onClose;
  final VoidCallback onZoom;

  const _EventInfoPanel({
    required this.event,
    required this.onClose,
    required this.onZoom,
  });

  static const _bg = Color(0xFF030810);
  static const _cyan = Color(0xFF00E5FF);
  static const _red = Color(0xFFFF1744);

  @override
  Widget build(BuildContext context) {
    final accent = event.isLive ? _red : _cyan;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _bg.withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.15),
            blurRadius: 24,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon block
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.sports_mma, color: accent, size: 28),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      event.sport.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: _cyan,
                        letterSpacing: 1,
                      ),
                    ),
                    if (event.isLive) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _red.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '● LIVE',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                            color: _red,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  event.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${event.venue} · ${event.city}',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
                Text(
                  event.date,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withValues(alpha: 0.35),
                  ),
                ),
              ],
            ),
          ),
          // Actions
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.zoom_in, color: accent, size: 22),
                onPressed: onZoom,
                tooltip: 'Zoom in',
              ),
              IconButton(
                icon: Icon(
                  Icons.close,
                  color: Colors.white.withValues(alpha: 0.4),
                  size: 18,
                ),
                onPressed: onClose,
                tooltip: 'Close',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
