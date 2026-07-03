import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/glass_panel.dart';
import '../../../core/theme/glow_effects.dart';
import '../../../shared/widgets/dfc_glow_button.dart';

class PpvDoorSalesScreen extends StatefulWidget {
  final String eventId;
  const PpvDoorSalesScreen({super.key, required this.eventId});

  @override
  State<PpvDoorSalesScreen> createState() => _PpvDoorSalesScreenState();
}

class _PpvDoorSalesScreenState extends State<PpvDoorSalesScreen> {
  bool _isScanning = false;
  final String _lastScanResult = '';

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
          'DOOR SALES & ENTRY',
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
            icon: const Icon(Icons.history, color: AppColors.neonCyan),
            onPressed: () {
              // Show scan history
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Event Info Card
              GlassPanel(
                backgroundColor: AppColors.glassMedium,
                borderColor: AppColors.neonCyan.withValues(alpha: 0.3),
                shadows: NeonGlow.softCyan(),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppColors.neonCyan.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.neonCyan.withValues(alpha: 0.5),
                        ),
                      ),
                      child: const Icon(
                        Icons.stadium,
                        color: AppColors.neonCyan,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'LIVE EVENT ENTRY',
                            style: TextStyle(
                              color: AppColors.neonCyan,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'DFC 204: Global Impact',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Action Tabs
              Row(
                children: [
                  Expanded(
                    child: _buildActionTab(
                      'SCAN TICKETS',
                      Icons.qr_code_scanner,
                      !_isScanning,
                      () => setState(() => _isScanning = false),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildActionTab(
                      'SELL AT DOOR',
                      Icons.point_of_sale,
                      _isScanning,
                      () => setState(() => _isScanning = true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Dynamic Content Area
              Expanded(
                child: _isScanning ? _buildDoorSales() : _buildScanner(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionTab(
    String title,
    IconData icon,
    bool isActive,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: GlassPanel(
        backgroundColor: isActive
            ? AppColors.neonCyan.withValues(alpha: 0.15)
            : AppColors.glassMedium,
        borderColor: isActive
            ? AppColors.neonCyan.withValues(alpha: 0.8)
            : Colors.white.withValues(alpha: 0.1),
        shadows: isActive ? NeonGlow.softCyan() : null,
        child: Column(
          children: [
            Icon(
              icon,
              color: isActive ? AppColors.neonCyan : Colors.white54,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.white54,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanner() {
    return GlassPanel(
      backgroundColor: AppColors.glassMedium,
      borderColor: AppColors.neonMagenta.withValues(alpha: 0.3),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Simulated Scanner Viewfinder
          Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              border: Border.all(
                color: AppColors.neonCyan,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: NeonGlow.softCyan(),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(
                  Icons.qr_code,
                  size: 120,
                  color: Colors.white24,
                ),
                // Scanning animation line could go here
                Container(
                  height: 2,
                  width: 200,
                  decoration: BoxDecoration(
                    color: AppColors.neonCyan,
                    boxShadow: NeonGlow.softCyan(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Ready to scan digital ticket...',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (_lastScanResult.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.greenAccent),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, color: Colors.greenAccent),
                  const SizedBox(width: 8),
                  Text(
                    _lastScanResult,
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildDoorSales() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GlassPanel(
            backgroundColor: AppColors.glassMedium,
            borderColor: Colors.white.withValues(alpha: 0.1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'QUICK SELL TICKETS',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                _buildTicketOption(
                  'General Admission',
                  '\$49.99',
                  'Standard entry',
                  Icons.confirmation_num,
                ),
                const SizedBox(height: 16),
                _buildTicketOption(
                  'VIP Access',
                  '\$149.99',
                  'Premium seating + Meet & Greet',
                  Icons.star,
                  isVip: true,
                ),
                const SizedBox(height: 16),
                _buildTicketOption(
                  'Micro-Payment Plan',
                  '\$12.50/mo',
                  'Split in 4 payments - Never miss an event!',
                  Icons.payments,
                  isPaymentPlan: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          DfcGlowButton(
            onPressed: () {
              // Launch Stripe or Tap-to-Pay
            },
            child: const Text(
              'PROCESS PRIMARY PAYMENT',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Launch PayPal / Venmo flow
                  },
                  icon: const Icon(Icons.paypal, size: 18, color: Colors.blueAccent),
                  label: const Text(
                    'PayPal / Venmo',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Launch Apple/Google Pay or Afterpay
                  },
                  icon: const Icon(Icons.account_balance_wallet, size: 18, color: Colors.greenAccent),
                  label: const Text(
                    'More Options',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.contactless, color: Colors.white70),
            label: const Text(
              'Accept Tap-to-Pay on Phone',
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketOption(
    String title,
    String price,
    String desc,
    IconData icon, {
    bool isVip = false,
    bool isPaymentPlan = false,
  }) {
    final color = isVip
        ? AppColors.neonMagenta
        : (isPaymentPlan ? Colors.greenAccent : AppColors.neonCyan);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  desc,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            price,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}
