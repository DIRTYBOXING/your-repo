import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../shared/models/image_rights_model.dart';
import '../../../shared/services/image_rights_service.dart';
import '../../../shared/services/auth_service.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// PROMOTER MEDIA UPLOAD PORTAL
///
/// This is the screen promoters see when uploading event posters, fight
/// images, and promotional assets. It enforces attestation BEFORE any
/// upload touches storage. Designed to look premium and professional —
/// the first impression that makes a promoter want to work with DFC.
/// ═══════════════════════════════════════════════════════════════════════════
class PromoterMediaUploadScreen extends StatefulWidget {
  final String? prefilledEventId;
  final String? prefilledPromotionId;

  const PromoterMediaUploadScreen({
    super.key,
    this.prefilledEventId,
    this.prefilledPromotionId,
  });

  @override
  State<PromoterMediaUploadScreen> createState() =>
      _PromoterMediaUploadScreenState();
}

class _PromoterMediaUploadScreenState extends State<PromoterMediaUploadScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _service = ImageRightsService();
  final _picker = ImagePicker();

  // Form fields
  final _ownerNameCtrl = TextEditingController();
  final _ownerEmailCtrl = TextEditingController();
  final _eventIdCtrl = TextEditingController();
  final _licenseNotesCtrl = TextEditingController();

  ImageLicenseType _licenseType = ImageLicenseType.promoUse;
  final List<ImageUsageScope> _scopes = [
    ImageUsageScope.feed,
    ImageUsageScope.social,
    ImageUsageScope.editorial,
  ];

  // Image data
  Uint8List? _imageBytes;
  String? _fileName;
  bool _attestationChecked = false;
  bool _uploading = false;
  double _uploadProgress = 0.0;
  String? _successMessage;
  String? _errorMessage;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _eventIdCtrl.text = widget.prefilledEventId ?? '';
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _ownerNameCtrl.dispose();
    _ownerEmailCtrl.dispose();
    _eventIdCtrl.dispose();
    _licenseNotesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 4096,
      maxHeight: 4096,
      imageQuality: 95,
    );
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    setState(() {
      _imageBytes = bytes;
      _fileName = picked.name;
      _errorMessage = null;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imageBytes == null) {
      setState(() => _errorMessage = 'Please select an image');
      return;
    }
    if (!_attestationChecked) {
      setState(() => _errorMessage = 'You must accept the attestation');
      return;
    }

    setState(() {
      _uploading = true;
      _uploadProgress = 0;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await _service.uploadWithAttestation(
        imageBytes: _imageBytes!,
        fileName: _fileName ?? 'upload.jpg',
        ownerType: ImageOwnerType.promoter,
        ownerName: _ownerNameCtrl.text.trim(),
        ownerEmail: _ownerEmailCtrl.text.trim(),
        licenseType: _licenseType,
        attestationSigned: true,
        licenseNotes: _licenseNotesCtrl.text.trim(),
        allowedScopes: _scopes,
        sourceEventId: _eventIdCtrl.text.trim().isEmpty
            ? null
            : _eventIdCtrl.text.trim(),
        sourcePromotionId: widget.prefilledPromotionId,
        tags: ['promoter_upload'],
        onProgress: (p) => setState(() => _uploadProgress = p),
      );

      setState(() {
        _uploading = false;
        _successMessage =
            'Upload complete! Your image is pending admin review. '
            'You\'ll be notified once approved.';
        _imageBytes = null;
        _fileName = null;
        _attestationChecked = false;
      });
    } catch (e) {
      setState(() {
        _uploading = false;
        _errorMessage = 'Upload failed: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // ── SUBSCRIPTION GATE ──
    // DFC owns the promotional pipeline. Promoters must be subscribed
    // or pay for promotion to access the upload portal.
    // DFC owner/admin bypasses this gate.
    final auth = context.watch<AuthService>();
    final isOwnerOrAdmin = auth.isOwner || auth.isAdmin;
    final isPromoterRole = auth.userModel?.role.name == 'promoter';
    // Stripe subscription check deferred — promoter role = access for now
    // Free users see paywall; live Stripe status check pending integration
    final hasAccess = isOwnerOrAdmin || isPromoterRole;

    if (!hasAccess) {
      return _buildSubscriptionGate(context);
    }

    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      body: CustomScrollView(
        slivers: [
          _buildHeader(),
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.spacingXL,
                    vertical: DesignTokens.spacingL,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildPipelineSteps(),
                        const SizedBox(height: DesignTokens.spacingXXL),
                        _buildImagePicker(),
                        const SizedBox(height: DesignTokens.spacingXXL),
                        _buildOwnerFields(),
                        const SizedBox(height: DesignTokens.spacingXL),
                        _buildLicenseSelector(),
                        const SizedBox(height: DesignTokens.spacingXL),
                        _buildScopeSelector(),
                        const SizedBox(height: DesignTokens.spacingXL),
                        _buildLicenseNotes(),
                        const SizedBox(height: DesignTokens.spacingXXL),
                        _buildAttestationPanel(),
                        const SizedBox(height: DesignTokens.spacingXXL),
                        if (_errorMessage != null) _buildError(),
                        if (_successMessage != null) _buildSuccess(),
                        _buildSubmitButton(),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── SUBSCRIPTION GATE — Paywall for non-subscribed promoters ──────────
  Widget _buildSubscriptionGate(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgPrimary,
        elevation: 0,
        title: const Text(
          'PROMOTER UPLOAD',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.neonMagenta.withValues(alpha: 0.6),
                      width: 3,
                    ),
                  ),
                  child: const Icon(
                    Icons.lock_outline,
                    color: AppTheme.neonMagenta,
                    size: 56,
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'DFC PROMOTIONAL PIPELINE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'The DFC promotional engine is the most powerful fight '
                  'promotion machine on the planet. Upload posters, get '
                  'waterfall-scored exposure, hype engine ramping, and '
                  'adrenaline dump coverage.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.neonCyan.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.neonCyan.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      _gateFeatureRow(
                        Icons.upload_file,
                        'Poster & media uploads',
                      ),
                      _gateFeatureRow(
                        Icons.trending_up,
                        'Waterfall promotion scoring',
                      ),
                      _gateFeatureRow(
                        Icons.local_fire_department,
                        'Hype engine ramping',
                      ),
                      _gateFeatureRow(
                        Icons.live_tv,
                        'PPV broadcast through DFC',
                      ),
                      _gateFeatureRow(
                        Icons.public,
                        'International region targeting',
                      ),
                      _gateFeatureRow(
                        Icons.bar_chart,
                        'Analytics & performance data',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      // Navigate to promoter pricing / subscription page
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.neonCyan,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'SUBSCRIBE TO PROMOTE',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'All PPV sales through DFC • Broadcast rights included',
                  style: TextStyle(
                    color: AppTheme.neonMagenta.withValues(alpha: 0.7),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _gateFeatureRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.neonCyan, size: 18),
          const SizedBox(width: 10),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ── HEADER ──────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: DesignTokens.bgPrimary,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.neonMagenta.withValues(alpha: 0.15),
                DesignTokens.bgPrimary,
                AppTheme.neonCyan.withValues(alpha: 0.08),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.neonMagenta.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(
                            DesignTokens.radiusSmall,
                          ),
                          border: Border.all(
                            color: AppTheme.neonMagenta.withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Icon(
                          Icons.cloud_upload_outlined,
                          color: AppTheme.neonMagenta,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'MEDIA UPLOAD PORTAL',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                            Text(
                              'Upload event posters, fight images & promo assets',
                              style: TextStyle(
                                color: DesignTokens.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
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
    );
  }

  // ── PIPELINE VISUALIZATION ──────────────────────────────────────────────

  Widget _buildPipelineSteps() {
    final steps = [
      _PipelineStep(
        'UPLOAD',
        Icons.cloud_upload,
        AppTheme.neonCyan,
        _imageBytes != null,
      ),
      _PipelineStep(
        'ATTEST',
        Icons.verified_user,
        AppTheme.neonGreen,
        _attestationChecked,
      ),
      const _PipelineStep(
        'REVIEW',
        Icons.admin_panel_settings,
        AppTheme.neonOrange,
        false,
      ),
      const _PipelineStep('LIVE', Icons.public, AppTheme.neonMagenta, false),
    ];

    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacingL),
      decoration: GlassDecoration.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'RIGHTS PIPELINE',
            style: TextStyle(
              color: DesignTokens.neonCyan,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingM),
          Row(
            children: [
              for (int i = 0; i < steps.length; i++) ...[
                Expanded(child: _buildStepChip(steps[i], i + 1)),
                if (i < steps.length - 1)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 2),
                    child: Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: DesignTokens.textMuted,
                    ),
                  ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepChip(_PipelineStep step, int number) {
    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (context, child) {
        final glow = step.active ? _pulseAnim.value * 0.3 : 0.0;
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: step.active
                ? step.color.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
            border: Border.all(
              color: step.active
                  ? step.color.withValues(alpha: 0.4)
                  : DesignTokens.borderSubtle,
              width: step.active ? 1.2 : 0.5,
            ),
            boxShadow: step.active
                ? [
                    BoxShadow(
                      color: step.color.withValues(alpha: glow),
                      blurRadius: 12,
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Icon(
                step.icon,
                size: 18,
                color: step.active ? step.color : DesignTokens.textMuted,
              ),
              const SizedBox(height: 4),
              Text(
                step.label,
                style: TextStyle(
                  color: step.active ? step.color : DesignTokens.textMuted,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── IMAGE PICKER ────────────────────────────────────────────────────────

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _uploading ? null : _pickImage,
      child: AnimatedContainer(
        duration: DesignTokens.animNormal,
        height: _imageBytes != null ? 280 : 180,
        decoration: BoxDecoration(
          color: _imageBytes != null ? Colors.transparent : DesignTokens.bgCard,
          borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
          border: Border.all(
            color: _imageBytes != null
                ? AppTheme.neonCyan.withValues(alpha: 0.4)
                : DesignTokens.borderSubtle,
            width: _imageBytes != null ? 1.5 : 1,
          ),
          image: _imageBytes != null
              ? DecorationImage(
                  image: MemoryImage(_imageBytes!),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: _imageBytes != null
            ? Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.85),
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(DesignTokens.radiusMedium),
                      bottomRight: Radius.circular(DesignTokens.radiusMedium),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: DesignTokens.neonGreen,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _fileName ?? 'Image selected',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      TextButton(
                        onPressed: _pickImage,
                        child: const Text(
                          'CHANGE',
                          style: TextStyle(
                            color: DesignTokens.neonCyan,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add_photo_alternate_outlined,
                      color: DesignTokens.textMuted,
                      size: 48,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'TAP TO SELECT IMAGE',
                      style: TextStyle(
                        color: DesignTokens.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'JPEG, PNG, WebP — max 5MB',
                      style: TextStyle(
                        color: DesignTokens.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  // ── OWNER FIELDS ────────────────────────────────────────────────────────

  Widget _buildOwnerFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('RIGHTS HOLDER'),
        const SizedBox(height: DesignTokens.spacingS),
        _glassTextField(
          controller: _ownerNameCtrl,
          label: 'Full Name / Business Name',
          icon: Icons.person_outline,
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Name is required' : null,
        ),
        const SizedBox(height: DesignTokens.spacingM),
        _glassTextField(
          controller: _ownerEmailCtrl,
          label: 'Contact Email',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Email is required';
            if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())) {
              return 'Enter a valid email';
            }
            return null;
          },
        ),
        const SizedBox(height: DesignTokens.spacingM),
        _glassTextField(
          controller: _eventIdCtrl,
          label: 'Event ID (optional)',
          icon: Icons.event_outlined,
        ),
      ],
    );
  }

  // ── LICENSE TYPE ────────────────────────────────────────────────────────

  Widget _buildLicenseSelector() {
    final options = [
      const _LicenseOption(
        ImageLicenseType.promoUse,
        'PROMO USE',
        'I grant DFC promotional use rights',
        AppTheme.neonMagenta,
      ),
      const _LicenseOption(
        ImageLicenseType.owned,
        'OWNED',
        'I own this image outright',
        AppTheme.neonGreen,
      ),
      const _LicenseOption(
        ImageLicenseType.stock,
        'STOCK',
        'Licensed stock photography',
        AppTheme.neonCyan,
      ),
      const _LicenseOption(
        ImageLicenseType.cc,
        'CC',
        'Creative Commons with commercial use',
        AppTheme.neonOrange,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('LICENSE TYPE'),
        const SizedBox(height: DesignTokens.spacingS),
        Wrap(
          spacing: DesignTokens.spacingS,
          runSpacing: DesignTokens.spacingS,
          children: options.map((opt) {
            final selected = _licenseType == opt.type;
            return GestureDetector(
              onTap: () => setState(() => _licenseType = opt.type),
              child: AnimatedContainer(
                duration: DesignTokens.animFast,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? opt.color.withValues(alpha: 0.15)
                      : DesignTokens.bgCard,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
                  border: Border.all(
                    color: selected
                        ? opt.color.withValues(alpha: 0.6)
                        : DesignTokens.borderSubtle,
                    width: selected ? 1.5 : 0.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      opt.label,
                      style: TextStyle(
                        color: selected
                            ? opt.color
                            : DesignTokens.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      opt.description,
                      style: const TextStyle(
                        color: DesignTokens.textMuted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── SCOPE SELECTOR ──────────────────────────────────────────────────────

  Widget _buildScopeSelector() {
    final allScopes = [
      (ImageUsageScope.feed, 'Feed', Icons.dynamic_feed),
      (ImageUsageScope.social, 'Social', Icons.share),
      (ImageUsageScope.editorial, 'Editorial', Icons.article),
      (ImageUsageScope.ads, 'Paid Ads', Icons.campaign),
      (ImageUsageScope.email, 'Email', Icons.email),
      (ImageUsageScope.ppv, 'PPV', Icons.live_tv),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('USAGE PERMISSIONS'),
        const SizedBox(height: DesignTokens.spacingXS),
        const Text(
          'Select where DFC can use this image',
          style: TextStyle(color: DesignTokens.textMuted, fontSize: 11),
        ),
        const SizedBox(height: DesignTokens.spacingS),
        Wrap(
          spacing: DesignTokens.spacingS,
          runSpacing: DesignTokens.spacingS,
          children: allScopes.map((s) {
            final active = _scopes.contains(s.$1);
            return FilterChip(
              selected: active,
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    s.$3,
                    size: 14,
                    color: active ? AppTheme.neonCyan : DesignTokens.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(s.$2),
                ],
              ),
              labelStyle: TextStyle(
                color: active ? Colors.white : DesignTokens.textSecondary,
                fontSize: 12,
              ),
              backgroundColor: DesignTokens.bgCard,
              selectedColor: AppTheme.neonCyan.withValues(alpha: 0.15),
              checkmarkColor: AppTheme.neonCyan,
              side: BorderSide(
                color: active
                    ? AppTheme.neonCyan.withValues(alpha: 0.4)
                    : DesignTokens.borderSubtle,
              ),
              onSelected: (val) {
                setState(() {
                  if (val) {
                    _scopes.add(s.$1);
                  } else {
                    _scopes.remove(s.$1);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── LICENSE NOTES ───────────────────────────────────────────────────────

  Widget _buildLicenseNotes() {
    return _glassTextField(
      controller: _licenseNotesCtrl,
      label: 'License Notes (optional)',
      icon: Icons.notes_outlined,
      maxLines: 3,
      hint:
          'e.g. "Licensed from Shutterstock #12345" or "Shot by our staff photographer"',
    );
  }

  // ── ATTESTATION PANEL ───────────────────────────────────────────────────

  Widget _buildAttestationPanel() {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacingL),
      decoration: BoxDecoration(
        color: _attestationChecked
            ? DesignTokens.neonGreen.withValues(alpha: 0.06)
            : DesignTokens.neonAmber.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        border: Border.all(
          color: _attestationChecked
              ? DesignTokens.neonGreen.withValues(alpha: 0.3)
              : DesignTokens.neonAmber.withValues(alpha: 0.3),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _attestationChecked ? Icons.gpp_good : Icons.gpp_maybe,
                color: _attestationChecked
                    ? DesignTokens.neonGreen
                    : DesignTokens.neonAmber,
                size: 22,
              ),
              const SizedBox(width: 8),
              const Text(
                'LEGAL ATTESTATION',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: DesignTokens.neonRed.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'REQUIRED',
                  style: TextStyle(
                    color: DesignTokens.neonRed,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spacingM),
          const Text(
            ImageRightsModel.promoterPermissionText,
            style: TextStyle(
              color: DesignTokens.textSecondary,
              fontSize: 12,
              height: 1.6,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingL),
          Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: _attestationChecked,
                  onChanged: (v) =>
                      setState(() => _attestationChecked = v ?? false),
                  activeColor: DesignTokens.neonGreen,
                  side: const BorderSide(color: DesignTokens.textMuted),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(
                    () => _attestationChecked = !_attestationChecked,
                  ),
                  child: Text(
                    'I agree to the above terms and confirm I have authority to grant this license.',
                    style: TextStyle(
                      color: _attestationChecked
                          ? Colors.white
                          : DesignTokens.textSecondary,
                      fontSize: 13,
                      fontWeight: _attestationChecked
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── SUBMIT ──────────────────────────────────────────────────────────────

  Widget _buildSubmitButton() {
    final ready = _imageBytes != null && _attestationChecked && !_uploading;

    return Column(
      children: [
        if (_uploading)
          Padding(
            padding: const EdgeInsets.only(bottom: DesignTokens.spacingM),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _uploadProgress,
                    backgroundColor: DesignTokens.bgCard,
                    color: AppTheme.neonCyan,
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${(_uploadProgress * 100).toInt()}% — Uploading with rights metadata...',
                  style: const TextStyle(color: DesignTokens.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: ready ? _submit : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: ready
                  ? AppTheme.neonMagenta
                  : DesignTokens.bgCard,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
              ),
              elevation: 0,
            ),
            child: _uploading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.cloud_upload,
                        size: 20,
                        color: ready ? Colors.white : DesignTokens.textMuted,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'SUBMIT FOR APPROVAL',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          color: ready ? Colors.white : DesignTokens.textMuted,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  // ── SUCCESS / ERROR ─────────────────────────────────────────────────────

  Widget _buildSuccess() {
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.spacingL),
      child: Container(
        padding: const EdgeInsets.all(DesignTokens.spacingL),
        decoration: BoxDecoration(
          color: DesignTokens.neonGreen.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
          border: Border.all(
            color: DesignTokens.neonGreen.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.check_circle,
              color: DesignTokens.neonGreen,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _successMessage!,
                style: const TextStyle(
                  color: DesignTokens.neonGreen,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.spacingL),
      child: Container(
        padding: const EdgeInsets.all(DesignTokens.spacingL),
        decoration: BoxDecoration(
          color: DesignTokens.neonRed.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
          border: Border.all(
            color: DesignTokens.neonRed.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.error_outline,
              color: DesignTokens.neonRed,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _errorMessage!,
                style: const TextStyle(
                  color: DesignTokens.neonRed,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── SHARED WIDGETS ──────────────────────────────────────────────────────

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: DesignTokens.neonCyan,
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 2,
      ),
    );
  }

  Widget _glassTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: DesignTokens.textMuted, fontSize: 13),
        hintStyle: const TextStyle(color: DesignTokens.textDisabled, fontSize: 12),
        prefixIcon: Icon(icon, color: DesignTokens.textMuted, size: 20),
        filled: true,
        fillColor: DesignTokens.bgCard,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
          borderSide: const BorderSide(color: DesignTokens.borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
          borderSide: const BorderSide(color: DesignTokens.borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
          borderSide: BorderSide(
            color: AppTheme.neonCyan.withValues(alpha: 0.6),
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
          borderSide: BorderSide(
            color: DesignTokens.neonRed.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }
}

// ── Data classes ──────────────────────────────────────────────────────────

class _PipelineStep {
  final String label;
  final IconData icon;
  final Color color;
  final bool active;
  const _PipelineStep(this.label, this.icon, this.color, this.active);
}

class _LicenseOption {
  final ImageLicenseType type;
  final String label;
  final String description;
  final Color color;
  const _LicenseOption(this.type, this.label, this.description, this.color);
}
