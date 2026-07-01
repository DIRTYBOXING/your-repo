import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/router_config.dart' as app_router;
import '../../../shared/services/auth_service.dart';
import '../../../shared/services/stripe_connect_service.dart';
import '../controllers/promoter_onboarding_controller.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// PROMOTER ONBOARDING WIZARD — Wired to PromoterOnboardingController
/// Steps: Identity → Terms → Stripe → Assets → Launch
/// ═══════════════════════════════════════════════════════════════════════════

const _kBg = Color(0xFF060A14);
const _kPanel = Color(0xFF0C1226);
const _kBorder = Color(0xFF1A2744);
const _kGold = Color(0xFFFFD740);
const _kGreen = Color(0xFF00E676);
const _kCyan = Color(0xFF00E5FF);

class PromoterOnboardingScreen extends StatelessWidget {
  const PromoterOnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final controller = PromoterOnboardingController(
          authService: Provider.of<AuthService>(context, listen: false),
          stripeService: StripeConnectService(),
        );
        controller.loadProgress();
        return controller;
      },
      child: const _OnboardingBody(),
    );
  }
}

class _OnboardingBody extends StatefulWidget {
  const _OnboardingBody();

  @override
  State<_OnboardingBody> createState() => _OnboardingBodyState();
}

class _OnboardingBodyState extends State<_OnboardingBody> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _regionCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  final _licenseCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final c = context.read<PromoterOnboardingController>();
      _nameCtrl.text = c.promotionName;
      _emailCtrl.text = c.contactEmail;
      _regionCtrl.text = c.region;
      _websiteCtrl.text = c.website;
      _licenseCtrl.text = c.licenseNumber;
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _regionCtrl.dispose();
    _websiteCtrl.dispose();
    _licenseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PromoterOnboardingController>(
      builder: (context, ctrl, _) {
        if (ctrl.isLoading) {
          return const Scaffold(
            backgroundColor: _kBg,
            body: Center(child: CircularProgressIndicator(color: _kGold)),
          );
        }
        return Scaffold(
          backgroundColor: _kBg,
          appBar: AppBar(
            title: const Text('PROMOTER ONBOARDING'),
            backgroundColor: _kBg,
            foregroundColor: _kGold,
            elevation: 0,
            centerTitle: true,
          ),
          body: Column(
            children: [
              _buildProgressBar(ctrl),
              Expanded(child: _buildStepContent(ctrl)),
              _buildNavBar(ctrl),
            ],
          ),
        );
      },
    );
  }

  // ── Progress bar ──────────────────────────────────────────────────
  Widget _buildProgressBar(PromoterOnboardingController ctrl) {
    const labels = ['Identity', 'Terms', 'Stripe', 'Assets', 'Launch'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: List.generate(PromoterOnboardingController.totalSteps, (i) {
          final active = i <= ctrl.currentStep;
          final completed = i < ctrl.currentStep;
          return Expanded(
            child: Row(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: active ? _kGold : _kPanel,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: active ? _kGold : _kBorder,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: completed
                            ? const Icon(
                                Icons.check,
                                color: Colors.black,
                                size: 14,
                              )
                            : Text(
                                '${i + 1}',
                                style: TextStyle(
                                  color: active ? Colors.black : Colors.white54,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      labels[i],
                      style: TextStyle(
                        color: active ? _kGold : Colors.white30,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (i < PromoterOnboardingController.totalSteps - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: completed ? _kGold : _kBorder,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ── Step dispatch ─────────────────────────────────────────────────
  Widget _buildStepContent(PromoterOnboardingController ctrl) {
    switch (ctrl.currentStep) {
      case 0:
        return _buildIdentityStep(ctrl);
      case 1:
        return _buildTermsStep(ctrl);
      case 2:
        return _buildStripeStep(ctrl);
      case 3:
        return _buildAssetsStep(ctrl);
      case 4:
        return _buildLaunchStep(ctrl);
      default:
        return const SizedBox.shrink();
    }
  }

  // ── Step 0: Identity ──────────────────────────────────────────────
  Widget _buildIdentityStep(PromoterOnboardingController ctrl) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Icon(Icons.business, color: _kGold, size: 48),
        const SizedBox(height: 12),
        const Text(
          'ORGANIZATION PROFILE',
          style: TextStyle(
            color: _kGold,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        const Text(
          'Tell us about your promotion',
          style: TextStyle(color: Colors.white54, fontSize: 13),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        _field(
          'Promotion Name *',
          _nameCtrl,
          (v) => ctrl.updatePromotionName(v),
        ),
        _field(
          'Contact Email *',
          _emailCtrl,
          (v) => ctrl.updateContactEmail(v),
          type: TextInputType.emailAddress,
        ),
        _field('Region / Country', _regionCtrl, (v) => ctrl.updateRegion(v)),
        _field(
          'Website',
          _websiteCtrl,
          (v) => ctrl.updateWebsite(v),
          type: TextInputType.url,
        ),
        _field(
          'License / ABN Number',
          _licenseCtrl,
          (v) => ctrl.updateLicenseNumber(v),
        ),
      ],
    );
  }

  // ── Step 1: Terms & Consent ───────────────────────────────────────
  Widget _buildTermsStep(PromoterOnboardingController ctrl) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Icon(Icons.gavel, color: _kGold, size: 48),
        const SizedBox(height: 12),
        const Text(
          'TERMS & CONSENT',
          style: TextStyle(
            color: _kGold,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        const Text(
          'Review and accept the required agreements',
          style: TextStyle(color: Colors.white54, fontSize: 13),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        _consentTile(
          'Platform Terms of Service',
          'You agree to the DFC Promoter Terms of Service, including event '
              'listing standards and content guidelines.',
          ctrl.termsAccepted,
          (v) {
            ctrl.setTermsAccepted(v ?? false);
            if (v == true) {
              ctrl.logConsentAudit(
                consentType: 'terms_of_service',
                version: '1.0',
              );
            }
          },
        ),
        _consentTile(
          'UGC Content License',
          'You grant DFC a non-exclusive license to use event media for '
              'platform promotion, subject to takedown rights.',
          ctrl.ugcLicenseAccepted,
          (v) {
            ctrl.setUgcLicenseAccepted(v ?? false);
            if (v == true) {
              ctrl.logConsentAudit(
                consentType: 'ugc_content_license',
                version: '1.0',
              );
            }
          },
        ),
        _consentTile(
          'Promoter Guarantee',
          'You confirm that all fighters are medically cleared and insured, '
              'and events comply with local regulations.',
          ctrl.promoterGuaranteeAccepted,
          (v) {
            ctrl.setPromoterGuaranteeAccepted(v ?? false);
            if (v == true) {
              ctrl.logConsentAudit(
                consentType: 'promoter_guarantee',
                version: '1.0',
              );
            }
          },
        ),
        _consentTile(
          'Refund & Cancellation Policy',
          'You agree to the DFC refund policy: full refunds if event is '
              'cancelled, partial refunds at your discretion.',
          ctrl.refundPolicyAccepted,
          (v) {
            ctrl.setRefundPolicyAccepted(v ?? false);
            if (v == true) {
              ctrl.logConsentAudit(
                consentType: 'refund_policy',
                version: '1.0',
              );
            }
          },
        ),
      ],
    );
  }

  // ── Step 2: Stripe Connect ────────────────────────────────────────
  Widget _buildStripeStep(PromoterOnboardingController ctrl) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Icon(Icons.account_balance_wallet, color: _kGold, size: 48),
        const SizedBox(height: 12),
        const Text(
          'STRIPE CONNECT',
          style: TextStyle(
            color: _kGold,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        const Text(
          'Connect your Stripe account to receive payouts',
          style: TextStyle(color: Colors.white54, fontSize: 13),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        _statusCard(
          Icons.account_balance,
          _kCyan,
          'How DFC handles payouts',
          'DFC does not hold or custody promoter money. Payments are '
              'processed through your connected Stripe account and payouts '
              'settle directly to your bank per Stripe/settlement schedule.',
        ),
        const SizedBox(height: 16),
        if (ctrl.stripeOnboarded)
          _statusCard(
            Icons.check_circle,
            _kGreen,
            'Stripe Connected',
            'Account ${ctrl.stripeAccountId ?? ''} is active. Charges and payouts enabled.',
          )
        else ...[
          _statusCard(
            Icons.warning_amber,
            Colors.orange,
            'Not Connected',
            'You need to connect a Stripe account to receive ticket sales and PPV revenue.',
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () async {
                final url = await ctrl.startStripeOnboarding();
                if (url != null) {
                  final uri = Uri.parse(url);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                }
              },
              icon: const Icon(Icons.open_in_new, size: 18),
              label: const Text('CONNECT STRIPE ACCOUNT'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kGold,
                foregroundColor: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton.icon(
              onPressed: () => ctrl.refreshStripeStatus(),
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('REFRESH STATUS'),
              style: TextButton.styleFrom(foregroundColor: _kGold),
            ),
          ),
        ],
      ],
    );
  }

  // ── Step 3: Assets ────────────────────────────────────────────────
  Widget _buildAssetsStep(PromoterOnboardingController ctrl) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Icon(Icons.photo_library, color: _kGold, size: 48),
        const SizedBox(height: 12),
        const Text(
          'MEDIA ASSETS',
          style: TextStyle(
            color: _kGold,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          '${ctrl.assetsCompleted}/4 uploaded',
          style: const TextStyle(color: Colors.white54, fontSize: 13),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        _assetTile(
          'Hero Image (required)',
          Icons.image,
          ctrl.heroImageUploaded,
          (v) => ctrl.markHeroImageUploaded(v),
        ),
        _assetTile(
          'Event Poster (required)',
          Icons.wallpaper,
          ctrl.eventPosterUploaded,
          (v) => ctrl.markEventPosterUploaded(v),
        ),
        _assetTile(
          'Promo Clip (optional)',
          Icons.videocam,
          ctrl.promoClipUploaded,
          (v) => ctrl.markPromoClipUploaded(v),
        ),
        _assetTile(
          'Fighter Consent Forms (optional)',
          Icons.description,
          ctrl.consentFormsUploaded,
          (v) => ctrl.markConsentFormsUploaded(v),
        ),
      ],
    );
  }

  // ── Step 4: Launch ────────────────────────────────────────────────
  Widget _buildLaunchStep(PromoterOnboardingController ctrl) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Icon(Icons.rocket_launch, color: _kGold, size: 48),
        const SizedBox(height: 12),
        const Text(
          'READY TO LAUNCH',
          style: TextStyle(
            color: _kGold,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        _summaryRow('Promotion', ctrl.promotionName),
        _summaryRow('Email', ctrl.contactEmail),
        _summaryRow('Region', ctrl.region),
        _summaryRow(
          'Stripe',
          ctrl.stripeOnboarded ? 'Connected ✓' : 'Not connected',
        ),
        _summaryRow('Assets', '${ctrl.assetsCompleted}/4 uploaded'),
        _summaryRow(
          'Terms',
          ctrl.allTermsAccepted ? 'All accepted ✓' : 'Incomplete',
        ),
        _summaryRow(
          'Payout custody',
          'DFC does not hold promoter funds; Stripe settles payouts directly',
        ),
        _summaryRow(
          'Rights Intake',
          !ctrl.rightsIntakeStarted
              ? 'Not started'
              : ctrl.rightsIntakeApproved
              ? 'Approved ✓'
              : ctrl.rightsIntakeSubmitted
              ? 'Submitted for review'
              : 'Draft saved',
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.push(
                  app_router.RouterConfig.promoterRightsIntakePath,
                ),
                icon: const Icon(Icons.gavel),
                label: const Text('OPEN RIGHTS INTAKE'),
                style: OutlinedButton.styleFrom(foregroundColor: _kGold),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: ctrl.refreshRightsIntakeStatus,
                icon: const Icon(Icons.refresh),
                label: const Text('REFRESH STATUS'),
                style: OutlinedButton.styleFrom(foregroundColor: _kGold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () =>
                    context.push(app_router.RouterConfig.howWeWorkPath),
                icon: const Icon(Icons.info_outline),
                label: const Text('HOW DFC WORKS'),
                style: OutlinedButton.styleFrom(foregroundColor: _kGold),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.push('/promoter/hub'),
                icon: const Icon(Icons.hub),
                label: const Text('PROMOTER HUB'),
                style: OutlinedButton.styleFrom(foregroundColor: _kGold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () async {
              final uri = Uri.parse('${Uri.base.origin}/promoters.html');
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            icon: const Icon(Icons.open_in_new),
            label: const Text('OPEN PROMOTER PACKAGE'),
            style: OutlinedButton.styleFrom(foregroundColor: _kGold),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Money flow at DFC: viewer pays at checkout, settlement is tracked in '
          'promoter reporting, and payout goes to your connected account. '
          'DFC platform fees are transparent in reconciliation.',
          style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.4),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        _consentTile(
          'Final Confirmation',
          'I confirm all information is accurate and I am authorized to '
              'represent this promotion on the DFC platform.',
          ctrl.finalConfirmAccepted,
          (v) => ctrl.setFinalConfirmAccepted(v ?? false),
        ),
        if (ctrl.errorMessage != null) ...[
          const SizedBox(height: 12),
          Text(
            ctrl.errorMessage!,
            style: const TextStyle(color: Colors.redAccent, fontSize: 13),
          ),
        ],
      ],
    );
  }

  // ── Shared widgets ────────────────────────────────────────────────

  Widget _field(
    String label,
    TextEditingController tc,
    ValueChanged<String> onChanged, {
    TextInputType? type,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: tc,
        onChanged: onChanged,
        keyboardType: type,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white38),
          filled: true,
          fillColor: _kPanel,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _kBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _kBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _kGold),
          ),
        ),
      ),
    );
  }

  Widget _consentTile(
    String title,
    String desc,
    bool value,
    ValueChanged<bool?> onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _kPanel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: value ? _kGreen : _kBorder),
      ),
      child: CheckboxListTile(
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            desc,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: _kGreen,
        checkColor: Colors.black,
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
    );
  }

  Widget _statusCard(IconData icon, Color color, String title, String desc) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kPanel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(128)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _assetTile(
    String label,
    IconData icon,
    bool uploaded,
    ValueChanged<bool> onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _kPanel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: uploaded ? _kGreen : _kBorder),
      ),
      child: ListTile(
        leading: Icon(icon, color: uploaded ? _kGreen : Colors.white38),
        title: Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
        trailing: Switch(
          value: uploaded,
          onChanged: onChanged,
          activeThumbColor: _kGreen,
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white38, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  // ── Navigation bar ────────────────────────────────────────────────
  Widget _buildNavBar(PromoterOnboardingController ctrl) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: _kPanel,
        border: Border(top: BorderSide(color: _kBorder)),
      ),
      child: Row(
        children: [
          if (ctrl.currentStep > 0)
            TextButton.icon(
              onPressed: () => ctrl.previousStep(),
              icon: const Icon(Icons.arrow_back, size: 16),
              label: const Text('BACK'),
              style: TextButton.styleFrom(foregroundColor: Colors.white54),
            ),
          const Spacer(),
          Text(
            'Step ${ctrl.currentStep + 1} of ${PromoterOnboardingController.totalSteps}',
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
          const Spacer(),
          if (ctrl.isLastStep)
            ElevatedButton.icon(
              onPressed: ctrl.canContinue && !ctrl.isSaving
                  ? () async {
                      final success = await ctrl.completeOnboarding();
                      if (success && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Promoter onboarding complete!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        Navigator.of(context).pop(true);
                      }
                    }
                  : null,
              icon: ctrl.isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : const Icon(Icons.rocket_launch, size: 16),
              label: Text(ctrl.isSaving ? 'SAVING...' : 'LAUNCH'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kGreen,
                foregroundColor: Colors.black,
                disabledBackgroundColor: Colors.grey[800],
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            )
          else
            ElevatedButton.icon(
              onPressed: ctrl.canContinue ? () => ctrl.nextStep() : null,
              icon: const Icon(Icons.arrow_forward, size: 16),
              label: const Text('NEXT'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kGold,
                foregroundColor: Colors.black,
                disabledBackgroundColor: Colors.grey[800],
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
