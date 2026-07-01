import 'package:flutter/material.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// DFC Trading Card Builder — Profile & Fighter Card Creator
/// ═══════════════════════════════════════════════════════════════════════════
class TradingCardBuilderScreen extends StatefulWidget {
  final String cardType; // 'profile' or 'fighter'
  final String? fighterId;
  final String? fighterName;

  const TradingCardBuilderScreen({
    super.key,
    required this.cardType,
    this.fighterId,
    this.fighterName,
  });

  @override
  State<TradingCardBuilderScreen> createState() =>
      _TradingCardBuilderScreenState();
}

class _TradingCardBuilderScreenState extends State<TradingCardBuilderScreen> {
  // Removed unused _titleCtrl and _subtitleCtrl
  final _stat1Ctrl = TextEditingController();
  final _stat2Ctrl = TextEditingController();
  final _stat3Ctrl = TextEditingController();
  String? _backgroundUrl;
  String? _eventStyle = 'ufc';
  String? _borderStyle = 'diamond';
  String? _overlayEffect = 'none';
  bool _removingBg = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trading Card Builder')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildSectionTitle('CARD PREVIEW'),
            // Event preview widget placeholder
            Container(
              height: 220,
              width: 160,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.amber, width: 2),
                borderRadius: BorderRadius.circular(16),
                color: Colors.black,
              ),
              child: const Center(
                child: Text(
                  'Preview Here',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 24),
            buildSectionTitle('EVENT STYLE'),
            buildStylePicker(),
            const SizedBox(height: 16),
            buildSectionTitle('EVENT BACKGROUND'),
            buildBackgroundPicker(),
            const SizedBox(height: 16),
            buildSectionTitle('EVENT BORDER'),
            buildBorderPicker(),
            const SizedBox(height: 16),
            buildSectionTitle('EVENT OVERLAY EFFECT'),
            buildOverlayPicker(),
            const SizedBox(height: 24),
            buildSectionTitle('EVENT STATS'),
            TextField(
              controller: _stat1Ctrl,
              decoration: const InputDecoration(
                labelText: 'Stat 1',
                hintText: 'e.g. Record: 18-4-0',
              ),
            ),
            TextField(
              controller: _stat2Ctrl,
              decoration: const InputDecoration(
                labelText: 'Stat 2',
                hintText: 'e.g. Height: 6\'0"',
              ),
            ),
            TextField(
              controller: _stat3Ctrl,
              decoration: const InputDecoration(
                labelText: 'Stat 3',
                hintText: 'e.g. Reach: 74"',
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              icon: const Icon(Icons.auto_fix_high),
              label: const Text('Remove Background'),
              onPressed: _removingBg ? null : handleRemoveBackground,
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              icon: const Icon(Icons.preview),
              label: const Text('Preview Event'),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Use the Fight Card Preview from the Promoter tools to see the full event layout')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.amber,
        ),
      ),
    );
  }

  Widget buildStylePicker() {
    final styles = [
      {'label': 'UFC EVENT', 'value': 'ufc'},
      {'label': 'BASKETBALL', 'value': 'basketball'},
      {'label': 'BASEBALL', 'value': 'baseball'},
      {'label': 'CYBERPUNK', 'value': 'cyberpunk'},
      {'label': 'MANGA', 'value': 'manga'},
    ];
    return Wrap(
      spacing: 8,
      children: styles
          .map(
            (s) => ChoiceChip(
              label: Text(s['label']!),
              selected: _eventStyle == s['value'],
              onSelected: (_) => setState(() => _eventStyle = s['value']),
            ),
          )
          .toList(),
    );
  }

  Widget buildBackgroundPicker() {
    final bgs = [
      {'label': 'METAL', 'value': 'metal'},
      {'label': 'FLAMES', 'value': 'flames'},
      {'label': 'ICE', 'value': 'ice'},
      {'label': 'HOLO', 'value': 'holo'},
      {'label': 'GALAXY', 'value': 'galaxy'},
      {'label': 'LIGHTNING', 'value': 'lightning'},
      {'label': 'SMOKE', 'value': 'smoke'},
      {'label': 'NEON GRID', 'value': 'neon'},
    ];
    return Wrap(
      spacing: 8,
      children: bgs
          .map(
            (b) => ChoiceChip(
              label: Text(b['label']!),
              selected: _backgroundUrl == b['value'],
              onSelected: (_) => setState(() => _backgroundUrl = b['value']),
            ),
          )
          .toList(),
    );
  }

  Widget buildBorderPicker() {
    final borders = [
      {'label': 'GOLD', 'value': 'gold'},
      {'label': 'PLATINUM', 'value': 'platinum'},
      {'label': 'DIAMOND', 'value': 'diamond'},
      {'label': 'BRONZE', 'value': 'bronze'},
      {'label': 'RAINBOW', 'value': 'rainbow'},
      {'label': 'OBSIDIAN', 'value': 'obsidian'},
    ];
    return Wrap(
      spacing: 8,
      children: borders
          .map(
            (b) => ChoiceChip(
              label: Text(b['label']!),
              selected: _borderStyle == b['value'],
              onSelected: (_) => setState(() => _borderStyle = b['value']),
            ),
          )
          .toList(),
    );
  }

  Widget buildOverlayPicker() {
    final overlays = [
      {'label': 'NONE', 'value': 'none'},
      {'label': 'SPARKS', 'value': 'sparks'},
      {'label': 'SNOW', 'value': 'snow'},
      {'label': 'EMBERS', 'value': 'embers'},
      {'label': 'LIGHTNING', 'value': 'lightning'},
      {'label': 'SAKURA', 'value': 'sakura'},
    ];
    return Wrap(
      spacing: 8,
      children: overlays
          .map(
            (o) => ChoiceChip(
              label: Text(o['label']!),
              selected: _overlayEffect == o['value'],
              onSelected: (_) => setState(() => _overlayEffect = o['value']),
            ),
          )
          .toList(),
    );
  }

  Future<void> handleRemoveBackground() async {
    setState(() => _removingBg = true);
    await Future.delayed(const Duration(seconds: 2));
    setState(() => _removingBg = false);
    // Background removal — demo mode until ML service integrated
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Background removed (demo)'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}
