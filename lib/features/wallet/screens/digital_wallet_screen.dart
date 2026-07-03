import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/glass_panel.dart';
import '../../../core/theme/glow_effects.dart';

class DigitalWalletScreen extends StatefulWidget {
  const DigitalWalletScreen({super.key});

  @override
  State<DigitalWalletScreen> createState() => _DigitalWalletScreenState();
}

class _DigitalWalletScreenState extends State<DigitalWalletScreen> {
  int _selectedTab = 0; // 0 = Cash, 1 = Fight Coin, 2 = Fit Coin

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
          'DFC DIGITAL WALLET',
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
        child: Column(
          children: [
            // Top Balance Switcher
            _buildBalanceHeader(),
            const SizedBox(height: 24),
            
            // Tab Selector
            _buildWalletTabs(),
            const SizedBox(height: 24),

            // Dynamic Content Area
            Expanded(
              child: _buildWalletContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceHeader() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: GlassPanel(
        backgroundColor: AppColors.glassMedium,
        borderColor: _getPrimaryColor().withValues(alpha: 0.3),
        shadows: NeonGlow.softCyan(),
        child: Column(
          children: [
            Text(
              _getPrimaryLabel(),
              style: TextStyle(
                color: _getPrimaryColor(),
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_selectedTab == 0)
                  const Text(
                    '\$',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                Text(
                  _getPrimaryBalance(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (_selectedTab != 0) ...[
                  const SizedBox(width: 8),
                  Text(
                    _selectedTab == 1 ? 'DFC' : 'FIT',
                    style: TextStyle(
                      color: _getPrimaryColor(),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildQuickAction('SEND', Icons.send),
                _buildQuickAction('RECEIVE', Icons.qr_code),
                _buildQuickAction('SWAP', Icons.swap_horiz),
                if (_selectedTab == 0) _buildQuickAction('WITHDRAW', Icons.account_balance),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction(String label, IconData icon) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _getPrimaryColor().withValues(alpha: 0.1),
            border: Border.all(color: _getPrimaryColor().withValues(alpha: 0.3)),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildWalletTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _buildTab(0, 'CASH PURSE', Icons.attach_money, Colors.greenAccent),
          const SizedBox(width: 12),
          _buildTab(1, 'FIGHT COIN', Icons.diamond, AppColors.neonCyan),
          const SizedBox(width: 12),
          _buildTab(2, 'FIT COIN', Icons.local_fire_department, AppColors.neonMagenta),
        ],
      ),
    );
  }

  Widget _buildTab(int index, String title, IconData icon, Color color) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : AppColors.glassMedium,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color.withValues(alpha: 0.6) : Colors.white24,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? color : Colors.white54, size: 16),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white54,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletContent() {
    switch (_selectedTab) {
      case 1:
        return _buildFightCoinLedger();
      case 2:
        return _buildFitCoinLedger();
      case 0:
      default:
        return _buildCashLedger();
    }
  }

  Widget _buildCashLedger() {
    return _buildLedgerView(
      'CASH TRANSACTIONS',
      [
        _buildTransactionRow('Ticket Door Sale', 'General Admission', '+ \$49.99', Colors.greenAccent),
        _buildTransactionRow('PPV Main Event', 'A-La-Carte Purchase', '+ \$14.99', Colors.greenAccent),
        _buildTransactionRow('Payout Transfer', 'Stripe Connect', '- \$1,200.00', Colors.white54),
      ],
    );
  }

  Widget _buildFightCoinLedger() {
    return _buildLedgerView(
      'EVENT PAYMENT SYSTEM',
      [
        _buildTransactionRow('PPV Main Event', 'A-La-Carte Unlock', '- 150 DFC', Colors.white54),
        _buildTransactionRow('Ticket Door Sale', 'VIP Access', '- 1500 DFC', Colors.white54),
        _buildTransactionRow('Tip to Fighter', 'Sent to @Tanaka_MMA', '- 50 DFC', Colors.white54),
      ],
      customHero: _buildCoinPromo(
        'DIGITAL FIGHT COIN (DFC)',
        'The global payment system for events. Use DFC for instant PPV unlocks, door sales, live stream micro-payments, and frictionless event access worldwide.',
        AppColors.neonCyan,
        Icons.stadium,
      ),
    );
  }

  Widget _buildFitCoinLedger() {
    return _buildLedgerView(
      'CREATOR & FIGHTER PAYOUTS',
      [
        _buildTransactionRow('Fight Win Bonus', 'DFC 204 Main Event', '+ 5000 FIT', AppColors.neonMagenta),
        _buildTransactionRow('Content Monetization', 'Viral Coaching Reel', '+ 850 FIT', AppColors.neonMagenta),
        _buildTransactionRow('Sponsorship Yield', 'NVIDIA Brand Deal', '+ 2500 FIT', AppColors.neonMagenta),
      ],
      customHero: _buildCoinPromo(
        'CREATORS DIGITAL FIT COIN',
        'The official payout and reward token for fighters, coaches, and creators. Earn FIT from fight performances, content monetization, and affiliate payouts.',
        AppColors.neonMagenta,
        Icons.military_tech,
      ),
    );
  }

  Widget _buildCoinPromo(String title, String desc, Color color, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.2),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  desc,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLedgerView(String title, List<Widget> transactions, {Widget? customHero}) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        if (customHero != null) customHero,
        Text(
          title,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: 16),
        ...transactions,
      ],
    );
  }

  Widget _buildTransactionRow(String title, String subtitle, String amount, Color amountColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.glassMedium,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.receipt_long, color: Colors.white54, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              color: amountColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Color _getPrimaryColor() {
    switch (_selectedTab) {
      case 1:
        return AppColors.neonCyan;
      case 2:
        return AppColors.neonMagenta;
      case 0:
      default:
        return Colors.greenAccent;
    }
  }

  String _getPrimaryLabel() {
    switch (_selectedTab) {
      case 1:
        return 'DIGITAL FIGHT COIN';
      case 2:
        return 'CREATORS FIT COIN';
      case 0:
      default:
        return 'AVAILABLE CASH PURSE';
    }
  }

  String _getPrimaryBalance() {
    switch (_selectedTab) {
      case 1:
        return '12,450';
      case 2:
        return '480';
      case 0:
      default:
        return '3,240.50';
    }
  }
}