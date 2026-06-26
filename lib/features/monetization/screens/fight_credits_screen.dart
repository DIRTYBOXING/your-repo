import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../shared/models/fight_credits_model.dart';
import '../../../shared/services/fight_credits_service.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// FIGHT CREDITS SCREEN — Buy, spend, and manage Fight Credits
/// ═══════════════════════════════════════════════════════════════════════════

const _kBg = Color(0xFF060A14);
const _kPanel = Color(0xFF0C1226);
const _kBorder = Color(0xFF1A2744);
const _kGold = Color(0xFFFFD740);
const _kCyan = Color(0xFF00E5FF);
const _kGreen = Color(0xFF00E676);
const _kMagenta = Color(0xFFE040FB);

class FightCreditsScreen extends StatefulWidget {
  const FightCreditsScreen({super.key});

  @override
  State<FightCreditsScreen> createState() => _FightCreditsScreenState();
}

class _FightCreditsScreenState extends State<FightCreditsScreen>
    with SingleTickerProviderStateMixin {
  final FightCreditsService _creditsService = FightCreditsService();
  late final TabController _tabs;

  CreditWallet? _wallet;
  List<CreditTransaction> _transactions = [];
  bool _isLoading = true;

  // Use actual authenticated user, fall back to 'demo_user' for demo mode
  String get _userId =>
      FirebaseAuth.instance.currentUser?.uid ?? 'demo_user';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      _wallet = await _creditsService.getWallet(_userId);
      _transactions = await _creditsService.getTransactions(_userId);
    } catch (_) {}
    setState(() => _isLoading = false);
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
        title: const Text('FIGHT CREDITS'),
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
            Tab(text: 'WALLET'),
            Tab(text: 'BUY CREDITS'),
            Tab(text: 'HISTORY'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _kGold))
          : TabBarView(
              controller: _tabs,
              children: [
                _buildWalletTab(),
                _buildBuyTab(),
                _buildHistoryTab(),
              ],
            ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // WALLET TAB — Balance + Quick Spend
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildWalletTab() {
    final balance = _wallet?.balance ?? 0;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Balance Card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1A0A2E), Color(0xFF0D1B2A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _kGold.withValues(alpha: 0.4)),
          ),
          child: Column(
            children: [
              const Text(
                'YOUR BALANCE',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Icon(Icons.bolt, color: _kGold, size: 32),
                  const SizedBox(width: 4),
                  Text(
                    '$balance',
                    style: const TextStyle(
                      color: _kGold,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8, left: 4),
                    child: Text(
                      'CREDITS',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _statChip(
                    'PURCHASED',
                    '${_wallet?.totalPurchased ?? 0}',
                    _kGreen,
                  ),
                  _statChip(
                    'SPENT',
                    '${_wallet?.totalSpent ?? 0}',
                    _kMagenta,
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Spend Rate Guide
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text(
            'WHAT YOU CAN WATCH',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 11,
              letterSpacing: 1.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...CreditSpendType.values.map((type) {
          final cost = CreditCosts.costFor(type);
          final canAfford = balance >= cost;
          return _spendRateRow(
            CreditCosts.labelFor(type),
            cost,
            canAfford,
            _iconForSpendType(type),
          );
        }),

        const SizedBox(height: 24),

        // Buy More CTA
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _tabs.animateTo(1),
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('BUY MORE CREDITS'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kGold,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
              textStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _statChip(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white38, fontSize: 10),
        ),
      ],
    );
  }

  Widget _spendRateRow(String label, int cost, bool canAfford, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _kPanel,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: canAfford ? _kBorder : Colors.red.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: canAfford ? _kCyan : Colors.white24, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: canAfford ? Colors.white : Colors.white38,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: canAfford
                  ? _kGold.withValues(alpha: 0.15)
                  : Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.bolt,
                  size: 14,
                  color: canAfford ? _kGold : Colors.red[300],
                ),
                Text(
                  ' $cost',
                  style: TextStyle(
                    color: canAfford ? _kGold : Colors.red[300],
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconForSpendType(CreditSpendType type) {
    switch (type) {
      case CreditSpendType.singleFight:
        return Icons.sports_mma;
      case CreditSpendType.payPerRound:
        return Icons.timer;
      case CreditSpendType.fullEventCard:
        return Icons.view_list;
      case CreditSpendType.replay:
        return Icons.replay;
      case CreditSpendType.premiumAnalysis:
        return Icons.insights;
      case CreditSpendType.tip:
        return Icons.favorite;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // BUY TAB — Credit Pack Cards
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildBuyTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 4),
          child: Text(
            'CHOOSE YOUR PACK',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 11,
              letterSpacing: 1.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(bottom: 16),
          child: Text(
            'Buy once, spend on any fight. No per-transaction fees.',
            style: TextStyle(color: Colors.white30, fontSize: 12),
          ),
        ),
        ...CreditPack.allPacks.map(_buildPackCard),

        const SizedBox(height: 24),

        // Afterpay hint
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _kPanel,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _kBorder),
          ),
          child: Row(
            children: [
              Icon(
                Icons.schedule,
                color: _kCyan.withValues(alpha: 0.7),
                size: 20,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Afterpay available on packs A\$20+\n4 interest-free payments',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPackCard(CreditPack pack) {
    final isPopular = pack.id == 'pack_war_chest';
    final borderColor = isPopular ? _kGold : _kBorder;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _kPanel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: borderColor,
          width: isPopular ? 2 : 1,
        ),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Credits badge
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isPopular
                          ? [const Color(0xFF2A1A00), const Color(0xFF1A0A00)]
                          : [const Color(0xFF0A1A2A), const Color(0xFF060D18)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isPopular
                          ? _kGold.withValues(alpha: 0.5)
                          : _kCyan.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.bolt,
                        color: isPopular ? _kGold : _kCyan,
                        size: 18,
                      ),
                      Text(
                        '${pack.credits}',
                        style: TextStyle(
                          color: isPopular ? _kGold : _kCyan,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),

                // Name + rate
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pack.name.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'A\$${pack.pricePerCredit.toStringAsFixed(2)}/credit',
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                        ),
                      ),
                      if (pack.bonusLabel != null) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _kGreen.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            pack.bonusLabel!,
                            style: const TextStyle(
                              color: _kGreen,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Price + buy button
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'A\$${pack.priceAUD.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 32,
                      child: ElevatedButton(
                        onPressed: _creditsService.isLoading
                            ? null
                            : () => _onBuyPack(pack),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isPopular ? _kGold : _kCyan,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('BUY'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Popular badge
          if (isPopular)
            Positioned(
              top: 0,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: const BoxDecoration(
                  color: _kGold,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(6),
                    bottomRight: Radius.circular(6),
                  ),
                ),
                child: const Text(
                  'MOST POPULAR',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _onBuyPack(CreditPack pack) async {
    final success = await _creditsService.purchaseCreditPack(
      userId: _userId,
      pack: pack,
    );
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _creditsService.error ?? 'Purchase failed',
          ),
          backgroundColor: Colors.red[800],
        ),
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // HISTORY TAB — Transaction Ledger
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildHistoryTab() {
    if (_transactions.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long, color: Colors.white24, size: 48),
            SizedBox(height: 12),
            Text(
              'No transactions yet',
              style: TextStyle(color: Colors.white38),
            ),
            SizedBox(height: 4),
            Text(
              'Buy some credits to get started!',
              style: TextStyle(color: Colors.white24, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _transactions.length,
      itemBuilder: (context, index) {
        final txn = _transactions[index];
        final isCredit = txn.isPurchase;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: _kPanel,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _kBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isCredit
                      ? _kGreen.withValues(alpha: 0.12)
                      : _kMagenta.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isCredit ? Icons.add_circle : Icons.remove_circle,
                  color: isCredit ? _kGreen : _kMagenta,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      txn.description,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatDate(txn.createdAt),
                      style: const TextStyle(
                        color: Colors.white30,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${isCredit ? '+' : ''}${txn.amount}',
                style: TextStyle(
                  color: isCredit ? _kGreen : _kMagenta,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 2),
              Icon(
                Icons.bolt,
                color: isCredit ? _kGreen : _kMagenta,
                size: 14,
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
