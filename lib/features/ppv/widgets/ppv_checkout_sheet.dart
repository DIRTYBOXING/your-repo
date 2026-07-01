import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../shared/models/ppv_model.dart';
import '../services/ppv_payment_service.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// PPV CHECKOUT BOTTOM SHEET — Complete Purchase Flow
/// ═══════════════════════════════════════════════════════════════════════════
///
/// A premium checkout experience that handles:
///   1. Package summary display
///   2. Payment method selection
///   3. Promo code entry
///   4. Credits vs Cash toggle
///   5. Secure checkout initiation
///
/// Usage:
///   PPVCheckoutSheet.show(
///     context: context,
///     event: ppvEvent,
///     tierId: selectedTier,
///     paymentMethod: 'stripe',
///     userId: currentUserId,
///   );
/// ═══════════════════════════════════════════════════════════════════════════

class PPVCheckoutSheet extends StatefulWidget {
  final PPVEvent event;
  final int tierId;
  final String initialPaymentMethod;
  final String userId;
  final VoidCallback? onSuccess;
  final VoidCallback? onCancel;

  const PPVCheckoutSheet({
    super.key,
    required this.event,
    required this.tierId,
    required this.initialPaymentMethod,
    required this.userId,
    this.onSuccess,
    this.onCancel,
  });

  /// Show the checkout sheet as a modal bottom sheet
  static Future<bool?> show({
    required BuildContext context,
    required PPVEvent event,
    required int tierId,
    required String paymentMethod,
    required String userId,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PPVCheckoutSheet(
        event: event,
        tierId: tierId,
        initialPaymentMethod: paymentMethod,
        userId: userId,
      ),
    );
  }

  @override
  State<PPVCheckoutSheet> createState() => _PPVCheckoutSheetState();
}

class _PPVCheckoutSheetState extends State<PPVCheckoutSheet> {
  final PPVPaymentService _paymentService = PPVPaymentService();
  final TextEditingController _promoController = TextEditingController();

  late String _selectedPayment;
  bool _useCredits = false;
  int _userCredits = 0;
  bool _isLoading = false;
  String? _promoDiscount;
  String? _error;

  Map<String, dynamic> get _tier => _paymentService.getTier(widget.tierId);
  double get _price => _tier['price'] as double;
  int get _requiredCredits => _tier['credits'] as int;
  bool get _hasEnoughCredits => _userCredits >= _requiredCredits;

  @override
  void initState() {
    super.initState();
    _selectedPayment = widget.initialPaymentMethod;
    _loadUserCredits();
  }

