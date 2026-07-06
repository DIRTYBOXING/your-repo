import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../shared/models/user_model.dart';
import '../../../shared/models/event_model.dart';
import '../../../shared/services/ads_service.dart';
import '../../../shared/services/auth_service.dart';
import '../../../shared/services/content_safety_service.dart';
import '../../../shared/services/dfc_ai_powerhouse.dart';
import '../../../shared/services/event_service.dart';
import '../../../shared/services/fight_news_service.dart';
import '../../../shared/services/samurai_core_engine.dart';
import '../../../shared/services/smart_device_service.dart';
import '../../../shared/services/sports_science_engine.dart';

class SamuraiOwnerCommandCenterPage extends StatefulWidget {
  const SamuraiOwnerCommandCenterPage({super.key});

  @override
  State<SamuraiOwnerCommandCenterPage> createState() =>
      _SamuraiOwnerCommandCenterPageState();
}

class _SamuraiOwnerCommandCenterPageState
    extends State<SamuraiOwnerCommandCenterPage> {
  final TextEditingController _eventNameController = TextEditingController();
  final TextEditingController _eventVenueController = TextEditingController();
  final TextEditingController _eventCityController = TextEditingController();
  final TextEditingController _eventDeleteIdController =
      TextEditingController();
  final TextEditingController _safetyTestController = TextEditingController();
  bool _busy = false;
  bool _newsAutoRefresh = false;
  bool _adsEnabled = true;
  String _ownerMessage = '';
  String _safetyMessage = '';

  // Bot Manager state (toggled via UI in future)
  // ignore: unused_field
  final bool _autoFeedEnabled = true;
  // ignore: unused_field
  final bool _pageRunnerEnabled = true;
  // ignore: unused_field
  final bool _socialSyncEnabled = true;
  // ignore: unused_field
  final bool _matchmakerBotEnabled = true;
  // ignore: unused_field
  final bool _analyticsBotEnabled = true;
  // ignore: unused_field
  final bool _moderatorBotEnabled = true;

  @override
  void dispose() {
    _eventNameController.dispose();
    _eventVenueController.dispose();
    _eventCityController.dispose();
    _eventDeleteIdController.dispose();
    _safetyTestController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.userModel;

    // ── OWNER-ONLY ACCESS — Fight HQ is restricted ──
    if (!auth.isOwner) {
      return Scaffold(
        appBar: AppBar(title: const Text('SAMURAI Owner Command Center')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFFF3366).withValues(alpha: 0.6),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.shield,
                  color: Color(0xFFFF3366),
                  size: 48,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'OWNER ACCESS ONLY',
                style: TextStyle(
                  color: Color(0xFFFF3366),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This command center is restricted to the DFC platform owner.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Owner verified → show full control center.
    return Scaffold(
      appBar: AppBar(title: const Text('SAMURAI Owner Command Center')),
      body: Container(
        color: Colors.black,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _buildControlCenter(user: user),
        ),
      ),
    );
  }

  Widget _buildControlCenter({required UserModel? user}) {
    return Consumer4<
      SamuraiCoreEngine,
      DFCAIPowerhouse,
      SportsScienceEngine,
      SmartDeviceService
    >(
      builder: (context, core, powerhouse, science, devices, child) {
        final eventService = context.read<EventService>();
        final newsService = context.read<FightNewsService>();
        final adsService = context.read<AdsService>();
        final safetyService = context.read<ContentSafetyService>();
        final snapshot = core.latestSnapshot;
        final status = powerhouse.status;
        final summary = core.getExecutiveSummary();
        final liveSignals = powerhouse.getLiveSignals(limit: 8);

        return ListView(
          children: [
            _sectionCard(
              title: 'Owner Identity',
              subtitle: 'Full authority session + authorization state',
              child: Row(
                children: [
                  const Icon(Icons.verified_user, color: Colors.cyanAccent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${user?.displayName ?? 'Owner'} • ${user?.email ?? 'no-email'}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  _pill('ADMIN', Colors.greenAccent),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _sectionCard(
              title: 'SAMURAI Protocol Power',
              subtitle:
                  'Autonomous strategy, discipline, monitoring, monetization',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _pill('Status: ${summary['status']}', Colors.cyanAccent),
                      _pill(
                        'Power: ${((summary['powerIndex'] ?? 0.0) * 100).toStringAsFixed(1)}%',
                        Colors.amberAccent,
                      ),
                      _pill(
                        core.autonomousMode
                            ? 'Autonomous ON'
                            : 'Autonomous OFF',
                        core.autonomousMode
                            ? Colors.greenAccent
                            : Colors.orangeAccent,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _busy
                              ? null
                              : () => _runOwnerAction(
                                  'Run protocol cycle',
                                  () async {
                                    await core.runAutonomousCycle();
                                  },
                                ),
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Run Cycle'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _busy
                              ? null
                              : () {
                                  core.setAutonomousMode(!core.autonomousMode);
                                  _showSnack(
                                    core.autonomousMode
                                        ? 'Autonomous mode enabled'
                                        : 'Autonomous mode disabled',
                                  );
                                },
                          icon: const Icon(Icons.autorenew),
                          label: Text(
                            core.autonomousMode ? 'Pause Auto' : 'Enable Auto',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _ownerMessage,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  if ((snapshot?.commandQueue ?? []).isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Top Commands',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...snapshot!.commandQueue
                        .take(3)
                        .map(
                          (cmd) => ListTile(
                            dense: true,
                            title: Text(
                              cmd.title,
                              style: const TextStyle(color: Colors.white),
                            ),
                            subtitle: Text(
                              cmd.action,
                              style: const TextStyle(color: Colors.white70),
                            ),
                            trailing: Text(
                              (cmd.priority * 100).toStringAsFixed(0),
                              style: const TextStyle(color: Colors.cyanAccent),
                            ),
                          ),
                        ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            _sectionCard(
              title: 'Engine Monitoring',
              subtitle: 'AI engines, bots, feeds, health pulse',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _pill(
                        'Engines: ${status.activeEngines}/${status.totalEngines}',
                        Colors.greenAccent,
                      ),
                      _pill(
                        'Bots: ${status.totalBotsActive}/${status.totalBotsTotal}',
                        Colors.purpleAccent,
                      ),
                      _pill(
                        'Feed: ${status.totalContentItems}',
                        Colors.amberAccent,
                      ),
                      _pill(
                        'Devices: ${devices.devices.length}',
                        Colors.lightBlueAccent,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _busy
                              ? null
                              : () => _runOwnerAction(
                                  'Booting all engines',
                                  () async {
                                    if (!powerhouse.initialized) {
                                      await powerhouse.bootAllEngines();
                                    }
                                  },
                                ),
                          icon: const Icon(Icons.power_settings_new),
                          label: const Text('Boot Engines'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _busy
                              ? null
                              : () => _runOwnerAction(
                                  'Force refresh all engines',
                                  () async {
                                    if (!powerhouse.initialized) {
                                      await powerhouse.bootAllEngines();
                                    }
                                    await powerhouse.forceRefreshAll();
                                  },
                                ),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Force Refresh'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _sectionCard(
              title: 'Live News & Promotion Signals',
              subtitle: 'Self-automated live feed intelligence (top 8)',
              child: Column(
                children: liveSignals
                    .map(
                      (signal) => ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          signal.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          '${signal.source} • ${signal.timeAgo}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        trailing: signal.isBreaking
                            ? const Icon(Icons.bolt, color: Colors.redAccent)
                            : const Icon(
                                Icons.chevron_right,
                                color: Colors.white54,
                              ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 12),
            _sectionCard(
              title: 'Fitness / Rehab / Combat Intelligence',
              subtitle: '2026 health + combat telemetry heartbeat',
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _pill(
                    'Biometrics: ${science.biometricHistory.length}',
                    Colors.greenAccent,
                  ),
                  _pill(
                    'Sessions: ${science.sessionHistory.length}',
                    Colors.orangeAccent,
                  ),
                  _pill(
                    'Recovery: ${science.recoveryState.name}',
                    Colors.cyanAccent,
                  ),
                  _pill(
                    'Phase: ${science.currentPhase.name}',
                    Colors.purpleAccent,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _sectionCard(
              title: 'Live Runtime Controls',
              subtitle:
                  'Full control while app is live: events, news, ads, safety',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Create / update / remove events instantly',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _eventNameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _ownerInputDecoration('Event name'),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _eventVenueController,
                          style: const TextStyle(color: Colors.white),
                          decoration: _ownerInputDecoration('Venue'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _eventCityController,
                          style: const TextStyle(color: Colors.white),
                          decoration: _ownerInputDecoration('City'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _busy
                              ? null
                              : () => _runOwnerAction(
                                  'Creating event',
                                  () async {
                                    final eventName = _eventNameController.text
                                        .trim();
                                    if (eventName.isEmpty) {
                                      throw Exception('Event name is required');
                                    }
                                    final now = DateTime.now();
                                    final newEvent = EventModel(
                                      id: 'owner-${now.millisecondsSinceEpoch}',
                                      promoterId: user?.id ?? 'owner',
                                      name: eventName,
                                      venue:
                                          _eventVenueController.text
                                              .trim()
                                              .isEmpty
                                          ? 'TBA Venue'
                                          : _eventVenueController.text.trim(),
                                      city:
                                          _eventCityController.text
                                              .trim()
                                              .isEmpty
                                          ? 'TBA City'
                                          : _eventCityController.text.trim(),
                                      country: 'Global',
                                      eventDate: now.add(
                                        const Duration(days: 14),
                                      ),
                                      description: 'Owner live-created event',
                                      isFeatured: true,
                                      createdAt: now,
                                      updatedAt: now,
                                    );
                                    final id = await eventService
                                        .createEventDoc(newEvent);
                                    if (id == null) {
                                      throw Exception('Event create failed');
                                    }
                                    _eventDeleteIdController.text = id;
                                  },
                                ),
                          icon: const Icon(Icons.add_circle_outline),
                          label: const Text('Add Event'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _busy
                              ? null
                              : () => _runOwnerAction(
                                  'Refreshing news',
                                  () async {
                                    await newsService.refreshNews();
                                  },
                                ),
                          icon: const Icon(Icons.newspaper),
                          label: const Text('Refresh News'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _eventDeleteIdController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _ownerInputDecoration(
                      'Event ID to remove/update status',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _busy
                              ? null
                              : () => _runOwnerAction(
                                  'Setting event LIVE',
                                  () async {
                                    final id = _eventDeleteIdController.text
                                        .trim();
                                    if (id.isEmpty) {
                                      throw Exception('Event ID required');
                                    }
                                    final ok = await eventService
                                        .updateEventStatus(
                                          id,
                                          EventStatus.live,
                                        );
                                    if (!ok) {
                                      throw Exception('Status update failed');
                                    }
                                  },
                                ),
                          icon: const Icon(Icons.live_tv),
                          label: const Text('Go Live'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _busy
                              ? null
                              : () =>
                                    _runOwnerAction('Deleting event', () async {
                                      final id = _eventDeleteIdController.text
                                          .trim();
                                      if (id.isEmpty) {
                                        throw Exception('Event ID required');
                                      }
                                      final ok = await eventService.deleteEvent(
                                        id,
                                      );
                                      if (!ok) throw Exception('Delete failed');
                                    }),
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Remove Event'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Safety + Ads + Inclusive controls',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    title: const Text(
                      'News Auto Refresh',
                      style: TextStyle(color: Colors.white),
                    ),
                    value: _newsAutoRefresh,
                    activeThumbColor: Colors.greenAccent,
                    onChanged: _busy
                        ? null
                        : (v) {
                            setState(() => _newsAutoRefresh = v);
                            if (v) {
                              newsService.startAutoRefresh(
                                interval: const Duration(minutes: 3),
                              );
                            } else {
                              newsService.stopAutoRefresh();
                            }
                          },
                  ),
                  SwitchListTile(
                    title: const Text(
                      'Ads Enabled',
                      style: TextStyle(color: Colors.white),
                    ),
                    value: _adsEnabled,
                    activeThumbColor: Colors.greenAccent,
                    onChanged: _busy
                        ? null
                        : (v) async {
                            await adsService.setAdsEnabled(v);
                            if (!mounted) return;
                            setState(() => _adsEnabled = v);
                          },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _safetyTestController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _ownerInputDecoration(
                      'Safety test text (content-only moderation)',
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      final result = safetyService.evaluateContentOnly(
                        _safetyTestController.text.trim(),
                      );
                      setState(() {
                        _safetyMessage = result.passed
                            ? 'Clean ✅ (inclusive policy respected)'
                            : 'Flagged ⚠️ terms: ${result.flaggedTerms.join(', ')}';
                      });
                    },
                    icon: const Icon(Icons.gpp_good),
                    label: const Text('Run Safety Check'),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _safetyMessage,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Inclusive Principles',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...safetyService.inclusiveCommunityPrinciples.map(
                    (item) => Text(
                      '• $item',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // ── AI SECURITY SCANNER ──────────────────────────────────────
            _sectionCard(
              title: 'AI Security Scanner',
              subtitle: 'Firestore v2.0 · Claude Sonnet · Frontier Red Team',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _pill('8 PATCHED', Colors.greenAccent),
                      const SizedBox(width: 8),
                      _pill('0 ACTIVE', Colors.cyanAccent),
                      const SizedBox(width: 8),
                      _pill('v2.0 RULES', Colors.purpleAccent),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'DATAFIGHTCENTRAL PROTECTS ALL — all 8 Firestore '
                    'vulnerabilities have been patched. Run the scanner '
                    'to verify current security posture.',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              context.push('/admin/security-scanner'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.cyanAccent.withValues(
                              alpha: 0.15,
                            ),
                            foregroundColor: Colors.cyanAccent,
                            side: const BorderSide(color: Colors.cyanAccent),
                          ),
                          icon: const Icon(Icons.security, size: 15),
                          label: const Text(
                            'SCANNER',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              context.push('/admin/data-protection'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(
                              0xFF00E676,
                            ).withValues(alpha: 0.12),
                            foregroundColor: const Color(0xFF00E676),
                            side: const BorderSide(color: Color(0xFF00E676)),
                          ),
                          icon: const Icon(Icons.shield_outlined, size: 15),
                          label: const Text(
                            'DATA HUB',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _runOwnerAction(
    String actionLabel,
    Future<void> Function() action,
  ) async {
    setState(() {
      _busy = true;
      _ownerMessage = actionLabel;
    });
    try {
      await action();
      if (!mounted) return;
      _showSnack('$actionLabel complete');
      setState(() => _ownerMessage = '$actionLabel complete');
    } catch (e) {
      if (!mounted) return;
      _showSnack('$actionLabel failed: $e');
      setState(() => _ownerMessage = '$actionLabel failed');
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Widget _sectionCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Card(
      color: const Color(0xFF121212),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _pill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  InputDecoration _ownerInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.cyanAccent),
      ),
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
