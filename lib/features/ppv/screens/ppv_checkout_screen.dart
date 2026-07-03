import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/mux_video_player.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/neon_glow_button.dart';

class PpvCheckoutScreen extends StatefulWidget {
  final String eventId;
  final String eventTitle;
  final String muxPlaybackId;

  const PpvCheckoutScreen({
    Key? key,
    required this.eventId,
    required this.eventTitle,
    required this.muxPlaybackId,
  }) : super(key: key);

  @override
  State<PpvCheckoutScreen> createState() => _PpvCheckoutScreenState();
}

class _PpvCheckoutScreenState extends State<PpvCheckoutScreen> {
  // Listen to the ppv_purchases collection for real-time unlock
  Stream<bool> _checkPurchaseStatus() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value(false);

    return FirebaseFirestore.instance
        .collection('ppv_purchases')
        .where('userId', isEqualTo: user.uid)
        .where('productId', isEqualTo: widget.eventId)
        .where('status', isEqualTo: 'completed')
        .snapshots()
        .map((snapshot) => snapshot.docs.isNotEmpty);
  }

  Future<void> _launchStripeCheckout() async {
    // In production, call a Cloud Function to generate a Stripe Checkout URL
    // For this mockup, we simulate navigating to the Stripe URL.
    final testUrl = Uri.parse('https://checkout.stripe.com/pay/cs_test_...');
    if (await canLaunchUrl(testUrl)) {
      await launchUrl(testUrl, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.eventTitle),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<bool>(
        stream: _checkPurchaseStatus(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.cyanAccent));
          }

          final hasPurchased = snapshot.data ?? false;

          // If unlocked via Stripe Webhook, show the Mux Stream instantly!
          if (hasPurchased) {
            return Column(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: MuxVideoPlayer(
                    playbackId: widget.muxPlaybackId,
                    autoPlay: true,
                  ),
                ),
                const Expanded(
                  child: Center(
                    child: Text(
                      'Live Stream Unlocked',
                      style: TextStyle(color: Colors.greenAccent, fontSize: 18),
                    ),
                  ),
                )
              ],
            );
          }

          // Otherwise, show the Neon Glass Paywall
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: GlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lock_outline, color: Colors.white, size: 64),
                      const SizedBox(height: 16),
                      Text(
                        'Unlock ${widget.eventTitle}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Secure this fight via Stripe to instantly unlock the live Mux stream.',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      NeonGlowButton(
                        text: 'Buy PPV Access - \$49.99',
                        onPressed: _launchStripeCheckout,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
