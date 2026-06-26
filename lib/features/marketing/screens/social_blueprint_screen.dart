import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Social Blueprint — DFC's repeatable social growth operating system.
class SocialBlueprintScreen extends StatefulWidget {
  const SocialBlueprintScreen({super.key});

  @override
  State<SocialBlueprintScreen> createState() => _SocialBlueprintScreenState();

  static const Color bg = Color(0xFF05070C);
  static const Color card = Color(0xFF0D1320);
  static const Color line = Color(0xFF1E2A44);
  static const Color blue = Color(0xFF3D7DFF);
  static const Color cyan = Color(0xFF57C7FF);
  static const Color text = Color(0xFFEAF1FF);
  static const Color muted = Color(0xFF97A6C3);
}

class _SocialBlueprintScreenState extends State<SocialBlueprintScreen> {
  Timer? _liveTimer;
  DateTime _now = DateTime.now();
  int _tick = 0;

  double _ctr = 3.4;
  double _watchMinutes = 6.2;
  int _conversions = 312;

  @override
  void initState() {
    super.initState();
    _liveTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      setState(() {
        _tick++;
        _now = DateTime.now();
        _ctr = (3.2 + math.sin(_tick * 0.22) * 0.65).clamp(2.1, 5.1);
        _watchMinutes = (5.8 + math.cos(_tick * 0.18) * 1.6).clamp(3.2, 9.4);
        _conversions = (300 + (math.sin(_tick * 0.19) * 70) + ((_tick % 5) * 6))
            .round();
      });
    });
  }

  @override
  void dispose() {
    _liveTimer?.cancel();
    super.dispose();
  }

  int get _dayIn7 => ((_now.difference(DateTime(2026)).inDays) % 7) + 1;
  int get _dayIn39 => ((_now.difference(DateTime(2026)).inDays) % 39) + 1;

  List<MapEntry<String, double>> _priorityChannels() {
    final base = <String, double>{
      'DFC Feed': 0.78,
      'YouTube': 0.86,
      'Instagram': 0.69,
      'Facebook': 0.58,
      'TikTok': 0.74,
      'X': 0.55,
      'FightWire': 0.82,
      'Social Queue': 0.71,
    };
    final mod = math.sin(_tick * 0.2) * 0.08;
    final entries = base.entries
        .map(
          (e) => MapEntry(
            e.key,
            (e.value + mod + (e.key.hashCode % 7) * 0.004).clamp(0.40, 0.99),
          ),
        )
        .toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }

  List<String> _adaptiveActions() {
    final actions = <String>[];

    if (_ctr < 3.0) {
      actions.add(
        'CTR is soft. Swap headline hooks and thumbnails in next queue run.',
      );
    } else {
      actions.add(
        'CTR is healthy. Duplicate top-performing hook across YouTube + FightWire.',
      );
    }

    if (_watchMinutes < 5.0) {
      actions.add(
        'Watch time dropped. Move strongest moment into first 6 seconds of video cuts.',
      );
    } else {
      actions.add(
        'Watch time is climbing. Extend long-form breakdowns and publish recap threads.',
      );
    }

    if (_dayIn7 == 7) {
      actions.add(
        'Weekly reset day. Archive losers, keep winners, and seed the next 7-day sprint.',
      );
    } else {
      actions.add(
        'Day $_dayIn7/7 sprint active. Stay on schedule and protect daily posting cadence.',
      );
    }

    if (_dayIn39 == 39) {
      actions.add(
        '39-day strategy pivot due now: retune channel mix and reposition core campaign themes.',
      );
    }

    return actions;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SocialBlueprintScreen.bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.go('/home?tab=0&drawer=1'),
                      icon: const Icon(
                        Icons.arrow_back,
                        color: SocialBlueprintScreen.text,
                      ),
                      tooltip: 'Back to Dashboard Drawer',
                    ),
                    const SizedBox(width: 6),
                    const Expanded(
                      child: Text(
                        'SOCIAL BLUEPRINT',
                        style: TextStyle(
                          color: SocialBlueprintScreen.text,
                          fontSize: 22,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 28,
                      height: 28,
                      child: Image(
                        image: AssetImage(
                          'assets/logos/dfc_icon_transparent.png',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Make DFC smarter every day: publish, measure, adapt. Build momentum for promoters, events, shows, trainers, and the next generation.',
                  style: TextStyle(
                    color: SocialBlueprintScreen.muted.withValues(alpha: 0.95),
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            SliverToBoxAdapter(
              child: _sectionCard(
                title: 'LIVE PERFORMANCE SIGNAL',
                child: Column(
                  children: [
                    Row(
                      children: [
                        _kpiTile(
                          'CTR',
                          '${_ctr.toStringAsFixed(2)}%',
                          SocialBlueprintScreen.cyan,
                        ),
                        const SizedBox(width: 8),
                        _kpiTile(
                          'WATCH',
                          '${_watchMinutes.toStringAsFixed(1)}m',
                          SocialBlueprintScreen.blue,
                        ),
                        const SizedBox(width: 8),
                        _kpiTile(
                          'CONV',
                          '$_conversions',
                          const Color(0xFF77C6FF),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(
                          Icons.bolt,
                          color: SocialBlueprintScreen.cyan,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Cycle Day $_dayIn7/7 · Macro Day $_dayIn39/39 · Updated ${_now.hour.toString().padLeft(2, '0')}:${_now.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                            color: SocialBlueprintScreen.muted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            SliverToBoxAdapter(
              child: _sectionCard(
                title: '3-STEP GROWTH LOOP',
                child: const Column(
                  children: [
                    _StepTile(
                      index: 1,
                      title: 'Plan Weekly Content',
                      description:
                          'Map fight news, promoter highlights, gym stories, and YouTube clips before posting.',
                    ),
                    SizedBox(height: 8),
                    _StepTile(
                      index: 2,
                      title: 'Publish Multi-Channel',
                      description:
                          'Post natively to DFC + connected channels with role-specific messaging.',
                    ),
                    SizedBox(height: 8),
                    _StepTile(
                      index: 3,
                      title: 'Measure + Tweak',
                      description:
                          'Track CTR, saves, shares, watch time, and conversions. Improve next cycle.',
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            SliverToBoxAdapter(
              child: _sectionCard(
                title: '28-DAY BLUEPRINT',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _weekRow(
                      'Week 1',
                      'Authority Build',
                      'Core story + brand positioning',
                    ),
                    _weekRow(
                      'Week 2',
                      'Audience Trust',
                      'Fighter stories + education + social proof',
                    ),
                    _weekRow(
                      'Week 3',
                      'Conversion Push',
                      'Event promos + sponsor offers + CTAs',
                    ),
                    _weekRow(
                      'Week 4',
                      'Scale + Repeat',
                      'Top-performer remix + pipeline reset',
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            SliverToBoxAdapter(
              child: _sectionCard(
                title: 'CHANNEL INTELLIGENCE MATRIX',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _priorityChannels()
                      .map(
                        (e) => _Pill(
                          '${e.key} ${(e.value * 100).toStringAsFixed(0)}%',
                          e.key == 'YouTube' || e.key == 'FightWire'
                              ? SocialBlueprintScreen.cyan
                              : SocialBlueprintScreen.blue,
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            SliverToBoxAdapter(
              child: _sectionCard(
                title: 'ADAPTIVE NEXT ACTIONS',
                child: Column(
                  children: _adaptiveActions()
                      .map(_actionRow)
                      .toList(),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            SliverToBoxAdapter(
              child: _sectionCard(
                title: 'SMARTER EVERY DAY',
                child: const Text(
                  'Daily cadence: 1) ingest new signals, 2) score content by outcome, 3) auto-prioritize tomorrow\'s plan.\n\n'
                  '7-day cycle: weekly review + optimization.\n'
                  '39-day cycle: deeper strategic reset for sustained growth.',
                  style: TextStyle(
                    color: SocialBlueprintScreen.muted,
                    height: 1.45,
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  static Widget _sectionCard({required String title, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: SocialBlueprintScreen.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: SocialBlueprintScreen.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: SocialBlueprintScreen.text,
                fontSize: 13,
                letterSpacing: 1.1,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }

  static Widget _weekRow(String week, String focus, String detail) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 78,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: SocialBlueprintScreen.blue.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              week,
              style: const TextStyle(
                color: SocialBlueprintScreen.cyan,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  focus,
                  style: const TextStyle(
                    color: SocialBlueprintScreen.text,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  detail,
                  style: const TextStyle(
                    color: SocialBlueprintScreen.muted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _kpiTile(String label, String value, Color accent) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: accent.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                color: accent,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: SocialBlueprintScreen.muted,
                fontSize: 10,
                letterSpacing: 0.7,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionRow(String action) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: SocialBlueprintScreen.blue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: SocialBlueprintScreen.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              Icons.double_arrow,
              color: SocialBlueprintScreen.cyan,
              size: 14,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              action,
              style: const TextStyle(
                color: SocialBlueprintScreen.muted,
                fontSize: 11,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  final int index;
  final String title;
  final String description;

  const _StepTile({
    required this.index,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: SocialBlueprintScreen.blue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: SocialBlueprintScreen.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              color: SocialBlueprintScreen.blue,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$index',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: SocialBlueprintScreen.text,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(
                    color: SocialBlueprintScreen.muted,
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final Color color;
  const _Pill(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class AutoFeedOrchestratorService {
  AutoFeedOrchestratorService._internal();

  static AutoFeedOrchestratorService? get instance {
    return _instance;
  }

  static AutoFeedOrchestratorService? _instance;

  void addLegendsEvent({
    required String id,
    required String title,
    required String body,
    required String imageUrl,
    required DateTime publishedAt,
  }) {
    // Add your logic to handle the event
  }
}
