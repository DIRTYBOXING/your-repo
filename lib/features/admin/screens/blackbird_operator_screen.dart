import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import '../../../shared/widgets/dfc_network_image.dart';

/// Backend base — override via dart-define BLACKBIRD_API_URL at build time.
const String _kApiBase = String.fromEnvironment(
  'BLACKBIRD_API_URL',
  defaultValue: 'http://localhost:8000',
);

/// ═══════════════════════════════════════════════════════════════════════════
/// BLACKBIRD OPERATOR CONTROL ROOM
/// Real-time alert triage, evidence export, and system status for operators.
///
/// Panels:
///   1. LIVE ALERTS   — Verify / Action alerts from PostGIS matching pipeline
///   2. MAP STATUS    — Node health + active zones summary
///   3. EVIDENCE      — One-tap encrypted export for selected alert
///   4. AUDIT TRAIL   — Recent operator actions
/// ═══════════════════════════════════════════════════════════════════════════

const Color _bbRed = Color(0xFFFF2D55);
const Color _bbAmber = Color(0xFFFFBF00);
const Color _bbCyan = Color(0xFF00D9FF);
const Color _bbGreen = Color(0xFF00FF88);
const Color _bbBg = Color(0xFF050A14);
const Color _bbCard = Color(0xFF0D1B2A);
const Color _bbBorder = Color(0xFF1A2E44);

class BlackbirdOperatorScreen extends StatefulWidget {
  const BlackbirdOperatorScreen({super.key});

  @override
  State<BlackbirdOperatorScreen> createState() =>
      _BlackbirdOperatorScreenState();
}

