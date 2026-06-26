import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:datafightcentral/core/theme/app_theme.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// STRIPE CONNECT ONBOARDING SCREEN
/// ═══════════════════════════════════════════════════════════════════════════
/// Complete UI for Stripe Connect V2 marketplace integration.
///
/// Features:
///   - Connected account creation
///   - Stripe-hosted onboarding (TFN/ABN collection)
///   - Account status monitoring
///   - Product management
///   - Subscription & billing portal access
///
/// Flow:
///   1. User taps "Become a Partner"
///   2. App creates V2 connected account
///   3. User redirects to Stripe for KYC (TFN, ABN, bank details)
///   4. User returns, account status updates via webhook
///   5. Once active, user can create products and accept payments
/// ═══════════════════════════════════════════════════════════════════════════

class StripeConnectScreen extends StatefulWidget {
  const StripeConnectScreen({super.key});

  @override
  State<StripeConnectScreen> createState() => _StripeConnectScreenState();
}

class _StripeConnectScreenState extends State<StripeConnectScreen>
    with SingleTickerProviderStateMixin {
  // ─── State ─────────────────────────────────────────────────────────────────
  bool _isLoading = true;
  bool _isProcessing = false;
  String? _errorMessage;

  // Account state
  bool _hasAccount = false;
  String? _accountId;
  String _accountStatus = 'none';
  bool _onboardingComplete = false;
  bool _readyToProcessPayments = false;

  // Subscription state
  // ignore: unused_field - retained for future "past subscriber" UI
  bool _hasSubscription = false;
  String? _subscriptionStatus;
  bool _subscriptionActive = false;

  // Products state
  List<Map<String, dynamic>> _products = [];

  // Animation
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Firebase Functions
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'australia-southeast1',
  );

  @override
  void initState() {
    super.initState();
    _initAnimation();
    _loadAccountStatus();
  }

  void _initAnimation() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // ─── Data Loading ──────────────────────────────────────────────────────────

  Future<void> _loadAccountStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Please sign in to continue';
      });
      return;
    }

    try {
      // Get connected account status
      final statusResult = await _functions
          .httpsCallable('getConnectedAccountStatus')
          .call({'userId': user.uid});

      final data = statusResult.data as Map<String, dynamic>;

      if (data['error'] != null) {
        setState(() {
          _isLoading = false;
          _hasAccount = false;
        });
        return;
      }

      setState(() {
        _hasAccount = data['exists'] == true;
        _accountId = data['accountId'];
        _onboardingComplete = data['onboardingComplete'] == true;
        _readyToProcessPayments = data['readyToProcessPayments'] == true;
        _accountStatus = _readyToProcessPayments
            ? 'active'
            : (_onboardingComplete ? 'pending' : 'onboarding_required');
      });

      // If account exists, load subscription status
      if (_hasAccount) {
        await _loadSubscriptionStatus();
        if (_readyToProcessPayments) {
          await _loadProducts();
        }
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load account status: $e';
      });
    }
  }

  Future<void> _loadSubscriptionStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final result = await _functions
          .httpsCallable('getSubscriptionStatus')
          .call({'userId': user.uid});

      final data = result.data as Map<String, dynamic>;

      setState(() {
        _hasSubscription = data['hasSubscription'] == true;
        _subscriptionStatus = data['subscriptionStatus'];
        _subscriptionActive = data['isActive'] == true;
      });
    } catch (e) {
      debugPrint('Failed to load subscription: $e');
    }
  }

  Future<void> _loadProducts() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final result = await _functions
          .httpsCallable('listConnectedProducts')
          .call({'userId': user.uid});

      final data = result.data as Map<String, dynamic>;

      if (data['success'] == true) {
        setState(() {
          _products = List<Map<String, dynamic>>.from(data['products'] ?? []);
        });
      }
    } catch (e) {
      debugPrint('Failed to load products: $e');
    }
  }

  // ─── Actions ───────────────────────────────────────────────────────────────

  Future<void> _createConnectedAccount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showError('Please sign in to continue');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // Step 1: Create the connected account
      final createResult = await _functions
          .httpsCallable('createConnectedAccountV2')
          .call({
            'userId': user.uid,
            'email': user.email,
            'displayName': user.displayName ?? 'DFC Partner',
            'country': 'AU',
          });

      final createData = createResult.data as Map<String, dynamic>;

      if (createData['error'] != null) {
        _showError(createData['error']);
        setState(() => _isProcessing = false);
        return;
      }

      // Step 2: Create onboarding link
      await _startOnboarding();
    } catch (e) {
      _showError('Failed to create account: $e');
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _startOnboarding() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isProcessing = true);

    try {
      final result = await _functions.httpsCallable('createAccountLink').call({
        'userId': user.uid,
      });

      final data = result.data as Map<String, dynamic>;

      if (data['error'] != null) {
        _showError(data['error']);
        setState(() => _isProcessing = false);
        return;
      }

      final onboardingUrl = data['onboardingUrl'] as String?;

      if (onboardingUrl != null) {
        // Open Stripe hosted onboarding
        final uri = Uri.parse(onboardingUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }

      setState(() => _isProcessing = false);

      // Show instructions
      if (mounted) {
        _showOnboardingInstructions();
      }
    } catch (e) {
      _showError('Failed to start onboarding: $e');
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _openBillingPortal() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isProcessing = true);

    try {
      final result = await _functions
          .httpsCallable('createBillingPortalSession')
          .call({'userId': user.uid});

      final data = result.data as Map<String, dynamic>;

      if (data['error'] != null) {
        _showError(data['error']);
        setState(() => _isProcessing = false);
        return;
      }

      final portalUrl = data['portalUrl'] as String?;

      if (portalUrl != null) {
        final uri = Uri.parse(portalUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }

      setState(() => _isProcessing = false);
    } catch (e) {
      _showError('Failed to open billing portal: $e');
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _startSubscription() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isProcessing = true);

    try {
      final result = await _functions
          .httpsCallable('createConnectedSubscription')
          .call({'userId': user.uid});

      final data = result.data as Map<String, dynamic>;

      if (data['error'] != null) {
        _showError(data['error']);
        setState(() => _isProcessing = false);
        return;
      }

      final checkoutUrl = data['checkoutUrl'] as String?;

      if (checkoutUrl != null) {
        final uri = Uri.parse(checkoutUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }

      setState(() => _isProcessing = false);
    } catch (e) {
      _showError('Failed to start subscription: $e');
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _createProduct() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const _CreateProductDialog(),
    );

    if (result == null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isProcessing = true);

    try {
      final createResult = await _functions
          .httpsCallable('createConnectedProduct')
          .call({
            'userId': user.uid,
            'name': result['name'],
            'description': result['description'],
            'priceInCents': result['priceInCents'],
            'currency': 'aud',
          });

      final data = createResult.data as Map<String, dynamic>;

      if (data['error'] != null) {
        _showError(data['error']);
      } else {
        _showSuccess('Product created successfully!');
        await _loadProducts();
      }

      setState(() => _isProcessing = false);
    } catch (e) {
      _showError('Failed to create product: $e');
      setState(() => _isProcessing = false);
    }
  }

  // ─── UI Helpers ────────────────────────────────────────────────────────────

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.neonPink),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.neonGreen),
    );
  }

  void _showOnboardingInstructions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppTheme.neonCyan.withValues(alpha: 0.3)),
        ),
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: AppTheme.neonCyan),
            SizedBox(width: 12),
            Text(
              'Complete Onboarding',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Stripe will collect the following information:',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.person, 'Personal details'),
            _buildInfoRow(Icons.badge, 'TFN or ABN'),
            _buildInfoRow(
              Icons.account_balance,
              'Bank account (BSB + Account)',
            ),
            _buildInfoRow(Icons.verified_user, 'Identity verification'),
            const SizedBox(height: 16),
            const Text(
              'After completing onboarding, return here to check your status.',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('GOT IT', style: TextStyle(color: AppTheme.neonCyan)),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.neonCyan),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Partner Dashboard',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_hasAccount)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white70),
              onPressed: _loadAccountStatus,
            ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _errorMessage != null
          ? _buildErrorState()
          : _buildContent(),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppTheme.neonCyan),
          SizedBox(height: 16),
          Text(
            'Loading account status...',
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppTheme.neonPink),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadAccountStatus,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.neonCyan,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Account Status Card
          _buildAccountStatusCard(),
          const SizedBox(height: 16),

          // Onboarding or Dashboard based on status
          if (!_hasAccount)
            _buildGetStartedCard()
          else if (!_onboardingComplete)
            _buildCompleteOnboardingCard()
          else if (!_readyToProcessPayments)
            _buildPendingVerificationCard()
          else ...[
            // Subscription Card
            _buildSubscriptionCard(),
            const SizedBox(height: 16),

            // Products Card
            _buildProductsCard(),
          ],

          const SizedBox(height: 24),

          // Info Section
          _buildInfoSection(),
        ],
      ),
    );
  }

  Widget _buildAccountStatusCard() {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (_accountStatus) {
      case 'active':
        statusColor = AppTheme.neonGreen;
        statusText = 'Active - Ready to Accept Payments';
        statusIcon = Icons.check_circle;
        break;
      case 'pending':
        statusColor = AppTheme.warning;
        statusText = 'Pending Verification';
        statusIcon = Icons.hourglass_top;
        break;
      case 'onboarding_required':
        statusColor = AppTheme.neonOrange;
        statusText = 'Onboarding Required';
        statusIcon = Icons.assignment;
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'No Account';
        statusIcon = Icons.account_circle_outlined;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            statusColor.withValues(alpha: 0.15),
            AppTheme.cardBackground,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _accountStatus == 'active' ? 1.0 : _pulseAnimation.value,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 32),
                ),
              );
            },
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Account Status',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_accountId != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'ID: ${_accountId!.substring(0, 12)}...',
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGetStartedCard() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.neonCyan.withValues(
                  alpha: 0.1 * _pulseAnimation.value,
                ),
                AppTheme.neonPurple.withValues(
                  alpha: 0.1 * _pulseAnimation.value,
                ),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.neonCyan.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.neonCyan, AppTheme.neonPurple],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.rocket_launch,
                  size: 48,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Become a DFC Partner',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Accept payments, sell products, and grow your combat sports business.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 24),
              _buildFeatureRow(Icons.payments, 'Accept card payments'),
              _buildFeatureRow(Icons.storefront, 'Create your storefront'),
              _buildFeatureRow(Icons.account_balance, 'Direct bank payouts'),
              _buildFeatureRow(Icons.security, 'Stripe\'s secure platform'),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _createConnectedAccount,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.neonCyan,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : const Text(
                          'GET STARTED',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFeatureRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.neonGreen),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildCompleteOnboardingCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.neonOrange.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          const Icon(Icons.assignment, size: 48, color: AppTheme.neonOrange),
          const SizedBox(height: 16),
          const Text(
            'Complete Your Onboarding',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Stripe needs additional information to verify your identity and enable payouts.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _startOnboarding,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.neonOrange,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _isProcessing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'CONTINUE ONBOARDING',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingVerificationCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.warning.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          const Icon(Icons.hourglass_top, size: 48, color: AppTheme.warning),
          const SizedBox(height: 16),
          const Text(
            'Verification in Progress',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Stripe is verifying your information. This usually takes a few minutes but can take up to 24 hours.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: _loadAccountStatus,
            icon: const Icon(Icons.refresh),
            label: const Text('Check Status'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.warning,
              side: const BorderSide(color: AppTheme.warning),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _subscriptionActive
              ? AppTheme.neonGreen.withValues(alpha: 0.5)
              : AppTheme.neonPurple.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _subscriptionActive ? Icons.verified : Icons.star,
                color: _subscriptionActive
                    ? AppTheme.neonGreen
                    : AppTheme.neonPurple,
              ),
              const SizedBox(width: 12),
              const Text(
                'DFC Partner Subscription',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_subscriptionActive)
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.neonGreen.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _subscriptionStatus?.toUpperCase() ?? 'ACTIVE',
                    style: const TextStyle(
                      color: AppTheme.neonGreen,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _isProcessing ? null : _openBillingPortal,
                  child: const Text(
                    'Manage',
                    style: TextStyle(color: AppTheme.neonCyan),
                  ),
                ),
              ],
            )
          else ...[
            const Text(
              'Subscribe to unlock premium features and reduce platform fees.',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _startSubscription,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.neonPurple,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: _isProcessing
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('SUBSCRIBE NOW'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProductsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.storefront, color: AppTheme.neonCyan),
              const SizedBox(width: 12),
              const Text(
                'Your Products',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: _isProcessing ? null : _createProduct,
                icon: const Icon(Icons.add_circle, color: AppTheme.neonGreen),
                tooltip: 'Add Product',
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_products.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 40,
                    color: Colors.white38,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'No products yet',
                    style: TextStyle(color: Colors.white54),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Create your first product to start selling',
                    style: TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _products.length,
              separatorBuilder: (_, _) => const Divider(color: Colors.white10),
              itemBuilder: (context, index) {
                final product = _products[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.neonCyan.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.sell, color: AppTheme.neonCyan),
                  ),
                  title: Text(
                    product['name'] ?? 'Product',
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    product['formattedPrice'] ?? '',
                    style: const TextStyle(color: AppTheme.neonGreen),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: Colors.white38,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.security, size: 18, color: AppTheme.neonCyan),
              SizedBox(width: 8),
              Text(
                'Secure Payments by Stripe',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Your financial data is securely handled by Stripe. DFC never stores your TFN, ABN, or bank account details.',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CREATE PRODUCT DIALOG
// ═══════════════════════════════════════════════════════════════════════════

class _CreateProductDialog extends StatefulWidget {
  const _CreateProductDialog();

  @override
  State<_CreateProductDialog> createState() => _CreateProductDialogState();
}

class _CreateProductDialogState extends State<_CreateProductDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppTheme.neonCyan.withValues(alpha: 0.3)),
      ),
      title: const Row(
        children: [
          Icon(Icons.add_box, color: AppTheme.neonGreen),
          SizedBox(width: 12),
          Text('Create Product', style: TextStyle(color: Colors.white)),
        ],
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Product Name',
                labelStyle: const TextStyle(color: Colors.white54),
                hintText: 'e.g., VIP Ringside Ticket',
                hintStyle: const TextStyle(color: Colors.white38),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.white24),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.neonCyan),
                ),
              ),
              validator: (value) => value?.isEmpty == true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              style: const TextStyle(color: Colors.white),
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Description (optional)',
                labelStyle: const TextStyle(color: Colors.white54),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.white24),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.neonCyan),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _priceController,
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Price (AUD)',
                labelStyle: const TextStyle(color: Colors.white54),
                prefixText: '\$ ',
                prefixStyle: const TextStyle(color: AppTheme.neonGreen),
                hintText: '49.99',
                hintStyle: const TextStyle(color: Colors.white38),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.white24),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.neonCyan),
                ),
              ),
              validator: (value) {
                if (value?.isEmpty == true) return 'Required';
                final price = double.tryParse(value!);
                if (price == null || price < 0.50) {
                  return 'Minimum \$0.50';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCEL', style: TextStyle(color: Colors.white54)),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final price = double.parse(_priceController.text);
              Navigator.pop(context, {
                'name': _nameController.text,
                'description': _descriptionController.text,
                'priceInCents': (price * 100).round(),
              });
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.neonGreen,
            foregroundColor: Colors.black,
          ),
          child: const Text('CREATE'),
        ),
      ],
    );
  }
}
