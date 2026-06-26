import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../shared/widgets/dfc_card.dart';
import '../../../shared/widgets/dfc_cosmetic_widgets.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// BILLING HISTORY — Transaction log, subscription management, payment methods
/// ═══════════════════════════════════════════════════════════════════════════

class BillingHistoryScreen extends StatefulWidget {
  const BillingHistoryScreen({super.key});

  @override
  State<BillingHistoryScreen> createState() => _BillingHistoryScreenState();
}

class _BillingHistoryScreenState extends State<BillingHistoryScreen> {
  String _filter = 'All';

  void _goBackSafely() {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: Stack(
        children: [
          const DFCCosmicBackground(particleCount: 12),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(child: _buildContent()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Back',
                onPressed: _goBackSafely,
                icon: const Icon(
                  Icons.arrow_back_ios,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const Spacer(),
              const DFCLogo(size: DFCLogoSize.small),
            ],
          ),
          const SizedBox(height: 12),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [DesignTokens.neonGold, DesignTokens.neonAmber],
            ).createShader(bounds),
            child: const Text(
              'BILLING',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Subscriptions · Transactions · Payment Methods',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          const DFCNeonDivider(color: DesignTokens.neonGold),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final transactions = const <_Transaction>[];
    final filtered = _filter == 'All'
        ? transactions
        : transactions.where((t) => t.type == _filter).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
      children: [
        // ── Current Plan ──
        DFCCard.glass(
          accent: DesignTokens.neonGold,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: DesignTokens.neonGold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'ACTIVE',
                      style: TextStyle(
                        color: DesignTokens.neonGold,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Since Jan 2026',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.35),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'Fighter Pro',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              RichText(
                text: TextSpan(
                  children: [
                    const TextSpan(
                      text: '\$2.99',
                      style: TextStyle(
                        color: DesignTokens.neonGold,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    TextSpan(
                      text: ' / month',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _planDetail(
                    Icons.calendar_today,
                    'Next billing',
                    'Mar 1, 2026',
                  ),
                  const SizedBox(width: 14),
                  _planDetail(Icons.credit_card, 'Payment', '•••• 4242'),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => context.push('/subscription'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: DesignTokens.neonCyan.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: DesignTokens.neonCyan.withValues(alpha: 0.2),
                            width: 0.5,
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            'UPGRADE PLAN',
                            style: TextStyle(
                              color: DesignTokens.neonCyan,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => context.push('/subscription'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                            width: 0.5,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'MANAGE',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // ── Payment Methods ──
        const DFCSectionHeader(title: 'PAYMENT METHODS', icon: Icons.credit_card),
        const SizedBox(height: 8),
        _paymentMethodCard(
          'Visa',
          '•••• 4242',
          '12/28',
          true,
          DesignTokens.neonCyan,
        ),
        const SizedBox(height: 6),
        _paymentMethodCard(
          'Apple Pay',
          'Connected',
          '',
          false,
          DesignTokens.neonGreen,
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Payment methods are managed through your Stripe checkout'),
                backgroundColor: DesignTokens.neonGold.withValues(alpha: 0.85),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.06),
                width: 0.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add,
                  color: Colors.white.withValues(alpha: 0.4),
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  'Add Payment Method',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // ── Transaction History ──
        const DFCSectionHeader(
          title: 'TRANSACTION HISTORY',
          icon: Icons.receipt_long,
        ),
        const SizedBox(height: 8),
        // Filters
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ['All', 'Subscription', 'Pass', 'Donation', 'Ticket']
                .map(
                  (f) => Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: GestureDetector(
                      onTap: () => setState(() => _filter = f),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _filter == f
                              ? DesignTokens.neonGold.withValues(alpha: 0.12)
                              : Colors.white.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _filter == f
                                ? DesignTokens.neonGold.withValues(alpha: 0.3)
                                : Colors.white.withValues(alpha: 0.06),
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          f,
                          style: TextStyle(
                            color: _filter == f
                                ? DesignTokens.neonGold
                                : Colors.white.withValues(alpha: 0.4),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 10),
        if (filtered.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Text(
              'No verified transactions yet. Complete a checkout and use Sync in Subscription to refresh billing data.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 12,
                height: 1.35,
              ),
            ),
          )
        else
          ...filtered.map(
            (t) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _transactionRow(t),
            ),
          ),

        const SizedBox(height: 16),
        // Spending summary
        const DFCSectionHeader(title: 'SPENDING SUMMARY', icon: Icons.pie_chart),
        const SizedBox(height: 8),
        DFCCard.glass(
          accent: DesignTokens.neonGold,
          child: Column(
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'This Month',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '\$34.98',
                    style: TextStyle(
                      color: DesignTokens.neonGold,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _spendRow('Subscription', '\$2.99', 0.12, DesignTokens.neonCyan),
              _spendRow(
                'Fight Passes',
                '\$15.00',
                0.43,
                DesignTokens.neonGreen,
              ),
              _spendRow('Donations', '\$4.99', 0.20, DesignTokens.neonMagenta),
            ],
          ),
        ),
      ],
    );
  }

  Widget _planDetail(IconData icon, String label, String value) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, color: Colors.white.withValues(alpha: 0.3), size: 14),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.35),
                  fontSize: 9,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _paymentMethodCard(
    String brand,
    String detail,
    String exp,
    bool isDefault,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDefault
            ? color.withValues(alpha: 0.04)
            : Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDefault
              ? color.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.06),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.credit_card, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  brand,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  detail,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          if (exp.isNotEmpty)
            Text(
              exp,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                fontSize: 10,
              ),
            ),
          if (isDefault) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'DEFAULT',
                style: TextStyle(
                  color: color,
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _transactionRow(_Transaction t) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: t.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(t.icon, color: t.color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.description,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  t.date,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.35),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                t.amount,
                style: TextStyle(
                  color: t.color,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                t.status,
                style: TextStyle(
                  color: t.status == 'Completed'
                      ? DesignTokens.neonGreen
                      : DesignTokens.neonAmber,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _spendRow(String label, String amount, double pct, Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              Text(
                amount,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: Colors.white.withValues(alpha: 0.05),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 3,
            ),
          ),
        ],
      ),
    );
  }
}

class _Transaction {
  final String description, date, amount, type, status;
  final IconData icon;
  final Color color;
  const _Transaction({
    required this.description,
    required this.date,
    required this.amount,
    required this.type,
    required this.status,
    required this.icon,
    required this.color,
  });
}
