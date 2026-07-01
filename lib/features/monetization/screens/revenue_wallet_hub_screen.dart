import 'package:flutter/material.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// REVENUE & WALLET HUB — Unified revenue dashboard for all user roles.
/// Surfaces: Earnings, Payouts, Sponsorships, PPV Revenue, Ticket Sales
/// ═══════════════════════════════════════════════════════════════════════════

const _kBg = Color(0xFF060A14);
const _kPanel = Color(0xFF0C1226);
const _kBorder = Color(0xFF1A2744);
const _kGold = Color(0xFFFFD740);
const _kCyan = Color(0xFF00E5FF);
const _kGreen = Color(0xFF00E676);
const _kMagenta = Color(0xFFE040FB);
const _kOrange = Color(0xFFFF9100);

class RevenueWalletHubScreen extends StatefulWidget {
  const RevenueWalletHubScreen({super.key});

  @override
  State<RevenueWalletHubScreen> createState() => _RevenueWalletHubScreenState();
}

class _RevenueWalletHubScreenState extends State<RevenueWalletHubScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: const Text('REVENUE HUB'),
        backgroundColor: _kBg,
        foregroundColor: _kGold,
        elevation: 0,
        centerTitle: true,
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: _kGold,
          labelColor: _kGold,
          unselectedLabelColor: Colors.white38,
          labelStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
          tabs: const [
            Tab(text: 'OVERVIEW'),
            Tab(text: 'EARNINGS'),
            Tab(text: 'PAYOUTS'),
            Tab(text: 'SPONSORS'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _buildOverview(),
          _buildEarnings(),
          _buildPayouts(),
          _buildSponsors(),
        ],
      ),
    );
  }

  Widget _buildOverview() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildBalanceCard(),
        const SizedBox(height: 16),
        _buildRevenueGrid(),
        const SizedBox(height: 16),
        _buildRecentTransactions(),
      ],
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _kGold.withValues(alpha: 0.15),
            _kMagenta.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kGold.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          const Text(
            'AVAILABLE BALANCE',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 11,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '\$12,450.00',
            style: TextStyle(
              color: _kGold,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'AUD · Multi-currency enabled',
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.arrow_upward, size: 16),
                  label: const Text('WITHDRAW'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kGreen,
                    foregroundColor: Colors.black,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.history, size: 16),
                  label: const Text('HISTORY'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _kCyan,
                    side: BorderSide(color: _kCyan.withValues(alpha: 0.5)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueGrid() {
    final streams = [
      const _RevStream('Ticket Sales', '\$5,200', _kGold, Icons.confirmation_number),
      const _RevStream('PPV Revenue', '\$3,850', _kCyan, Icons.live_tv),
      const _RevStream('Sponsorships', '\$2,400', _kMagenta, Icons.handshake),
      const _RevStream('Merchandise', '\$1,000', _kOrange, Icons.shopping_bag),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.6,
      ),
      itemCount: streams.length,
      itemBuilder: (context, i) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _kPanel,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: streams[i].color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(streams[i].icon, color: streams[i].color, size: 22),
            const SizedBox(height: 8),
            Text(
              streams[i].amount,
              style: TextStyle(
                color: streams[i].color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              streams[i].label,
              style: const TextStyle(color: Colors.white54, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactions() {
    final txns = [
      const _Txn('Ticket Sale — DFC 14', '+\$120.00', _kGreen, 'Mar 8'),
      const _Txn('PPV Purchase x3', '+\$89.97', _kGreen, 'Mar 7'),
      const _Txn('Withdrawal to Bank', '-\$2,000.00', _kOrange, 'Mar 5'),
      const _Txn('Sponsor Payment — GymBro', '+\$500.00', _kGreen, 'Mar 3'),
      const _Txn('Platform Fee', '-\$45.00', _kOrange, 'Mar 1'),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kPanel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'RECENT TRANSACTIONS',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 11,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ...txns.map(
            (t) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          t.date,
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    t.amount,
                    style: TextStyle(
                      color: t.color,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarnings() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildPeriodSelector(),
        const SizedBox(height: 16),
        _buildEarningsChart(),
        const SizedBox(height: 16),
        _buildEarningsBreakdown(),
      ],
    );
  }

  Widget _buildPeriodSelector() {
    return Row(
      children: ['7D', '30D', '90D', '1Y', 'ALL'].map((p) {
        final sel = p == '30D';
        return Expanded(
          child: GestureDetector(
            onTap: () {},
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: sel ? _kGold.withValues(alpha: 0.2) : _kPanel,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: sel ? _kGold : _kBorder),
              ),
              child: Text(
                p,
                style: TextStyle(
                  color: sel ? _kGold : Colors.white54,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEarningsChart() {
    return Container(
      height: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kPanel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      child: const Center(
        child: Text(
          'EARNINGS CHART\n(visual rendering here)',
          style: TextStyle(color: Colors.white38, fontSize: 13),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildEarningsBreakdown() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kPanel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '30-DAY BREAKDOWN',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 11,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          _breakdownRow('Ticket Revenue', '\$5,200', _kGold),
          _breakdownRow('PPV Revenue', '\$3,850', _kCyan),
          _breakdownRow('Sponsorships', '\$2,400', _kMagenta),
          _breakdownRow('Merchandise', '\$1,000', _kOrange),
          const Divider(color: _kBorder),
          _breakdownRow('Total', '\$12,450', _kGreen),
        ],
      ),
    );
  }

  Widget _breakdownRow(String label, String amount, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayouts() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _kPanel,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _kGreen.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              const Icon(Icons.account_balance, color: _kGreen, size: 40),
              const SizedBox(height: 12),
              const Text(
                'PAYOUT SETTINGS',
                style: TextStyle(
                  color: _kGreen,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Stripe Connected ✓',
                style: TextStyle(color: _kGreen, fontSize: 13),
              ),
              const SizedBox(height: 4),
              const Text(
                'Weekly automatic payouts enabled',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kGreen,
                        foregroundColor: Colors.black,
                      ),
                      child: const Text('INSTANT PAYOUT'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _kCyan,
                        side: BorderSide(color: _kCyan.withValues(alpha: 0.5)),
                      ),
                      child: const Text('SETTINGS'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSponsors() {
    final sponsors = [
      const _Sponsor('GymBro Supplements', '\$500/event', _kGold, 'Active'),
      const _Sponsor('FightWear Co.', '\$300/event', _kCyan, 'Active'),
      const _Sponsor('Energy Drink X', '\$1,200/event', _kMagenta, 'Negotiating'),
      const _Sponsor('Local Gym Network', '\$150/event', _kGreen, 'Active'),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'SPONSOR PARTNERSHIPS',
          style: TextStyle(
            color: _kMagenta,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 16),
        ...sponsors.map(
          (s) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _kPanel,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: s.color.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.handshake, color: s.color, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        s.amount,
                        style: TextStyle(color: s.color, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: s.status == 'Active'
                        ? _kGreen.withValues(alpha: 0.12)
                        : _kOrange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    s.status,
                    style: TextStyle(
                      color: s.status == 'Active' ? _kGreen : _kOrange,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RevStream {
  final String label;
  final String amount;
  final Color color;
  final IconData icon;
  const _RevStream(this.label, this.amount, this.color, this.icon);
}

class _Txn {
  final String label;
  final String amount;
  final Color color;
  final String date;
  const _Txn(this.label, this.amount, this.color, this.date);
}

class _Sponsor {
  final String name;
  final String amount;
  final Color color;
  final String status;
  const _Sponsor(this.name, this.amount, this.color, this.status);
}
