import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/glass_panel.dart';
import '../../../core/theme/glow_effects.dart';
import '../../../shared/widgets/dfc_glow_button.dart';

class CommercialRevenueDashboardScreen extends StatefulWidget {
  const CommercialRevenueDashboardScreen({super.key});

  @override
  State<CommercialRevenueDashboardScreen> createState() => _CommercialRevenueDashboardScreenState();
}

class _CommercialRevenueDashboardScreenState extends State<CommercialRevenueDashboardScreen> {
  // Mock Data for the Meta-Apex 5 Traffic Pipeline
  final String _viralTrafficIn = '14.2M'; // e.g. from reels/ring girls targeted to specific regions
  final String _ppvConversion = '8.4%';
  final String _adRevenue = '\$142,500';

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
          'GLOBAL REVENUE & ADS',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics, color: AppColors.neonCyan),
            onPressed: () {},
          )
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildMetaApexPipeline(),
            const SizedBox(height: 24),
            _buildAdSalesInventory(),
            const SizedBox(height: 24),
            _buildContentMonetization(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaApexPipeline() {
    return GlassPanel(
      backgroundColor: AppColors.glassMedium,
      borderColor: AppColors.neonCyan.withValues(alpha: 0.4),
      shadows: NeonGlow.softCyan(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.hub, color: AppColors.neonCyan, size: 20),
              SizedBox(width: 8),
              Text(
                'META-APEX 5 PIPELINE',
                style: TextStyle(
                  color: AppColors.neonCyan,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Live traffic ingestion from social feeds (Viral Reels, High-Drama Face-offs) converting into platform engagement and PPV sales.',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildMetricCard('INBOUND\nTRAFFIC', _viralTrafficIn, Colors.blueAccent),
              const SizedBox(width: 12),
              const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 16),
              const SizedBox(width: 12),
              _buildMetricCard('PPV / EVENT\nCONVERSION', _ppvConversion, AppColors.neonMagenta),
            ],
          ),
          const SizedBox(height: 16),
          const LinearProgressIndicator(
            value: 0.84,
            backgroundColor: Colors.white10,
            color: AppColors.neonCyan,
            minHeight: 4,
          ),
          const SizedBox(height: 8),
          const Text(
            'Targeted Distribution: High saturation in India, Pakistan, Brazil, & US Markets.',
            style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold),
          )
        ],
      ),
    );
  }

  Widget _buildAdSalesInventory() {
    return GlassPanel(
      backgroundColor: AppColors.glassMedium,
      borderColor: AppColors.neonMagenta.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ADVERTISING INVENTORY & SPONSORSHIPS',
            style: TextStyle(
              color: AppColors.neonMagenta,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          _buildAdRow('Broadcast Lower-Thirds', 'Active: Monster Energy', '2 slots available', Icons.tv),
          _buildAdRow('Octagon Canvas Digital Ads', 'Active: Crypto.com', 'SOLD OUT', Icons.sports_mma),
          _buildAdRow('In-Feed Sponsored Posts', 'Active: DraftKings', 'Unlimited', Icons.feed),
          const SizedBox(height: 20),
          DfcGlowButton(
            color: AppColors.neonMagenta,
            onPressed: () {},
            child: const Text('CREATE NEW AD CAMPAIGN', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildContentMonetization() {
    return GlassPanel(
      backgroundColor: AppColors.glassMedium,
      borderColor: Colors.greenAccent.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CONTENT MONETIZATION (NEWS & EVENTS)',
            style: TextStyle(
              color: Colors.greenAccent,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Content Revenue (30D):', style: TextStyle(color: Colors.white70)),
              Text(_adRevenue, style: const TextStyle(color: Colors.greenAccent, fontSize: 20, fontWeight: FontWeight.w900)),
            ],
          ),
          const Divider(color: Colors.white10, height: 32),
          _buildMonetizationItem('Promoted Fight News', 'Boosted articles in the Global Feed.', '+ \$12,400'),
          _buildMonetizationItem('Viral Creator Payouts', 'Revenue split from high-traffic reels.', '- \$4,200'),
          _buildMonetizationItem('Event Title Sponsorships', 'B2B enterprise package sales.', '+ \$134,300'),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, height: 1.2),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdRow(String title, String active, String availability, IconData icon) {
    final isSoldOut = availability.toUpperCase() == 'SOLD OUT';
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.white54, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text(active, style: const TextStyle(color: Colors.white54, fontSize: 11)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isSoldOut ? Colors.redAccent.withValues(alpha: 0.1) : AppColors.neonCyan.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: isSoldOut ? Colors.redAccent.withValues(alpha: 0.5) : AppColors.neonCyan.withValues(alpha: 0.5)),
            ),
            child: Text(
              availability,
              style: TextStyle(
                color: isSoldOut ? Colors.redAccent : AppColors.neonCyan,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMonetizationItem(String title, String desc, String amount) {
    final isPositive = amount.contains('+');
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                Text(desc, style: const TextStyle(color: Colors.white54, fontSize: 11)),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              color: isPositive ? Colors.greenAccent : Colors.redAccent,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}