  Future<void> _loadUserCredits() async {
    final credits = await _paymentService.getUserCredits(widget.userId);
    if (mounted) {
      setState(() => _userCredits = credits);
    }
  }

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A0A2E), Color(0xFF0D0416), Colors.black],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: DesignTokens.neonMagenta.withValues(alpha: 0.3),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHandle(),
                  const SizedBox(height: 16),
                  _buildHeader(),
                  const SizedBox(height: 20),
                  _buildOrderSummary(),
                  const SizedBox(height: 16),
                  _buildCreditsToggle(),
                  if (!_useCredits) ...[
                    const SizedBox(height: 16),
                    _buildPaymentMethods(),
                    const SizedBox(height: 16),
                    _buildPromoCode(),
                  ],
                  const SizedBox(height: 20),
                  if (_error != null) _buildError(),
                  _buildCheckoutButton(),
                  const SizedBox(height: 12),
                  _buildSecureNote(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHandle() {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.white24,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [DesignTokens.neonMagenta, DesignTokens.neonRed],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.shopping_cart, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'CHECKOUT',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              Text(
                widget.event.title,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.pop(context, false),
          icon: const Icon(Icons.close, color: Colors.white54),
        ),
      ],
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.receipt_long, color: Colors.white54, size: 16),
              SizedBox(width: 8),
              Text(
                'ORDER SUMMARY',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Package name
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _tier['name'] as String,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '${_tier['type'].toString().toUpperCase()} PACKAGE',
                      style: const TextStyle(
                        color: DesignTokens.neonMagenta,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _useCredits
                        ? '${_requiredCredits}C'
                        : '\$${_price.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: _useCredits
                          ? DesignTokens.neonGold
                          : DesignTokens.neonCyan,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (_promoDiscount != null && !_useCredits)
                    Text(
                      _promoDiscount!,
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ],
          ),
          const Divider(color: Colors.white12, height: 24),
          // Event details
          Row(
            children: [
              const Icon(Icons.event, color: Colors.white38, size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  widget.event.title,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.access_time, color: Colors.white38, size: 14),
              const SizedBox(width: 6),
              Text(
                '7-day replay access included',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCreditsToggle() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            DesignTokens.neonGold.withValues(alpha: 0.15),
            DesignTokens.neonAmber.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DesignTokens.neonGold.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.monetization_on,
            color: DesignTokens.neonGold,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PAY WITH DFC CREDITS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Balance: ${_userCredits}C${_hasEnoughCredits ? '' : ' (Need ${_requiredCredits}C)'}',
                  style: TextStyle(
                    color: _hasEnoughCredits
                        ? Colors.greenAccent
                        : Colors.redAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _useCredits,
            onChanged: _hasEnoughCredits
                ? (v) => setState(() => _useCredits = v)
                : null,
            activeThumbColor: DesignTokens.neonGold,
            inactiveThumbColor: Colors.white30,
            inactiveTrackColor: Colors.white12,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethods() {
    final payments = [
      {'id': 'stripe', 'name': 'Card', 'icon': Icons.credit_card},
      {'id': 'afterpay', 'name': 'Afterpay', 'icon': Icons.schedule},
      {'id': 'zip', 'name': 'Zip', 'icon': Icons.bolt},
      {'id': 'paypal', 'name': 'PayPal', 'icon': Icons.account_balance_wallet},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PAYMENT METHOD',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: payments.map((p) {
            final selected = _selectedPayment == p['id'];
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedPayment = p['id'] as String);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? DesignTokens.neonCyan.withValues(alpha: 0.15)
                      : Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected
                        ? DesignTokens.neonCyan
                        : Colors.white.withValues(alpha: 0.1),
                    width: selected ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      p['icon'] as IconData,
                      color: selected ? DesignTokens.neonCyan : Colors.white54,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      p['name'] as String,
                      style: TextStyle(
                        color: selected
                            ? DesignTokens.neonCyan
                            : Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        if (_selectedPayment == 'afterpay' || _selectedPayment == 'zip')
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Colors.greenAccent,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '4 payments of \$${(_price / 4).toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPromoCode() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _promoController,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Promo code',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                ),
                prefixIcon: const Icon(
                  Icons.local_offer,
                  color: Colors.white38,
                  size: 18,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
          ),
          TextButton(
            onPressed: _promoController.text.isNotEmpty
                ? _applyPromoCode
                : null,
            child: Text(
              'APPLY',
              style: TextStyle(
                color: _promoController.text.isNotEmpty
                    ? DesignTokens.neonCyan
                    : Colors.white30,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _error!,
              style: const TextStyle(color: Colors.redAccent, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _processCheckout,
      style: ElevatedButton.styleFrom(
        backgroundColor: _useCredits
            ? DesignTokens.neonGold
            : DesignTokens.neonMagenta,
        foregroundColor: _useCredits ? Colors.black : Colors.white,
        disabledBackgroundColor: Colors.grey.shade800,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 8,
        shadowColor:
            (_useCredits ? DesignTokens.neonGold : DesignTokens.neonMagenta)
                .withValues(alpha: 0.5),
      ),
      child: _isLoading
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation(Colors.white),
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _useCredits ? Icons.monetization_on : Icons.lock_open,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  _useCredits
                      ? 'SPEND ${_requiredCredits}C — UNLOCK NOW'
                      : 'PAY \$${_price.toStringAsFixed(2)} AUD',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSecureNote() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.lock, color: Colors.white.withValues(alpha: 0.3), size: 12),
        const SizedBox(width: 6),
        Text(
          'Secure hosted checkout • final payment methods depend on region and Stripe configuration',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.3),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Future<void> _applyPromoCode() async {
    final code = _promoController.text.trim();
    if (code.isEmpty) return;

    setState(() => _isLoading = true);

    final result = await _paymentService.validatePromoCode(
      code: code,
      amountCents: (_price * 100).round(),
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result['valid'] == true) {
          final percentOff = result['percentOff'] as int?;
          final amountOff = result['amountOffCents'] as int?;
          if (percentOff != null) {
            _promoDiscount = '$percentOff% OFF';
          } else if (amountOff != null) {
            _promoDiscount = '\$${(amountOff / 100).toStringAsFixed(2)} OFF';
          }
          _error = null;
        } else {
          _promoDiscount = null;
          _error = result['error'] as String? ?? 'Invalid promo code';
        }
      });
    }
  }

  Future<void> _processCheckout() async {
    HapticFeedback.heavyImpact();
    setState(() {
      _isLoading = true;
      _error = null;
    });

    // Demo mode: simulate successful purchase without Cloud Functions
    final isDemoMode = AppConstants.guestMode || !AppConstants.authEnabled;
    if (isDemoMode) {
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) {
        Navigator.pop(context, true);
        widget.onSuccess?.call();
      }
      return;
    }

    try {
      if (_useCredits) {
        // Pay with DFC Credits
        final success = await _paymentService.spendCreditsForPPV(
          userId: widget.userId,
          ppvId: widget.event.id,
          tierId: widget.tierId,
        );

        if (mounted) {
          if (success) {
            Navigator.pop(context, true);
            widget.onSuccess?.call();
          } else {
            setState(() {
              _error = _paymentService.error ?? 'Failed to process credits';
              _isLoading = false;
            });
          }
        }
      } else {
        // Stripe / Afterpay / Zip checkout
        final success = await _paymentService.openStripeCheckout(
          userId: widget.userId,
          ppvId: widget.event.id,
          ppvTitle: widget.event.title,
          tierId: widget.tierId,
          promoCode: _promoController.text.isNotEmpty
              ? _promoController.text.trim()
              : null,
        );

        if (mounted) {
          if (success) {
            Navigator.pop(context, true);
          } else {
            setState(() {
              _error = _paymentService.error ?? 'Failed to open checkout';
              _isLoading = false;
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Checkout failed: $e';
          _isLoading = false;
        });
      }
    }
  }
}
