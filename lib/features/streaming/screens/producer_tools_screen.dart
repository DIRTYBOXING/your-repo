import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';

/// PRODUCER TOOLS — Broadcast overlay management for approved UGC.
/// Overlay editor · Q&A feed injector · Highlight clip queue · API keys
/// This is the gap no competitor fills — DFC gives broadcasters tools.
class ProducerToolsScreen extends StatefulWidget {
  const ProducerToolsScreen({super.key});

  @override
  State<ProducerToolsScreen> createState() => _ProducerToolsScreenState();
}

class _ProducerToolsScreenState extends State<ProducerToolsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgSecondary,
        title: const Row(
          children: [
            Icon(
              Icons.broadcast_on_personal,
              color: DesignTokens.neonGold,
              size: 22,
            ),
            SizedBox(width: 8),
            Text(
              'PRODUCER TOOLS',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 18,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: DesignTokens.neonGold,
          labelColor: DesignTokens.neonGold,
          unselectedLabelColor: Colors.white30,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 11,
          ),
          tabs: const [
            Tab(text: 'OVERLAYS'),
            Tab(text: 'Q&A FEED'),
            Tab(text: 'HIGHLIGHTS'),
            Tab(text: 'API & KEYS'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverlaysTab(),
          _buildQAFeedTab(),
          _buildHighlightsTab(),
          _buildAPITab(),
        ],
      ),
    );
  }

  // ── OVERLAYS TAB ──

  Widget _buildOverlaysTab() {
    final overlays = [
      const _Overlay('Lower Third — Fighter Intro', 'ACTIVE', DesignTokens.neonGreen),
      const _Overlay('Score Bug', 'ACTIVE', DesignTokens.neonGreen),
      const _Overlay('Q&A Ticker', 'STANDBY', DesignTokens.neonAmber),
      const _Overlay('Sponsor Banner', 'STANDBY', DesignTokens.neonAmber),
      const _Overlay('Round Timer', 'ACTIVE', DesignTokens.neonGreen),
      const _Overlay('Fan Reaction Meter', 'DISABLED', Colors.white30),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Preview area
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: DesignTokens.bgCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: DesignTokens.neonGold.withValues(alpha: 0.15),
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.tv,
                  color: DesignTokens.neonGold.withValues(alpha: 0.3),
                  size: 48,
                ),
                const SizedBox(height: 8),
                const Text(
                  'BROADCAST PREVIEW',
                  style: TextStyle(
                    color: Colors.white30,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const Text(
                  'Overlays render here in real-time',
                  style: TextStyle(color: Colors.white24, fontSize: 10),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'ACTIVE OVERLAYS',
          style: TextStyle(
            color: DesignTokens.neonGold,
            fontWeight: FontWeight.w900,
            fontSize: 11,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: 8),
        ...overlays.map(_overlayCard),
      ],
    );
  }

  Widget _overlayCard(_Overlay o) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: Row(
        children: [
          Icon(Icons.layers, color: o.color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              o.name,
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: o.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              o.status,
              style: TextStyle(
                color: o.color,
                fontWeight: FontWeight.w800,
                fontSize: 9,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.edit, color: Colors.white24, size: 16),
        ],
      ),
    );
  }

  // ── Q&A FEED TAB ──

  Widget _buildQAFeedTab() {
    final questions = [
      const _QAItem('Fan_Logan_01', 'What does Logan mean to you?', 'approved', '2m'),
      const _QAItem(
        'BKFC_Fan',
        'How do you prepare for bare knuckle?',
        'approved',
        '5m',
      ),
      const _QAItem(
        'IslanderPride',
        'Message for the Bronx Islanders?',
        'pending',
        '8m',
      ),
      const _QAItem('FightFan99', 'What round do you predict?', 'approved', '12m'),
      const _QAItem(
        'TownsvilleFan',
        'Can you shout out Townsville youth?',
        'pending',
        '15m',
      ),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                DesignTokens.neonCyan.withValues(alpha: 0.08),
                Colors.transparent,
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: DesignTokens.neonCyan.withValues(alpha: 0.15),
            ),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: DesignTokens.neonCyan, size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Approved questions appear on broadcast overlay. Drag to reorder priority.',
                  style: TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...questions.map(_qaCard),
      ],
    );
  }

  Widget _qaCard(_QAItem q) {
    final statusColor = q.status == 'approved'
        ? DesignTokens.neonGreen
        : DesignTokens.neonAmber;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '@${q.author}',
                style: const TextStyle(
                  color: DesignTokens.neonCyan,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  q.status.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 8,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                q.timeAgo,
                style: const TextStyle(color: Colors.white24, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            q.question,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _actionBtn('PUSH TO OVERLAY', DesignTokens.neonGold),
              const SizedBox(width: 8),
              _actionBtn('SKIP', Colors.white30),
              const SizedBox(width: 8),
              _actionBtn('PIN', DesignTokens.neonCyan),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 9,
        ),
      ),
    );
  }

  // ── HIGHLIGHTS TAB ──

  Widget _buildHighlightsTab() {
    final clips = [
      ('Hepi KO Reel', '0:32', 'ready'),
      ('Round 1 Exchange', '1:14', 'processing'),
      ('Corner Cam — Pre-Fight', '0:45', 'ready'),
      ('Fan Reaction Montage', '0:28', 'queued'),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ...clips.map((c) {
          final (title, duration, status) = c;
          final sColor = switch (status) {
            'ready' => DesignTokens.neonGreen,
            'processing' => DesignTokens.neonAmber,
            _ => Colors.white30,
          };
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: DesignTokens.bgCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.movie_creation,
                  color: sColor.withValues(alpha: 0.6),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        '$duration · ${status.toUpperCase()}',
                        style: TextStyle(color: sColor, fontSize: 10),
                      ),
                    ],
                  ),
                ),
                if (status == 'ready')
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: DesignTokens.neonGold.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'BROADCAST',
                      style: TextStyle(
                        color: DesignTokens.neonGold,
                        fontWeight: FontWeight.w800,
                        fontSize: 9,
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ── API TAB ──

  Widget _buildAPITab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _apiSection(
          'PRODUCER API ENDPOINT',
          'wss://api.dfc.com/producer/v1',
          DesignTokens.neonCyan,
        ),
        _apiSection(
          'REST ENDPOINT',
          'https://api.dfc.com/producer/overlays',
          DesignTokens.neonGreen,
        ),
        const SizedBox(height: 16),
        const Text(
          'API KEYS',
          style: TextStyle(
            color: DesignTokens.neonGold,
            fontWeight: FontWeight.w900,
            fontSize: 11,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: 8),
        _keyCard('Production Key', 'Managed outside the app', true),
        _keyCard('Test Key', 'Managed outside the app', false),
        const SizedBox(height: 16),
        const Text(
          'WEBHOOK EVENTS',
          style: TextStyle(
            color: DesignTokens.neonGold,
            fontWeight: FontWeight.w900,
            fontSize: 11,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: 8),
        _webhookRow('overlay.update', 'Fired when overlay state changes'),
        _webhookRow('qa.approved', 'Fired when Q&A item is approved'),
        _webhookRow('highlight.ready', 'Fired when clip is ready'),
        _webhookRow('stream.started', 'Fired when live stream begins'),
        _webhookRow('stream.ended', 'Fired when live stream ends'),
      ],
    );
  }

  Widget _apiSection(String label, String url, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 10,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  url,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
              const Icon(Icons.copy, color: Colors.white24, size: 16),
            ],
          ),
        ],
      ),
    );
  }

  Widget _keyCard(String label, String key, bool active) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.key,
            color: active ? DesignTokens.neonGreen : Colors.white24,
            size: 16,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
                Text(
                  key,
                  style: const TextStyle(
                    color: Colors.white30,
                    fontFamily: 'monospace',
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.copy, color: Colors.white24, size: 14),
        ],
      ),
    );
  }

  Widget _webhookRow(String event, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: DesignTokens.neonCyan,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            event,
            style: const TextStyle(
              color: DesignTokens.neonCyan,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              desc,
              style: const TextStyle(color: Colors.white30, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }
}

class _Overlay {
  final String name;
  final String status;
  final Color color;
  const _Overlay(this.name, this.status, this.color);
}

class _QAItem {
  final String author;
  final String question;
  final String status;
  final String timeAgo;
  const _QAItem(this.author, this.question, this.status, this.timeAgo);
}
