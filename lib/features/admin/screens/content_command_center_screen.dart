import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/image_assets.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../shared/services/content_publisher_service.dart';
import '../../../shared/services/dfc_social_engine.dart';
import '../../../shared/services/samurai_content_transformer.dart';
import '../../../shared/services/samurai_swarm_coordinator.dart';
import '../../../shared/services/social_service.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// DFC CONTENT COMMAND CENTER
// ═══════════════════════════════════════════════════════════════════════════════
// Manual publishing + AI Autonomous Feeder + Content management.
// No code changes, no redeployment, no logging out users — ever.
// ═══════════════════════════════════════════════════════════════════════════════

class ContentCommandCenterScreen extends StatefulWidget {
  const ContentCommandCenterScreen({super.key});

  @override
  State<ContentCommandCenterScreen> createState() =>
      _ContentCommandCenterScreenState();
}

class _ContentCommandCenterScreenState extends State<ContentCommandCenterScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _service = ContentPublisherService();
  final _formKey = GlobalKey<FormState>();

  // ── Manual publish fields ──
  DfcContentType _selectedType = DfcContentType.fightShow;
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  final _imageUrlCtrl = TextEditingController();
  final _promotionCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  final _mainEventCtrl = TextEditingController();
  final _broadcastCtrl = TextEditingController();
  final _ticketUrlCtrl = TextEditingController();
  final _sportTypeCtrl = TextEditingController();
  final _fightCountCtrl = TextEditingController();
  bool _isFeatured = false;
  bool _isBreaking = false;
  bool _publishing = false;

  // ── AI Feeder state ──
  bool _feederRunning = false;
  Timer? _feederTimer;
  int _feederIntervalMinutes = 30;
  int _itemsGenerated = 0;
  final List<_AIFeedItem> _feedLog = [];
  bool _autoNews = true;
  bool _autoSignals = true;
  bool _autoFightShows = false;
  bool _autoSocialPosts = true;

  // ── Manage tab ──
  DfcContentType? _filterType;

  // ── Social tab ──
  final _socialEngine = DfcSocialEngine();
  final _socialService = SocialService();
  final _samurai = SamuraiContentTransformer();
  final _swarm = SamuraiSwarmCoordinator();
  final _socialBodyCtrl = TextEditingController();
  final _socialTitleCtrl = TextEditingController();
  bool _socialPublishing = false;
  bool _mediaBackfillRunning = false;
  SocialPostMediaBackfillResult? _mediaBackfillResult;
  String _socialContentStyle = 'promo';
  final Set<String> _selectedPlatforms = {
    'facebook',
    'instagram',
    'tiktok',
    'x',
    'youtube',
    'linkedin',
    'snapchat',
    'whatsapp',
  };

  // ── Workshop tab ──
  final _assetTitleCtrl = TextEditingController();
  final _assetUrlCtrl = TextEditingController();
  final _assetNotesCtrl = TextEditingController();
  String _assetType = 'image';
  final List<_WorkshopAsset> _workshopAssets = [];
  bool _workshopBusy = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _service.loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    _imageUrlCtrl.dispose();
    _promotionCtrl.dispose();
    _locationCtrl.dispose();
    _dateCtrl.dispose();
    _mainEventCtrl.dispose();
    _broadcastCtrl.dispose();
    _ticketUrlCtrl.dispose();
    _sportTypeCtrl.dispose();
    _fightCountCtrl.dispose();
    _socialBodyCtrl.dispose();
    _socialTitleCtrl.dispose();
    _assetTitleCtrl.dispose();
    _assetUrlCtrl.dispose();
    _assetNotesCtrl.dispose();
    _feederTimer?.cancel();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: const Text(
          'CONTENT COMMAND CENTER',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 16,
            letterSpacing: 1.5,
          ),
        ),
        backgroundColor: DesignTokens.bgSecondary,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.neonCyan,
          labelColor: AppTheme.neonCyan,
          unselectedLabelColor: Colors.white54,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 11,
          ),
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.publish, size: 18), text: 'PUBLISH'),
            Tab(icon: Icon(Icons.smart_toy, size: 18), text: 'AI FEEDER'),
            Tab(icon: Icon(Icons.share, size: 18), text: 'SOCIAL'),
            Tab(icon: Icon(Icons.folder_open, size: 18), text: 'MANAGE'),
            Tab(
              icon: Icon(Icons.precision_manufacturing, size: 18),
              text: 'WORKSHOP',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPublishTab(),
          _buildAIFeederTab(),
          _buildSocialMediaTab(),
          _buildManageTab(),
          _buildWorkshopTab(),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 1: MANUAL PUBLISH
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildPublishTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('CONTENT TYPE'),
            const SizedBox(height: 8),
            _buildTypeSelector(),
            const SizedBox(height: 20),

            _sectionLabel('DETAILS'),
            const SizedBox(height: 8),
            _buildTextField(_titleCtrl, 'Title *', Icons.title),
            const SizedBox(height: 12),
            _buildTextField(
              _bodyCtrl,
              'Body / Description *',
              Icons.article,
              maxLines: 5,
            ),
            const SizedBox(height: 12),
            _buildTextField(_imageUrlCtrl, 'Poster / Image URL', Icons.image),
            const SizedBox(height: 12),

            // Contextual fields based on type
            if (_selectedType == DfcContentType.fightShow ||
                _selectedType == DfcContentType.event ||
                _selectedType == DfcContentType.ppv) ...[
              _buildTextField(_promotionCtrl, 'Promotion Name', Icons.business),
              const SizedBox(height: 12),
              _buildTextField(
                _locationCtrl,
                'Venue / Location',
                Icons.location_on,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                _dateCtrl,
                'Event Date (YYYY-MM-DD)',
                Icons.calendar_today,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                _mainEventCtrl,
                'Main Event / Headline',
                Icons.star,
              ),
              const SizedBox(height: 12),
              _buildTextField(_broadcastCtrl, 'Broadcast Info', Icons.live_tv),
              const SizedBox(height: 12),
              _buildTextField(
                _ticketUrlCtrl,
                'Ticket / Stream URL',
                Icons.link,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                _sportTypeCtrl,
                'Sport Type (boxing, mma, etc)',
                Icons.sports_mma,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                _fightCountCtrl,
                'Number of Bouts',
                Icons.format_list_numbered,
              ),
              const SizedBox(height: 12),
            ],

            if (_selectedType == DfcContentType.news) ...[
              _buildTextField(_promotionCtrl, 'Source Name', Icons.source),
              const SizedBox(height: 12),
            ],

            if (_selectedType == DfcContentType.signal) ...[
              _buildTextField(_locationCtrl, 'Location', Icons.location_on),
              const SizedBox(height: 12),
            ],

            const SizedBox(height: 8),
            _buildToggleRow(),
            const SizedBox(height: 24),
            _buildPublishButton(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: DfcContentType.values.map((type) {
        final selected = _selectedType == type;
        final icon = _typeIcon(type);
        final color = _typeColor(type);
        return ChoiceChip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: selected ? Colors.black : color),
              const SizedBox(width: 4),
              Text(
                type.name.toUpperCase(),
                style: TextStyle(
                  color: selected ? Colors.black : color,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          selected: selected,
          selectedColor: color,
          backgroundColor: color.withValues(alpha: 0.1),
          side: BorderSide(color: color.withValues(alpha: 0.3)),
          onSelected: (_) => setState(() => _selectedType = type),
        );
      }).toList(),
    );
  }

  Widget _buildTextField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.white.withValues(alpha: 0.5),
          fontSize: 12,
        ),
        prefixIcon: Icon(icon, color: AppTheme.neonCyan, size: 18),
        filled: true,
        fillColor: DesignTokens.bgCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: AppTheme.neonCyan.withValues(alpha: 0.2),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: AppTheme.neonCyan.withValues(alpha: 0.2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppTheme.neonCyan),
        ),
      ),
      validator: label.endsWith('*')
          ? (v) => (v == null || v.isEmpty) ? 'Required' : null
          : null,
    );
  }

  Widget _buildToggleRow() {
    return Row(
      children: [
        _buildSwitch(
          'Featured',
          _isFeatured,
          AppTheme.neonOrange,
          (v) => setState(() => _isFeatured = v),
        ),
        const SizedBox(width: 16),
        _buildSwitch(
          'Breaking',
          _isBreaking,
          AppTheme.error,
          (v) => setState(() => _isBreaking = v),
        ),
      ],
    );
  }

  Widget _buildSwitch(
    String label,
    bool value,
    Color color,
    ValueChanged<bool> onChanged,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 12,
          ),
        ),
        const SizedBox(width: 4),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: color,
          inactiveTrackColor: Colors.white12,
        ),
      ],
    );
  }

  Widget _buildPublishButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        icon: _publishing
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.black,
                ),
              )
            : const Icon(Icons.publish, size: 20),
        label: Text(
          _publishing ? 'PUBLISHING...' : 'PUBLISH TO DFC',
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 14,
            letterSpacing: 1,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.neonCyan,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: _publishing ? null : _handlePublish,
      ),
    );
  }

  Future<void> _handlePublish() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _publishing = true);
    final user = FirebaseAuth.instance.currentUser;

    final content = PublishedContent(
      id: '',
      type: _selectedType,
      title: _titleCtrl.text.trim(),
      body: _bodyCtrl.text.trim(),
      imageUrl: _imageUrlCtrl.text.trim().isNotEmpty
          ? _imageUrlCtrl.text.trim()
          : null,
      promotion: _promotionCtrl.text.trim().isNotEmpty
          ? _promotionCtrl.text.trim()
          : null,
      location: _locationCtrl.text.trim().isNotEmpty
          ? _locationCtrl.text.trim()
          : null,
      date: _dateCtrl.text.trim().isNotEmpty ? _dateCtrl.text.trim() : null,
      mainEvent: _mainEventCtrl.text.trim().isNotEmpty
          ? _mainEventCtrl.text.trim()
          : null,
      broadcastInfo: _broadcastCtrl.text.trim().isNotEmpty
          ? _broadcastCtrl.text.trim()
          : null,
      ticketUrl: _ticketUrlCtrl.text.trim().isNotEmpty
          ? _ticketUrlCtrl.text.trim()
          : null,
      sportType: _sportTypeCtrl.text.trim().isNotEmpty
          ? _sportTypeCtrl.text.trim()
          : null,
      fightCount: int.tryParse(_fightCountCtrl.text.trim()),
      isFeatured: _isFeatured,
      isBreaking: _isBreaking,
      authorId: user?.uid ?? 'admin',
      authorName: user?.displayName ?? 'DFC Admin',
      createdAt: DateTime.now(),
    );

    final result = await _service.publish(content);
    setState(() => _publishing = false);

    if (result != null && mounted) {
      _clearForm();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Published "${result.title}" → Live on DFC now!'),
          backgroundColor: AppTheme.neonGreen.withValues(alpha: 0.9),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _clearForm() {
    _titleCtrl.clear();
    _bodyCtrl.clear();
    _imageUrlCtrl.clear();
    _promotionCtrl.clear();
    _locationCtrl.clear();
    _dateCtrl.clear();
    _mainEventCtrl.clear();
    _broadcastCtrl.clear();
    _ticketUrlCtrl.clear();
    _sportTypeCtrl.clear();
    _fightCountCtrl.clear();
    setState(() {
      _isFeatured = false;
      _isBreaking = false;
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 2: AI AUTONOMOUS FEEDER
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildAIFeederTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFeederStatusCard(),
          const SizedBox(height: 16),
          _buildFeederControlsCard(),
          const SizedBox(height: 16),
          _buildContentChannels(),
          const SizedBox(height: 16),
          _buildFeederLog(),
        ],
      ),
    );
  }

  Widget _buildFeederStatusCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: _feederRunning
              ? [
                  AppTheme.neonGreen.withValues(alpha: 0.15),
                  DesignTokens.bgCard,
                ]
              : [AppTheme.error.withValues(alpha: 0.1), DesignTokens.bgCard],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: _feederRunning
              ? AppTheme.neonGreen.withValues(alpha: 0.3)
              : AppTheme.error.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (_feederRunning ? AppTheme.neonGreen : AppTheme.error)
                      .withValues(alpha: 0.2),
                ),
                child: Icon(
                  _feederRunning ? Icons.smart_toy : Icons.smart_toy_outlined,
                  color: _feederRunning ? AppTheme.neonGreen : AppTheme.error,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _feederRunning ? 'AI FEEDER ACTIVE' : 'AI FEEDER OFFLINE',
                      style: TextStyle(
                        color: _feederRunning
                            ? AppTheme.neonGreen
                            : AppTheme.error,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _feederRunning
                          ? 'Auto-generating content every $_feederIntervalMinutes min'
                          : 'Tap START to begin autonomous publishing',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Text(
                    '$_itemsGenerated',
                    style: const TextStyle(
                      color: AppTheme.neonCyan,
                      fontWeight: FontWeight.w900,
                      fontSize: 24,
                    ),
                  ),
                  Text(
                    'PUBLISHED',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _miniStat(
                'News',
                _feedLog.where((i) => i.type == DfcContentType.news).length,
                AppTheme.neonCyan,
              ),
              _miniStat(
                'Signals',
                _feedLog.where((i) => i.type == DfcContentType.signal).length,
                AppTheme.neonMagenta,
              ),
              _miniStat(
                'Shows',
                _feedLog
                    .where((i) => i.type == DfcContentType.fightShow)
                    .length,
                AppTheme.neonOrange,
              ),
              _miniStat(
                'Posts',
                _feedLog.where((i) => i.type == DfcContentType.post).length,
                AppTheme.neonGreen,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          '$count',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildFeederControlsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: DesignTokens.bgCard,
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('FEEDER CONTROLS'),
          const SizedBox(height: 12),
          // Start / Stop button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              icon: Icon(
                _feederRunning ? Icons.stop_circle : Icons.play_circle_fill,
                size: 22,
              ),
              label: Text(
                _feederRunning ? 'STOP AI FEEDER' : 'START AI FEEDER',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  letterSpacing: 1,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _feederRunning
                    ? AppTheme.error
                    : AppTheme.neonGreen,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: _toggleFeeder,
            ),
          ),
          const SizedBox(height: 16),
          // Interval slider
          Row(
            children: [
              Text(
                'Interval:',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 12,
                ),
              ),
              Expanded(
                child: Slider(
                  value: _feederIntervalMinutes.toDouble(),
                  min: 5,
                  max: 120,
                  divisions: 23,
                  activeColor: AppTheme.neonCyan,
                  inactiveColor: Colors.white12,
                  label: '$_feederIntervalMinutes min',
                  onChanged: (v) =>
                      setState(() => _feederIntervalMinutes = v.round()),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: AppTheme.neonCyan.withValues(alpha: 0.15),
                ),
                child: Text(
                  '$_feederIntervalMinutes min',
                  style: const TextStyle(
                    color: AppTheme.neonCyan,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Generate one now
          OutlinedButton.icon(
            icon: const Icon(Icons.bolt, size: 16),
            label: const Text(
              'GENERATE ONE NOW',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.neonOrange,
              side: BorderSide(
                color: AppTheme.neonOrange.withValues(alpha: 0.4),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: _generateOneItem,
          ),
        ],
      ),
    );
  }

  Widget _buildContentChannels() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: DesignTokens.bgCard,
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('CONTENT CHANNELS'),
          const SizedBox(height: 4),
          Text(
            'Choose which types of content the AI auto-publishes',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 12),
          _channelToggle(
            'Fight News & Headlines',
            Icons.newspaper,
            AppTheme.neonCyan,
            _autoNews,
            (v) => setState(() => _autoNews = v),
          ),
          _channelToggle(
            'Fightwire Signals',
            Icons.bolt,
            AppTheme.neonMagenta,
            _autoSignals,
            (v) => setState(() => _autoSignals = v),
          ),
          _channelToggle(
            'Fight Show Announcements',
            Icons.event,
            AppTheme.neonOrange,
            _autoFightShows,
            (v) => setState(() => _autoFightShows = v),
          ),
          _channelToggle(
            'Social Posts',
            Icons.chat_bubble,
            AppTheme.neonGreen,
            _autoSocialPosts,
            (v) => setState(() => _autoSocialPosts = v),
          ),
        ],
      ),
    );
  }

  Widget _channelToggle(
    String label,
    IconData icon,
    Color color,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 13,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: color,
            inactiveTrackColor: Colors.white12,
          ),
        ],
      ),
    );
  }

  Widget _buildFeederLog() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: DesignTokens.bgCard,
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _sectionLabel('ACTIVITY LOG'),
              const Spacer(),
              if (_feedLog.isNotEmpty)
                TextButton(
                  onPressed: () => setState(_feedLog.clear),
                  child: Text(
                    'Clear',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                      fontSize: 10,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (_feedLog.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'No items generated yet.\nStart the feeder or tap "Generate One Now".',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontSize: 12,
                  ),
                ),
              ),
            )
          else
            ...List.generate(_feedLog.length > 20 ? 20 : _feedLog.length, (i) {
              final item = _feedLog[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: _typeColor(item.type).withValues(alpha: 0.06),
                  border: Border.all(
                    color: _typeColor(item.type).withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _typeIcon(item.type),
                      size: 14,
                      color: _typeColor(item.type),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${item.type.name.toUpperCase()} • ${_timeAgo(item.timestamp)}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.3),
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      item.published ? Icons.check_circle : Icons.error,
                      size: 14,
                      color: item.published
                          ? AppTheme.neonGreen
                          : AppTheme.error,
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 3: SOCIAL MEDIA — DFC Social Engine + Samurai Transform
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _runSocialMediaBackfill({required bool dryRun}) async {
    if (_mediaBackfillRunning) return;

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _mediaBackfillRunning = true);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          dryRun
              ? 'Scanning posts for media normalization...'
              : 'Running post media normalization backfill...',
        ),
        backgroundColor: DesignTokens.neonAmber,
      ),
    );

    try {
      final result = await _socialService.backfillNormalizedPostMedia(
        dryRun: dryRun,
      );
      if (!mounted) return;

      setState(() => _mediaBackfillResult = result);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            dryRun
                ? 'Scan complete: ${result.updatedCount} posts need normalization.'
                : 'Backfill complete: ${result.updatedCount} posts updated.',
          ),
          backgroundColor: AppTheme.neonGreen,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Media normalization failed: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _mediaBackfillRunning = false);
      }
    }
  }

  Widget _buildSocialMediaTab() {
    final pages = DfcSocialEngine.officialPages;
    final queue = _samurai.queue;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── CONNECTED PLATFORMS ──
        _sectionLabel('CONNECTED PLATFORMS'),
        const SizedBox(height: 8),
        SizedBox(
          height: 82,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: pages.length,
            itemBuilder: (ctx, i) {
              final page = pages[i];
              return Container(
                width: 140,
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: DesignTokens.bgSecondary,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _platformColor(page.platform).withValues(alpha: 0.4),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _platformIcon(page.platform),
                          size: 14,
                          color: _platformColor(page.platform),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            page.platform.toUpperCase(),
                            style: TextStyle(
                              color: _platformColor(page.platform),
                              fontWeight: FontWeight.w900,
                              fontSize: 9,
                              letterSpacing: 1,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppTheme.neonGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      page.pageName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (page.handle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        page.handle,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 9,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              '${pages.length} pages connected  •  ',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 10,
              ),
            ),
            Text(
              '${_selectedPlatforms.length} platforms active',
              style: const TextStyle(
                color: AppTheme.neonGreen,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // ── COMPOSE POST ──
        _sectionLabel('COMPOSE & TRANSFORM'),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: DesignTokens.bgSecondary,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.neonCyan.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _socialTitleCtrl,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: 'Headline / Title...',
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppTheme.neonCyan),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _socialBodyCtrl,
                maxLines: 4,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText:
                      'Write your post body here... or let Samurai AI transform it!',
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppTheme.neonCyan),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 8),

              // Content style selector
              Row(
                children: [
                  const Text(
                    'STYLE: ',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  ...[
                    ('promo', '📣'),
                    ('breaking', '🚨'),
                    ('hype', '🔥'),
                    ('event', '📅'),
                    ('training', '💪'),
                    ('editorial', '📰'),
                  ].map(
                    (s) => Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: ChoiceChip(
                        label: Text(
                          '${s.$2} ${s.$1.toUpperCase()}',
                          style: TextStyle(
                            fontSize: 9,
                            color: _socialContentStyle == s.$1
                                ? Colors.black
                                : Colors.white70,
                          ),
                        ),
                        selected: _socialContentStyle == s.$1,
                        selectedColor: AppTheme.neonCyan,
                        backgroundColor: DesignTokens.bgPrimary,
                        onSelected: (_) =>
                            setState(() => _socialContentStyle = s.$1),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Platform toggles
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children:
                    [
                      'facebook',
                      'instagram',
                      'tiktok',
                      'x',
                      'youtube',
                      'linkedin',
                      'snapchat',
                      'whatsapp',
                    ].map((p) {
                      final active = _selectedPlatforms.contains(p);
                      return FilterChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _platformIcon(p),
                              size: 12,
                              color: active ? Colors.black : _platformColor(p),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              p.toUpperCase(),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: active ? Colors.black : Colors.white70,
                              ),
                            ),
                          ],
                        ),
                        selected: active,
                        selectedColor: _platformColor(p),
                        backgroundColor: DesignTokens.bgPrimary,
                        onSelected: (val) {
                          setState(() {
                            if (val) {
                              _selectedPlatforms.add(p);
                            } else {
                              _selectedPlatforms.remove(p);
                            }
                          });
                        },
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      );
                    }).toList(),
              ),
              const SizedBox(height: 12),

              // Action buttons
              Row(
                children: [
                  // SAMURAI TRANSFORM
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _samurai.isTransforming
                          ? null
                          : () {
                              if (_socialTitleCtrl.text.isEmpty &&
                                  _socialBodyCtrl.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Enter a title or body first',
                                    ),
                                  ),
                                );
                                return;
                              }
                              setState(() {
                                _samurai.transform(
                                  title: _socialTitleCtrl.text,
                                  body: _socialBodyCtrl.text,
                                  contentStyle: _socialContentStyle,
                                );
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    '⚡ Samurai Transform complete — added to queue',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              _socialTitleCtrl.clear();
                              _socialBodyCtrl.clear();
                            },
                      icon: const Icon(Icons.auto_fix_high, size: 14),
                      label: const Text(
                        'SAMURAI TRANSFORM',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DesignTokens.neonAmber,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // DIRECT PUBLISH
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _socialPublishing
                          ? null
                          : () async {
                              if (_socialTitleCtrl.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Enter a title first'),
                                  ),
                                );
                                return;
                              }
                              setState(() => _socialPublishing = true);
                              final messenger = ScaffoldMessenger.of(context);
                              await _socialEngine.publishToAll(
                                title: _socialTitleCtrl.text,
                                body: _socialBodyCtrl.text,
                                targetPlatforms: _selectedPlatforms.toList(),
                              );
                              setState(() => _socialPublishing = false);
                              if (mounted) {
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '🚀 Published to ${_selectedPlatforms.length} platforms!',
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                              _socialTitleCtrl.clear();
                              _socialBodyCtrl.clear();
                            },
                      icon: _socialPublishing
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                          : const Icon(Icons.send, size: 14),
                      label: Text(
                        _socialPublishing ? 'PUBLISHING...' : 'PUBLISH NOW',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.neonCyan,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // ── AI ENGINE BULK ACTIONS ──
        _sectionLabel('AI ENGINE ACTIONS'),
        const SizedBox(height: 8),
        Row(
          children: [
            // SCAN ALL ENGINES
            Expanded(
              child: _socialActionButton(
                icon: Icons.radar,
                label: 'SCAN ALL ENGINES',
                color: AppTheme.neonMagenta,
                onTap: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('⚡ Scanning all AI engines...'),
                    ),
                  );
                  final results = await _samurai.transformFromAllEngines();
                  setState(() {});
                  if (mounted) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          '🔥 ${results.length} items transformed and queued!',
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            // FIRE ALL APPROVED
            Expanded(
              child: _socialActionButton(
                icon: Icons.local_fire_department,
                label: 'FIRE ALL (${_samurai.approvedQueue.length})',
                color: AppTheme.error,
                onTap: _samurai.approvedQueue.isEmpty
                    ? null
                    : () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final count = await _samurai.fireAll();
                        setState(() {});
                        if (mounted) {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                '🚀 $count posts blasted across all platforms!',
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            // PROMO BLAST
            Expanded(
              child: _socialActionButton(
                icon: Icons.campaign,
                label: 'PROMO BLAST',
                color: DesignTokens.neonAmber,
                onTap: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  await _socialEngine.firePromoBlast(
                    headline: 'DFC Promotional Blast',
                    description:
                        'DataFightCentral — The Promotional Engine for Combat Sports. Fighters, promoters, fans — your platform is LIVE. AI-powered, global, unstoppable. 🥊⚡',
                  );
                  setState(() {});
                  if (mounted) {
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text(
                          '📣 Random promo blast fired to all platforms!',
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            // PLATFORM LAUNCH CAMPAIGN
            Expanded(
              child: _socialActionButton(
                icon: Icons.rocket_launch,
                label: 'LAUNCH CAMPAIGN',
                color: DesignTokens.neonGold,
                onTap: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final results = await _samurai
                      .generatePlatformPromoCampaign();
                  setState(() {});
                  if (mounted) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          '🚀 ${results.length} campaign posts generated!',
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // ── NORMALIZE LEGACY POST MEDIA ──
        _sectionLabel('POST MEDIA NORMALIZATION'),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: DesignTokens.bgSecondary,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.neonCyan.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Scan or backfill existing posts so older records inherit normalized mediaUrls, mediaTypes, thumbnails, and external video metadata.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontSize: 11,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _socialActionButton(
                      icon: Icons.preview,
                      label: 'DRY RUN SCAN',
                      color: DesignTokens.neonAmber,
                      onTap: _mediaBackfillRunning
                          ? null
                          : () => _runSocialMediaBackfill(dryRun: true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _socialActionButton(
                      icon: Icons.cleaning_services,
                      label: 'RUN BACKFILL',
                      color: AppTheme.neonGreen,
                      onTap: _mediaBackfillRunning
                          ? null
                          : () => _runSocialMediaBackfill(dryRun: false),
                    ),
                  ),
                ],
              ),
              if (_mediaBackfillRunning) ...[
                const SizedBox(height: 12),
                const LinearProgressIndicator(
                  minHeight: 3,
                  color: AppTheme.neonCyan,
                  backgroundColor: Colors.white12,
                ),
              ],
              if (_mediaBackfillResult != null) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _statPill(
                      'MODE',
                      _mediaBackfillResult!.dryRun ? 'DRY' : 'LIVE',
                      _mediaBackfillResult!.dryRun
                          ? DesignTokens.neonAmber
                          : AppTheme.neonGreen,
                    ),
                    _statPill(
                      'SCANNED',
                      '${_mediaBackfillResult!.scannedCount}',
                      AppTheme.neonCyan,
                    ),
                    _statPill(
                      _mediaBackfillResult!.dryRun ? 'NEEDS WORK' : 'UPDATED',
                      '${_mediaBackfillResult!.updatedCount}',
                      _mediaBackfillResult!.dryRun
                          ? DesignTokens.neonAmber
                          : AppTheme.neonGreen,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _mediaBackfillResult!.dryRun
                      ? 'Dry run only. No Firestore writes were made.'
                      : 'Live backfill complete. Normalized media fields were written to matching posts.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 10,
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 20),

        // ── SAMURAI STATS ──
        _sectionLabel('SAMURAI ENGINE STATUS'),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: DesignTokens.bgSecondary,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statPill(
                'TRANSFORMED',
                '${_samurai.totalTransformed}',
                DesignTokens.neonAmber,
              ),
              _statPill('QUEUED', '${_samurai.queueSize}', AppTheme.neonCyan),
              _statPill(
                'APPROVED',
                '${_samurai.approvedQueue.length}',
                AppTheme.neonGreen,
              ),
              _statPill(
                'PUBLISHED',
                '${_samurai.totalPublished}',
                AppTheme.neonMagenta,
              ),
            ],
          ),
        ),

        // ── AUTO MODE TOGGLE ──
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: DesignTokens.bgSecondary,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(
                _samurai.autoMode ? Icons.autorenew : Icons.pause_circle,
                color: _samurai.autoMode ? AppTheme.neonGreen : Colors.white38,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _samurai.autoMode
                      ? 'AUTO MODE ON — Scanning every 15 min'
                      : 'AUTO MODE OFF',
                  style: TextStyle(
                    color: _samurai.autoMode
                        ? AppTheme.neonGreen
                        : Colors.white54,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
              Switch(
                value: _samurai.autoMode,
                onChanged: (val) {
                  setState(() {
                    if (val) {
                      _samurai.startAutoMode();
                    } else {
                      _samurai.stopAutoMode();
                    }
                  });
                },
                activeThumbColor: AppTheme.neonGreen,
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // ── TRANSFORM QUEUE ──
        _sectionLabel('TRANSFORM QUEUE (${queue.length})'),
        const SizedBox(height: 8),
        if (queue.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: DesignTokens.bgSecondary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Text(
                'No transformed content yet.\nCompose a post or scan AI engines above.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ),
          )
        else
          ...queue
              .take(20)
              .map(
                (item) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: DesignTokens.bgSecondary,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: item.published
                          ? AppTheme.neonGreen.withValues(alpha: 0.3)
                          : item.approved
                          ? DesignTokens.neonAmber.withValues(alpha: 0.3)
                          : Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _styleColor(
                                item.contentStyle,
                              ).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              item.contentStyle.toUpperCase(),
                              style: TextStyle(
                                color: _styleColor(item.contentStyle),
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              item.sourceEngine.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const Spacer(),
                          // Hype score badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _hypeColor(
                                item.hypeScore,
                              ).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '🔥 ${(item.hypeScore * 100).toInt()}%',
                              style: TextStyle(
                                color: _hypeColor(item.hypeScore),
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          if (item.published) ...[
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.check_circle,
                              color: AppTheme.neonGreen,
                              size: 16,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.transformedHeadline,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.transformedBody,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 11,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      // Hashtags
                      if (item.generatedHashtags.isNotEmpty)
                        Wrap(
                          spacing: 4,
                          runSpacing: 2,
                          children: item.generatedHashtags
                              .take(6)
                              .map(
                                (t) => Text(
                                  '#$t',
                                  style: const TextStyle(
                                    color: AppTheme.neonCyan,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      if (!item.published) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            if (!item.approved)
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () =>
                                      setState(() => _samurai.approve(item.id)),
                                  icon: const Icon(Icons.thumb_up, size: 12),
                                  label: const Text(
                                    'APPROVE',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppTheme.neonGreen,
                                    side: const BorderSide(
                                      color: AppTheme.neonGreen,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 6,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                ),
                              ),
                            if (!item.approved) const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  final messenger = ScaffoldMessenger.of(
                                    context,
                                  );
                                  await _samurai.publishToSocial(item.id);
                                  setState(() {});
                                  if (mounted) {
                                    messenger.showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          '🚀 Published to all platforms!',
                                        ),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.send, size: 12),
                                label: const Text(
                                  'PUBLISH',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.neonCyan,
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 6,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),

        const SizedBox(height: 32),
      ],
    );
  }

  Widget _socialActionButton({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Material(
      color: DesignTokens.bgSecondary,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statPill(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: color.withValues(alpha: 0.7),
            fontSize: 8,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  IconData _platformIcon(String platform) {
    switch (platform) {
      case 'facebook':
        return Icons.facebook;
      case 'instagram':
        return Icons.camera_alt;
      case 'tiktok':
        return Icons.music_note;
      case 'x':
        return Icons.tag;
      case 'youtube':
        return Icons.play_circle;
      case 'linkedin':
        return Icons.business;
      case 'snapchat':
        return Icons.lens_blur;
      case 'whatsapp':
        return Icons.chat;
      default:
        return Icons.public;
    }
  }

  Color _platformColor(String platform) {
    switch (platform) {
      case 'facebook':
        return const Color(0xFF1877F2);
      case 'instagram':
        return const Color(0xFFE4405F);
      case 'tiktok':
        return const Color(0xFF00F2EA);
      case 'x':
        return Colors.white;
      case 'youtube':
        return const Color(0xFFFF0000);
      case 'linkedin':
        return const Color(0xFF0A66C2);
      case 'snapchat':
        return const Color(0xFFFFFC00);
      case 'whatsapp':
        return const Color(0xFF25D366);
      default:
        return AppTheme.neonCyan;
    }
  }

  Color _styleColor(String style) {
    switch (style) {
      case 'breaking':
        return AppTheme.error;
      case 'hype':
        return DesignTokens.neonAmber;
      case 'event':
        return AppTheme.neonMagenta;
      case 'training':
        return AppTheme.neonGreen;
      case 'editorial':
        return AppTheme.neonCyan;
      default:
        return DesignTokens.neonGold;
    }
  }

  Color _hypeColor(double score) {
    if (score >= 0.8) return AppTheme.error;
    if (score >= 0.6) return DesignTokens.neonAmber;
    return AppTheme.neonGreen;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 4: MANAGE CONTENT
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildManageTab() {
    return Column(
      children: [
        // Filter chips
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _filterChip('All', null),
                ...DfcContentType.values.map(
                  (t) => _filterChip(t.name.toUpperCase(), t),
                ),
              ],
            ),
          ),
        ),
        // Content list
        Expanded(
          child: ListenableBuilder(
            listenable: _service,
            builder: (context, _) {
              if (_service.loading) {
                return const Center(
                  child: CircularProgressIndicator(color: AppTheme.neonCyan),
                );
              }

              final filtered = _filterType == null
                  ? _service.items
                  : _service.items.where((c) => c.type == _filterType).toList();

              if (filtered.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.inbox,
                        size: 48,
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No content published yet',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.3),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Use the PUBLISH or AI FEEDER tabs to create content',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.2),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () => _service.loadAll(filterType: _filterType),
                color: AppTheme.neonCyan,
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) => _buildContentCard(filtered[i]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _filterChip(String label, DfcContentType? type) {
    final selected = _filterType == type;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.black : Colors.white54,
          ),
        ),
        selected: selected,
        selectedColor: AppTheme.neonCyan,
        backgroundColor: DesignTokens.bgCard,
        side: const BorderSide(color: Colors.white12),
        onSelected: (_) {
          setState(() => _filterType = type);
          _service.loadAll(filterType: type);
        },
      ),
    );
  }

  Widget _buildContentCard(PublishedContent item) {
    final color = _typeColor(item.type);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: DesignTokens.bgCard,
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: color.withValues(alpha: 0.15),
          ),
          child: Icon(_typeIcon(item.type), color: color, size: 20),
        ),
        title: Text(
          item.title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${item.type.name.toUpperCase()} • ${_timeAgo(item.createdAt)}'
          '${item.isFeatured ? ' • ⭐ Featured' : ''}'
          '${item.isBreaking ? ' • 🔴 Breaking' : ''}',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 10,
          ),
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(
            Icons.more_vert,
            color: Colors.white.withValues(alpha: 0.3),
            size: 18,
          ),
          color: DesignTokens.bgSecondary,
          onSelected: (v) => _handleAction(v, item),
          itemBuilder: (_) => [
            PopupMenuItem(
              value: 'feature',
              child: Text(
                item.isFeatured ? 'Remove Featured' : 'Mark Featured',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
            PopupMenuItem(
              value: 'draft',
              child: Text(
                item.isPublished ? 'Unpublish (Draft)' : 'Publish',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Text(
                'Delete',
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleAction(String action, PublishedContent item) {
    switch (action) {
      case 'feature':
        _service.toggleFeatured(item.id, !item.isFeatured);
        break;
      case 'draft':
        _service.togglePublished(item.id, !item.isPublished);
        break;
      case 'delete':
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: DesignTokens.bgSecondary,
            title: const Text(
              'Delete Content',
              style: TextStyle(color: Colors.white),
            ),
            content: Text(
              'Delete "${item.title}"?',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  _service.delete(item.id);
                  Navigator.pop(ctx);
                },
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        );
        break;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // AI FEEDER ENGINE
  // ═══════════════════════════════════════════════════════════════════════════

  void _toggleFeeder() {
    if (_feederRunning) {
      _feederTimer?.cancel();
      _feederTimer = null;
      setState(() => _feederRunning = false);
    } else {
      setState(() => _feederRunning = true);
      _generateOneItem(); // Immediate first item
      _feederTimer = Timer.periodic(
        Duration(minutes: _feederIntervalMinutes),
        (_) => _generateOneItem(),
      );
    }
  }

  Future<void> _generateOneItem() async {
    final enabledTypes = <DfcContentType>[];
    if (_autoNews) enabledTypes.add(DfcContentType.news);
    if (_autoSignals) enabledTypes.add(DfcContentType.signal);
    if (_autoFightShows) enabledTypes.add(DfcContentType.fightShow);
    if (_autoSocialPosts) enabledTypes.add(DfcContentType.post);

    if (enabledTypes.isEmpty) return;

    final rng = math.Random();
    final type = enabledTypes[rng.nextInt(enabledTypes.length)];
    final generated = _aiGenerateContent(type, rng);

    final user = FirebaseAuth.instance.currentUser;
    final content = PublishedContent(
      id: '',
      type: type,
      title: generated['title']!,
      body: generated['body']!,
      imageUrl: generated['imageUrl'],
      promotion: generated['promotion'],
      location: generated['location'],
      mainEvent: generated['mainEvent'],
      broadcastInfo: generated['broadcastInfo'],
      isFeatured: rng.nextDouble() > 0.7,
      isBreaking: type == DfcContentType.news && rng.nextDouble() > 0.85,
      authorId: user?.uid ?? 'ai-feeder',
      authorName: 'DFC AI Engine',
      createdAt: DateTime.now(),
    );

    final result = await _service.publish(content);
    setState(() {
      _itemsGenerated++;
      _feedLog.insert(
        0,
        _AIFeedItem(
          title: generated['title']!,
          type: type,
          timestamp: DateTime.now(),
          published: result != null,
        ),
      );
    });
  }

  Map<String, String?> _aiGenerateContent(
    DfcContentType type,
    math.Random rng,
  ) {
    switch (type) {
      case DfcContentType.news:
        return _newsTemplates[rng.nextInt(_newsTemplates.length)];
      case DfcContentType.signal:
        return _signalTemplates[rng.nextInt(_signalTemplates.length)];
      case DfcContentType.fightShow:
        return _fightShowTemplates[rng.nextInt(_fightShowTemplates.length)];
      case DfcContentType.post:
        return _postTemplates[rng.nextInt(_postTemplates.length)];
      default:
        return _newsTemplates[rng.nextInt(_newsTemplates.length)];
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // AI CONTENT TEMPLATES — Combat Sports News Engine
  // ═══════════════════════════════════════════════════════════════════════════

  static final _newsTemplates = <Map<String, String?>>[
    {
      'title':
          'UFC Perth 2026: Della Maddalena vs Prates — Full Card Announced',
      'body':
          'The UFC has officially announced the full fight card for its first-ever event in Perth, Western Australia. Local hero Jack Della Maddalena will headline against Carlos "The Nightmare" Prates in a welterweight showdown at RAC Arena. The event features 13 bouts including several Australian fighters.',
      'imageUrl': ImageAssets.bgAction,
    },
    {
      'title':
          'Ultimate Legends Fight Night Returns to Melbourne Pavilion — WBC Silver Title on the Line',
      'body':
          'Joey Demicoli and John Scida\'s Ultimate Legends Promotions returns April 24th with a WBC Silver Australian Title fight headlining an action-packed card of pro Boxing, K1, Kickboxing & Muay Thai. Main Event: Jordan Roesler — trained by Scida since childhood, cornered by his father James Roesler. A father-and-son legacy 30+ years in the making. Melbourne\'s longest-running combat sports promotion (est. 1992) continues its legacy. Live on Live Combat Sports.',
      'imageUrl': ImageAssets.bgEvent,
    },
    {
      'title':
          'International Brawling Championship Expands to Las Vegas — IBC 04 Confirmed',
      'body':
          'Gold Coast entrepreneur Danny Mac confirms IBC is heading to the fight capital of the world. After sold-out events in Australia, the closed-fist hybrid format goes global with IBC 04 in Las Vegas. Live on TrillerTV+ PPV.',
      'imageUrl': ImageAssets.bgSquare,
    },
    {
      'title': 'Eternal MMA 80 Perth: Stacked 16-Fight Card at HBF Stadium',
      'body':
          'Australia\'s premier MMA promotion Eternal MMA brings a monster card to Perth with a WA vs QLD superfight series headlining 16 bouts. Live on UFC Fight Pass.',
      'imageUrl': ImageAssets.bgHero,
    },
    {
      'title': 'Australia\'s 2026 Combat Sports Calendar: 48 Shows Nationwide',
      'body':
          'From UFC Perth to Ultimate Legends Melbourne to IBC Gold Coast to Elite Fight Series Cairns — Australia\'s fight calendar has never been more stacked. 48 confirmed events across Boxing, MMA, Muay Thai, Kickboxing, K1 and Brawling.',
      'imageUrl': ImageAssets.bgCentral,
    },
    {
      'title':
          'ONE Championship 170: Superlek vs Takeru Headlines Bangkok Mega-Event',
      'body':
          'The most anticipated kickboxing fight of 2026. Superlek Kiatmookao defends his ONE Flyweight Kickboxing title against K-1 legend Takeru at Impact Arena, Bangkok. Amazon Prime PPV worldwide.',
      'imageUrl': ImageAssets.bgPromo,
    },
    {
      'title': 'Empire Fight Series: WA vs QLD National Muay Thai Showdown',
      'body':
          'Cian Lougheed (WA) takes on Jaga Chan in the biggest domestic Muay Thai fight of the year at Claremont Showground, Perth. Empire Fight Series: Inception 5 features 12 pro bouts.',
      'imageUrl': ImageAssets.bgLogo1024,
    },
    {
      'title': 'Naoya Inoue Eyes Third Weight Class — The Monster Unstoppable',
      'body':
          'Japan\'s Naoya "The Monster" Inoue continues his legendary run, confirming plans to campaign at super bantamweight after unifying all four belts. Boxing\'s pound-for-pound king shows no signs of slowing.',
      'imageUrl': ImageAssets.bgEvent,
    },
    {
      'title': 'PFL Australia Confirmed: Rob Wilkinson Headlines Sydney Card',
      'body':
          'The Professional Fighters League officially expands to Australia with PFL Australia at ICC Sydney. Local stars Rob Wilkinson and Sean Gauci feature. Live on ESPN/ESPN+.',
      'imageUrl': ImageAssets.bgAction,
    },
    {
      'title':
          'Jai Opetaia IBF Cruiserweight Title Defense Set for Qudos Bank Arena, Sydney',
      'body':
          'Australia\'s IBF Cruiserweight Champion Jai Opetaia will defend his title on home soil at Qudos Bank Arena. The undefeated Sydneysider looks to cement his legacy. Live on DAZN and Kayo Sports.',
      'imageUrl': ImageAssets.bgResized,
    },
  ];

  static final _signalTemplates = <Map<String, String?>>[
    {
      'title': 'BREAKING: New bout added to Ultimate Legends April 24 card',
      'body':
          'Ultimate Legends confirms additional pro boxing bout for the Melbourne Pavilion fight night. Full card to be announced this week. Contact Joey Demicoli for tickets.',
      'location': 'Melbourne, VIC',
    },
    {
      'title': 'Jordan Roesler — Father-Son Legacy Headlines WBC Silver Title',
      'body':
          'Jordan Roesler headlines April 24 at Melbourne Pavilion for the WBC Silver Australian Title. Father James Roesler in the corner. Trained under John Scida since the Ultimate Muay Thai era. Joey Demicoli co-promoting. This is generational. Live on Live Combat Sports.',
      'location': 'Melbourne, VIC',
    },
    {
      'title': 'UFC Perth early bird tickets SOLD OUT in 3 hours',
      'body':
          'Massive demand for UFC\'s first Perth event. General sale opens next week. Della Maddalena vs Prates headliner driving unprecedented local interest.',
      'location': 'Perth, WA',
    },
    {
      'title': 'IBC 03 weigh-ins confirmed — All fighters on weight',
      'body':
          'International Brawling Championship 03 Gold Coast tomorrow. Full card cleared at weigh-ins. Hardman vs TBA main event. TrillerTV+ & Kayo Sports.',
      'location': 'Gold Coast, QLD',
    },
    {
      'title': 'Eternal MMA 80 fight card update: Two bouts added',
      'body':
          'Eternal MMA adds two exciting WA fighters to the Perth card. Now 16 bouts confirmed for HBF Stadium. Get tickets at eternalmma.com.',
      'location': 'Perth, WA',
    },
    {
      'title': 'Elite Fight Series Cairns: Poster Drop + Ticket Link',
      'body':
          'Official poster revealed for North QLD\'s biggest fight show. 12 bouts of MMA, Muay Thai & Boxing at Cairns Convention Centre. Livestreamed by Cairns Post.',
      'location': 'Cairns, QLD',
    },
    {
      'title': 'DFC x Ultimate Legends Partnership LIVE',
      'body':
          'DataFightCentral officially partners with Melbourne\'s Ultimate Legends Promotions. WBC Silver Australian Title fight night April 24. The Promotional Engine is powered up.',
      'location': 'Melbourne, VIC',
    },
  ];

  static final _fightShowTemplates = <Map<String, String?>>[
    {
      'title': 'ULTIMATE LEGENDS FIGHT NIGHT: WBC Silver Australian Title',
      'body':
          'Melbourne Pavilion • April 24, 2026 • Pro Boxing, K1, Kickboxing & Muay Thai. Main Event: Jordan Roesler — WBC Silver Australian Title. Father James Roesler in the corner. Promoted by Joey Demicoli & John Scida. Trained under Scida since the Ultimate Muay Thai days. Live on Live Combat Sports.',
      'promotion': 'Ultimate Legends',
      'location': 'Melbourne Pavilion, VIC',
      'mainEvent': 'Jordan Roesler — WBC Silver Australian Title',
      'broadcastInfo': 'Live Combat Sports',
    },
    {
      'title': 'IBC 03: International Brawling Championship — Gold Coast',
      'body':
          'Closed-fist hybrid format returns. No grappling, all action. Danny Mac\'s IBC at Gold Coast Convention Centre. Live on TrillerTV+ & Kayo Sports PPV.',
      'promotion': 'IBC',
      'location': 'Gold Coast Convention Centre, QLD',
      'mainEvent': 'Issac Hardman vs TBA',
      'broadcastInfo': 'TrillerTV+ / Kayo Sports PPV',
    },
    {
      'title': 'ETERNAL MMA 80: Perth — WA vs QLD Superfight Series',
      'body':
          '16-fight card at HBF Stadium. Australia\'s premier MMA promotion. Feature bouts include WA vs QLD interstate rivalries.',
      'promotion': 'Eternal MMA',
      'location': 'HBF Stadium, Perth, WA',
      'mainEvent': 'WA vs QLD Superfight Series',
      'broadcastInfo': 'UFC Fight Pass',
    },
    {
      'title': 'ELITE FIGHT SERIES: CAIRNS — North QLD Fight Night',
      'body':
          '12 bouts of explosive MMA, Muay Thai & Boxing from Far North Queensland. Livestreamed by Cairns Post.',
      'promotion': 'Elite Fight Series',
      'location': 'Cairns Convention Centre, QLD',
      'mainEvent': 'North QLD\'s Best',
      'broadcastInfo': 'Cairns Post Livestream',
    },
  ];

  static final _postTemplates = <Map<String, String?>>[
    {
      'title': '🥊 Ultimate Legends April 24 — Who\'s coming?',
      'body':
          'WBC Silver Australian Title at Melbourne Pavilion! Jordan Roesler main event. Pro Boxing, K1, Kickboxing & Muay Thai. 30+ years of fight history. Tag a mate who needs to be there! #UltimateLegends #WBCSilver #MelbourneFights #DFC',
      'imageUrl': ImageAssets.bgEvent,
    },
    {
      'title': '🇦🇺 Australian combat sports is BOOMING in 2026',
      'body':
          'UFC Perth, IBC Gold Coast, Eternal MMA, Ultimate Legends Melbourne, Empire Fight Series — this is the golden era of Australian fighting. Which show are you most hyped for? Drop your pick below 👇 #AusFighting #CombatSportsAustralia #DFC',
      'imageUrl': ImageAssets.bgCentral,
    },
    {
      'title': '💪 Training camp vibes — 7 weeks out',
      'body':
          'Every champion was once a contender who refused to give up. Put in the work today so you can shine on fight night. Tag your training partner! 🥊 #FightCamp #TrainHard #CombatSports #DFC',
      'imageUrl': ImageAssets.bgAction,
    },
    {
      'title': '🔥 IBC is the future of combat sports',
      'body':
          'No hugging, no stalling, just FISTS. Danny Mac\'s International Brawling Championship is changing the game. IBC 03 on the Gold Coast was INSANE. Who watched? 🇦🇺🥊 #IBCBrawling #GoldCoast #DFC',
      'imageUrl': ImageAssets.bgSquare,
    },
    {
      'title': '📣 Promoters: Get your fight shows on DFC FREE',
      'body':
          'DataFightCentral is the Promotional Engine for Combat Sports. Upload your event, reach thousands of fight fans, livestream integration, PPV support. Contact us to get started. #DFC #PromotionalEngine #FightPromoters',
      'imageUrl': ImageAssets.bgHero,
    },
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        color: AppTheme.neonCyan.withValues(alpha: 0.8),
        fontWeight: FontWeight.w900,
        fontSize: 11,
        letterSpacing: 1.5,
      ),
    );
  }

  IconData _typeIcon(DfcContentType type) {
    switch (type) {
      case DfcContentType.news:
        return Icons.newspaper;
      case DfcContentType.fightShow:
        return Icons.event;
      case DfcContentType.post:
        return Icons.chat_bubble;
      case DfcContentType.event:
        return Icons.stadium;
      case DfcContentType.ppv:
        return Icons.live_tv;
      case DfcContentType.signal:
        return Icons.bolt;
    }
  }

  Color _typeColor(DfcContentType type) {
    switch (type) {
      case DfcContentType.news:
        return AppTheme.neonCyan;
      case DfcContentType.fightShow:
        return AppTheme.neonOrange;
      case DfcContentType.post:
        return AppTheme.neonGreen;
      case DfcContentType.event:
        return AppTheme.neonMagenta;
      case DfcContentType.ppv:
        return DesignTokens.neonGold;
      case DfcContentType.signal:
        return AppTheme.neonMagenta;
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 5: MANUAL WORKSHOP (WAREHOUSE + AGENT COMMAND)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildWorkshopTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionLabel('SUPersonic WORKSHOP — CONTENT WAREHOUSE'),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: DesignTokens.bgSecondary,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.neonCyan.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _assetTitleCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Asset Title',
                  labelStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                  prefixIcon: const Icon(
                    Icons.title,
                    color: AppTheme.neonCyan,
                    size: 16,
                  ),
                  border: _workshopInputBorder(),
                  enabledBorder: _workshopInputBorder(),
                  focusedBorder: _workshopInputFocusedBorder(),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _assetUrlCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Image / Video URL',
                        labelStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                        prefixIcon: const Icon(
                          Icons.link,
                          color: AppTheme.neonCyan,
                          size: 16,
                        ),
                        border: _workshopInputBorder(),
                        enabledBorder: _workshopInputBorder(),
                        focusedBorder: _workshopInputFocusedBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: DesignTokens.bgPrimary,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: DropdownButton<String>(
                      value: _assetType,
                      dropdownColor: DesignTokens.bgSecondary,
                      underline: const SizedBox.shrink(),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      items: const [
                        DropdownMenuItem(value: 'image', child: Text('IMAGE')),
                        DropdownMenuItem(value: 'video', child: Text('VIDEO')),
                        DropdownMenuItem(
                          value: 'caption',
                          child: Text('CAPTION'),
                        ),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => _assetType = v);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _assetNotesCtrl,
                maxLines: 2,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Notes / Instructions for Agents',
                  labelStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                  prefixIcon: const Icon(
                    Icons.menu_book,
                    color: AppTheme.neonCyan,
                    size: 16,
                  ),
                  border: _workshopInputBorder(),
                  enabledBorder: _workshopInputBorder(),
                  focusedBorder: _workshopInputFocusedBorder(),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (_assetTitleCtrl.text.trim().isEmpty) return;
                    setState(() {
                      _workshopAssets.insert(
                        0,
                        _WorkshopAsset(
                          title: _assetTitleCtrl.text.trim(),
                          url: _assetUrlCtrl.text.trim(),
                          type: _assetType,
                          notes: _assetNotesCtrl.text.trim(),
                          createdAt: DateTime.now(),
                        ),
                      );
                      _assetTitleCtrl.clear();
                      _assetUrlCtrl.clear();
                      _assetNotesCtrl.clear();
                    });
                  },
                  icon: const Icon(Icons.add_box, size: 16),
                  label: const Text(
                    'ADD TO WAREHOUSE',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.neonCyan,
                    foregroundColor: Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),
        _sectionLabel('AGENT COMMAND DECK'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _socialActionButton(
                icon: Icons.refresh,
                label: 'FORCE PUMP',
                color: AppTheme.neonGreen,
                onTap: _workshopBusy
                    ? null
                    : () async {
                        setState(() => _workshopBusy = true);
                        await _swarm.forcePump();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('⚔️ Swarm content pump executed'),
                            ),
                          );
                        }
                        setState(() => _workshopBusy = false);
                      },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _socialActionButton(
                icon: Icons.local_fire_department,
                label: 'FIRE ALL',
                color: AppTheme.error,
                onTap: _workshopBusy
                    ? null
                    : () async {
                        setState(() => _workshopBusy = true);
                        await _swarm.fireAll();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                '🔥 Fire-all signal sent to social engine',
                              ),
                            ),
                          );
                        }
                        setState(() => _workshopBusy = false);
                      },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: _socialActionButton(
            icon: Icons.hive,
            label: 'MEGA SEED ALL PAGES',
            color: DesignTokens.neonAmber,
            onTap: _workshopBusy
                ? null
                : () async {
                    setState(() => _workshopBusy = true);
                    final total = await _swarm.seedAllPages();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '🚀 Seeded $total items across DFC pages',
                          ),
                        ),
                      );
                    }
                    setState(() => _workshopBusy = false);
                  },
          ),
        ),

        const SizedBox(height: 16),
        _sectionLabel('WAREHOUSE INVENTORY (${_workshopAssets.length})'),
        const SizedBox(height: 8),
        if (_workshopAssets.isEmpty)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: DesignTokens.bgSecondary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'No assets loaded yet. Add image/video/caption blocks above, then use FORCE PUMP or FIRE ALL.',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          )
        else
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _workshopBusy
                          ? null
                          : () async {
                              setState(() => _workshopBusy = true);
                              int routed = 0;
                              for (final asset in _workshopAssets.take(10)) {
                                await _routeAssetToSamurai(asset);
                                routed++;
                              }
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '⚔️ Routed $routed assets to approved Samurai queue',
                                    ),
                                  ),
                                );
                              }
                              setState(() => _workshopBusy = false);
                            },
                      icon: const Icon(Icons.queue, size: 14),
                      label: const Text(
                        'ROUTE TOP 10',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.neonGreen,
                        side: const BorderSide(color: AppTheme.neonGreen),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _workshopBusy
                          ? null
                          : () async {
                              setState(() => _workshopBusy = true);
                              int pushed = 0;
                              for (final asset in _workshopAssets.take(5)) {
                                await _routeAssetToSamurai(
                                  asset,
                                  autoPublish: true,
                                );
                                pushed++;
                              }
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '🚀 Routed + pushed $pushed assets live',
                                    ),
                                  ),
                                );
                              }
                              setState(() => _workshopBusy = false);
                            },
                      icon: const Icon(Icons.rocket_launch, size: 14),
                      label: const Text(
                        'PUSH TOP 5 LIVE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.neonCyan,
                        foregroundColor: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ..._workshopAssets
                  .take(20)
                  .map(
                    (asset) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: DesignTokens.bgSecondary,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppTheme.neonCyan.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            asset.type == 'video'
                                ? Icons.movie
                                : asset.type == 'caption'
                                ? Icons.short_text
                                : Icons.image,
                            color: AppTheme.neonCyan,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  asset.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                                if (asset.notes.isNotEmpty)
                                  Text(
                                    asset.notes,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.65,
                                      ),
                                      fontSize: 10,
                                    ),
                                  ),
                                Text(
                                  '${asset.type.toUpperCase()} • ${_timeAgo(asset.createdAt)}',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.35),
                                    fontSize: 9,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: _workshopBusy
                                            ? null
                                            : () async {
                                                setState(
                                                  () => _workshopBusy = true,
                                                );
                                                await _routeAssetToSamurai(
                                                  asset,
                                                );
                                                if (mounted) {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        '✅ Routed to approved Samurai queue',
                                                      ),
                                                    ),
                                                  );
                                                }
                                                setState(
                                                  () => _workshopBusy = false,
                                                );
                                              },
                                        icon: const Icon(Icons.queue, size: 12),
                                        label: const Text(
                                          'QUEUE',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppTheme.neonGreen,
                                          side: const BorderSide(
                                            color: AppTheme.neonGreen,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 6,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: _workshopBusy
                                            ? null
                                            : () async {
                                                setState(
                                                  () => _workshopBusy = true,
                                                );
                                                await _routeAssetToSamurai(
                                                  asset,
                                                  autoPublish: true,
                                                );
                                                if (mounted) {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        '🚀 Routed + published from Samurai queue',
                                                      ),
                                                    ),
                                                  );
                                                }
                                                setState(
                                                  () => _workshopBusy = false,
                                                );
                                              },
                                        icon: const Icon(Icons.send, size: 12),
                                        label: const Text(
                                          'PUSH LIVE',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.neonCyan,
                                          foregroundColor: Colors.black,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 6,
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
                      ),
                    ),
                  ),
            ],
          ),

        const SizedBox(height: 16),
        _sectionLabel('PROMOTER PLAYBOOKS'),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: DesignTokens.bgSecondary,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '1) Load assets into Warehouse (image/video/caption)',
                style: TextStyle(color: Colors.white70, fontSize: 11),
              ),
              SizedBox(height: 4),
              Text(
                '2) Set event countdown ladder: 1 month → 3w → 2w → 1w → days → hours',
                style: TextStyle(color: Colors.white70, fontSize: 11),
              ),
              SizedBox(height: 4),
              Text(
                '3) Use FORCE PUMP to draft content, approve in SOCIAL tab, then FIRE ALL',
                style: TextStyle(color: Colors.white70, fontSize: 11),
              ),
              SizedBox(height: 4),
              Text(
                '4) Use MEGA SEED once when launching a new campaign wheel',
                style: TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  OutlineInputBorder _workshopInputBorder() {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
    );
  }

  OutlineInputBorder _workshopInputFocusedBorder() {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppTheme.neonCyan),
    );
  }

  Future<void> _routeAssetToSamurai(
    _WorkshopAsset asset, {
    bool autoPublish = false,
  }) async {
    final mergedBody = [
      if (asset.notes.trim().isNotEmpty) asset.notes.trim(),
      if (asset.url.trim().isNotEmpty) 'Asset: ${asset.url.trim()}',
    ].join('\n\n');

    _samurai.transform(
      title: asset.title,
      body: mergedBody,
      contentStyle: _assetTypeToStyle(asset.type),
      sourceEngine: 'warehouse',
    );

    final queued = _samurai.queue.isNotEmpty ? _samurai.queue.first : null;
    if (queued == null) return;

    _samurai.approve(queued.id);

    if (autoPublish) {
      await _samurai.publishToSocial(queued.id);
    }

    setState(() {});
  }

  String _assetTypeToStyle(String type) {
    switch (type) {
      case 'video':
        return 'hype';
      case 'caption':
        return 'editorial';
      default:
        return 'promo';
    }
  }
}

class _AIFeedItem {
  final String title;
  final DfcContentType type;
  final DateTime timestamp;
  final bool published;

  const _AIFeedItem({
    required this.title,
    required this.type,
    required this.timestamp,
    required this.published,
  });
}

class _WorkshopAsset {
  final String title;
  final String url;
  final String type;
  final String notes;
  final DateTime createdAt;

  const _WorkshopAsset({
    required this.title,
    required this.url,
    required this.type,
    required this.notes,
    required this.createdAt,
  });
}
