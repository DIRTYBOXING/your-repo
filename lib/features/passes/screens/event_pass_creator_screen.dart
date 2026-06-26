import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/constants/image_assets.dart';
import '../../../shared/widgets/dfc_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/theme/design_tokens.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// EVENT PASS CREATOR — Create fight passes for shows & events
/// Upload logo · Set pass type · Generate QR codes · Issue to fighters/staff
/// ═══════════════════════════════════════════════════════════════════════════

// Pass role that the credential grants
enum CredentialRole {
  fighter,
  corner,
  trainer,
  cutman,
  promoter,
  security,
  mediaPress,
  vipGuest,
  generalAdmission,
}

extension CredentialRoleExt on CredentialRole {
  String get label => switch (this) {
    CredentialRole.fighter => 'Fighter',
    CredentialRole.corner => 'Corner',
    CredentialRole.trainer => 'Trainer',
    CredentialRole.cutman => 'Cutman',
    CredentialRole.promoter => 'Promoter',
    CredentialRole.security => 'Security',
    CredentialRole.mediaPress => 'Media / Press',
    CredentialRole.vipGuest => 'VIP Guest',
    CredentialRole.generalAdmission => 'General Admission',
  };

  IconData get icon => switch (this) {
    CredentialRole.fighter => Icons.sports_mma,
    CredentialRole.corner => Icons.group,
    CredentialRole.trainer => Icons.school,
    CredentialRole.cutman => Icons.healing,
    CredentialRole.promoter => Icons.campaign,
    CredentialRole.security => Icons.security,
    CredentialRole.mediaPress => Icons.videocam,
    CredentialRole.vipGuest => Icons.star,
    CredentialRole.generalAdmission => Icons.confirmation_number,
  };

  Color get color => switch (this) {
    CredentialRole.fighter => DesignTokens.neonCyan,
    CredentialRole.corner => DesignTokens.neonGreen,
    CredentialRole.trainer => DesignTokens.neonAmber,
    CredentialRole.cutman => const Color(0xFFFF6B6B),
    CredentialRole.promoter => DesignTokens.neonMagenta,
    CredentialRole.security => const Color(0xFF78909C),
    CredentialRole.mediaPress => const Color(0xFF40C4FF),
    CredentialRole.vipGuest => DesignTokens.neonGold,
    CredentialRole.generalAdmission => DesignTokens.textSecondary,
  };
}

class EventPassCreatorScreen extends StatefulWidget {
  const EventPassCreatorScreen({super.key});

  @override
  State<EventPassCreatorScreen> createState() => _EventPassCreatorScreenState();
}

