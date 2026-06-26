import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/services/identity_verification_service.dart';

/// ═══════════════════════════════════════════════════════════════════════
/// Identity Verification Screen
///
/// Users submit their ID (driver's licence, passport, etc.) to become
/// verified. Verified users get Gold/Diamond badge and trusted status.
/// Destroys fake accounts, spam, and impersonators.
/// ═══════════════════════════════════════════════════════════════════════
class IdentityVerificationScreen extends StatefulWidget {
  const IdentityVerificationScreen({super.key});

  @override
  State<IdentityVerificationScreen> createState() =>
      _IdentityVerificationScreenState();
}

class _IdentityVerificationScreenState
    extends State<IdentityVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();

  IdDocumentType _selectedDocType = IdDocumentType.driversLicence;
  String _selectedCountry = 'Australia';
  bool _submitting = false;
  bool _termsAccepted = false;

  static const List<String> _countries = [
    'Australia',
    'New Zealand',
    'United States',
    'United Kingdom',
    'Canada',
    'Ireland',
    'South Africa',
    'Philippines',
    'India',
    'Japan',
    'Thailand',
    'Brazil',
    'Germany',
    'France',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    context.read<IdentityVerificationService>().loadStatus();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      body: Consumer<IdentityVerificationService>(
        builder: (context, service, _) {
          return CustomScrollView(
            slivers: [
              _buildAppBar(context),
              SliverToBoxAdapter(child: _buildHero()),
              if (service.status == VerificationStatus.none ||
                  service.status == VerificationStatus.rejected)
                SliverToBoxAdapter(child: _buildForm(service))
              else
                SliverToBoxAdapter(child: _buildStatus(service)),
              SliverToBoxAdapter(child: _buildBenefits()),
              SliverToBoxAdapter(child: _buildPrivacyNote()),
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          );
        },
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context) {
    return SliverAppBar(
      backgroundColor: AppTheme.primaryBackground.withValues(alpha: 0.9),
      pinned: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
      ),
      title: const Row(
        children: [
          Icon(Icons.verified, color: Color(0xFFFFD700), size: 22),
          SizedBox(width: 8),
          Text(
            'Get Verified',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3E2723), Color(0xFF1A1A2E)],
        ),
        border: Border.all(
          color: const Color(0xFFFFD700).withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        children: [
          // Gold shield icon
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFFFD700).withValues(alpha: 0.3),
                      const Color(0xFFFFD700).withValues(alpha: 0.1),
                    ],
                  ),
                ),
              ),
              const Icon(Icons.verified, color: Color(0xFFFFD700), size: 48),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'IDENTITY VERIFICATION',
            style: TextStyle(
              color: Color(0xFFFFD700),
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Prove You\'re Real',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Submit your driver\'s licence or government ID.\n'
            'Verified users earn Gold status and help keep\n'
            'the platform free from fakes and spam.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatus(IdentityVerificationService service) {
    final isPending = service.status == VerificationStatus.pending;
    final isVerified = service.status == VerificationStatus.verified;

    final color = isVerified
        ? const Color(0xFFFFD700)
        : isPending
        ? AppTheme.warning
        : AppTheme.error;
    final icon = isVerified
        ? Icons.verified
        : isPending
        ? Icons.hourglass_top
        : Icons.cancel;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 48),
          const SizedBox(height: 12),
          Text(
            service.status.label.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isPending
                ? 'Your ID is being reviewed. This usually takes 24–48 hours.'
                : isVerified
                ? 'You are a verified Gold member. Your badge is visible on your profile.'
                : 'Your verification was expired. You can re-submit below.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
          if (service.currentVerification != null) ...[
            const SizedBox(height: 16),
            _infoRow(
              'Document',
              service.currentVerification!.documentType.label,
            ),
            _infoRow('Name', service.currentVerification!.fullName),
            _infoRow('Country', service.currentVerification!.country),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 13,
            ),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(IdentityVerificationService service) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.neonCyan.withValues(alpha: 0.2)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.badge, color: AppTheme.neonCyan, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Submit Your ID',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Document Type
                const Text(
                  'Document Type',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<IdDocumentType>(
                  initialValue: _selectedDocType,
                  dropdownColor: AppTheme.cardBackground,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppTheme.secondaryBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: IdDocumentType.values
                      .map(
                        (t) => DropdownMenuItem(
                          value: t,
                          child: Text(
                            t.label,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _selectedDocType = v!),
                ),

                const SizedBox(height: 16),

                // Full Name
                const Text(
                  'Full Legal Name (as on ID)',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _fullNameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'e.g. John Michael Smith',
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: AppTheme.secondaryBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().length < 3) {
                      return 'Please enter your full legal name';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Country
                const Text(
                  'Country of Issue',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _selectedCountry,
                  dropdownColor: AppTheme.cardBackground,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppTheme.secondaryBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: _countries
                      .map(
                        (c) => DropdownMenuItem(
                          value: c,
                          child: Text(
                            c,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _selectedCountry = v!),
                ),

                const SizedBox(height: 20),

                // Terms
                CheckboxListTile(
                  value: _termsAccepted,
                  onChanged: (v) => setState(() => _termsAccepted = v ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  activeColor: AppTheme.neonCyan,
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'I confirm this is my real identity and I agree to DFC '
                    'verifying my ID. My documents are stored securely and '
                    'used only for verification purposes.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Submit
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _termsAccepted && !_submitting ? _submit : null,
                    icon: _submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                        : const Icon(Icons.verified_user),
                    label: Text(
                      _submitting ? 'Submitting...' : 'Submit for Verification',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD700),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                if (service.status == VerificationStatus.rejected &&
                    service.currentVerification?.reviewerNote != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.error.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: AppTheme.error,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Previous submission rejected: ${service.currentVerification!.reviewerNote}',
                            style: TextStyle(
                              color: AppTheme.error.withValues(alpha: 0.9),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBenefits() {
    const gold = Color(0xFFFFD700);
    const diamond = Color(0xFFB9F2FF);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: gold.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.star, color: gold, size: 22),
              SizedBox(width: 8),
              Text(
                'Verification Benefits',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _benefit(Icons.verified, gold, 'Gold verified badge on profile'),
          _benefit(Icons.shield, gold, 'Protection against impersonators'),
          _benefit(Icons.people, gold, 'Trusted status in community'),
          _benefit(Icons.trending_up, gold, 'Priority in search & discovery'),
          _benefit(Icons.block, gold, 'Helps eliminate fake accounts & spam'),
          _benefit(
            Icons.diamond,
            diamond,
            'Diamond badge for paid subscribers',
          ),
          _benefit(
            Icons.workspace_premium,
            diamond,
            'Diamond = Verified + Premium subscription',
          ),
        ],
      ),
    );
  }

  Widget _benefit(IconData icon, Color color, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyNote() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lock,
            color: Colors.white.withValues(alpha: 0.5),
            size: 18,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Your ID is encrypted, stored securely, and never shared. '
              'Review is conducted by authorized DFC staff only. '
              'Documents are deleted after verification is complete. '
              'Compliant with Australian Privacy Principles.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    final service = context.read<IdentityVerificationService>();
    final success = await service.submitVerification(
      documentType: _selectedDocType,
      fullName: _fullNameController.text.trim(),
      country: _selectedCountry,
    );

    if (mounted) {
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Verification submitted! We\'ll review within 24-48 hours.'
                : 'Failed to submit. Please try again.',
          ),
        ),
      );
    }
  }
}
