import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../shared/models/ppv_model.dart';
import '../services/ppv_access_service.dart';
import 'ppv_checkout_sheet.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// PPV GATE — Access Control Wrapper
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Wraps any PPV-protected content (video player, live watch screen, replay).
/// If the user has purchased → shows [child].
/// If not → shows a premium paywall with purchase CTA.
///
/// Uses [PPVAccessService.hasAccess] to check the `ppv_access` collection.
///
/// Usage:
///   PpvGate(
///     ppvId: 'ibc-03-gold-coast',
///     event: loadedPPVEvent,
///     child: DFCVideoPlayer(streamUrl: ...),
///   )
/// ═══════════════════════════════════════════════════════════════════════════
class PpvGate extends StatefulWidget {
  final String ppvId;
  final PPVEvent? event;
  final Widget child;

  const PpvGate({
    super.key,
    required this.ppvId,
    this.event,
    required this.child,
  });

  @override
  State<PpvGate> createState() => _PpvGateState();
}

class _PpvGateState extends State<PpvGate> {
  final PPVAccessService _accessService = PPVAccessService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: _accessService.accessStream(widget.ppvId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.cyanAccent),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_off, color: Colors.red.shade300, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'Could not verify your purchase',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'Check your connection and try again',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          );
        }

        final hasAccess = snapshot.data ?? false;
        if (hasAccess) {
          return Semantics(
            label: 'data-test=entitlement-success-${widget.ppvId}',
            child: Semantics(
              label: 'data-test=watch-now-${widget.ppvId}',
              child: widget.child,
            ),
          );
        }

        return Semantics(
          label: 'data-test=ppv-watch-gate-${widget.ppvId}',
          child: _PpvPaywall(
            ppvId: widget.ppvId,
            event: widget.event,
            onPurchaseComplete: () {}, // StreamBuilder handles the swap now
          ),
        );
      },
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// PPV PAYWALL — Premium Purchase Screen
/// ═══════════════════════════════════════════════════════════════════════════
class _PpvPaywall extends StatelessWidget {
  final String ppvId;
  final PPVEvent? event;
  final VoidCallback onPurchaseComplete;

  const _PpvPaywall({
    required this.ppvId,
    this.event,
    required this.onPurchaseComplete,
  });

  @override
  Widget build(BuildContext context) {
    final title = event?.title ?? 'PPV Event';
    final price = event?.standardPrice ?? 29.99;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0D0416), Colors.black],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Lock icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      DesignTokens.neonMagenta.withValues(alpha: 0.3),
                      DesignTokens.neonCyan.withValues(alpha: 0.3),
                    ],
                  ),
                  border: Border.all(
                    color: DesignTokens.neonMagenta.withValues(alpha: 0.6),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.lock_outline,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Purchase PPV access to watch this event',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 32),

              // Price badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: DesignTokens.neonCyan.withValues(alpha: 0.5),
                  ),
                  color: DesignTokens.neonCyan.withValues(alpha: 0.08),
                ),
                child: Text(
                  'From \$${price.toStringAsFixed(2)} AUD',
                  style: const TextStyle(
                    color: Colors.cyanAccent,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Buy button
              SizedBox(
                width: double.infinity,
                child: Semantics(
                  button: true,
                  label: 'data-test=buy-cta-$ppvId',
                  child: Semantics(
                    button: true,
                    label: 'data-test=ppv-watch-buy-$ppvId',
                    child: ElevatedButton(
                      onPressed: () => _handleBuy(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DesignTokens.neonMagenta,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 8,
                        shadowColor: DesignTokens.neonMagenta.withValues(
                          alpha: 0.5,
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.lock_open, size: 20),
                          SizedBox(width: 10),
                          Text(
                            'BUY PPV ACCESS',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Hosted checkout unlocks entitlement automatically after confirmation.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),

              // Back to hub
              TextButton(
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/home');
                  }
                },
                child: Text(
                  'Back to PPV Hub',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleBuy(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please sign in to purchase'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'SIGN IN',
            textColor: Colors.white,
            onPressed: () => context.push('/login'),
          ),
        ),
      );
      return;
    }

    if (event != null) {
      PPVCheckoutSheet.show(
        context: context,
        event: event!,
        tierId: 4, // Default to Main Card
        paymentMethod: 'stripe',
        userId: user.uid,
      ).then((success) {
        if (success == true) onPurchaseComplete();
      });
    } else {
      // Fallback: navigate to PPV detail for full tier selection
      context.push('/ppv/$ppvId');
    }
  }
}
