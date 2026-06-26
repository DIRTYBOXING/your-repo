import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/services/gemini_image_service.dart';
import '../../genie/genie_api_service.dart';
import '../../genie/genie_persona.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// AI CARD PRODUCER v3.0 — Turn Any Fighter Into A Collectible Legend
///
/// Upload your fighter photo → choose card style → select effects →
/// hit PRODUCE CARD → AI creates a holographic, shareable trading card.
///
/// Card Styles: UFC · Basketball · Baseball · Cyberpunk · Manga
/// Backgrounds: Metal · Flames · Ice · Holographic · Galaxy · Lightning
/// Borders: Gold · Platinum · Diamond · Bronze · Rainbow · Obsidian
/// Overlays: Sparks · Snow · Embers · Lightning · Sakura
///
/// The card that makes every fighter feel like a champion.
/// ═══════════════════════════════════════════════════════════════════════════

class AICardCreatorScreen extends StatefulWidget {
  final int? initialFighterRank;
  const AICardCreatorScreen({super.key, this.initialFighterRank});

  @override
  State<AICardCreatorScreen> createState() => _AICardCreatorScreenState();
}

class _AICardCreatorScreenState extends State<AICardCreatorScreen>
    with TickerProviderStateMixin {
  // Genie AI pick methods — return empty defaults until ML model integrated
  List<int> _genieBgPicks() {
    return <int>[];
  }

  List<int> _genieBorderPicks() {
    return <int>[];
  }

  List<int> _genieOverlayPicks() {
    return <int>[];
  }

  Widget _buildProduceButton() {
    return GestureDetector(
      onTap: _isGenerating ? null : _produceCard,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _isGenerating
                ? [Colors.grey.shade800, Colors.grey.shade700]
                : [AppColors.neonCyan, AppColors.neonPurple],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: _isGenerating
              ? []
              : [
                  BoxShadow(
                    color: AppColors.neonCyan.withValues(alpha: 0.3),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isGenerating ? Icons.hourglass_top : Icons.auto_awesome,
              color: Colors.white,
              size: 22,
            ),
            const SizedBox(width: 10),
            Text(
              _isGenerating ? 'FORGING CARD...' : '⚔ PRODUCE CARD',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Genie persona picker state
  int _selectedPersonaIdx = 0;

  late final AnimationController _shimmerCtrl;
  late final AnimationController _effectCtrl;
  late final AnimationController _pulseCtrl;

  // Card repaint key for export
  final GlobalKey _cardKey = GlobalKey();

  // Photo state
  Uint8List? _photoBytes;
  Uint8List? _geminiCardImage;
  String _fighterName = '';
  String _fighterAlias = '';
  String _fighterRecord = '';
  String _fighterDivision = '';

  // Selection state
  int _selectedStyleIdx = 0;
  int _selectedBgIdx = 0;
  int _selectedBorderIdx = 0;
  int _selectedOverlayIdx = 0;
  bool _isGenerating = false;
  bool _cardProduced = false;
  double _generateProgress = 0.0;
  GeniePersona? _shidoPersona;
  GeniePersona get _persona => geniePersonas[_selectedPersonaIdx];
  bool _isFetchingCombo = false;
  String? _hypeText;

  // Card styles
  static const _styles = [
    _CardStyle(
      'UFC FIGHT',
      Icons.sports_mma,
      Color(0xFFFF2D55),
      'Championship caliber',
    ),
    _CardStyle(
      'BASKETBALL',
      Icons.sports_basketball,
      Color(0xFFFF9800),
      'All-star edition',
    ),
    _CardStyle(
      'BASEBALL',
      Icons.sports_baseball,
      Color(0xFF4CAF50),
      'Hall of fame series',
    ),
    _CardStyle(
      'CYBERPUNK',
      Icons.memory,
      Color(0xFF00FFF0),
      'Neon warrior edition',
    ),
    _CardStyle(
      'MANGA',
      Icons.auto_stories,
      Color(0xFFFF0080),
      'Anime legend series',
    ),
  ];

  // Background effects
  static const _backgrounds = [
    _Effect('METAL', Icons.shield, Color(0xFF808080)),
    _Effect('FLAMES', Icons.local_fire_department, Color(0xFFFF4500)),
    _Effect('ICE', Icons.ac_unit, Color(0xFF00BFFF)),
    _Effect('HOLOGRAPHIC', Icons.blur_on, Color(0xFFB100FF)),
    _Effect('GALAXY', Icons.stars, Color(0xFF1E0A3C)),
    _Effect('LIGHTNING', Icons.flash_on, Color(0xFFFFD700)),
    _Effect('SMOKE', Icons.cloud, Color(0xFF444444)),
    _Effect('NEON GRID', Icons.grid_on, Color(0xFF00FF9D)),
  ];

  // Border styles
  static const _borders = [
    _Effect('GOLD', Icons.circle, Color(0xFFFFD700)),
    _Effect('PLATINUM', Icons.circle, Color(0xFFE5E5E5)),
    _Effect('DIAMOND', Icons.diamond, Color(0xFF00BFFF)),
    _Effect('BRONZE', Icons.circle, Color(0xFFCD7F32)),
    _Effect('RAINBOW', Icons.circle, Color(0xFFFF0080)),
    _Effect('OBSIDIAN', Icons.circle, Color(0xFF1A1A2E)),
  ];

  // Overlay effects
  static const _overlays = [
    _Effect('NONE', Icons.block, Color(0xFF444444)),
    _Effect('SPARKS', Icons.auto_awesome, Color(0xFFFFD700)),
    _Effect('SNOW', Icons.grain, Color(0xFFE0E0FF)),
    _Effect('EMBERS', Icons.whatshot, Color(0xFFFF6B35)),
    _Effect('LIGHTNING', Icons.bolt, Color(0xFF00BFFF)),
    _Effect('SAKURA', Icons.spa, Color(0xFFFF69B4)),
  ];

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
    _effectCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    // Pre-fill if initial rank provided
    if (widget.initialFighterRank != null) {
      final idx = _presets.indexWhere(
        (f) => f.rank == widget.initialFighterRank,
      );
      if (idx >= 0) {
        final p = _presets[idx];
        _fighterName = p.name;
        _fighterAlias = p.alias;
        _fighterRecord = p.record;
        _fighterDivision = p.division;
      }
    }

    // Prefer Samurai Shido as the AI card producer persona
    final shidoIdx = geniePersonas.indexWhere((p) => p.id == 'shido');
    _selectedPersonaIdx = shidoIdx >= 0 ? shidoIdx : 0;
    _shidoPersona = geniePersonas[_selectedPersonaIdx];
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    _effectCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  _CardStyle get _style => _styles[_selectedStyleIdx];
  _Effect get _bg => _backgrounds[_selectedBgIdx];
  _Effect get _border => _borders[_selectedBorderIdx];
  _Effect get _overlay => _overlays[_selectedOverlayIdx];

  // ── PHOTO PICKER ──
  Future<void> _pickPhoto(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 90,
    );
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _photoBytes = bytes;
        _cardProduced = false;
      });
    }
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.panel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'UPLOAD FIGHTER PHOTO',
                style: TextStyle(
                  color: AppColors.neonCyan,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Choose a source for your fighter image',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 24),
              _photoOptionTile(
                Icons.camera_alt,
                'TAKE PHOTO',
                'Use camera to capture fighter',
                AppColors.neonMagenta,
                () {
                  Navigator.pop(context);
                  _pickPhoto(ImageSource.camera);
                },
              ),
              const SizedBox(height: 12),
              _photoOptionTile(
                Icons.photo_library,
                'CHOOSE FROM GALLERY',
                'Select an existing photo',
                AppColors.neonCyan,
                () {
                  Navigator.pop(context);
                  _pickPhoto(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _photoOptionTile(
    IconData icon,
    String title,
    String subtitle,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: color.withValues(alpha: 0.06),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.35),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: color.withValues(alpha: 0.4),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  // ── GENERATE CARD ──
  Future<void> _produceCard() async {
    if (_fighterName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Enter a fighter name first'),
          backgroundColor: AppColors.neonRed.withValues(alpha: 0.8),
        ),
      );
      return;
    }
    setState(() {
      _isGenerating = true;
      _generateProgress = 0.0;
      _cardProduced = false;
    });

    // Kick off Genie card data generation with Samurai Shido persona
    final genieFuture = GenieApiService.generateCardData(
      photoBytes: _photoBytes,
      description: _fighterName,
      persona: _persona,
    );

    // Simulate AI processing steps for UX
    final steps = [
      'Analyzing fighter photo...',
      'Applying ${_style.name} template...',
      'Rendering ${_bg.name} background...',
      'Applying ${_border.name} border...',
      'Adding ${_overlay.name} overlay...',
      'Generating holographic finish...',
      'AI enhancing card quality...',
      'Finalizing collectible card...',
    ];

    for (int i = 0; i < steps.length; i++) {
      await Future.delayed(const Duration(milliseconds: 350));
      if (mounted) {
        setState(() => _generateProgress = (i + 1) / steps.length);
      }
    }

    // ── Gemini AI card artwork generation ─────────────────────────────
    final gemini = GeminiImageService();
    if (gemini.isConfigured) {
      final cardPrompt =
          'Create a premium collectible MMA/combat sports trading card artwork. '
          'Fighter: $_fighterName. Style: ${_style.name}. '
          'Background: ${_bg.name}. Border: ${_border.name}. '
          'Overlay: ${_overlay.name}. '
          'High quality, sharp details, dramatic lighting, holographic finish.';

      final GeminiImageResult gemResult;
      if (_photoBytes != null) {
        gemResult = await gemini.generateFromImage(
          imageBytes: _photoBytes!,
          prompt: cardPrompt,
        );
      } else {
        gemResult = await gemini.generateFromText(
          prompt: cardPrompt,
          aspect: GeminiAspectRatio.portrait,
        );
      }

      if (mounted && gemResult.success && gemResult.hasImage) {
        setState(() => _geminiCardImage = gemResult.imageBytes);
      }
    }

    // Apply Genie card data once processing "completes"
    GenieApiResponse genie;
    try {
      genie = await genieFuture;
    } catch (_) {
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _cardProduced = true;
        });
      }
      return;
    }

    if (!mounted) return;

    _applyGenieCardData(genie);

    if (mounted) {
      setState(() {
        _isGenerating = false;
        _cardProduced = true;
      });
    }
  }

  void _applyGenieCardData(GenieApiResponse genie) {
    setState(() {
      if (genie.alias.isNotEmpty) {
        _fighterAlias = genie.alias;
      }
      if (genie.record.isNotEmpty) {
        _fighterRecord = genie.record;
      }
      if (genie.division.isNotEmpty) {
        _fighterDivision = genie.division;
      }

      _selectedStyleIdx = _mapStyleFromGenie(genie.suggestedStyle);
      _selectedBorderIdx = _mapBorderFromGenie(genie.border);
      _selectedOverlayIdx = _mapOverlayFromGenie(genie.overlay);

      if (genie.hypeText.isNotEmpty) {
        _hypeText = genie.hypeText;
      }
    });
  }

  int _mapStyleFromGenie(String style) {
    final s = style.toLowerCase();
    if (s.contains('cyber')) {
      return _styles.indexWhere((st) => st.name == 'CYBERPUNK');
    }
    if (s.contains('manga') || s.contains('anime')) {
      return _styles.indexWhere((st) => st.name == 'MANGA');
    }
    if (s.contains('basket')) {
      return _styles.indexWhere((st) => st.name == 'BASKETBALL');
    }
    if (s.contains('baseball')) {
      return _styles.indexWhere((st) => st.name == 'BASEBALL');
    }
    if (s.contains('ufc') || s.contains('fight')) {
      return _styles.indexWhere((st) => st.name == 'UFC FIGHT');
    }
    // Fallback to current index if no match
    return _selectedStyleIdx;
  }

  int _mapBorderFromGenie(String border) {
    final b = border.toLowerCase();
    if (b.contains('gold')) {
      return _borders.indexWhere((bd) => bd.name == 'GOLD');
    }
    if (b.contains('platinum')) {
      return _borders.indexWhere((bd) => bd.name == 'PLATINUM');
    }
    if (b.contains('diamond')) {
      return _borders.indexWhere((bd) => bd.name == 'DIAMOND');
    }
    if (b.contains('bronze')) {
      return _borders.indexWhere((bd) => bd.name == 'BRONZE');
    }
    if (b.contains('rainbow')) {
      return _borders.indexWhere((bd) => bd.name == 'RAINBOW');
    }
    if (b.contains('obsidian')) {
      return _borders.indexWhere((bd) => bd.name == 'OBSIDIAN');
    }
    return _selectedBorderIdx;
  }

  int _mapOverlayFromGenie(String overlay) {
    final o = overlay.toLowerCase();
    if (o.contains('spark')) {
      return _overlays.indexWhere((ov) => ov.name == 'SPARKS');
    }
    if (o.contains('snow')) {
      return _overlays.indexWhere((ov) => ov.name == 'SNOW');
    }
    if (o.contains('ember')) {
      return _overlays.indexWhere((ov) => ov.name == 'EMBERS');
    }
    if (o.contains('lightning')) {
      return _overlays.indexWhere((ov) => ov.name == 'LIGHTNING');
    }
    if (o.contains('sakura')) {
      return _overlays.indexWhere((ov) => ov.name == 'SAKURA');
    }
    return _selectedOverlayIdx;
  }

  // ── FIGHTER INFO EDITOR ──
  void _showFighterInfoEditor() {
    final nameCtrl = TextEditingController(text: _fighterName);
    final aliasCtrl = TextEditingController(text: _fighterAlias);
    final recordCtrl = TextEditingController(text: _fighterRecord);
    final divisionCtrl = TextEditingController(text: _fighterDivision);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.panel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'FIGHTER DETAILS',
              style: TextStyle(
                color: AppColors.neonCyan,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 20),
            _infoField('FIGHTER NAME', nameCtrl, 'Marcus Santos'),
            const SizedBox(height: 12),
            _infoField('ALIAS / NICKNAME', aliasCtrl, 'The Storm'),
            const SizedBox(height: 12),
            _infoField('RECORD', recordCtrl, '18-4-0'),
            const SizedBox(height: 12),
            _infoField('DIVISION', divisionCtrl, 'Welterweight'),
            const SizedBox(height: 20),
            // Presets row
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _presets
                    .map(
                      (p) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () {
                            nameCtrl.text = p.name;
                            aliasCtrl.text = p.alias;
                            recordCtrl.text = p.record;
                            divisionCtrl.text = p.division;
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: AppColors.neonCyan.withValues(alpha: 0.06),
                              border: Border.all(
                                color: AppColors.neonCyan.withValues(
                                  alpha: 0.12,
                                ),
                              ),
                            ),
                            child: Text(
                              p.name.split(' ').last,
                              style: TextStyle(
                                color: AppColors.neonCyan.withValues(
                                  alpha: 0.6,
                                ),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                setState(() {
                  _fighterName = nameCtrl.text;
                  _fighterAlias = aliasCtrl.text;
                  _fighterRecord = recordCtrl.text;
                  _fighterDivision = divisionCtrl.text;
                  _cardProduced = false;
                });
                Navigator.pop(context);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: const LinearGradient(
                    colors: [AppColors.neonCyan, AppColors.neonGreen],
                  ),
                ),
                child: const Text(
                  'SAVE FIGHTER INFO',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoField(String label, TextEditingController ctrl, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 15,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.15),
              fontSize: 15,
            ),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.04),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.neonCyan.withValues(alpha: 0.4),
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060A14),
      body: Stack(
        children: [
          // Animated bg
          AnimatedBuilder(
            animation: _effectCtrl,
            builder: (_, _) => CustomPaint(
              size: MediaQuery.of(context).size,
              painter: _CreatorBgPainter(phase: _effectCtrl.value),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                // ── Genie Persona Picker ──
                _buildPersonaPicker(),
                _buildPersonaBanner(),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),

                        // ── PHOTO UPLOAD ──
                        _buildPhotoUpload(),

                        const SizedBox(height: 16),

                        // ── FIGHTER INFO ──
                        _buildFighterInfo(),

                        const SizedBox(height: 20),

                        // ── CARD PREVIEW ──
                        _sectionLabel('CARD PREVIEW', AppColors.neonAmber),
                        const SizedBox(height: 10),
                        _buildCardPreview(),

                        if (_hypeText != null && _hypeText!.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          _buildHypeBanner(),
                        ],

                        const SizedBox(height: 22),

                        // ── CARD STYLE ──
                        _sectionLabel('CARD STYLE', AppColors.neonMagenta),
                        const SizedBox(height: 4),
                        Text(
                          'Choose your collectible aesthetic',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.25),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildStyleSelector(),

                        const SizedBox(height: 20),

                        // ── BACKGROUND EFFECT ──
                        _sectionLabel('BACKGROUND', AppColors.neonOrange),
                        const SizedBox(height: 4),
                        Text(
                          'Set the scene behind your fighter',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.25),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildEffectGrid(
                          _backgrounds,
                          _selectedBgIdx,
                          (i) => setState(() {
                            _selectedBgIdx = i;
                            _cardProduced = false;
                          }),
                          geniePicks: _genieBgPicks(),
                        ),

                        const SizedBox(height: 20),

                        // ── BORDER STYLE ──
                        _sectionLabel('BORDER', AppColors.neonAmber),
                        const SizedBox(height: 4),
                        Text(
                          'Frame your legend in precious metal',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.25),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildEffectGrid(
                          _borders,
                          _selectedBorderIdx,
                          (i) => setState(() {
                            _selectedBorderIdx = i;
                            _cardProduced = false;
                          }),
                          geniePicks: _genieBorderPicks(),
                        ),

                        const SizedBox(height: 20),

                        // ── OVERLAY ──
                        _sectionLabel('OVERLAY EFFECT', AppColors.neonPurple),
                        const SizedBox(height: 4),
                        Text(
                          'Add atmospheric particles to the card',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.25),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildEffectGrid(
                          _overlays,
                          _selectedOverlayIdx,
                          (i) => setState(() {
                            _selectedOverlayIdx = i;
                            _cardProduced = false;
                          }),
                          geniePicks: _genieOverlayPicks(),
                        ),

                        const SizedBox(height: 28),

                        // ── SHIDO AI ASSISTANT ──
                        _buildShidoAssistantBanner(),
                        const SizedBox(height: 16),

                        // ── PRODUCE CARD BUTTON ──
                        _buildProduceButton(),

                        // ── POST-PRODUCTION ACTIONS ──
                        if (_cardProduced) ...[
                          const SizedBox(height: 16),
                          _buildPostProduction(),
                        ],

                        const SizedBox(height: 50),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Loading overlay
          if (_isGenerating) _buildGeneratingOverlay(),
        ],
      ),
    );
  }

  // ── Genie Persona Picker Widget ──
  Widget _buildPersonaPicker() {
    return Container(
      height: 74,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: geniePersonas.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (ctx, i) {
          final p = geniePersonas[i];
          final selected = i == _selectedPersonaIdx;
          return GestureDetector(
            onTap: () => setState(() {
              _selectedPersonaIdx = i;
              _shidoPersona = geniePersonas[i];
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected
                      ? AppColors.neonMagenta
                      : Colors.white.withValues(alpha: 0.08),
                  width: selected ? 2.5 : 1.2,
                ),
                color: selected
                    ? AppColors.neonMagenta.withValues(alpha: 0.08)
                    : Colors.white.withValues(alpha: 0.02),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: AppColors.neonMagenta.withValues(alpha: 0.18),
                          blurRadius: 12,
                        ),
                      ]
                    : [],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(p.icon, size: 22, color: AppColors.neonMagenta),
                  const SizedBox(height: 2),
                  Flexible(
                    child: Text(
                      p.displayName.split(' ')[0],
                      style: TextStyle(
                        color: Colors.white.withValues(
                          alpha: selected ? 0.9 : 0.5,
                        ),
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                        letterSpacing: 1,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Persona Banner Widget ──
  Widget _buildPersonaBanner() {
    final p = _persona;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: AppColors.neonMagenta.withValues(alpha: 0.07),
        border: Border.all(
          color: AppColors.neonMagenta.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        children: [
          Icon(p.icon, color: AppColors.neonMagenta, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
                Text(
                  p.style,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '“${p.quote}”',
                  style: TextStyle(
                    color: AppColors.neonMagenta.withValues(alpha: 0.7),
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HEADER
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.canPop() ? context.pop() : context.go('/home'),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white.withValues(alpha: 0.6),
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [
                      AppColors.neonMagenta,
                      AppColors.neonPurple,
                      AppColors.neonCyan,
                    ],
                  ).createShader(bounds),
                  child: const Text(
                    'AI CARD PRODUCER',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Upload photo · Choose style · Produce card',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.35),
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: const LinearGradient(
                colors: [AppColors.neonMagenta, AppColors.neonPurple],
              ),
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PHOTO UPLOAD — The hero moment
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildPhotoUpload() {
    return GestureDetector(
      onTap: _showPhotoOptions,
      child: AnimatedBuilder(
        animation: _pulseCtrl,
        builder: (_, _) => Container(
          width: double.infinity,
          height: _photoBytes != null ? 200 : 160,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: _photoBytes != null
                ? Colors.transparent
                : AppColors.neonCyan.withValues(alpha: 0.02),
            border: Border.all(
              color: _photoBytes != null
                  ? AppColors.neonGreen.withValues(alpha: 0.2)
                  : AppColors.neonCyan.withValues(
                      alpha: 0.08 + _pulseCtrl.value * 0.06,
                    ),
              width: 2,
            ),
          ),
          child: _photoBytes != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.memory(_photoBytes!, fit: BoxFit.cover),
                      // Gradient overlay
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.7),
                            ],
                          ),
                        ),
                      ),
                      const Positioned(
                        bottom: 14,
                        left: 16,
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: AppColors.neonGreen,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'PHOTO UPLOADED',
                              style: TextStyle(
                                color: AppColors.neonGreen,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        bottom: 14,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.white.withValues(alpha: 0.15),
                          ),
                          child: Text(
                            'CHANGE',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.neonCyan.withValues(alpha: 0.06),
                        border: Border.all(
                          color: AppColors.neonCyan.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Icon(
                        Icons.add_a_photo,
                        color: AppColors.neonCyan.withValues(alpha: 0.5),
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'UPLOAD FIGHTER PHOTO',
                      style: TextStyle(
                        color: AppColors.neonCyan.withValues(alpha: 0.6),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap to choose from camera or gallery',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FIGHTER INFO — Quick edit row
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildFighterInfo() {
    final hasInfo = _fighterName.isNotEmpty;

    return GestureDetector(
      onTap: _showFighterInfoEditor,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: hasInfo
              ? AppColors.neonGreen.withValues(alpha: 0.03)
              : AppColors.neonOrange.withValues(alpha: 0.03),
          border: Border.all(
            color: hasInfo
                ? AppColors.neonGreen.withValues(alpha: 0.1)
                : AppColors.neonOrange.withValues(alpha: 0.12),
          ),
        ),
        child: Row(
          children: [
            Icon(
              hasInfo ? Icons.person : Icons.edit,
              color: hasInfo
                  ? AppColors.neonGreen.withValues(alpha: 0.5)
                  : AppColors.neonOrange.withValues(alpha: 0.5),
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: hasInfo
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _fighterName.toUpperCase(),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                        Row(
                          children: [
                            if (_fighterAlias.isNotEmpty) ...[
                              Text(
                                '"$_fighterAlias"',
                                style: TextStyle(
                                  color: AppColors.neonGreen.withValues(
                                    alpha: 0.5,
                                  ),
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            if (_fighterRecord.isNotEmpty)
                              Text(
                                _fighterRecord,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.4),
                                  fontSize: 12,
                                ),
                              ),
                            if (_fighterDivision.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Text(
                                '· $_fighterDivision',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ENTER FIGHTER DETAILS',
                          style: TextStyle(
                            color: AppColors.neonOrange.withValues(alpha: 0.7),
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                        Text(
                          'Name, alias, record, division',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.3),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.white.withValues(alpha: 0.2),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CARD PREVIEW — Real-time with photo, effects, holographic finish
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildCardPreview() {
    return Center(
      child: AnimatedBuilder(
        animation: _shimmerCtrl,
        builder: (_, _) => RepaintBoundary(
          key: _cardKey,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width - 40,
              maxHeight: MediaQuery.of(context).size.height - 120,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _border.color.withValues(alpha: 0.6),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: _border.color.withValues(alpha: 0.3),
                  blurRadius: 30,
                  spreadRadius: 4,
                ),
                BoxShadow(
                  color: _bg.color.withValues(alpha: 0.2),
                  blurRadius: 50,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(17),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Background effect
                  if (_geminiCardImage != null) ...[
                    // Full-bleed AI-generated card artwork
                    Positioned.fill(
                      child: Image.memory(_geminiCardImage!, fit: BoxFit.cover),
                    ),
                    // Gradient overlay for text readability
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.1),
                              Colors.black.withValues(alpha: 0.5),
                              Colors.black.withValues(alpha: 0.85),
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ] else
                    CustomPaint(
                      painter: _CardBackgroundPainter(
                        bgType: _selectedBgIdx,
                        phase: _effectCtrl.value,
                        primaryColor: _bg.color,
                        styleColor: _style.color,
                      ),
                    ),

                  // Rainbow border
                  if (_selectedBorderIdx == 4)
                    CustomPaint(
                      painter: _RainbowBorderPainter(phase: _shimmerCtrl.value),
                    ),

                  // Overlay effects
                  if (_selectedOverlayIdx > 0)
                    CustomPaint(
                      painter: _OverlayPainter(
                        type: _selectedOverlayIdx,
                        phase: _effectCtrl.value,
                        color: _overlay.color,
                      ),
                    ),

                  // Card content with photo
                  _buildCardContent(),

                  // Holographic shimmer
                  CustomPaint(
                    painter: _HoloShimmerPainter(phase: _shimmerCtrl.value),
                  ),

                  // Produced badge
                  if (_cardProduced)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: AppColors.neonGreen.withValues(alpha: 0.25),
                          border: Border.all(
                            color: AppColors.neonGreen.withValues(alpha: 0.5),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.verified,
                              color: AppColors.neonGreen,
                              size: 14,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'AI PRODUCED',
                              style: TextStyle(
                                color: AppColors.neonGreen,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardContent() {
    final sColor = _style.color;
    final name = _fighterName.isNotEmpty
        ? _fighterName.toUpperCase()
        : 'YOUR NAME';
    final alias = _fighterAlias.isNotEmpty ? _fighterAlias : '';
    final record = _fighterRecord.isNotEmpty ? _fighterRecord : '0-0-0';
    final division = _fighterDivision.isNotEmpty
        ? _fighterDivision.toUpperCase()
        : 'DIVISION';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Style badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: sColor.withValues(alpha: 0.2),
              border: Border.all(color: sColor.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_style.icon, color: sColor, size: 14),
                const SizedBox(width: 5),
                Text(
                  _style.name,
                  style: TextStyle(
                    color: sColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Fighter photo or avatar (AI image is now full-bleed background)
          if (_geminiCardImage == null)
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    sColor.withValues(alpha: 0.3),
                    sColor.withValues(alpha: 0.05),
                  ],
                ),
                border: Border.all(
                  color: _border.color.withValues(alpha: 0.7),
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: sColor.withValues(alpha: 0.3),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: ClipOval(
                child: _photoBytes != null
                    ? Image.memory(_photoBytes!, fit: BoxFit.cover)
                    : Center(
                        child: Icon(
                          Icons.person,
                          color: sColor.withValues(alpha: 0.5),
                          size: 48,
                        ),
                      ),
              ),
            ),
          // When AI image is the background, push content to bottom
          if (_geminiCardImage != null) const Spacer(),

          const SizedBox(height: 10),

          // Alias
          if (alias.isNotEmpty)
            Text(
              '"$alias"',
              style: TextStyle(
                color: sColor.withValues(alpha: 0.6),
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),

          const SizedBox(height: 4),

          // Name
          Text(
            name,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.95),
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),

          const SizedBox(height: 2),

          // Division
          Text(
            division,
            style: TextStyle(
              color: sColor.withValues(alpha: 0.45),
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 3,
            ),
          ),

          const SizedBox(height: 10),

          // Record
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: _border.color.withValues(alpha: 0.08),
              border: Border.all(color: _border.color.withValues(alpha: 0.2)),
            ),
            child: Text(
              record,
              style: TextStyle(
                color: _border.color,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 3,
              ),
            ),
          ),

          const Spacer(),

          // DFC watermark
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.verified_user,
                color: Colors.white.withValues(alpha: 0.12),
                size: 12,
              ),
              const SizedBox(width: 4),
              Text(
                'DATA FIGHT CENTRAL',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.12),
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STYLE SELECTOR
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildStyleSelector() {
    return SizedBox(
      height: 74,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _styles.length,
        itemBuilder: (_, i) {
          final s = _styles[i];
          final isSelected = i == _selectedStyleIdx;
          return GestureDetector(
            onTap: () => setState(() {
              _selectedStyleIdx = i;
              _cardProduced = false;
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: isSelected
                    ? s.color.withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.03),
                border: Border.all(
                  color: isSelected
                      ? s.color.withValues(alpha: 0.5)
                      : Colors.white.withValues(alpha: 0.06),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    s.icon,
                    color: isSelected
                        ? s.color
                        : Colors.white.withValues(alpha: 0.3),
                    size: 22,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    s.name,
                    style: TextStyle(
                      color: isSelected
                          ? s.color
                          : Colors.white.withValues(alpha: 0.3),
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SHIDO ASSISTANT — Let Samurai Shido auto-style the card
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildShidoAssistantBanner() {
    final persona = _shidoPersona;
    return GestureDetector(
      onTap: _isFetchingCombo ? null : _applyShidoCombo,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            colors: [AppColors.neonPurple, AppColors.neonCyan],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.neonCyan.withValues(alpha: 0.25),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.2),
                border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
              ),
              child: Icon(
                persona?.icon ?? Icons.self_improvement,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SAMURAI SHIDO ASSIST',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _isFetchingCombo
                        ? 'Summoning a legendary combo...'
                        : 'Tap to let Shido auto-pick style, border & overlay.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: Colors.black.withValues(alpha: 0.35),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isFetchingCombo)
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.neonCyan,
                        ),
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                      ),
                    )
                  else
                    const Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 14,
                    ),
                  const SizedBox(width: 6),
                  Text(
                    _isFetchingCombo ? 'WORKING' : 'SHIDO PICK',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _applyShidoCombo() async {
    setState(() {
      _isFetchingCombo = true;
    });

    try {
      final response = await GenieApiService.generateCreativeCombo(
        photoBytes: _photoBytes,
        description: _fighterName.isNotEmpty ? _fighterName : null,
        persona: _shidoPersona,
      );

      if (!mounted) return;

      setState(() {
        _selectedStyleIdx = _mapStyleFromGenie(response.suggestedStyle);
        _selectedBorderIdx = _mapBorderFromGenie(response.border);
        _selectedOverlayIdx = _mapOverlayFromGenie(response.overlay);
        if (response.hypeText.isNotEmpty) {
          _hypeText = response.hypeText;
        }
        _cardProduced = false;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingCombo = false;
        });
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HYPE BANNER — Show Shido’s hype line under the preview
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildHypeBanner() {
    final text = _hypeText ?? '';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          colors: [
            AppColors.neonGreen.withValues(alpha: 0.12),
            AppColors.neonCyan.withValues(alpha: 0.06),
          ],
        ),
        border: Border.all(color: AppColors.neonGreen.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.record_voice_over,
            color: AppColors.neonGreen,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SHIDO’S HYPE LINE',
                  style: TextStyle(
                    color: AppColors.neonGreen.withValues(alpha: 0.9),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // EFFECT GRID — Reusable for backgrounds, borders, overlays
  // ═══════════════════════════════════════════════════════════════════════════
  // (Removed duplicate _buildEffectGrid definition. Only the version with geniePicks remains.)
  Widget _buildEffectGrid(
    List<_Effect> effects,
    int selectedIdx,
    ValueChanged<int> onSelect, {
    List<int>? geniePicks, // Indices of Genie/AI recommended effects
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: effects.asMap().entries.map((entry) {
        final i = entry.key;
        final e = entry.value;
        final isSelected = i == selectedIdx;
        final isGeniePick = geniePicks?.contains(i) ?? false;
        return GestureDetector(
          onTap: () => onSelect(i),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 82,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: isSelected
                      ? e.color.withValues(alpha: 0.18)
                      : isGeniePick
                      ? e.color.withValues(alpha: 0.10)
                      : Colors.white.withValues(alpha: 0.03),
                  border: Border.all(
                    color: isSelected
                        ? e.color.withValues(alpha: 0.7)
                        : isGeniePick
                        ? e.color.withValues(alpha: 0.35)
                        : Colors.white.withValues(alpha: 0.06),
                    width: isSelected
                        ? 2.5
                        : isGeniePick
                        ? 2
                        : 1,
                  ),
                  boxShadow: isGeniePick
                      ? [
                          BoxShadow(
                            color: e.color.withValues(alpha: 0.18),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  children: [
                    Icon(
                      e.icon,
                      color: isSelected
                          ? e.color
                          : isGeniePick
                          ? e.color.withValues(alpha: 0.7)
                          : Colors.white.withValues(alpha: 0.3),
                      size: 20,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      e.name,
                      style: TextStyle(
                        color: isSelected
                            ? e.color
                            : isGeniePick
                            ? e.color.withValues(alpha: 0.7)
                            : Colors.white.withValues(alpha: 0.3),
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              if (isGeniePick)
                Positioned(
                  top: -8,
                  right: -8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: e.color, width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: e.color.withValues(alpha: 0.18),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.stars, color: e.color, size: 12),
                        const SizedBox(width: 2),
                        Text(
                          "Shido’s Pick",
                          style: TextStyle(
                            color: e.color,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // POST-PRODUCTION — Share, save, print actions
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildPostProduction() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.neonGreen.withValues(alpha: 0.04),
            AppColors.neonCyan.withValues(alpha: 0.02),
          ],
        ),
        border: Border.all(color: AppColors.neonGreen.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.verified,
                color: AppColors.neonGreen.withValues(alpha: 0.6),
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'YOUR CARD IS READY',
                  style: TextStyle(
                    color: AppColors.neonGreen.withValues(alpha: 0.7),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _actionButton(Icons.share, 'SHARE', AppColors.neonCyan),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _actionButton(
                  Icons.save_alt,
                  'SAVE',
                  AppColors.neonGreen,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _actionButton(
                  Icons.print,
                  'PRINT',
                  AppColors.neonOrange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => setState(() => _cardProduced = false),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: AppColors.neonMagenta.withValues(alpha: 0.06),
                border: Border.all(
                  color: AppColors.neonMagenta.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.refresh,
                    color: AppColors.neonMagenta.withValues(alpha: 0.6),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'CREATE ANOTHER CARD',
                    style: TextStyle(
                      color: AppColors.neonMagenta.withValues(alpha: 0.7),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(IconData icon, String label, Color color) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '$label coming soon — AI card integration in progress',
            ),
            backgroundColor: color.withValues(alpha: 0.8),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: color.withValues(alpha: 0.06),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color.withValues(alpha: 0.6), size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color.withValues(alpha: 0.6),
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GENERATING OVERLAY — Immersive AI production sequence
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildGeneratingOverlay() {
    final steps = [
      'Analyzing fighter photo',
      'Applying ${_style.name} template',
      'Rendering ${_bg.name} background',
      'Applying ${_border.name} border',
      'Adding ${_overlay.name} overlay',
      'Generating holographic finish',
      'AI enhancing card quality',
      'Finalizing collectible card',
    ];
    final currentStep = (_generateProgress * steps.length).floor().clamp(
      0,
      steps.length - 1,
    );

    return AnimatedBuilder(
      animation: _shimmerCtrl,
      builder: (_, _) => Container(
        color: Colors.black.withValues(alpha: 0.9),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: CustomPaint(
                  painter: _GeneratingPainter(phase: _shimmerCtrl.value),
                ),
              ),
              const SizedBox(height: 28),
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [
                    AppColors.neonMagenta,
                    AppColors.neonCyan,
                    AppColors.neonPurple,
                  ],
                ).createShader(bounds),
                child: const Text(
                  'PRODUCING CARD',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 5,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                steps[currentStep],
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 200,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: _generateProgress,
                    backgroundColor: Colors.white.withValues(alpha: 0.06),
                    valueColor: const AlwaysStoppedAnimation(
                      AppColors.neonMagenta,
                    ),
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${(_generateProgress * 100).toInt()}%',
                style: TextStyle(
                  color: AppColors.neonMagenta.withValues(alpha: 0.6),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text, Color color) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 10),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: TextStyle(
            color: color.withValues(alpha: 0.75),
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 3,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DATA CLASSES
// ═══════════════════════════════════════════════════════════════════════════
class _CardStyle {
  final String name, subtitle;
  final IconData icon;
  final Color color;
  const _CardStyle(this.name, this.icon, this.color, this.subtitle);
}

class _Effect {
  final String name;
  final IconData icon;
  final Color color;
  const _Effect(this.name, this.icon, this.color);
}

class _FighterPreset {
  final int rank;
  final String name, alias, record, division;
  const _FighterPreset(
    this.rank,
    this.name,
    this.alias,
    this.record,
    this.division,
  );
}

// Preset fighters for quick fill
const _presets = [
  _FighterPreset(1, 'Marcus Torres', 'The Phoenix', '25-7-0', 'Middleweight'),
  _FighterPreset(2, 'Tyler Reid', 'The Great', '26-4-0', 'Featherweight'),
  _FighterPreset(
    3,
    'Elijah Okafor',
    'The Last Stylebender',
    '24-4-0',
    'Middleweight',
  ),
  _FighterPreset(4, 'Casey O\'Neill', 'King Casey', '10-2-0', 'Flyweight'),
  _FighterPreset(5, 'Mako Tua', 'The Wave', '15-8-0', 'Heavyweight'),
  _FighterPreset(6, 'Stamp Fairtex', 'Stamp', '73-19-5', 'Atomweight'),
  _FighterPreset(
    7,
    'John Wayne Parr',
    'The Gunslinger',
    '99-37-0',
    'Middleweight',
  ),
  _FighterPreset(8, 'Jack Della Maddalena', 'JDM', '17-2-0', 'Welterweight'),
  _FighterPreset(9, 'Nathan Cross', 'The Hangman', '24-12-0', 'Lightweight'),
  _FighterPreset(10, 'Tyson Pedro', 'Tyson', '10-4-0', 'Light Heavyweight'),
];

// ═══════════════════════════════════════════════════════════════════════════
// CREATOR BACKGROUND PAINTER
// ═══════════════════════════════════════════════════════════════════════════
class _CreatorBgPainter extends CustomPainter {
  final double phase;
  _CreatorBgPainter({required this.phase});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 80);
    final colors = [
      AppColors.neonMagenta,
      AppColors.neonPurple,
      AppColors.neonCyan,
    ];
    for (int i = 0; i < 3; i++) {
      final x =
          size.width * (0.15 + i * 0.35) +
          math.sin(phase * math.pi * 2 + i) * 50;
      final y =
          size.height * (0.1 + i * 0.3) +
          math.cos(phase * math.pi * 2 + i * 0.5) * 40;
      paint.color = colors[i].withValues(alpha: 0.012);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, y), width: 280, height: 180),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CreatorBgPainter old) => old.phase != phase;
}

// ═══════════════════════════════════════════════════════════════════════════
// CARD BACKGROUND PAINTER — Dynamic per selected effect
// ═══════════════════════════════════════════════════════════════════════════
class _CardBackgroundPainter extends CustomPainter {
  final int bgType;
  final double phase;
  final Color primaryColor, styleColor;

  _CardBackgroundPainter({
    required this.bgType,
    required this.phase,
    required this.primaryColor,
    required this.styleColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Base dark gradient
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0A0E1A), Color(0xFF060A14), Color(0xFF0A0E1A)],
        ).createShader(Offset.zero & size),
    );

    switch (bgType) {
      case 0:
        _paintMetal(canvas, size);
      case 1:
        _paintFlames(canvas, size);
      case 2:
        _paintIce(canvas, size);
      case 3:
        _paintHolo(canvas, size);
      case 4:
        _paintGalaxy(canvas, size);
      case 5:
        _paintLightning(canvas, size);
      case 6:
        _paintSmoke(canvas, size);
      case 7:
        _paintNeonGrid(canvas, size);
    }
  }

  void _paintMetal(Canvas canvas, Size size) {
    final paint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    for (int i = 0; i < 8; i++) {
      final y =
          size.height * i / 8 + math.sin(phase * math.pi * 2 + i * 0.7) * 10;
      paint.color = Colors.white.withValues(
        alpha: 0.02 + (i % 2 == 0 ? 0.01 : 0),
      );
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y + 5),
        paint..strokeWidth = 3,
      );
    }
    final shineX = phase * size.width * 1.5 - size.width * 0.25;
    canvas.drawRect(
      Rect.fromLTWH(shineX, 0, 40, size.height),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.03)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30),
    );
  }

  void _paintFlames(Canvas canvas, Size size) {
    final paint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40);
    for (int i = 0; i < 6; i++) {
      final x = size.width * (0.1 + i * 0.15);
      final y =
          size.height - (30 + math.sin(phase * math.pi * 2 + i) * 40 + i * 20);
      paint.color = const Color(0xFFFF4500).withValues(
        alpha: 0.04 + math.sin(phase * math.pi * 2 + i * 1.3) * 0.02,
      );
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, y), width: 60, height: 100),
        paint,
      );
    }
    for (int i = 0; i < 4; i++) {
      final x = size.width * (0.2 + i * 0.2);
      final y =
          size.height * 0.3 - math.sin(phase * math.pi * 2 + i * 1.5) * 30;
      paint.color = const Color(0xFFFFD700).withValues(alpha: 0.025);
      canvas.drawCircle(Offset(x, y), 8, paint);
    }
  }

  void _paintIce(Canvas canvas, Size size) {
    final paint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);
    for (int i = 0; i < 8; i++) {
      final x =
          size.width * math.sin(i * 0.8 + phase * math.pi) * 0.5 +
          size.width * 0.5;
      final y =
          size.height * math.cos(i * 0.6 + phase * math.pi * 0.7) * 0.3 +
          size.height * 0.5;
      paint.color = const Color(0xFF00BFFF).withValues(alpha: 0.03);
      canvas.drawCircle(Offset(x, y), 30, paint);
    }
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, 3),
      Paint()..color = const Color(0xFF00BFFF).withValues(alpha: 0.08),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, size.height - 3, size.width, 3),
      Paint()..color = const Color(0xFF00BFFF).withValues(alpha: 0.08),
    );
  }

  void _paintHolo(Canvas canvas, Size size) {
    final colors = [
      AppColors.neonRed,
      AppColors.neonCyan,
      AppColors.neonPurple,
      AppColors.neonGreen,
    ];
    final paint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 50);
    for (int i = 0; i < 4; i++) {
      final angle = phase * math.pi * 2 + i * math.pi / 2;
      final x = size.width * 0.5 + math.cos(angle) * size.width * 0.3;
      final y = size.height * 0.5 + math.sin(angle) * size.height * 0.2;
      paint.color = colors[i].withValues(alpha: 0.04);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, y), width: 120, height: 80),
        paint,
      );
    }
  }

  void _paintGalaxy(Canvas canvas, Size size) {
    final paint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60);
    paint.color = const Color(0xFF1E0A3C).withValues(alpha: 0.08);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.4),
        width: size.width * 0.8,
        height: size.height * 0.4,
      ),
      paint,
    );
    final rng = math.Random(42);
    final starPaint = Paint();
    for (int i = 0; i < 30; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final alpha =
          0.1 +
          rng.nextDouble() * 0.15 +
          math.sin(phase * math.pi * 2 + i) * 0.05;
      starPaint.color = Colors.white.withValues(alpha: alpha);
      canvas.drawCircle(Offset(x, y), 1, starPaint);
    }
  }

  void _paintLightning(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFD700).withValues(alpha: 0.04)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    for (int b = 0; b < 2; b++) {
      final path = Path();
      var x = size.width * (0.3 + b * 0.4);
      var y = 0.0;
      path.moveTo(x, y);
      while (y < size.height) {
        x += (math.sin(y * 0.05 + phase * math.pi * 2 + b * 3) * 20);
        y += 20;
        path.lineTo(x, y);
      }
      canvas.drawPath(path, paint);
    }
  }

  void _paintSmoke(Canvas canvas, Size size) {
    final paint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 50);
    for (int i = 0; i < 5; i++) {
      final x =
          size.width * (0.1 + i * 0.2) + math.sin(phase * math.pi * 2 + i) * 20;
      final y = size.height * 0.6 + math.cos(phase * math.pi + i * 0.8) * 40;
      paint.color = Colors.white.withValues(alpha: 0.02);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, y), width: 100, height: 60),
        paint,
      );
    }
  }

  void _paintNeonGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.neonGreen.withValues(alpha: 0.03)
      ..strokeWidth = 0.5;
    for (double x = 0; x < size.width; x += 20) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 20) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    final dotPaint = Paint()
      ..color = AppColors.neonGreen.withValues(alpha: 0.06)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    for (double x = 0; x < size.width; x += 40) {
      for (double y = 0; y < size.height; y += 40) {
        canvas.drawCircle(Offset(x, y), 2, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CardBackgroundPainter old) =>
      old.phase != phase || old.bgType != bgType;
}

// ═══════════════════════════════════════════════════════════════════════════
// OVERLAY PAINTER — Sparks, Snow, Embers, Lightning, Sakura
// ═══════════════════════════════════════════════════════════════════════════
class _OverlayPainter extends CustomPainter {
  final int type;
  final double phase;
  final Color color;
  _OverlayPainter({
    required this.type,
    required this.phase,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(7);
    switch (type) {
      case 1: // Sparks
        for (int i = 0; i < 15; i++) {
          final x = rng.nextDouble() * size.width;
          final baseY = rng.nextDouble() * size.height;
          final y = (baseY - phase * size.height * 0.3) % size.height;
          final alpha = 0.2 + math.sin(phase * math.pi * 2 + i) * 0.15;
          canvas.drawCircle(
            Offset(x, y),
            1.5,
            Paint()..color = color.withValues(alpha: alpha),
          );
        }
        break;
      case 2: // Snow
        for (int i = 0; i < 20; i++) {
          final x =
              rng.nextDouble() * size.width +
              math.sin(phase * math.pi * 2 + i) * 8;
          final baseY = rng.nextDouble() * size.height;
          final y = (baseY + phase * size.height * 0.4) % size.height;
          canvas.drawCircle(
            Offset(x, y),
            1 + rng.nextDouble(),
            Paint()
              ..color = color.withValues(alpha: 0.15 + rng.nextDouble() * 0.1),
          );
        }
        break;
      case 3: // Embers
        for (int i = 0; i < 12; i++) {
          final x = rng.nextDouble() * size.width;
          final baseY = rng.nextDouble() * size.height;
          final y = (baseY - phase * size.height * 0.5) % size.height;
          final alpha = 0.15 + math.sin(phase * math.pi * 2 + i * 1.3) * 0.1;
          canvas.drawCircle(
            Offset(x, y),
            2,
            Paint()
              ..color = color.withValues(alpha: alpha)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
          );
        }
        break;
      case 4: // Lightning
        final paint = Paint()
          ..color = color.withValues(
            alpha: 0.1 + math.sin(phase * math.pi * 6) * 0.1,
          )
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke;
        final path = Path();
        var px = size.width * 0.5;
        path.moveTo(px, 0);
        for (double y = 0; y < size.height; y += 15) {
          px += (rng.nextDouble() - 0.5) * 30;
          path.lineTo(px, y);
        }
        if (math.sin(phase * math.pi * 4) > 0.3) {
          canvas.drawPath(path, paint);
        }
        break;
      case 5: // Sakura
        for (int i = 0; i < 10; i++) {
          final x =
              rng.nextDouble() * size.width +
              math.sin(phase * math.pi * 2 + i * 0.8) * 15;
          final baseY = rng.nextDouble() * size.height;
          final y = (baseY + phase * size.height * 0.3) % size.height;
          canvas.drawOval(
            Rect.fromCenter(center: Offset(x, y), width: 4, height: 3),
            Paint()
              ..color = color.withValues(alpha: 0.15 + rng.nextDouble() * 0.1),
          );
        }
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _OverlayPainter old) =>
      old.phase != phase || old.type != type;
}

// ═══════════════════════════════════════════════════════════════════════════
// HOLOGRAPHIC SHIMMER
// ═══════════════════════════════════════════════════════════════════════════
class _HoloShimmerPainter extends CustomPainter {
  final double phase;
  _HoloShimmerPainter({required this.phase});

  @override
  void paint(Canvas canvas, Size size) {
    final x = -size.width * 0.3 + phase * size.width * 1.6;
    canvas.drawRect(
      Rect.fromLTWH(x, 0, 35, size.height),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.04)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );
  }

  @override
  bool shouldRepaint(covariant _HoloShimmerPainter old) => old.phase != phase;
}

// ═══════════════════════════════════════════════════════════════════════════
// RAINBOW BORDER PAINTER
// ═══════════════════════════════════════════════════════════════════════════
class _RainbowBorderPainter extends CustomPainter {
  final double phase;
  _RainbowBorderPainter({required this.phase});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..shader = SweepGradient(
        startAngle: phase * math.pi * 2,
        endAngle: phase * math.pi * 2 + math.pi * 2,
        colors: const [
          AppColors.neonRed,
          AppColors.neonOrange,
          AppColors.neonAmber,
          AppColors.neonGreen,
          AppColors.neonCyan,
          AppColors.neonPurple,
          AppColors.neonMagenta,
          AppColors.neonRed,
        ],
      ).createShader(Offset.zero & size);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(1, 1, size.width - 2, size.height - 2),
        const Radius.circular(17),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _RainbowBorderPainter old) => old.phase != phase;
}

// ═══════════════════════════════════════════════════════════════════════════
// GENERATING ANIMATION PAINTER
// ═══════════════════════════════════════════════════════════════════════════
class _GeneratingPainter extends CustomPainter {
  final double phase;
  _GeneratingPainter({required this.phase});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.4;

    for (int i = 0; i < 3; i++) {
      final startAngle = phase * math.pi * 2 + i * math.pi * 2 / 3;
      final sweepAngle = math.pi * 0.6;
      final colors = [
        AppColors.neonMagenta,
        AppColors.neonCyan,
        AppColors.neonPurple,
      ];
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r - i * 6),
        startAngle,
        sweepAngle,
        false,
        Paint()
          ..color = colors[i].withValues(alpha: 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round,
      );
    }

    canvas.drawCircle(
      Offset(cx, cy),
      10,
      Paint()
        ..color = AppColors.neonMagenta.withValues(
          alpha: 0.3 + math.sin(phase * math.pi * 4) * 0.2,
        )
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
  }

  @override
  bool shouldRepaint(covariant _GeneratingPainter old) => old.phase != phase;
}
