import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/dfc_network_image.dart';
import '../../../core/config/router_config.dart' as app_router;
import '../../../core/theme/design_tokens.dart';
import '../../../shared/services/auth_service.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/widgets/glass_components.dart';
import '../../../core/utils/helpline_directory.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// PROFILE SETUP / EDIT SCREEN
/// Users can set or update their personal details, role, bio, and more.
/// Uses AuthService to persist to Firestore via UserModel.
/// ═══════════════════════════════════════════════════════════════════════════
class ProfileSetupScreen extends StatefulWidget {
  /// If true, this is the initial setup flow (shows different header/CTA).
  final bool isFirstSetup;

  const ProfileSetupScreen({super.key, this.isFirstSetup = false});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late final AnimationController _pulseCtrl;

  // Controllers
  final _displayNameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _fightNameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _postcodeCtrl = TextEditingController();
  String _selectedCountry = 'Australia';
  final _weightCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _reachCtrl = TextEditingController();
  final _gymNameCtrl = TextEditingController();

  UserRole _selectedRole = UserRole.fan;
  String _selectedStance = 'Orthodox';
  String _selectedWeightClass = 'Lightweight';
  bool _isSaving = false;
  bool _loaded = false;
  bool _isUploadingPhoto = false;

  static const _stances = ['Orthodox', 'Southpaw', 'Switch'];
  static const _weightClasses = [
    'Strawweight',
    'Flyweight',
    'Bantamweight',
    'Featherweight',
    'Lightweight',
    'Welterweight',
    'Middleweight',
    'Light Heavyweight',
    'Heavyweight',
    'Super Heavyweight',
  ];

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) => _loadExisting());
  }

  void _loadExisting() {
    final auth = context.read<AuthService>();
    final user = auth.userModel;
    if (user != null && !_loaded) {
      _displayNameCtrl.text = user.displayName ?? '';
      _usernameCtrl.text = user.username ?? '';
      _bioCtrl.text = user.bio ?? '';
      _selectedRole = user.role;
      if (user.metadata != null) {
        _fightNameCtrl.text = (user.metadata!['fightName'] as String?) ?? '';
        _locationCtrl.text = (user.metadata!['location'] as String?) ?? '';
        _cityCtrl.text = (user.metadata!['city'] as String?) ?? '';
        _postcodeCtrl.text = (user.metadata!['postcode'] as String?) ?? '';
        _selectedCountry =
            (user.metadata!['country'] as String?) ?? 'Australia';
        _gymNameCtrl.text = (user.metadata!['gymName'] as String?) ?? '';
        _weightCtrl.text = (user.metadata!['weight']?.toString()) ?? '';
        _heightCtrl.text = (user.metadata!['height']?.toString()) ?? '';
        _reachCtrl.text = (user.metadata!['reach']?.toString()) ?? '';
        _selectedStance = (user.metadata!['stance'] as String?) ?? 'Orthodox';
        _selectedWeightClass =
            (user.metadata!['weightClass'] as String?) ?? 'Lightweight';
      }
      _loaded = true;
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _displayNameCtrl.dispose();
    _usernameCtrl.dispose();
    _fightNameCtrl.dispose();
    _bioCtrl.dispose();
    _locationCtrl.dispose();
    _cityCtrl.dispose();
    _postcodeCtrl.dispose();
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    _reachCtrl.dispose();
    _gymNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final auth = context.read<AuthService>();

    // Update core fields via AuthService
    await auth.updateProfile(
      displayName: _displayNameCtrl.text.trim(),
      bio: _bioCtrl.text.trim().isEmpty ? null : _bioCtrl.text.trim(),
      username: _usernameCtrl.text.trim().isEmpty
          ? null
          : _usernameCtrl.text.trim(),
    );

    // Update role if changed
    final currentRole = auth.userModel?.role;
    if (currentRole != _selectedRole) {
      await auth.updateUserRole(_selectedRole);
    }

    // Update extended metadata (location, gym, physical stats)
    await _saveExtendedMetadata(auth);

    await auth.refreshUserProfile();

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profile updated successfully!'),
          backgroundColor: DesignTokens.neonGreen.withValues(alpha: 0.9),
          duration: const Duration(seconds: 2),
        ),
      );
      if (widget.isFirstSetup) {
        context.go(app_router.RouteConstants.home);
      } else {
        context.pop();
      }
    }
  }

  Future<void> _saveExtendedMetadata(AuthService auth) async {
    if (auth.isDemoUser) return;
    final uid = auth.firebaseUser?.uid;
    if (uid == null) return;

    try {
      final metadata = <String, dynamic>{
        'location': _cityCtrl.text.trim().isNotEmpty
            ? '${_cityCtrl.text.trim()}, $_selectedCountry'
            : _locationCtrl.text.trim(),
        'country': _selectedCountry,
        'city': _cityCtrl.text.trim(),
        'postcode': _postcodeCtrl.text.trim(),
        'gymName': _gymNameCtrl.text.trim(),
        'fightName': _fightNameCtrl.text.trim(),
        'stance': _selectedStance,
        'weightClass': _selectedWeightClass,
      };

      if (_weightCtrl.text.trim().isNotEmpty) {
        metadata['weight'] = double.tryParse(_weightCtrl.text.trim());
      }
      if (_heightCtrl.text.trim().isNotEmpty) {
        metadata['height'] = double.tryParse(_heightCtrl.text.trim());
      }
      if (_reachCtrl.text.trim().isNotEmpty) {
        metadata['reach'] = double.tryParse(_reachCtrl.text.trim());
      }

      await auth.updateProfileMetadata(metadata);
    } catch (e) {
      debugPrint('Error saving extended metadata: $e');
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
                _buildAvatarSection(),
                const SizedBox(height: 24),
                _buildForm(),
                const SizedBox(height: 32),
                _buildSaveButton(),
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
      leading: widget.isFirstSetup
          ? null
          : IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 18,
              ),
              onPressed: () => context.pop(),
            ),
      title: Text(
        widget.isFirstSetup ? 'Set Up Your Profile' : 'Edit Profile',
        style: const TextStyle(
          color: DesignTokens.textPrimary,
          fontSize: DesignTokens.fontSizeTitle,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ─── Avatar Section (with upload) ───────────────────────────────
  Widget _buildAvatarSection() {
    final auth = context.watch<AuthService>();
    final user = auth.userModel;

    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: _showPhotoOptions,
            child: Stack(
              children: [
                AnimatedBuilder(
                  animation: _pulseCtrl,
                  builder: (context, _) {
                    final p = _pulseCtrl.value;
                    return Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            DesignTokens.neonCyan.withValues(alpha: 0.3),
                            DesignTokens.neonMagenta.withValues(alpha: 0.2),
                          ],
                        ),
                        border: Border.all(
                          color: DesignTokens.neonCyan.withValues(
                            alpha: 0.5 + p * 0.2,
                          ),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: DesignTokens.neonCyan.withValues(
                              alpha: 0.15 + p * 0.1,
                            ),
                            blurRadius: 16 + p * 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: _isUploadingPhoto
                          ? const Center(
                              child: SizedBox(
                                width: 32,
                                height: 32,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: DesignTokens.neonCyan,
                                ),
                              ),
                            )
                          : user?.photoUrl != null && user!.photoUrl!.isNotEmpty
                          ? ClipOval(
                              child: DfcNetworkImage(
                                url: user.photoUrl!,
                                width: 110,
                                height: 110,
                              ),
                            )
                          : const Icon(
                              Icons.person,
                              color: DesignTokens.textPrimary,
                              size: 48,
                            ),
                    );
                  },
                ),
                // Camera badge
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: DesignTokens.neonCyan,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: DesignTokens.bgPrimary,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: DesignTokens.neonCyan.withValues(alpha: 0.4),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.black,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Tap to change photo',
            style: TextStyle(
              color: DesignTokens.neonCyan.withValues(alpha: 0.6),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user?.email ?? 'Not signed in',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 12,
            ),
          ),
          if (user?.role != null) ...[
            const SizedBox(height: 4),
            PillChip(
              label: user!.role.displayName,
              accent: DesignTokens.neonCyan,
              isSmall: true,
            ),
          ],
        ],
      ),
    );
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: DesignTokens.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white30,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Change Profile Photo',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Image will be resized to 800×800',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: DesignTokens.neonCyan.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.photo_library,
                      color: DesignTokens.neonCyan,
                      size: 22,
                    ),
                  ),
                  title: const Text(
                    'Choose from Gallery',
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    'Pick an existing photo',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 12,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _uploadPhoto(ImageSource.gallery);
                  },
                ),
                const Divider(color: Colors.white12, height: 1, indent: 70),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: DesignTokens.neonMagenta.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: DesignTokens.neonMagenta,
                      size: 22,
                    ),
                  ),
                  title: const Text(
                    'Take Photo',
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    'Use your camera',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 12,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _uploadPhoto(ImageSource.camera);
                  },
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _uploadPhoto(ImageSource source) async {
    setState(() => _isUploadingPhoto = true);
    final auth = context.read<AuthService>();
    try {
      final url = await auth.pickAndUploadProfilePhoto(source: source);
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
        if (url != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Photo updated!'),
              backgroundColor: DesignTokens.neonGreen.withValues(alpha: 0.9),
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(auth.error ?? 'Upload failed. Please try again.'),
              backgroundColor: Colors.red.shade800,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: Colors.red.shade800,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // ─── Form ───────────────────────────────────────────────────────────
  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('BASIC INFO'),
          const SizedBox(height: 12),
          _buildField(
            controller: _displayNameCtrl,
            label: 'Display Name',
            hint: 'Your real name',
            icon: Icons.person_outline,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Name is required' : null,
          ),
          const SizedBox(height: 14),
          _buildField(
            controller: _usernameCtrl,
            label: 'Username',
            hint: '@yourusername',
            icon: Icons.alternate_email,
          ),
          const SizedBox(height: 14),
          _buildField(
            controller: _fightNameCtrl,
            label: 'Fight Name / Alias',
            hint: 'e.g. "The Hammer"',
            icon: Icons.sports_mma,
          ),
          const SizedBox(height: 14),
          _buildField(
            controller: _bioCtrl,
            label: 'Bio',
            hint: 'Tell the fight world about yourself...',
            icon: Icons.edit_note,
            maxLines: 3,
          ),
          const SizedBox(height: 14),
          // Structured location fields
          _buildCountryDropdown(),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: _buildField(
                  controller: _cityCtrl,
                  label: 'City',
                  hint: 'e.g. Melbourne',
                  icon: Icons.location_city,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: _buildField(
                  controller: _postcodeCtrl,
                  label: 'Postcode',
                  hint: '3000',
                  icon: Icons.pin_drop,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildField(
            controller: _gymNameCtrl,
            label: 'Gym / Team',
            hint: 'Your training gym or team name',
            icon: Icons.fitness_center_outlined,
          ),
          const SizedBox(height: 28),
          _sectionLabel('ROLE'),
          const SizedBox(height: 12),
          _buildRoleSelector(),
          if (_selectedRole == UserRole.fighter) ...[
            const SizedBox(height: 28),
            _sectionLabel('PHYSICAL STATS'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildField(
                    controller: _heightCtrl,
                    label: 'Height (cm)',
                    hint: '175',
                    icon: Icons.height,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildField(
                    controller: _weightCtrl,
                    label: 'Weight (kg)',
                    hint: '70',
                    icon: Icons.monitor_weight_outlined,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _buildField(
                    controller: _reachCtrl,
                    label: 'Reach (cm)',
                    hint: '180',
                    icon: Icons.open_with,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: _buildStanceDropdown()),
              ],
            ),
            const SizedBox(height: 14),
            _buildWeightClassDropdown(),
          ], // end fighters-only physical stats
        ],
      ),
    );
  }

  // ─── Field Builder ──────────────────────────────────────────────────
  Widget _buildField({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? icon,
    int maxLines = 1,
    TextInputType? keyboardType,
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
          keyboardType: keyboardType,
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

  // ─── Role Selector ─────────────────────────────────────────────────
  Widget _buildRoleSelector() {
    final roles = [
      UserRole.fighter,
      UserRole.coach,
      UserRole.gym,
      UserRole.promoter,
      UserRole.fan,
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: roles.map((role) {
        final sel = role == _selectedRole;
        final roleIcon = switch (role) {
          UserRole.fighter => Icons.sports_mma,
          UserRole.coach => Icons.school,
          UserRole.gym => Icons.fitness_center,
          UserRole.promoter => Icons.campaign,
          UserRole.fan => Icons.people,
          _ => Icons.person,
        };

        return GestureDetector(
          onTap: () => setState(() => _selectedRole = role),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: sel
                  ? DesignTokens.neonCyan.withValues(alpha: 0.12)
                  : Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: sel
                    ? DesignTokens.neonCyan.withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.08),
                width: sel ? 1.5 : 1,
              ),
              boxShadow: sel
                  ? [
                      BoxShadow(
                        color: DesignTokens.neonCyan.withValues(alpha: 0.1),
                        blurRadius: 8,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  roleIcon,
                  color: sel
                      ? DesignTokens.neonCyan
                      : Colors.white.withValues(alpha: 0.4),
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  role.displayName,
                  style: TextStyle(
                    color: sel
                        ? DesignTokens.neonCyan
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
    );
  }

  // ─── Dropdowns ──────────────────────────────────────────────────────
  Widget _buildCountryDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Country',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButtonFormField<String>(
            initialValue: _selectedCountry,
            decoration: const InputDecoration(
              border: InputBorder.none,
              icon: Icon(Icons.public, color: DesignTokens.neonCyan, size: 18),
            ),
            dropdownColor: DesignTokens.bgCard,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            items: HelplineDirectory.supportedCountries.map((c) {
              final hl = HelplineDirectory.forCountry(c);
              return DropdownMenuItem(
                value: c,
                child: Text('${hl?.flag ?? ''} $c'),
              );
            }).toList(),
            onChanged: (v) {
              if (v != null) setState(() => _selectedCountry = v);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStanceDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Stance',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedStance,
              isExpanded: true,
              dropdownColor: DesignTokens.bgPrimary,
              icon: const Icon(
                Icons.keyboard_arrow_down,
                color: DesignTokens.neonCyan,
                size: 18,
              ),
              items: _stances.map((s) {
                return DropdownMenuItem(
                  value: s,
                  child: Text(
                    s,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                );
              }).toList(),
              onChanged: (v) => setState(() => _selectedStance = v!),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeightClassDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Weight Class',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedWeightClass,
              isExpanded: true,
              dropdownColor: DesignTokens.bgPrimary,
              icon: const Icon(
                Icons.keyboard_arrow_down,
                color: DesignTokens.neonCyan,
                size: 18,
              ),
              items: _weightClasses.map((wc) {
                return DropdownMenuItem(
                  value: wc,
                  child: Text(
                    wc,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                );
              }).toList(),
              onChanged: (v) => setState(() => _selectedWeightClass = v!),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Save Button ───────────────────────────────────────────────────
  Widget _buildSaveButton() {
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (context, _) {
        final p = _pulseCtrl.value;
        return GestureDetector(
          onTap: _isSaving ? null : _saveProfile,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  DesignTokens.neonCyan,
                  DesignTokens.neonCyan.withValues(alpha: 0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: DesignTokens.neonCyan.withValues(alpha: 0.2 + p * 0.1),
                  blurRadius: 12 + p * 6,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Center(
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : Text(
                      widget.isFirstSetup ? 'Complete Setup' : 'Save Changes',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }

  // ─── Section Label ─────────────────────────────────────────────────
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
