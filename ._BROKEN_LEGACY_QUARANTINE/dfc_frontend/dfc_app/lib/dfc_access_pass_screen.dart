import 'package:flutter/material.dart';
import '../../../shared/services/stripe_payment_service.dart';

class DfcAccessPassScreen extends StatefulWidget {
  final String eventId;
  final String eventTitle;
  final String description;
  final double price;

  const DfcAccessPassScreen({
    super.key,
    required this.eventId,
    required this.eventTitle,
    required this.description,
    required this.price,
  });

  @override
  State<DfcAccessPassScreen> createState() => _DfcAccessPassScreenState();
}

class _DfcAccessPassScreenState extends State<DfcAccessPassScreen> {
  bool _isLoading = false;

  Future<void> _handlePurchase() async {
    setState(() => _isLoading = true);
    try {
      final success = await StripePaymentService().purchasePpvPass(widget.eventId);
      if (success) {
        if (mounted) {
          // Payment successful! Navigate to the PPV Stream.
          Navigator.of(context).pushReplacementNamed(
            '/ppv-stream',
            arguments: widget.eventId,
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment canceled or failed.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error initiating payment: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05060A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.lock_outline, size: 80, color: Colors.cyanAccent),
            const SizedBox(height: 24),
            Text(
              widget.eventTitle.toUpperCase(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.description,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 32),
            Text(
              '\$${widget.price.toStringAsFixed(2)}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.cyanAccent,
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyanAccent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _isLoading ? null : _handlePurchase,
              child: _isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.black,
                        strokeWidth: 3,
                      ),
                    )
                  : const Text(
                      'PURCHASE SECURELY',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}