import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/glass_panel.dart';
import '../../../core/theme/glow_effects.dart';
import '../../../shared/widgets/dfc_glow_button.dart';

class PromoterDashboardScreen extends StatefulWidget {
  const PromoterDashboardScreen({super.key});

  @override
  State<PromoterDashboardScreen> createState() => _PromoterDashboardScreenState();
}

class _PromoterDashboardScreenState extends State<PromoterDashboardScreen> {
  // Mock Data
  final String _totalRevenue = '\$124,500';
  final String _ticketsSold = '3,420';
  final String _ppvBuys = '1,205';

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
        title: const Text(
          'PROMOTER CONTROL ROOM',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildRevenueSnapshot(),
            const SizedBox(height: 24),
            _buildQuickActions(),
            const SizedBox(height: 24),
            _buildEventConfiguration(),
            const SizedBox(height: 24),
            _buildFighterManagement(),
            const SizedBox(height: 40),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.neonCyan,
        child: const Icon(Icons.add, color: Colors.black),
        onPressed: () {
          // Launch Event Builder
        },
      ),
    );
  }

  Widget _buildRevenueSnapshot() {
    return GlassPanel(
      backgroundColor: AppColors.glassMedium,
      borderColor: Colors.greenAccent.withValues(alpha: 0.3),
      shadows: NeonGlow.softCyan(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'LIFETIME REVENUE',
            style: TextStyle(
              color: Colors.greenAccent,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _totalRevenue,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 42,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildMiniStat('TICKETS', _ticketsSold, Icons.confirmation_num),
              const SizedBox(width: 12),
              _buildMiniStat('PPV BUYS', _ppvBuys, Icons.live_tv),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white54, size: 16),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold),
                ),
                Text(
                  value,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildActionBtn('New Event', Icons.add_business, AppColors.neonCyan),
        _buildActionBtn('Posters', Icons.image, AppColors.neonMagenta),
        _buildActionBtn('Payouts', Icons.account_balance_wallet, Colors.greenAccent),
        _buildActionBtn('Marketing', Icons.campaign, Colors.orangeAccent),
      ],
    );
  }

  Widget _buildActionBtn(String label, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.1),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildEventConfiguration() {
    return GlassPanel(
      backgroundColor: AppColors.glassMedium,
      borderColor: AppColors.neonCyan.withValues(alpha: 0.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.stadium, color: AppColors.neonCyan, size: 18),
              SizedBox(width: 8),
              Text(
                'ACTIVE EVENTS',
                style: TextStyle(
                  color: AppColors.neonCyan,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildEventRow('DFC 204: Global Impact', 'Tokyo, Japan • Aug 14', 'Draft'),
          _buildEventRow('DFC 203: The Uprising', 'Las Vegas, NV • Live', 'Live'),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: DfcGlowButton(
              color: AppColors.neonCyan,
              onPressed: () {},
              child: const Text('CONFIGURE EVENT & PPV PRICING', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildEventRow(String title, String details, String status) {
    final isLive = status == 'Live';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                Text(details, style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isLive ? AppColors.neonRed.withValues(alpha: 0.15) : Colors.white10,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isLive ? AppColors.neonRed : Colors.white24),
            ),
            child: Row(
              children: [
                if (isLive) ...[
                  const Icon(Icons.circle, color: AppColors.neonRed, size: 8),
                  const SizedBox(width: 6),
                ],
                Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    color: isLive ? AppColors.neonRed : Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFighterManagement() {
    return GlassPanel(
      backgroundColor: AppColors.glassMedium,
      borderColor: AppColors.neonMagenta.withValues(alpha: 0.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.sports_mma, color: AppColors.neonMagenta, size: 18),
              SizedBox(width: 8),
              Text(
                'BOUT SCHEDULING & ROSTER',
                style: TextStyle(
                  color: AppColors.neonMagenta,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Drag and drop fighters to build your fight card. Setup digital contracts and assign purse splits instantly.',
            style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.handshake, color: AppColors.neonMagenta, size: 18),
            label: const Text('MANAGE FIGHTER CONTRACTS', style: TextStyle(color: AppColors.neonMagenta)),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.neonMagenta.withValues(alpha: 0.5)),
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ],
      ),
    );
  }
}
