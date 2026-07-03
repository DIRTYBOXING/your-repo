import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/glass_panel.dart';
import '../../../core/theme/glow_effects.dart';
import '../../../shared/widgets/dfc_glow_button.dart';
import '../services/ppv_service.dart';

class PpvDetailScreen extends StatefulWidget {
  final String eventId;

  const PpvDetailScreen({super.key, required this.eventId});

  @override
  State<PpvDetailScreen> createState() => _PpvDetailScreenState();
}

class _PpvDetailScreenState extends State<PpvDetailScreen> {
  final _service = PpvService();

  Future<void> _handleWatchPressed(BuildContext context, String entitlementKey) async {
    // In a real app, you would pass the entitlementKey (e.g. 'event_101_full' or 'event_101_fight_3')
    final result = await _service.checkPpvAndEnter(widget.eventId);

    if (result['allowed'] == true && result['streamUrl'] != null) {
      if (context.mounted) {
        context.push('/ppv-stream/${widget.eventId}');
      }
    } else {
      if (context.mounted) {
        // Trigger the purchase flow for this specific entitlement
        _showPurchaseDialog(context, entitlementKey);
      }
    }
  }

  void _showPurchaseDialog(BuildContext context, String entitlementKey) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => GlassPanel(
        backgroundColor: AppColors.glassMedium,
        borderColor: AppColors.neonCyan.withValues(alpha: 0.3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'SECURE ACCESS',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Text(
              'Unlocking access for: $entitlementKey',
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            DfcGlowButton(
              onPressed: () {
                context.pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Processing micro-payment for $entitlementKey...'),
                    backgroundColor: AppColors.neonCyan,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text('CONFIRM PAYMENT'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context.pop(),
              child: const Text('CANCEL', style: TextStyle(color: Colors.white54)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          // Hero Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const Text(
                    'DFC 204: GLOBAL IMPACT',
                    style: TextStyle(
                      color: AppColors.neonCyan,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'TOKYO, JAPAN',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Full Event Purchase
                  GlassPanel(
                    backgroundColor: AppColors.neonMagenta.withValues(alpha: 0.1),
                    borderColor: AppColors.neonMagenta.withValues(alpha: 0.4),
                    shadows: NeonGlow.softMagenta(),
                    child: Column(
                      children: [
                        const Text(
                          'FULL EVENT PASS',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '\$49.99',
                          style: TextStyle(
                            color: AppColors.neonMagenta,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 16),
                        DfcGlowButton(
                          color: AppColors.neonMagenta,
                          onPressed: () => _handleWatchPressed(context, 'full_event'),
                          child: const Text('BUY FULL CARD', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Micro-Sales Section Header
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Text(
                'A LA CARTE FIGHTS',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                ),
              ),
            ),
          ),

          // Individual Fights
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildMicroSaleFight(
                  title: 'MAIN EVENT',
                  fighterA: 'TANAKA',
                  fighterB: 'SMITH',
                  price: '\$14.99',
                  entitlementKey: 'fight_main_event',
                  isMainEvent: true,
                ),
                const SizedBox(height: 16),
                _buildMicroSaleFight(
                  title: 'CO-MAIN EVENT',
                  fighterA: 'SILVA',
                  fighterB: 'JOHNSON',
                  price: '\$9.99',
                  entitlementKey: 'fight_co_main',
                ),
                const SizedBox(height: 16),
                _buildMicroSaleFight(
                  title: 'UNDERCARD',
                  fighterA: 'LEE',
                  fighterB: 'KIM',
                  price: '\$4.99',
                  entitlementKey: 'fight_undercard_3',
                ),
              ]),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildMicroSaleFight({
    required String title,
    required String fighterA,
    required String fighterB,
    required String price,
    required String entitlementKey,
    bool isMainEvent = false,
  }) {
    final borderColor = isMainEvent ? AppColors.neonCyan : Colors.white.withValues(alpha: 0.1);
    final glow = isMainEvent ? NeonGlow.softCyan() : null;

    return GlassPanel(
      backgroundColor: AppColors.glassMedium,
      borderColor: borderColor,
      shadows: glow,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isMainEvent ? AppColors.neonCyan : Colors.white54,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$fighterA vs $fighterB',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                price,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => _handleWatchPressed(context, entitlementKey),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.neonCyan),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('BUY FIGHT', style: TextStyle(color: AppColors.neonCyan, fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
