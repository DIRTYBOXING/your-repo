import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';

/// CREATOR COMMERCE — Priority Q&A slots, timed merch drops, tipping.
/// Revenue layer that no competitor gives to fighters directly.
class CreatorCommerceScreen extends StatefulWidget {
  const CreatorCommerceScreen({super.key});

  @override
  State<CreatorCommerceScreen> createState() => _CreatorCommerceScreenState();
}

class _CreatorCommerceScreenState extends State<CreatorCommerceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgSecondary,
        title: const Row(
          children: [
            Icon(Icons.storefront, color: DesignTokens.neonGold, size: 22),
            SizedBox(width: 8),
            Text(
              'CREATOR COMMERCE',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 16,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: DesignTokens.neonGold,
          labelColor: DesignTokens.neonGold,
          unselectedLabelColor: Colors.white30,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 11,
          ),
          tabs: const [
            Tab(text: 'MERCH DROPS'),
            Tab(text: 'Q&A SLOTS'),
            Tab(text: 'TIPS & GIFTS'),
            Tab(text: 'REVENUE'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMerchDrops(),
          _buildQASlots(),
          _buildTipping(),
          _buildRevenue(),
        ],
      ),
    );
  }

  // ── MERCH DROPS ──

  Widget _buildMerchDrops() {
    final drops = [
      const _MerchDrop(
        'Hepi Fight Night Tee',
        '\$39.99',
        'LIVE',
        142,
        DesignTokens.neonGreen,
      ),
      const _MerchDrop(
        'BKFC Logan Chapter Hoodie',
        '\$64.99',
        'LIVE',
        87,
        DesignTokens.neonGreen,
      ),
      const _MerchDrop(
        'BK Bau Signature Gloves',
        '\$89.99',
        'DROPS IN 2H',
        0,
        DesignTokens.neonAmber,
      ),
      const _MerchDrop(
        'Bronx Islanders Cap',
        '\$29.99',
        'SOLD OUT',
        312,
        DesignTokens.neonRed,
      ),
      const _MerchDrop(
        'Townsville Fight Week Bundle',
        '\$119.99',
        'SCHEDULED',
        0,
        Colors.white30,
      ),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Timer banner
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                DesignTokens.neonGold.withValues(alpha: 0.1),
                Colors.transparent,
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: DesignTokens.neonGold.withValues(alpha: 0.15),
            ),
          ),
          child: const Row(
            children: [
              Icon(Icons.timer, color: DesignTokens.neonGold, size: 20),
              SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'NEXT DROP',
                    style: TextStyle(
                      color: DesignTokens.neonGold,
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    'BK Bau Signature Gloves — 01:58:42',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...drops.map(_merchCard),
      ],
    );
  }

  Widget _merchCard(_MerchDrop d) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: d.color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.checkroom,
              color: d.color.withValues(alpha: 0.5),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  d.name,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      d.price,
                      style: TextStyle(
                        color: d.color,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (d.sold > 0)
                      Text(
                        '${d.sold} sold',
                        style: const TextStyle(
                          color: Colors.white30,
                          fontSize: 10,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: d.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              d.status,
              style: TextStyle(
                color: d.color,
                fontWeight: FontWeight.w800,
                fontSize: 9,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Q&A SLOTS ──

  Widget _buildQASlots() {
    final slots = [
      const _QASlot(
        'Pre-Fight Q&A — Hepi',
        '\$4.99',
        '12 / 20',
        'OPEN',
        DesignTokens.neonGreen,
      ),
      const _QASlot(
        'Corner Insight — BK Bau',
        '\$2.99',
        '20 / 20',
        'FULL',
        DesignTokens.neonRed,
      ),
      const _QASlot(
        'Post-Fight AMA — Hardman',
        '\$3.99',
        '5 / 30',
        'OPEN',
        DesignTokens.neonGreen,
      ),
      const _QASlot(
        'Training Camp Q&A — Flanagan',
        '\$1.99',
        '0 / 15',
        'SCHEDULED',
        DesignTokens.neonAmber,
      ),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                DesignTokens.neonCyan.withValues(alpha: 0.08),
                Colors.transparent,
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: DesignTokens.neonCyan.withValues(alpha: 0.15),
            ),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: DesignTokens.neonCyan, size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Priority Q&A slots give fans guaranteed fighter responses during live events.',
                  style: TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...slots.map(_qaSlotCard),
      ],
    );
  }

  Widget _qaSlotCard(_QASlot s) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.question_answer,
                color: DesignTokens.neonCyan,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  s.name,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: s.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  s.status,
                  style: TextStyle(
                    color: s.color,
                    fontWeight: FontWeight.w800,
                    fontSize: 9,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                s.price,
                style: const TextStyle(
                  color: DesignTokens.neonGold,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              const Text(
                ' / slot',
                style: TextStyle(color: Colors.white30, fontSize: 10),
              ),
              const Spacer(),
              Text(
                s.capacity,
                style: const TextStyle(
                  color: Colors.white38,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
              const Text(
                ' slots',
                style: TextStyle(color: Colors.white24, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── TIPPING ──

  Widget _buildTipping() {
    final tipAmounts = ['\$1', '\$5', '\$10', '\$25', '\$50', '\$100'];
    final recentTips = [
      ('Fan_Logan_01', '\$25', 'Hepi', '2m ago'),
      ('BKFC_Fan', '\$10', 'BK Bau', '5m ago'),
      ('IslanderPride', '\$50', 'Sione', '8m ago'),
      ('FightFan99', '\$5', 'Hardman', '12m ago'),
      ('GoldCoastMMA', '\$100', 'Hepi', '18m ago'),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Quick tip amounts
        const Text(
          'QUICK TIP',
          style: TextStyle(
            color: DesignTokens.neonGold,
            fontWeight: FontWeight.w900,
            fontSize: 11,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: tipAmounts.map((t) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: DesignTokens.bgCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: DesignTokens.neonGold.withValues(alpha: 0.15),
                ),
              ),
              child: Text(
                t,
                style: const TextStyle(
                  color: DesignTokens.neonGold,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),

        // Recent tips feed
        const Text(
          'RECENT TIPS',
          style: TextStyle(
            color: DesignTokens.neonGreen,
            fontWeight: FontWeight.w900,
            fontSize: 11,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: 8),
        ...recentTips.map((t) {
          final (fan, amount, fighter, time) = t;
          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: DesignTokens.bgCard,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.volunteer_activism,
                  color: DesignTokens.neonGold,
                  size: 16,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 12),
                      children: [
                        TextSpan(
                          text: '@$fan ',
                          style: const TextStyle(
                            color: DesignTokens.neonCyan,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const TextSpan(
                          text: 'tipped ',
                          style: TextStyle(color: Colors.white38),
                        ),
                        TextSpan(
                          text: '$amount ',
                          style: const TextStyle(
                            color: DesignTokens.neonGold,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const TextSpan(
                          text: 'to ',
                          style: TextStyle(color: Colors.white38),
                        ),
                        TextSpan(
                          text: fighter,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Text(
                  time,
                  style: const TextStyle(color: Colors.white24, fontSize: 10),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ── REVENUE ──

  Widget _buildRevenue() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Revenue summary
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                DesignTokens.neonGold.withValues(alpha: 0.08),
                DesignTokens.neonGreen.withValues(alpha: 0.04),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: DesignTokens.neonGold.withValues(alpha: 0.12),
            ),
          ),
          child: Column(
            children: [
              const Text(
                'TOTAL CREATOR REVENUE',
                style: TextStyle(
                  color: Colors.white30,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                '\$12,847.50',
                style: TextStyle(
                  color: DesignTokens.neonGold,
                  fontWeight: FontWeight.w900,
                  fontSize: 28,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _revStat('MERCH', '\$8,240', DesignTokens.neonCyan),
                  _revStat('Q&A', '\$2,105', DesignTokens.neonGreen),
                  _revStat('TIPS', '\$1,890', DesignTokens.neonMagenta),
                  _revStat('OTHER', '\$612', Colors.white38),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Payout schedule
        const Text(
          'PAYOUT SCHEDULE',
          style: TextStyle(
            color: DesignTokens.neonGreen,
            fontWeight: FontWeight.w900,
            fontSize: 11,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: 8),
        _payoutRow(
          'Next Payout',
          'Mar 28, 2026',
          '\$3,412.00',
          DesignTokens.neonGreen,
        ),
        _payoutRow('Last Payout', 'Mar 21, 2026', '\$2,841.50', Colors.white38),
        _payoutRow(
          'Pending',
          'Processing',
          '\$1,206.00',
          DesignTokens.neonAmber,
        ),

        const SizedBox(height: 16),

        // Top earners
        const Text(
          'TOP EARNERS — THIS EVENT',
          style: TextStyle(
            color: DesignTokens.neonGold,
            fontWeight: FontWeight.w900,
            fontSize: 11,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: 8),
        _earnerRow('1', 'Hepi', '\$4,280', DesignTokens.neonGold),
        _earnerRow('2', 'BK Bau', '\$2,915', DesignTokens.neonCyan),
        _earnerRow('3', 'Hardman', '\$1,840', DesignTokens.neonGreen),
        _earnerRow('4', 'Flanagan', '\$1,205', Colors.white38),
        _earnerRow('5', 'Sione', '\$890', Colors.white30),
      ],
    );
  }

  Widget _revStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w900,
            fontSize: 14,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white30,
            fontWeight: FontWeight.w700,
            fontSize: 8,
          ),
        ),
      ],
    );
  }

  Widget _payoutRow(String label, String date, String amount, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: Row(
        children: [
          Icon(Icons.account_balance_wallet, color: color, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                Text(
                  date,
                  style: const TextStyle(color: Colors.white30, fontSize: 10),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _earnerRow(String rank, String name, String earned, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text(
              rank,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          Text(
            earned,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _MerchDrop {
  final String name, price, status;
  final int sold;
  final Color color;
  const _MerchDrop(this.name, this.price, this.status, this.sold, this.color);
}

class _QASlot {
  final String name, price, capacity, status;
  final Color color;
  const _QASlot(this.name, this.price, this.capacity, this.status, this.color);
}
