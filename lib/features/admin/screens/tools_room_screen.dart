import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// TOOLS ROOM — DFC Operations Command Console
// Campaign Library · Promo Builder · Publish Toggle · Pipeline Monitor
// ═══════════════════════════════════════════════════════════════════════════════

const _cyan = Color(0xFF00F5FF);
const _magenta = Color(0xFFFF00FF);
const _green = Color(0xFF00FF88);
const _amber = Color(0xFFFFB800);
const _red = Color(0xFFFF3366);
const _gold = Color(0xFFFFD700);
const _bg = Color(0xFF050A14);
const _panel = Color(0xFF0D1B2A);
const _surface = Color(0xFF142236);
const _border = Color(0xFF1A2744);

class ToolsRoomScreen extends StatefulWidget {
  const ToolsRoomScreen({super.key});
  @override
  State<ToolsRoomScreen> createState() => _ToolsRoomScreenState();
}

class _ToolsRoomScreenState extends State<ToolsRoomScreen>
    with TickerProviderStateMixin {
  late TabController _tabCtrl;
  final _focusNode = FocusNode();

  // ── Publish toggle ──
  int _publishMode = 0; // 0=Off, 1=Auto, 2=Manual
  static const _publishLabels = ['OFF', 'AUTO PUBLISH', 'MANUAL CONFIRM'];
  static const _publishColors = [_red, _green, _amber];

  // ── Pipeline health ──
  final _rng = math.Random(42);
  late Timer _healthTimer;
  double _consumerLag = 1.2;
  int _queueDepth = 3;
  double _clipSuccessRate = 99.2;
  int _moderationPending = 7;
  String _lastPublish = '32s ago';

  // ── Campaign library ──
  final _campaigns = <_Campaign>[
    _Campaign('Logan Hero Clip', 'hero_clip', _cyan, 'Live', 3420, 89.2),
    _Campaign('BKFC Round Highlight', 'round_hl', _magenta, 'Scheduled', 0, 0),
    _Campaign('Brisbane Title Fight', 'title_fight', _gold, 'Live', 8100, 94.1),
    _Campaign('MMA Underground', 'underground', _green, 'Draft', 0, 0),
    _Campaign('Promoter Promo Pack', 'promo_pack', _amber, 'Live', 1890, 78.3),
    _Campaign('Bare Knuckle Series', 'bk_series', _red, 'Paused', 560, 62.4),
  ];

  // ── Promo builder state ──
  String? _selectedMedia;
  String _selectedFormat = '9:16';
  String _selectedCaption = 'short';
  String _promoCode = '';
  bool _bulkMode = false;
  final _selectedCampaigns = <int>{};

  // ── Clip queue ──
  final _clipQueue = <_ClipJob>[
    _ClipJob('clip_001', 'Logan Main Event KO', 'processing', 0.72, '9:16'),
    _ClipJob('clip_002', 'Brisbane Undercard TKO', 'transcoding', 0.45, '1:1'),
    _ClipJob('clip_003', 'BKFC Round 3 Finish', 'uploading', 0.91, '16:9'),
    _ClipJob('clip_004', 'Title Fight Walkout', 'queued', 0.0, '9:16'),
    _ClipJob('clip_005', 'Corner Cam Highlight', 'complete', 1.0, '9:16'),
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    _healthTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      setState(() {
        _consumerLag = (0.5 + _rng.nextDouble() * 3.0);
        _queueDepth = _rng.nextInt(12);
        _clipSuccessRate = 95.0 + _rng.nextDouble() * 5.0;
        _moderationPending = _rng.nextInt(15);
        final secs = _rng.nextInt(120);
        _lastPublish = '${secs}s ago';
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _healthTimer.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.keyT) {
      setState(() => _publishMode = (_publishMode + 1) % 3);
    } else if (key == LogicalKeyboardKey.keyB) {
      setState(() => _bulkMode = !_bulkMode);
    } else if (key == LogicalKeyboardKey.digit1) {
      _tabCtrl.animateTo(0);
    } else if (key == LogicalKeyboardKey.digit2) {
      _tabCtrl.animateTo(1);
    } else if (key == LogicalKeyboardKey.digit3) {
      _tabCtrl.animateTo(2);
    } else if (key == LogicalKeyboardKey.digit4) {
      _tabCtrl.animateTo(3);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;
    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: _handleKey,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: _buildAppBar(),
        body: Column(
          children: [
            _buildHealthBar(),
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: [
                  _buildCampaignLibrary(isWide),
                  _buildPromoBuilder(isWide),
                  _buildClipQueue(isWide),
                  _buildPipelinePanel(isWide),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: _buildPublishToggleFAB(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _panel,
      foregroundColor: _cyan,
      elevation: 0,
      title: Row(
        children: [
          const Icon(Icons.rocket_launch, color: _cyan, size: 22),
          const SizedBox(width: 8),
          const Text(
            'TOOLS ROOM',
            style: TextStyle(
              fontFamily: 'Segoe UI',
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              color: _cyan,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: _green.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _green.withValues(alpha: 0.4)),
            ),
            child: const Text(
              'OPERATIONAL',
              style: TextStyle(
                color: _green,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      bottom: TabBar(
        controller: _tabCtrl,
        isScrollable: true,
        indicatorColor: _cyan,
        labelColor: _cyan,
        unselectedLabelColor: Colors.white54,
        labelStyle: const TextStyle(
          fontFamily: 'Segoe UI',
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        tabs: const [
          Tab(text: '1 CAMPAIGNS'),
          Tab(text: '2 PROMO BUILDER'),
          Tab(text: '3 CLIP QUEUE'),
          Tab(text: '4 PIPELINE'),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HEALTH BAR — Live ops metrics
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildHealthBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: _panel,
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _healthChip(
              'CONSUMER LAG',
              '${_consumerLag.toStringAsFixed(1)}s',
              _consumerLag < 2.0
                  ? _green
                  : (_consumerLag < 5.0 ? _amber : _red),
            ),
            const SizedBox(width: 16),
            _healthChip(
              'QUEUE DEPTH',
              '$_queueDepth',
              _queueDepth < 8 ? _cyan : _amber,
            ),
            const SizedBox(width: 16),
            _healthChip(
              'CLIP SUCCESS',
              '${_clipSuccessRate.toStringAsFixed(1)}%',
              _clipSuccessRate > 98 ? _green : _amber,
            ),
            const SizedBox(width: 16),
            _healthChip(
              'MOD PENDING',
              '$_moderationPending',
              _moderationPending < 10 ? _cyan : _red,
            ),
            const SizedBox(width: 16),
            _healthChip('LAST PUBLISH', _lastPublish, _green),
            const SizedBox(width: 16),
            _healthChip(
              'PUBLISH MODE',
              _publishLabels[_publishMode],
              _publishColors[_publishMode],
            ),
          ],
        ),
      ),
    );
  }

  Widget _healthChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.7),
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              fontFamily: 'Segoe UI',
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 1 — Campaign Library
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildCampaignLibrary(bool isWide) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.library_books, color: _cyan, size: 20),
              const SizedBox(width: 8),
              const Text(
                'CAMPAIGN LIBRARY',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              if (_bulkMode)
                TextButton.icon(
                  onPressed: () => setState(_selectedCampaigns.clear),
                  icon: const Icon(Icons.clear_all, size: 16),
                  label: const Text('Clear'),
                  style: TextButton.styleFrom(foregroundColor: _amber),
                ),
              _pillButton('+ NEW CAMPAIGN', _cyan, () {}),
            ],
          ),
          const SizedBox(height: 12),
          // Stats row
          Row(
            children: [
              _statCard('TOTAL', '${_campaigns.length}', _cyan),
              const SizedBox(width: 8),
              _statCard(
                'LIVE',
                '${_campaigns.where((c) => c.status == 'Live').length}',
                _green,
              ),
              const SizedBox(width: 8),
              _statCard(
                'TOTAL VIEWS',
                '${_campaigns.fold<int>(0, (s, c) => s + c.views)}',
                _gold,
              ),
              const SizedBox(width: 8),
              _statCard(
                'AVG CTR',
                '${(_campaigns.where((c) => c.ctr > 0).fold<double>(0, (s, c) => s + c.ctr) / math.max(1, _campaigns.where((c) => c.ctr > 0).length)).toStringAsFixed(1)}%',
                _magenta,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: _campaigns.length,
              itemBuilder: (ctx, i) {
                final c = _campaigns[i];
                final selected = _selectedCampaigns.contains(i);
                return _campaignCard(c, i, selected);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _campaignCard(_Campaign c, int index, bool selected) {
    final statusColor = switch (c.status) {
      'Live' => _green,
      'Scheduled' => _amber,
      'Paused' => _red,
      _ => Colors.white38,
    };
    return GestureDetector(
      onTap: () {
        if (_bulkMode) {
          setState(() {
            if (selected) {
              _selectedCampaigns.remove(index);
            } else {
              _selectedCampaigns.add(index);
            }
          });
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? _cyan.withValues(alpha: 0.08) : _panel,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? _cyan.withValues(alpha: 0.5) : _border,
          ),
        ),
        child: Row(
          children: [
            if (_bulkMode)
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Icon(
                  selected ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: selected ? _cyan : Colors.white24,
                  size: 20,
                ),
              ),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: c.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.campaign, color: c.color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    c.template,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                c.status,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            _miniStat('Views', '${c.views}', _cyan),
            const SizedBox(width: 8),
            _miniStat('CTR', c.ctr > 0 ? '${c.ctr}%' : '—', _magenta),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(
                Icons.play_circle_outline,
                color: _green,
                size: 20,
              ),
              onPressed: () {},
              tooltip: 'Publish / Boost',
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: color.withValues(alpha: 0.6), fontSize: 9),
        ),
      ],
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: color.withValues(alpha: 0.7),
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 2 — Promo Builder (drag-drop concept adapted to Flutter)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildPromoBuilder(bool isWide) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: isWide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: _builderForm()),
                const SizedBox(width: 16),
                Expanded(flex: 2, child: _builderPreview()),
              ],
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  _builderForm(),
                  const SizedBox(height: 16),
                  _builderPreview(),
                ],
              ),
            ),
    );
  }

  Widget _builderForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'PROMO BUILDER',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          // Media drop zone
          GestureDetector(
            onTap: () =>
                setState(() => _selectedMedia = 'sample_fight_clip.mp4'),
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _selectedMedia != null
                      ? _cyan.withValues(alpha: 0.5)
                      : _border,
                  style: _selectedMedia != null
                      ? BorderStyle.solid
                      : BorderStyle.none,
                ),
              ),
              child: Center(
                child: _selectedMedia != null
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.videocam, color: _green, size: 24),
                          const SizedBox(width: 8),
                          Text(
                            _selectedMedia!,
                            style: const TextStyle(
                              color: _green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: _red,
                              size: 16,
                            ),
                            onPressed: () =>
                                setState(() => _selectedMedia = null),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.cloud_upload_outlined,
                            color: Colors.white.withValues(alpha: 0.3),
                            size: 32,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Tap to select media or drag & drop',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.4),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Format row
          Row(
            children: [
              const Text(
                'FORMAT',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 12),
              for (final fmt in ['9:16', '1:1', '16:9'])
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(fmt, style: const TextStyle(fontSize: 11)),
                    selected: _selectedFormat == fmt,
                    selectedColor: _cyan.withValues(alpha: 0.2),
                    backgroundColor: _surface,
                    labelStyle: TextStyle(
                      color: _selectedFormat == fmt ? _cyan : Colors.white54,
                      fontWeight: FontWeight.w700,
                    ),
                    side: BorderSide(
                      color: _selectedFormat == fmt
                          ? _cyan.withValues(alpha: 0.5)
                          : _border,
                    ),
                    onSelected: (_) => setState(() => _selectedFormat = fmt),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Caption variant
          Row(
            children: [
              const Text(
                'CAPTION',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 12),
              for (final cap in ['short', 'hype', 'stats'])
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(
                      cap.toUpperCase(),
                      style: const TextStyle(fontSize: 11),
                    ),
                    selected: _selectedCaption == cap,
                    selectedColor: _magenta.withValues(alpha: 0.2),
                    backgroundColor: _surface,
                    labelStyle: TextStyle(
                      color: _selectedCaption == cap
                          ? _magenta
                          : Colors.white54,
                      fontWeight: FontWeight.w700,
                    ),
                    side: BorderSide(
                      color: _selectedCaption == cap
                          ? _magenta.withValues(alpha: 0.5)
                          : _border,
                    ),
                    onSelected: (_) => setState(() => _selectedCaption = cap),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Promo code
          TextField(
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              labelText: 'PROMO CODE',
              labelStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 11,
              ),
              prefixIcon: const Icon(Icons.local_offer, color: _gold, size: 18),
              enabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: _border),
                borderRadius: BorderRadius.circular(10),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: _gold),
                borderRadius: BorderRadius.circular(10),
              ),
              filled: true,
              fillColor: _surface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
            onChanged: (v) => setState(() => _promoCode = v),
          ),
          const SizedBox(height: 16),
          // Action buttons
          Row(
            children: [
              Expanded(
                child: _actionButton(
                  'PUBLISH NOW',
                  _green,
                  Icons.publish,
                  () {},
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _actionButton('SCHEDULE', _amber, Icons.schedule, () {}),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _actionButton(
                  'A/B TEST',
                  _magenta,
                  Icons.science,
                  () {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _builderPreview() {
    final captionText = switch (_selectedCaption) {
      'short' => 'KNOCKOUT. 🔥',
      'hype' =>
        'You won\'t BELIEVE this finish — absolute carnage in Round 3! 💥🥊',
      'stats' => 'KO at 2:34 in R3 — 4th straight finish for the champion 📊',
      _ => '',
    };
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.preview, color: _cyan, size: 18),
              const SizedBox(width: 6),
              const Text(
                'PREVIEW',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _cyan.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _selectedFormat,
                  style: const TextStyle(
                    color: _cyan,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Mock video preview
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _border),
            ),
            child: Center(
              child: _selectedMedia != null
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.play_circle_filled,
                          color: _cyan.withValues(alpha: 0.7),
                          size: 48,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _selectedMedia!,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      'No media selected',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontSize: 12,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          // Caption preview
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_selectedCaption.toUpperCase()} CAPTION',
                  style: TextStyle(
                    color: _magenta.withValues(alpha: 0.7),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  captionText,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ],
            ),
          ),
          if (_promoCode.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _gold.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _gold.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.local_offer, color: _gold, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    'CODE: $_promoCode',
                    style: const TextStyle(
                      color: _gold,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          // UTM preview
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'utm_source=dfc&utm_medium=social&utm_campaign=${_promoCode.isNotEmpty ? _promoCode : 'default'}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 10,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 3 — Clip Queue (live job tracker)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildClipQueue(bool isWide) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.movie_filter, color: _magenta, size: 20),
              const SizedBox(width: 8),
              const Text(
                'CLIP PROCESSING QUEUE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              _pillButton('FLUSH DLQ', _red, () {}),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: _clipQueue.length,
              itemBuilder: (ctx, i) => _clipJobCard(_clipQueue[i]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _clipJobCard(_ClipJob job) {
    final statusColor = switch (job.status) {
      'complete' => _green,
      'processing' => _cyan,
      'transcoding' => _magenta,
      'uploading' => _amber,
      _ => Colors.white38,
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                job.status == 'complete'
                    ? Icons.check_circle
                    : Icons.hourglass_top,
                color: statusColor,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  job.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  job.status.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  job.format,
                  style: const TextStyle(color: Colors.white54, fontSize: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: job.progress,
              backgroundColor: _surface,
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                job.id,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 10,
                  fontFamily: 'monospace',
                ),
              ),
              const Spacer(),
              Text(
                '${(job.progress * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  color: statusColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 4 — Pipeline Overview (ingest→moderate→clip→publish)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildPipelinePanel(bool isWide) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'PIPELINE FLOW',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 16),
            // Pipeline stages
            if (isWide)
              Row(
                children: [
                  Expanded(
                    child: _pipelineStage(
                      'INGEST',
                      Icons.input,
                      _cyan,
                      '142 events/hr',
                      true,
                    ),
                  ),
                  _pipelineArrow(),
                  Expanded(
                    child: _pipelineStage(
                      'MODERATE',
                      Icons.shield,
                      _amber,
                      '$_moderationPending pending',
                      true,
                    ),
                  ),
                  _pipelineArrow(),
                  Expanded(
                    child: _pipelineStage(
                      'CLIP',
                      Icons.content_cut,
                      _magenta,
                      '${_clipQueue.where((j) => j.status != 'complete').length} active',
                      true,
                    ),
                  ),
                  _pipelineArrow(),
                  Expanded(
                    child: _pipelineStage(
                      'ENRICH',
                      Icons.auto_awesome,
                      _gold,
                      '3 variants/clip',
                      true,
                    ),
                  ),
                  _pipelineArrow(),
                  Expanded(
                    child: _pipelineStage(
                      'PUBLISH',
                      Icons.publish,
                      _green,
                      _lastPublish,
                      true,
                    ),
                  ),
                ],
              )
            else
              Column(
                children: [
                  _pipelineStage(
                    'INGEST',
                    Icons.input,
                    _cyan,
                    '142 events/hr',
                    false,
                  ),
                  _pipelineArrowVertical(),
                  _pipelineStage(
                    'MODERATE',
                    Icons.shield,
                    _amber,
                    '$_moderationPending pending',
                    false,
                  ),
                  _pipelineArrowVertical(),
                  _pipelineStage(
                    'CLIP',
                    Icons.content_cut,
                    _magenta,
                    '${_clipQueue.where((j) => j.status != 'complete').length} active',
                    false,
                  ),
                  _pipelineArrowVertical(),
                  _pipelineStage(
                    'ENRICH',
                    Icons.auto_awesome,
                    _gold,
                    '3 variants/clip',
                    false,
                  ),
                  _pipelineArrowVertical(),
                  _pipelineStage(
                    'PUBLISH',
                    Icons.publish,
                    _green,
                    _lastPublish,
                    false,
                  ),
                ],
              ),
            const SizedBox(height: 24),
            // Throughput stats
            const Text(
              'THROUGHPUT (24H)',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _throughputCard('Events Ingested', '3,408', _cyan),
                const SizedBox(width: 8),
                _throughputCard('Auto Approved', '3,102', _green),
                const SizedBox(width: 8),
                _throughputCard('Flagged', '241', _amber),
                const SizedBox(width: 8),
                _throughputCard('Rejected', '65', _red),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _throughputCard('Clips Produced', '2,847', _magenta),
                const SizedBox(width: 8),
                _throughputCard('Articles Generated', '1,102', _gold),
                const SizedBox(width: 8),
                _throughputCard('Social Posts', '4,291', _cyan),
                const SizedBox(width: 8),
                _throughputCard(
                  'Avg Latency',
                  '${_consumerLag.toStringAsFixed(1)}s',
                  _green,
                ),
              ],
            ),
            const SizedBox(height: 24),
            // DLQ / Error summary
            const Text(
              'ERROR & DLQ SUMMARY',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            _errorRow('Clip Worker Failures', '3', _amber),
            _errorRow('Moderation Timeouts', '1', _amber),
            _errorRow('CDN Upload Errors', '0', _green),
            _errorRow('DLQ Depth', '2', _red),
            _errorRow('Materializer Retries', '4', _amber),
          ],
        ),
      ),
    );
  }

  Widget _pipelineStage(
    String label,
    IconData icon,
    Color color,
    String metric,
    bool horizontal,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            metric,
            style: TextStyle(color: color.withValues(alpha: 0.8), fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _pipelineArrow() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 4),
      child: Icon(Icons.arrow_forward, color: Colors.white24, size: 20),
    );
  }

  Widget _pipelineArrowVertical() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Icon(Icons.arrow_downward, color: Colors.white24, size: 20),
    );
  }

  Widget _throughputCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: color.withValues(alpha: 0.6),
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorRow(String label, String count, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            count == '0' ? Icons.check_circle : Icons.warning_amber,
            color: color,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
          Text(
            count,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Publish Toggle FAB
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildPublishToggleFAB() {
    return FloatingActionButton.extended(
      onPressed: () => setState(() => _publishMode = (_publishMode + 1) % 3),
      backgroundColor: _publishColors[_publishMode].withValues(alpha: 0.9),
      icon: Icon(
        _publishMode == 0
            ? Icons.block
            : (_publishMode == 1 ? Icons.flash_on : Icons.pan_tool),
        color: Colors.white,
      ),
      label: Text(
        _publishLabels[_publishMode],
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 12,
          letterSpacing: 0.5,
        ),
      ),
      tooltip: 'T to toggle publish mode',
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Shared helpers
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _pillButton(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _actionButton(
    String label,
    Color color,
    IconData icon,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Data models
// ═══════════════════════════════════════════════════════════════════════════════
class _Campaign {
  final String name;
  final String template;
  final Color color;
  final String status;
  final int views;
  final double ctr;
  _Campaign(
    this.name,
    this.template,
    this.color,
    this.status,
    this.views,
    this.ctr,
  );
}

class _ClipJob {
  final String id;
  final String title;
  final String status;
  final double progress;
  final String format;
  _ClipJob(this.id, this.title, this.status, this.progress, this.format);
}
