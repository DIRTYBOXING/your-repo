import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/services/auth_service.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// SPONSORSHIP SYSTEM
/// Where Brands bid on DFC Placements (Canvas, Broadcast, App Overlays).
/// ═══════════════════════════════════════════════════════════════════════════
class SponsorshipSystemScreen extends StatefulWidget {
  const SponsorshipSystemScreen({super.key});

  @override
  State<SponsorshipSystemScreen> createState() =>
      _SponsorshipSystemScreenState();
}

class _SponsorshipSystemScreenState extends State<SponsorshipSystemScreen> {
  bool _isBidding = false;

  Future<void> _submitBid(
    String placementId,
    String promoterId,
    int amountCents,
  ) async {
    setState(() => _isBidding = true);
    try {
      final callable = FirebaseFunctions.instance.httpsCallable(
        'placeSponsorBid',
      );
      await callable.call({
        'placementId': placementId,
        'promoterId': promoterId,
        'bidAmountCents': amountCents,
        'brandName':
            context.read<AuthService>().userModel?.displayName ?? 'Brand',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bid submitted successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isBidding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          'AD SPOTLIGHT & BIDDING',
          style: TextStyle(
            color: Colors.amberAccent,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'AVAILABLE INVENTORY',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildPlacementCard(
            title: 'Main Event Canvas Logo',
            event: 'DFC Fight Night 12',
            promoterId: 'promo_123',
            placementId: 'placement_canvas_1',
            minBid: 500000, // $5,000.00
            icon: Icons.stadium,
          ),
          const SizedBox(height: 16),
          _buildPlacementCard(
            title: 'Broadcast Lower-Third Overlay',
            event: 'DFC Fight Night 12',
            promoterId: 'promo_123',
            placementId: 'placement_broadcast_1',
            minBid: 250000, // $2,500.00
            icon: Icons.live_tv,
          ),
        ],
      ),
    );
  }

  Widget _buildPlacementCard({
    required String title,
    required String event,
    required String promoterId,
    required String placementId,
    required int minBid,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.amberAccent),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(event, style: const TextStyle(color: Colors.white54)),
          const SizedBox(height: 16),
          Text(
            'Current Minimum Bid: \$${(minBid / 100).toStringAsFixed(2)}',
            style: const TextStyle(
              color: AppColors.neonGreen,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amberAccent,
                foregroundColor: Colors.black,
              ),
              onPressed: _isBidding
                  ? null
                  : () => _submitBid(
                      placementId,
                      promoterId,
                      minBid + 10000,
                    ), // Bid min + $100
              child: _isBidding
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(color: Colors.black),
                    )
                  : const Text('PLACE BID (+ \$100)'),
            ),
          ),
        ],
      ),
    );
  }
}