class _EventPassCreatorScreenState extends State<EventPassCreatorScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late final AnimationController _pulseCtrl;

  // Form fields
  final _eventNameCtrl = TextEditingController();
  final _venueCtrl = TextEditingController();
  final _holderNameCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  CredentialRole _selectedRole = CredentialRole.fighter;
  DateTime _eventDate = DateTime.now().add(const Duration(days: 30));
  String? _logoUrl;
  XFile? _pickedLogo;
  bool _isGenerating = false;
  String? _generatedPassId;
  bool _isUploadingLogo = false;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _eventNameCtrl.dispose();
    _venueCtrl.dispose();
    _holderNameCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 90,
    );
    if (picked != null && mounted) {
      setState(() {
        _pickedLogo = picked;
        _isUploadingLogo = true;
      });

      // Upload to Firebase Storage
      try {
        final bytes = await picked.readAsBytes();
        final ext = picked.name.split('.').last.toLowerCase();
        final fileName =
            'event_logos/logo_${DateTime.now().millisecondsSinceEpoch}.$ext';

        final ref = FirebaseStorage.instance.ref().child(fileName);
        final metadata = SettableMetadata(
          contentType: 'image/$ext',
          customMetadata: {'uploadedBy': 'event-pass-creator'},
        );
        await ref.putData(bytes, metadata);
        final url = await ref.getDownloadURL();

        if (mounted) {
          setState(() {
            _logoUrl = url;
            _isUploadingLogo = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isUploadingLogo = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Logo upload failed: $e'),
              backgroundColor: DesignTokens.neonRed,
            ),
          );
        }
      }
    }
  }

  Future<void> _generatePass() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isGenerating = true);

    // Simulate pass creation (would write to Firestore in production)
    await Future.delayed(const Duration(milliseconds: 800));

    final passId =
        'DFC-${_selectedRole.label.toUpperCase().replaceAll(' ', '')}-${DateTime.now().millisecondsSinceEpoch.toRadixString(36).toUpperCase()}';

    if (mounted) {
      setState(() {
        _generatedPassId = passId;
        _isGenerating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverPadding(
            padding: const EdgeInsets.all(DesignTokens.spacingL),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (_generatedPassId != null) ...[
                  _buildGeneratedPass(),
                  const SizedBox(height: 24),
                  _buildNewPassButton(),
                ] else ...[
                  _buildLogoSection(),
                  const SizedBox(height: 24),
                  _buildForm(),
                  const SizedBox(height: 24),
                  _buildRoleSelector(),
                  const SizedBox(height: 24),
                  _buildDatePicker(),
                  const SizedBox(height: 32),
                  _buildGenerateButton(),
                ],
                const SizedBox(height: 60),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      floating: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      expandedHeight: 60,
      flexibleSpace: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  DesignTokens.bgPrimary.withValues(alpha: 0.9),
                  DesignTokens.bgPrimary.withValues(alpha: 0.7),
                ],
              ),
            ),
          ),
        ),
      ),
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new,
          color: Colors.white,
          size: 18,
        ),
        onPressed: () => context.pop(),
      ),
      title: const Text(
        'Create Event Pass',
        style: TextStyle(
          color: DesignTokens.textPrimary,
          fontSize: DesignTokens.fontSizeTitle,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LOGO UPLOAD
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildLogoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('EVENT / PROMOTER LOGO'),
        const SizedBox(height: 12),
        Center(
          child: GestureDetector(
            onTap: _pickLogo,
            child: AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (context, _) {
                final p = _pulseCtrl.value;
                return Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: DesignTokens.bgCard,
                    border: Border.all(
                      color: _logoUrl != null
                          ? DesignTokens.neonGreen.withValues(alpha: 0.5)
                          : DesignTokens.neonCyan.withValues(
                              alpha: 0.2 + p * 0.15,
                            ),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:
                            (_logoUrl != null
                                    ? DesignTokens.neonGreen
                                    : DesignTokens.neonCyan)
                                .withValues(alpha: 0.08 + p * 0.06),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: _isUploadingLogo
                      ? const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: DesignTokens.neonCyan,
                          ),
                        )
                      : _logoUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: ImageAssets.isLocalAsset(_logoUrl!)
                              ? Image.asset(
                                  _logoUrl!,
                                  fit: BoxFit.cover,
                                  width: 140,
                                  height: 140,
                                  errorBuilder: (_, _, _) =>
                                      _buildLogoPlaceholder(),
                                )
                              : DfcNetworkImage(
                                  url: _logoUrl!,
                                  width: 140,
                                  height: 140,
                                ),
                        )
                      : _pickedLogo != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: const Icon(
                            Icons.check_circle,
                            color: DesignTokens.neonGreen,
                            size: 40,
                          ),
                        )
                      : _buildLogoPlaceholder(),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            _logoUrl != null
                ? 'Tap to change logo'
                : 'Tap to upload event logo',
            style: TextStyle(
              color: DesignTokens.neonCyan.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogoPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_photo_alternate,
          color: DesignTokens.neonCyan.withValues(alpha: 0.5),
          size: 36,
        ),
        const SizedBox(height: 6),
        Text(
          'Upload Logo',
          style: TextStyle(
            color: DesignTokens.neonCyan.withValues(alpha: 0.5),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FORM FIELDS
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('EVENT DETAILS'),
          const SizedBox(height: 12),
          _buildField(
            controller: _eventNameCtrl,
            label: 'Event / Show Name',
            hint: 'e.g. DFC Championship Series',
            icon: Icons.event,
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Event name is required'
                : null,
          ),
          const SizedBox(height: 14),
          _buildField(
            controller: _venueCtrl,
            label: 'Venue',
            hint: 'e.g. Brisbane Convention Centre',
            icon: Icons.location_on_outlined,
          ),
          const SizedBox(height: 20),
          _sectionLabel('PASS HOLDER'),
          const SizedBox(height: 12),
          _buildField(
            controller: _holderNameCtrl,
            label: 'Name on Pass',
            hint: 'Fighter / Trainer / Staff name',
            icon: Icons.badge_outlined,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Name is required' : null,
          ),
          const SizedBox(height: 14),
          _buildField(
            controller: _notesCtrl,
            label: 'Notes (optional)',
            hint: 'Corner for Fighter X, etc.',
            icon: Icons.note_alt_outlined,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CREDENTIAL ROLE SELECTOR
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildRoleSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('PASS TYPE'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: CredentialRole.values.map((role) {
            final sel = role == _selectedRole;
            return GestureDetector(
              onTap: () => setState(() => _selectedRole = role),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: sel
                      ? role.color.withValues(alpha: 0.15)
                      : Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: sel
                        ? role.color.withValues(alpha: 0.6)
                        : Colors.white.withValues(alpha: 0.08),
                    width: sel ? 1.5 : 1,
                  ),
                  boxShadow: sel
                      ? [
                          BoxShadow(
                            color: role.color.withValues(alpha: 0.12),
                            blurRadius: 8,
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      role.icon,
                      color: sel
                          ? role.color
                          : Colors.white.withValues(alpha: 0.4),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      role.label,
                      style: TextStyle(
                        color: sel
                            ? role.color
                            : Colors.white.withValues(alpha: 0.6),
                        fontSize: 12,
                        fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
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

  // ═══════════════════════════════════════════════════════════════════════════
  // DATE PICKER
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('EVENT DATE'),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _eventDate,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
              builder: (ctx, child) {
                return Theme(
                  data: ThemeData.dark().copyWith(
                    colorScheme: const ColorScheme.dark(
                      primary: DesignTokens.neonCyan,
                      surface: DesignTokens.bgCard,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) setState(() => _eventDate = picked);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: DesignTokens.neonCyan.withValues(alpha: 0.5),
                  size: 18,
                ),
                const SizedBox(width: 12),
                Text(
                  '${_eventDate.day}/${_eventDate.month}/${_eventDate.year}',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
                const Spacer(),
                Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GENERATE BUTTON
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildGenerateButton() {
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (context, _) {
        final p = _pulseCtrl.value;
        return GestureDetector(
          onTap: _isGenerating ? null : _generatePass,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _selectedRole.color,
                  _selectedRole.color.withValues(alpha: 0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: _selectedRole.color.withValues(alpha: 0.25 + p * 0.1),
                  blurRadius: 14 + p * 6,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Center(
              child: _isGenerating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.qr_code_2,
                          color: Colors.black,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Generate ${_selectedRole.label} Pass',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GENERATED PASS CARD (with QR code)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildGeneratedPass() {
    final qrData =
        'DFC-PASS|$_generatedPassId|${_eventNameCtrl.text}|${_holderNameCtrl.text}|${_selectedRole.label}|${_eventDate.toIso8601String()}';
    final roleColor = _selectedRole.color;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            DesignTokens.bgCard,
            roleColor.withValues(alpha: 0.08),
            DesignTokens.bgSecondary,
          ],
        ),
        border: Border.all(color: roleColor.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: roleColor.withValues(alpha: 0.15),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Pass header with logo ──
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              gradient: LinearGradient(
                colors: [
                  roleColor.withValues(alpha: 0.12),
                  roleColor.withValues(alpha: 0.04),
                ],
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    // Event logo
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.white.withValues(alpha: 0.06),
                        border: Border.all(
                          color: roleColor.withValues(alpha: 0.3),
                        ),
                        image: _logoUrl != null
                            ? DecorationImage(
                                image: ImageAssets.resolveImage(_logoUrl!),
                                fit: BoxFit.cover,
                                onError: (_, _) {},
                              )
                            : null,
                      ),
                      child: _logoUrl == null
                          ? Icon(
                              Icons.sports_mma,
                              color: roleColor.withValues(alpha: 0.5),
                              size: 28,
                            )
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _eventNameCtrl.text,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (_venueCtrl.text.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              _venueCtrl.text,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Role badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: roleColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: roleColor.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_selectedRole.icon, color: roleColor, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        _selectedRole.label.toUpperCase(),
                        style: TextStyle(
                          color: roleColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Ticket tear line ──
          SizedBox(
            height: 20,
            child: Row(
              children: [
                _tearCircle(true, roleColor),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final dashCount = (constraints.maxWidth / 8).floor();
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(
                          dashCount,
                          (_) => Container(
                            width: 4,
                            height: 1,
                            color: roleColor.withValues(alpha: 0.2),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                _tearCircle(false, roleColor),
              ],
            ),
          ),

          // ── Pass holder + QR ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child: Column(
              children: [
                // Holder name
                Text(
                  _holderNameCtrl.text.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_eventDate.day}/${_eventDate.month}/${_eventDate.year}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
                if (_notesCtrl.text.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    _notesCtrl.text,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 20),

                // QR Code
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: roleColor.withValues(alpha: 0.2),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: QrImageView(
                    data: qrData,
                    size: 180,
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _generatedPassId!,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.35),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Scan for entry verification',
                  style: TextStyle(
                    color: roleColor.withValues(alpha: 0.6),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tearCircle(bool isLeft, Color color) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: DesignTokens.bgPrimary,
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
    );
  }

  Widget _buildNewPassButton() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _generatedPassId = null;
          _eventNameCtrl.clear();
          _venueCtrl.clear();
          _holderNameCtrl.clear();
          _notesCtrl.clear();
          _logoUrl = null;
          _pickedLogo = null;
          _selectedRole = CredentialRole.fighter;
        });
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_circle_outline,
              color: DesignTokens.neonCyan,
              size: 20,
            ),
            SizedBox(width: 8),
            Text(
              'Create Another Pass',
              style: TextStyle(
                color: DesignTokens.neonCyan,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SHARED BUILDERS
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildField({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: validator,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.2),
              fontSize: 13,
            ),
            prefixIcon: icon != null
                ? Icon(
                    icon,
                    color: DesignTokens.neonCyan.withValues(alpha: 0.5),
                    size: 18,
                  )
                : null,
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.04),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
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
                color: DesignTokens.neonCyan.withValues(alpha: 0.4),
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: DesignTokens.neonRed.withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        color: DesignTokens.neonCyan.withValues(alpha: 0.7),
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 2,
      ),
    );
  }
}