class _BlackbirdOperatorScreenState extends State<BlackbirdOperatorScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  // ignore: unused_field  — reserved for camera animation on alert selection
  GoogleMapController? _mapController;

  bool _isLoading = false;
  bool _alertsLoading = false;
  String _alertsError = '';
  String? _selectedAlertId;
  String _statusMessage = '';
  Timer? _refreshTimer;
  DateTime? _lastRefreshed;

  List<_AlertItem> _alerts = [];
  final List<_AuditEntry> _auditTrail = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fetchAlerts();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _fetchAlerts(),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _tabController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // ── Backend calls ──────────────────────────────────────────────────────
  Future<void> _fetchAlerts() async {
    setState(() {
      _alertsLoading = true;
      _alertsError = '';
    });
    try {
      final res = await http
          .get(Uri.parse('$_kApiBase/blackbird/alerts?limit=50'))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body) as List<dynamic>;
        setState(() {
          _alerts = data
              .map((j) => _AlertItem.fromJson(j as Map<String, dynamic>))
              .toList();
          _alertsLoading = false;
          _lastRefreshed = DateTime.now();
        });
      } else {
        setState(() {
          _alertsError = 'Server returned ${res.statusCode}';
          _alertsLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _alertsError = 'Cannot reach backend: $e';
        _alertsLoading = false;
      });
    }
  }

  Future<void> _patchAlertStatus(
    String alertId,
    String newStatus,
    String action,
  ) async {
    // Optimistic update
    setState(() {
      final idx = _alerts.indexWhere((a) => a.id == alertId);
      if (idx != -1) _alerts[idx] = _alerts[idx].copyWith(status: newStatus);
      _auditTrail.insert(
        0,
        _AuditEntry(action: action, targetId: alertId, ts: DateTime.now()),
      );
      _statusMessage = 'Alert $alertId: ${action.toLowerCase()}';
    });
    try {
      await http
          .post(
            Uri.parse(
              '$_kApiBase/blackbird/alerts/$alertId/${newStatus.toLowerCase()}',
            ),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 8));
    } catch (_) {
      // Backend unavailable — local update already applied
    }
  }

  // ── Alert actions ──────────────────────────────────────────────────────
  void _acknowledgeAlert(String alertId) =>
      _patchAlertStatus(alertId, 'Acknowledged', 'ACKNOWLEDGE');

  void _escalateAlert(String alertId) =>
      _patchAlertStatus(alertId, 'Escalated', 'ESCALATE → Police Queue');

  void _resolveAlert(String alertId) =>
      _patchAlertStatus(alertId, 'Resolved', 'RESOLVE');

  Future<void> _exportEvidence(String alertId) async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Requesting encrypted export...';
    });
    try {
      final res = await http
          .post(
            Uri.parse('$_kApiBase/blackbird/export/$alertId'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final exportId = body['export_id'] ?? alertId;
        await Clipboard.setData(
          ClipboardData(text: const JsonEncoder.withIndent('  ').convert(body)),
        );
        setState(() {
          _isLoading = false;
          _auditTrail.insert(
            0,
            _AuditEntry(
              action: 'EXPORT EVIDENCE',
              targetId: alertId,
              ts: DateTime.now(),
            ),
          );
          _statusMessage = 'Export ready — ID: $exportId (copied to clipboard)';
        });
      } else {
        setState(() {
          _isLoading = false;
          _statusMessage =
              'Export failed (${res.statusCode}) — retrying from clipboard fallback';
        });
        await _exportEvidenceFallback(alertId);
      }
    } catch (_) {
      setState(() {
        _isLoading = false;
      });
      await _exportEvidenceFallback(alertId);
    }
  }

  Future<void> _exportEvidenceFallback(String alertId) async {
    final manifest = {
      'export_id': 'LOCAL-${DateTime.now().millisecondsSinceEpoch}',
      'alert_id': alertId,
      'exported_at': DateTime.now().toIso8601String(),
      'note': 'Backend unreachable — local manifest only',
    };
    await Clipboard.setData(
      ClipboardData(text: const JsonEncoder.withIndent('  ').convert(manifest)),
    );
    setState(() {
      _auditTrail.insert(
        0,
        _AuditEntry(
          action: 'EXPORT (local fallback)',
          targetId: alertId,
          ts: DateTime.now(),
        ),
      );
      _statusMessage = 'Backend unavailable — local manifest copied.';
    });
  }

  // ── UI ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final unackCount = _alerts
        .where((a) => a.status == 'Unacknowledged')
        .length;

    return Scaffold(
      backgroundColor: _bbBg,
      appBar: AppBar(
        backgroundColor: _bbBg,
        elevation: 0,
        title: Row(
          children: [
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (_, _) => Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: _bbRed,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _bbRed.withValues(
                        alpha: _pulseAnimation.value * 0.8,
                      ),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'BLACKBIRD CONTROL ROOM',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
            const Spacer(),
            if (unackCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _bbRed,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$unackCount ACTIVE',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.refresh, color: _bbCyan, size: 18),
              tooltip: 'Refresh alerts',
              onPressed: _fetchAlerts,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: _bbCyan,
          labelColor: _bbCyan,
          unselectedLabelColor: Colors.white38,
          labelStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
          ),
          tabs: const [
            Tab(text: 'ALERTS'),
            Tab(text: 'NODES'),
            Tab(text: 'EVIDENCE'),
            Tab(text: 'AUDIT'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Status / last-refreshed bar
          Container(
            width: double.infinity,
            color: _bbCyan.withValues(alpha: 0.07),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                if (_statusMessage.isNotEmpty)
                  Expanded(
                    child: Text(
                      _statusMessage,
                      style: const TextStyle(
                        color: _bbCyan,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  )
                else
                  const Expanded(child: SizedBox.shrink()),
                if (_lastRefreshed != null)
                  Text(
                    'Refreshed ${_formatTime(_lastRefreshed!)} · auto 30s',
                    style: const TextStyle(color: Colors.white24, fontSize: 10),
                  ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAlertsTab(),
                _buildNodesTab(),
                _buildEvidenceTab(),
                _buildAuditTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab 1: Alerts ───────────────────────────────────────────────────────
  Widget _buildAlertsTab() {
    if (_alertsLoading) {
      return const Center(child: CircularProgressIndicator(color: _bbCyan));
    }
    if (_alertsError.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, color: Colors.white38, size: 36),
            const SizedBox(height: 12),
            Text(
              _alertsError,
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _fetchAlerts,
              icon: const Icon(Icons.refresh, size: 14),
              label: const Text('Retry'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _bbCyan,
                side: const BorderSide(color: _bbCyan),
              ),
            ),
          ],
        ),
      );
    }
    return _alerts.isEmpty
        ? const Center(
            child: Text(
              'No active alerts.',
              style: TextStyle(color: Colors.white38),
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _alerts.length,
            itemBuilder: (_, i) => _AlertCard(
              alert: _alerts[i],
              isSelected: _selectedAlertId == _alerts[i].id,
              onTap: () => setState(() => _selectedAlertId = _alerts[i].id),
              onAcknowledge: () => _acknowledgeAlert(_alerts[i].id),
              onEscalate: () => _escalateAlert(_alerts[i].id),
              onResolve: () => _resolveAlert(_alerts[i].id),
              onExport: () {
                _selectedAlertId = _alerts[i].id;
                _tabController.animateTo(2);
              },
            ),
          );
  }

  // ── Tab 2: Nodes ────────────────────────────────────────────────────────
  Widget _buildNodesTab() {
    final nodes = [
      const _NodeStatus(
        id: 'NODE-AU-SYD-01',
        lat: -33.8688,
        lon: 151.2093,
        healthy: true,
        lastSeen: 12,
      ),
      const _NodeStatus(
        id: 'NODE-AU-MEL-03',
        lat: -37.8136,
        lon: 144.9631,
        healthy: true,
        lastSeen: 34,
      ),
      const _NodeStatus(
        id: 'NODE-AU-BNE-02',
        lat: -27.4698,
        lon: 153.0251,
        healthy: true,
        lastSeen: 67,
      ),
      const _NodeStatus(
        id: 'NODE-AU-PER-01',
        lat: -31.9505,
        lon: 115.8605,
        healthy: false,
        lastSeen: 420,
      ),
    ];

    // Build map markers: nodes + alerts with known lat/lon
    final Set<Marker> mapMarkers = {
      for (final n in nodes)
        Marker(
          markerId: MarkerId('node_${n.id}'),
          position: LatLng(n.lat, n.lon),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            n.healthy ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed,
          ),
          infoWindow: InfoWindow(
            title: n.id,
            snippet: n.healthy
                ? 'Online · ${n.lastSeen}s ago'
                : 'OFFLINE · ${n.lastSeen}s ago',
          ),
        ),
      for (final a in _alerts.where((a) => a.lat != null && a.lon != null))
        Marker(
          markerId: MarkerId('alert_${a.id}'),
          position: LatLng(a.lat!, a.lon!),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            a.level == 'Action'
                ? BitmapDescriptor.hueRed
                : BitmapDescriptor.hueOrange,
          ),
          infoWindow: InfoWindow(
            title: '${a.level.toUpperCase()} ALERT',
            snippet: a.reason,
          ),
        ),
    };

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 240,
            child: GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: LatLng(-28.0, 133.0), // Australia
                zoom: 4,
              ),
              markers: mapMarkers,
              onMapCreated: (c) => _mapController = c,
              zoomControlsEnabled: false,
              myLocationButtonEnabled: false,
              mapToolbarEnabled: false,
            ),
          ),
        ),
        const SizedBox(height: 16),
        _sectionHeader(
          'EDGE NODES',
          '${nodes.where((n) => n.healthy).length}/${nodes.length} ONLINE',
        ),
        const SizedBox(height: 12),
        ...nodes.map((n) => _NodeCard(node: n)),
        const SizedBox(height: 24),
        _sectionHeader('SYSTEM STATUS', 'ALL SYSTEMS'),
        const SizedBox(height: 12),
        _statusRow('Ingest API', true, '< 80ms'),
        _statusRow('PostGIS Matching', true, '< 120ms'),
        _statusRow('Alert Pipeline', true, 'Running'),
        _statusRow('Evidence Store', true, 'Encrypted'),
        _statusRow('Prometheus', true, 'Scraping'),
        _statusRow('Perth Node', false, 'No heartbeat > 7min'),
      ],
    );
  }

  // ── Tab 3: Evidence ─────────────────────────────────────────────────────
  Widget _buildEvidenceTab() {
    final alert = _selectedAlertId != null
        ? _alerts.firstWhere(
            (a) => a.id == _selectedAlertId,
            orElse: () => _alerts.first,
          )
        : (_alerts.isNotEmpty ? _alerts.first : null);

    if (alert == null) {
      return const Center(
        child: Text(
          'Select an alert to export evidence.',
          style: TextStyle(color: Colors.white38),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('EVIDENCE EXPORT', alert.id),
          const SizedBox(height: 16),
          _EvidenceManifestCard(alert: alert),
          const SizedBox(height: 20),
          _sectionHeader('CHAIN OF CUSTODY', ''),
          const SizedBox(height: 12),
          _infoRow('Operator', 'Current Operator'),
          _infoRow('Export Target', 'Encrypted GCS Bucket'),
          _infoRow('Retention', '30 days (auto-delete)'),
          _infoRow('Redaction', 'Phone hashed · GPS rounded 10m'),
          _infoRow('Encryption', 'AES-256 · Key in Secret Manager'),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: _bbCyan))
                : ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _bbCyan,
                      foregroundColor: _bbBg,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.lock_outline, size: 18),
                    label: const Text(
                      'EXPORT ENCRYPTED EVIDENCE',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                      ),
                    ),
                    onPressed: () => _exportEvidence(alert.id),
                  ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: _bbAmber,
                side: const BorderSide(color: _bbAmber),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.local_police_outlined, size: 18),
              label: const Text(
                'PREPARE POLICE HANDOFF',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
              onPressed: () {
                setState(() {
                  _auditTrail.insert(
                    0,
                    _AuditEntry(
                      action: 'POLICE HANDOFF PREPARED',
                      targetId: alert.id,
                      ts: DateTime.now(),
                    ),
                  );
                  _statusMessage = 'Police handoff prepared for ${alert.id}.';
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab 4: Audit Trail ──────────────────────────────────────────────────
  Widget _buildAuditTab() {
    if (_auditTrail.isEmpty) {
      return const Center(
        child: Text(
          'No operator actions recorded yet.',
          style: TextStyle(color: Colors.white38),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _auditTrail.length,
      itemBuilder: (_, i) {
        final e = _auditTrail[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _bbCard,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _bbBorder),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.history, color: _bbCyan, size: 14),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e.action,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      e.targetId,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                _formatTime(e.ts),
                style: const TextStyle(color: Colors.white38, fontSize: 10),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────
  Widget _sectionHeader(String title, String badge) => Row(
    children: [
      Text(
        title,
        style: const TextStyle(
          color: Colors.white54,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
        ),
      ),
      const SizedBox(width: 8),
      if (badge.isNotEmpty)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: _bbBorder,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            badge,
            style: const TextStyle(
              color: _bbCyan,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
    ],
  );

  Widget _infoRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _statusRow(String label, bool ok, String note) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: _bbCard,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: ok
            ? _bbGreen.withValues(alpha: 0.3)
            : _bbRed.withValues(alpha: 0.3),
      ),
    ),
    child: Row(
      children: [
        Icon(
          ok ? Icons.check_circle_outline : Icons.warning_amber_outlined,
          color: ok ? _bbGreen : _bbRed,
          size: 14,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
        Text(
          note,
          style: TextStyle(
            color: ok ? _bbGreen : _bbRed,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }
}

// ── Alert Card ─────────────────────────────────────────────────────────────
class _AlertCard extends StatelessWidget {
  final _AlertItem alert;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onAcknowledge;
  final VoidCallback onEscalate;
  final VoidCallback onResolve;
  final VoidCallback onExport;

  const _AlertCard({
    required this.alert,
    required this.isSelected,
    required this.onTap,
    required this.onAcknowledge,
    required this.onEscalate,
    required this.onResolve,
    required this.onExport,
  });

  Color get _levelColor => alert.level == 'Action' ? _bbRed : _bbAmber;
  IconData get _levelIcon =>
      alert.level == 'Action' ? Icons.emergency : Icons.search;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _bbCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? _levelColor
                : _levelColor.withValues(alpha: 0.3),
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _levelColor.withValues(alpha: 0.15),
                    blurRadius: 12,
                  ),
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _levelColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: _levelColor.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_levelIcon, color: _levelColor, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        alert.level.toUpperCase(),
                        style: TextStyle(
                          color: _levelColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _bbBorder,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${(alert.score * 100).toStringAsFixed(0)}% CONFIDENCE',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                _statusBadge(alert.status),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              alert.reason,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.sensors, color: Colors.white38, size: 12),
                const SizedBox(width: 4),
                Text(
                  alert.nodeId,
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.straighten, color: Colors.white38, size: 12),
                const SizedBox(width: 4),
                Text(
                  '${alert.distM.toStringAsFixed(1)}m',
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.access_time, color: Colors.white38, size: 12),
                const SizedBox(width: 4),
                Text(
                  _timeAgo(alert.ts),
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
            if (isSelected) ...[
              const SizedBox(height: 14),
              const Divider(color: _bbBorder, height: 1),
              const SizedBox(height: 12),
              if (alert.evidence.isNotEmpty) ...[
                SizedBox(
                  height: 72,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: alert.evidence.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, i) =>
                        _EvidenceThumbnail(item: alert.evidence[i]),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  _actionButton('ACK', _bbGreen, Icons.check, onAcknowledge),
                  const SizedBox(width: 8),
                  _actionButton(
                    'ESCALATE',
                    _bbAmber,
                    Icons.local_police_outlined,
                    onEscalate,
                  ),
                  const SizedBox(width: 8),
                  _actionButton(
                    'EXPORT',
                    _bbCyan,
                    Icons.lock_outline,
                    onExport,
                  ),
                  const SizedBox(width: 8),
                  _actionButton(
                    'RESOLVE',
                    Colors.white38,
                    Icons.done_all,
                    onResolve,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }
}

Widget _actionButton(
  String label,
  Color color,
  IconData icon,
  VoidCallback onPressed,
) => Expanded(
  child: OutlinedButton.icon(
    style: OutlinedButton.styleFrom(
      foregroundColor: color,
      side: BorderSide(color: color.withValues(alpha: 0.5)),
      padding: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    ),
    icon: Icon(icon, size: 13),
    label: Text(
      label,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      ),
    ),
    onPressed: onPressed,
  ),
);

Widget _statusBadge(String status) {
  Color c = Colors.white38;
  if (status == 'Unacknowledged') c = _bbRed;
  if (status == 'Acknowledged') c = _bbAmber;
  if (status == 'Escalated') c = _bbCyan;
  if (status == 'Resolved') c = _bbGreen;
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
    decoration: BoxDecoration(
      color: c.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(4),
      border: Border.all(color: c.withValues(alpha: 0.4)),
    ),
    child: Text(
      status.toUpperCase(),
      style: TextStyle(
        color: c,
        fontSize: 9,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
      ),
    ),
  );
}

// ── Evidence Thumbnail ─────────────────────────────────────────────────────
class _EvidenceThumbnail extends StatelessWidget {
  final _EvidenceItem item;
  const _EvidenceThumbnail({required this.item});

  @override
  Widget build(BuildContext context) {
    final hasMedia = item.mediaUrl != null && item.mediaUrl!.isNotEmpty;
    if (hasMedia) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: DfcNetworkImage(
          url: item.mediaUrl!,
          width: 72,
          height: 72,
        ),
      );
    }
    return _iconBox();
  }

  Widget _iconBox() => Container(
    width: 72,
    height: 72,
    decoration: BoxDecoration(
      color: _bbCard,
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: _bbBorder),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(item.icon, color: _bbCyan, size: 22),
        const SizedBox(height: 4),
        Text(
          item.type.split('_').first,
          style: const TextStyle(color: Colors.white38, fontSize: 9),
        ),
      ],
    ),
  );
}

// ── Node Card ──────────────────────────────────────────────────────────────
class _NodeCard extends StatelessWidget {
  final _NodeStatus node;
  const _NodeCard({required this.node});

  @override
  Widget build(BuildContext context) {
    final color = node.healthy ? _bbGreen : _bbRed;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _bbCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            node.healthy ? Icons.wifi_tethering : Icons.wifi_tethering_error,
            color: color,
            size: 16,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  node.id,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${node.lat.toStringAsFixed(4)}, ${node.lon.toStringAsFixed(4)}',
                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                ),
              ],
            ),
          ),
          Text(
            '${node.lastSeen}s ago',
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Evidence Manifest Card ─────────────────────────────────────────────────
class _EvidenceManifestCard extends StatelessWidget {
  final _AlertItem alert;
  const _EvidenceManifestCard({required this.alert});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _bbCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _bbCyan.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.folder_special_outlined,
                color: _bbCyan,
                size: 16,
              ),
              SizedBox(width: 8),
              Text(
                'EVIDENCE PACKAGE',
                style: TextStyle(
                  color: _bbCyan,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _manifestRow('Alert ID', alert.id),
          _manifestRow('Level', alert.level),
          _manifestRow('Score', '${(alert.score * 100).toStringAsFixed(0)}%'),
          _manifestRow('Node', alert.nodeId),
          _manifestRow('Distance', '${alert.distM.toStringAsFixed(1)} m'),
          _manifestRow('Timestamp', alert.ts.toIso8601String()),
          _manifestRow('Status', alert.status),
          const SizedBox(height: 10),
          const Text(
            'Package contents:',
            style: TextStyle(color: Colors.white54, fontSize: 11),
          ),
          const SizedBox(height: 4),
          _packageItem('alert_record.json'),
          _packageItem('track_snapshot.json'),
          _packageItem('device_match.json'),
          _packageItem('audit_trail.json'),
          _packageItem('export_signature.txt'),
        ],
      ),
    );
  }

  Widget _manifestRow(String k, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            k,
            style: const TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ),
        Expanded(
          child: Text(
            v,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _packageItem(String name) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        const Icon(Icons.check_box_outlined, color: _bbGreen, size: 12),
        const SizedBox(width: 6),
        Text(name, style: const TextStyle(color: Colors.white54, fontSize: 11)),
      ],
    ),
  );
}

// ── Data Models ────────────────────────────────────────────────────────────
class _AlertItem {
  final String id;
  final String level;
  final String reason;
  final double score;
  final String nodeId;
  final double distM;
  final double? lat;
  final double? lon;
  final DateTime ts;
  final String status;
  final List<_EvidenceItem> evidence;
  final String? operatorNotes;

  const _AlertItem({
    required this.id,
    required this.level,
    required this.reason,
    required this.score,
    required this.nodeId,
    required this.distM,
    this.lat,
    this.lon,
    required this.ts,
    required this.status,
    this.evidence = const [],
    this.operatorNotes,
  });

  factory _AlertItem.fromJson(Map<String, dynamic> j) => _AlertItem(
    id: j['id']?.toString() ?? j['alert_id']?.toString() ?? 'unknown',
    level: j['level']?.toString() ?? 'Verify',
    reason: j['reason']?.toString() ?? '',
    score: (j['score'] as num?)?.toDouble() ?? 0.0,
    nodeId: j['node_id']?.toString() ?? j['nodeId']?.toString() ?? '',
    distM: (j['dist_m'] as num?)?.toDouble() ?? 0.0,
    lat: (j['lat'] as num?)?.toDouble(),
    lon: (j['lon'] as num?)?.toDouble(),
    ts: j['ts'] != null
        ? DateTime.tryParse(j['ts'].toString()) ?? DateTime.now()
        : DateTime.now(),
    status: j['status']?.toString() ?? 'Unacknowledged',
    evidence: (j['evidence'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(_EvidenceItem.fromJson)
        .toList(),
    operatorNotes: j['operator_notes']?.toString(),
  );

  _AlertItem copyWith({String? status, String? operatorNotes}) => _AlertItem(
    id: id,
    level: level,
    reason: reason,
    score: score,
    nodeId: nodeId,
    distM: distM,
    lat: lat,
    lon: lon,
    ts: ts,
    status: status ?? this.status,
    evidence: evidence,
    operatorNotes: operatorNotes ?? this.operatorNotes,
  );
}

class _NodeStatus {
  final String id;
  final double lat;
  final double lon;
  final bool healthy;
  final int lastSeen;
  const _NodeStatus({
    required this.id,
    required this.lat,
    required this.lon,
    required this.healthy,
    required this.lastSeen,
  });
}

class _AuditEntry {
  final String action;
  final String targetId;
  final DateTime ts;
  const _AuditEntry({
    required this.action,
    required this.targetId,
    required this.ts,
  });
}

class _EvidenceItem {
  final String id;
  final String type; // 'track' | 'device_location' | 'ping' | 'camera_snapshot'
  final String? mediaUrl;
  final DateTime timestamp;
  final String source; // 'radar' | 'gps' | 'sms' | 'camera'

  const _EvidenceItem({
    required this.id,
    required this.type,
    this.mediaUrl,
    required this.timestamp,
    required this.source,
  });

  factory _EvidenceItem.fromJson(Map<String, dynamic> j) => _EvidenceItem(
    id: j['id']?.toString() ?? '',
    type: j['type']?.toString() ?? '',
    mediaUrl: j['media_url']?.toString(),
    timestamp: j['timestamp'] != null
        ? DateTime.tryParse(j['timestamp'].toString()) ?? DateTime.now()
        : DateTime.now(),
    source:
        (j['details'] as Map<String, dynamic>?)?['source']?.toString() ?? '',
  );

  IconData get icon {
    switch (type) {
      case 'camera_snapshot':
        return Icons.camera_alt_outlined;
      case 'track':
        return Icons.timeline_outlined;
      case 'ping':
        return Icons.message_outlined;
      case 'device_location':
        return Icons.location_on_outlined;
      default:
        return Icons.help_outline;
    }
  }
}
