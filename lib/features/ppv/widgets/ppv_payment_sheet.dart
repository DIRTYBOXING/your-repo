import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/models/ppv_model.dart';
import '../services/ppv_payment_service.dart';

typedef PPVPaymentCallback = Future<void> Function(PPVPurchaseRequest request);

class PPVPurchaseRequest {
  final PaymentMethod paymentMethod;
  final PurchaseTier purchaseTier;
  final double amount;
  final int installmentCount;
  final String externalPaymentReference;

  const PPVPurchaseRequest({
    required this.paymentMethod,
    required this.purchaseTier,
    required this.amount,
    required this.installmentCount,
    required this.externalPaymentReference,
  });
}

/// PPV Payment Sheet with affordability tiers and multiple payment methods
class PPVPaymentSheet extends StatefulWidget {
  final PPVEvent event;
  final PPVPaymentCallback onPaymentConfirmed;

  const PPVPaymentSheet({
    super.key,
    required this.event,
    required this.onPaymentConfirmed,
  });

  @override
  State<PPVPaymentSheet> createState() => _PPVPaymentSheetState();
}

class _PPVPaymentSheetState extends State<PPVPaymentSheet>
    with SingleTickerProviderStateMixin {
  bool _isProcessing = false;
  PaymentMethod _selectedMethod = PaymentMethod.stripe;
  PurchaseTier _selectedTier = PurchaseTier.fullShow;
  final PpvPaymentService _PpvPaymentService = PpvPaymentService();
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  double get _singleFightPrice {
    final candidate = widget.event.standardPrice * 0.28;
    return candidate.clamp(1.99, widget.event.standardPrice).toDouble();
  }

  double get _mainEventPrice {
    final candidate = widget.event.standardPrice * 0.55;
    return candidate.clamp(3.99, widget.event.standardPrice).toDouble();
  }

  double get _selectedPrice {
    switch (_selectedTier) {
      case PurchaseTier.singleFight:
        return _singleFightPrice;
      case PurchaseTier.mainEvent:
        return _mainEventPrice;
      case PurchaseTier.fullShow:
        return widget.event.standardPrice;
    }
  }

  int get _installmentCount {
    return _selectedMethod == PaymentMethod.afterpay ? 4 : 1;
  }

  int get _selectedTierId {
    switch (_selectedTier) {
      case PurchaseTier.singleFight:
        return 2;
      case PurchaseTier.mainEvent:
        return 4;
      case PurchaseTier.fullShow:
        return 5;
    }
  }

  double get _installmentAmount {
    return _selectedPrice / _installmentCount;
  }

  @override
  Widget build(BuildContext context) {
    final viewportHeight = MediaQuery.of(context).size.height;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      top: false,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: bottomInset),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: viewportHeight * 0.88),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF1A0A2E),
                  Color(0xFF0D0416),
                  Color(0xFF0A0A0A),
                ],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              border: Border.all(
                color: const Color(0xFF00F0FF).withValues(alpha: 0.2),
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: Colors.grey[600],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Title
                  const Text(
                    'Complete Purchase',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.event.title,
                    style: TextStyle(fontSize: 16, color: Colors.grey[400]),
                  ),
                  const SizedBox(height: 24),

                  // Package selection
                  const Text(
                    'Choose Your Access',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildTierTile(
                    PurchaseTier.singleFight,
                    'Single Fight',
                    'Best entry price for budget fans',
                    _singleFightPrice,
                  ),
                  const SizedBox(height: 8),
                  _buildTierTile(
                    PurchaseTier.mainEvent,
                    'Main Event Only',
                    'Headliner without full card cost',
                    _mainEventPrice,
                  ),
                  const SizedBox(height: 8),
                  _buildTierTile(
                    PurchaseTier.fullShow,
                    'Full Show',
                    'Every fight on the card',
                    widget.event.standardPrice,
                  ),
                  const SizedBox(height: 20),

                  // Price breakdown
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_selectedTier.label),
                            Text(
                              '\$${_selectedPrice.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        if (_installmentCount > 1) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Installments'),
                              Text(
                                '$_installmentCount x \$${_installmentAmount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '\$${_selectedPrice.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF00F0FF),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Payment methods
                  const Text(
                    'Payment Method',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  _buildPaymentMethodTile(
                    PaymentMethod.stripe,
                    'Credit/Debit Card',
                    Icons.credit_card,
                    'Secure payment via Stripe',
                  ),
                  const SizedBox(height: 8),
                  _buildPaymentMethodTile(
                    PaymentMethod.paypal,
                    'PayPal',
                    Icons.payment,
                    'Pay now or pay later via PayPal',
                  ),
                  const SizedBox(height: 8),
                  _buildPaymentMethodTile(
                    PaymentMethod.afterpay,
                    'Afterpay',
                    Icons.wallet,
                    '4 interest-free installments',
                  ),
                  const SizedBox(height: 24),

                  // Pay button
                  AnimatedBuilder(
                    animation: _glowController,
                    builder: (context, child) {
                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: _selectedMethod == PaymentMethod.paypal
                                  ? const Color(0xFF0070BA).withValues(
                                      alpha: 0.3 + _glowController.value * 0.3,
                                    )
                                  : _selectedMethod == PaymentMethod.afterpay
                                  ? const Color(0xFFB2FCE4).withValues(
                                      alpha: 0.2 + _glowController.value * 0.2,
                                    )
                                  : const Color(0xFF00F0FF).withValues(
                                      alpha: 0.3 + _glowController.value * 0.3,
                                    ),
                              blurRadius: 16 + _glowController.value * 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: child,
                      );
                    },
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isProcessing ? null : _processPayment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _selectedMethod == PaymentMethod.paypal
                              ? const Color(0xFF0070BA)
                              : _selectedMethod == PaymentMethod.afterpay
                              ? const Color(0xFFB2FCE4)
                              : const Color(0xFF00F0FF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isProcessing
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : Text(
                                _selectedMethod == PaymentMethod.afterpay
                                    ? 'PAY $_installmentCount x \$${_installmentAmount.toStringAsFixed(2)}'
                                    : _selectedMethod == PaymentMethod.paypal
                                    ? 'PAY WITH PAYPAL \$${_selectedPrice.toStringAsFixed(2)}'
                                    : 'PAY \$${_selectedPrice.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                  color:
                                      _selectedMethod == PaymentMethod.afterpay
                                      ? Colors.black
                                      : _selectedMethod == PaymentMethod.paypal
                                      ? Colors.white
                                      : Colors.black,
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Security notice
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock, size: 16, color: Colors.grey[400]),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'Secure hosted checkout. Final payment options depend on your region and Stripe configuration.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[400],
                          ),
                          textAlign: TextAlign.center,
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

  Widget _buildTierTile(
    PurchaseTier tier,
    String title,
    String subtitle,
    double price,
  ) {
    final isSelected = _selectedTier == tier;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedTier = tier;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF00F0FF).withValues(alpha: 0.1)
              : Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF00F0FF) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                  ),
                ],
              ),
            ),
            Text(
              '\$${price.toStringAsFixed(2)}',
              style: const TextStyle(
                color: Color(0xFF00F0FF),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodTile(
    PaymentMethod method,
    String title,
    IconData icon,
    String subtitle,
  ) {
    final isSelected = _selectedMethod == method;
    final brandColor = switch (method) {
      PaymentMethod.stripe => const Color(0xFF00F0FF),
      PaymentMethod.paypal => const Color(0xFF0070BA),
      PaymentMethod.afterpay => const Color(0xFFB2FCE4),
    };

    return InkWell(
      onTap: () {
        setState(() {
          _selectedMethod = method;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? brandColor.withValues(alpha: 0.12)
              : Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? brandColor : Colors.transparent,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: brandColor.withValues(alpha: 0.25),
                    blurRadius: 12,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? brandColor : Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? brandColor : Colors.white,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: isSelected ? brandColor : Colors.grey[500],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processPayment() async {
    setState(() {
      _isProcessing = true;
    });

    // Demo mode: simulate successful payment without external services
    final isDemoMode = AppConstants.guestMode || !AppConstants.authEnabled;
    if (isDemoMode) {
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) {
        final request = PPVPurchaseRequest(
          paymentMethod: _selectedMethod,
          purchaseTier: _selectedTier,
          amount: _selectedPrice,
          installmentCount: _installmentCount,
          externalPaymentReference:
              'demo_${DateTime.now().millisecondsSinceEpoch}',
        );
        await widget.onPaymentConfirmed(request);
        if (mounted) Navigator.pop(context);
      }
      return;
    }

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (userId.isEmpty) {
        throw Exception('Please sign in to purchase this event');
      }

      final externalReference =
          'ppv_${widget.event.id}_${_selectedTier.key}_${_selectedMethod.key}_${DateTime.now().millisecondsSinceEpoch}';

      final opened = await _PpvPaymentService.openStripeCheckout(
        userId: userId,
        ppvId: widget.event.id,
        ppvTitle: widget.event.title,
        tierId: _selectedTierId,
      );

      if (!opened) {
        throw Exception(
          _PpvPaymentService.error ?? 'Could not open hosted checkout',
        );
      }

      if (mounted) {
        final request = PPVPurchaseRequest(
          paymentMethod: _selectedMethod,
          purchaseTier: _selectedTier,
          amount: _selectedPrice,
          installmentCount: _installmentCount,
          externalPaymentReference: externalReference,
        );
        await widget.onPaymentConfirmed(request);
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }
}

enum PaymentMethod { stripe, paypal, afterpay }

extension PaymentMethodMeta on PaymentMethod {
  String get key {
    switch (this) {
      case PaymentMethod.stripe:
        return 'stripe';
      case PaymentMethod.paypal:
        return 'paypal';
      case PaymentMethod.afterpay:
        return 'afterpay';
    }
  }

  String get label {
    switch (this) {
      case PaymentMethod.stripe:
        return 'Stripe Card';
      case PaymentMethod.paypal:
        return 'PayPal';
      case PaymentMethod.afterpay:
        return 'Afterpay';
    }
  }
}

enum PurchaseTier { singleFight, mainEvent, fullShow }

extension PurchaseTierMeta on PurchaseTier {
  String get key {
    switch (this) {
      case PurchaseTier.singleFight:
        return 'single_fight';
      case PurchaseTier.mainEvent:
        return 'main_event';
      case PurchaseTier.fullShow:
        return 'full_show';
    }
  }

  String get label {
    switch (this) {
      case PurchaseTier.singleFight:
        return 'Single Fight Access';
      case PurchaseTier.mainEvent:
        return 'Main Event Access';
      case PurchaseTier.fullShow:
        return 'Full Show Access';
    }
  }
}
