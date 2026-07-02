import 'package:flutter/material.dart';

import '../services/stripe_payment_service.dart';

class CheckoutFlowScreen extends StatefulWidget {
  const CheckoutFlowScreen({super.key, required this.productId});

  final String productId;

  @override
  State<CheckoutFlowScreen> createState() => _CheckoutFlowScreenState();
}

class _CheckoutFlowScreenState extends State<CheckoutFlowScreen> {
  final StripePaymentService _stripe = StripePaymentService();
  bool _loading = false;
  String? _checkoutUrl;

  Future<void> _startCheckout() async {
    setState(() {
      _loading = true;
    });

    final String url = await _stripe.createCheckoutSession(
      userId: 'demo-user',
      productId: widget.productId,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _checkoutUrl = url;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Center(
        child: _loading
            ? const CircularProgressIndicator()
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Text('Ready to purchase'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _startCheckout,
                    child: const Text('Pay'),
                  ),
                  if (_checkoutUrl != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        'Checkout URL: $_checkoutUrl',
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
