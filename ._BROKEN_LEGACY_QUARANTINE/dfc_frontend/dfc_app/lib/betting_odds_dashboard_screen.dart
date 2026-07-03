import 'package:flutter/material.dart';
import 'api_service.dart';
import 'blue/controllers/betting_controller.dart';
import 'blue/repositories/betting_repository.dart';
import 'blue/state/betting_state.dart';

class BettingOddsDashboardScreen extends StatefulWidget {
  const BettingOddsDashboardScreen({super.key});

  @override
  State<BettingOddsDashboardScreen> createState() =>
      _BettingOddsDashboardScreenState();
}

class _BettingOddsDashboardScreenState
    extends State<BettingOddsDashboardScreen> {
  late final BettingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = BettingController(repo: BettingRepository(api: ApiService()))
      ..loadOdds();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleAddToSlip(String pick, String odds, double wager, double payout) {
    _controller.addToSlip(pick, odds, wager, payout);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$pick added to bet slip!'),
        backgroundColor: Colors.greenAccent,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _handleSubmitBets() async {
    await _controller.submitBets();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bets placed successfully!'),
          backgroundColor: Colors.greenAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05060A),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            final state = _controller.state;

            if (state is BettingInitial || state is BettingLoading) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.cyanAccent),
              );
            }

            if (state is BettingError) {
              return Center(
                child: Text(
                  'Error: ${state.message}',
                  style: const TextStyle(color: Colors.redAccent),
                ),
              );
            }

            if (state is BettingLoaded) {
              return _buildContent();
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildContent() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      children: [
        const SizedBox(height: 32),

        // ─── 1. HEADER ───────────────────────────────────────────────────
        Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Icon(Icons.arrow_back, color: Colors.white),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Text(
                'SPORTSBOOK & ODDS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.amberAccent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.receipt_long,
                    color: Colors.amberAccent,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${_controller.slipCount} SLIP',
                    style: const TextStyle(
                      color: Colors.amberAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),

        // ─── 2. BANKROLL BALANCE ─────────────────────────────────────────
        _DfcCard(
          height: 100,
          glow: true,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    'ACCOUNT BALANCE',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '\$1,245.50',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'DEPOSIT',
                  style: TextStyle(
                    color: Colors.greenAccent,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // ─── 3. FEATURED FIGHT (MONEYLINE) ───────────────────────────────
        _buildSectionHeader(
          Icons.local_fire_department,
          'FEATURED BOUT',
          Colors.redAccent,
        ),
        _DfcCard(
          height: 190,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    'UFC 300 - MAIN EVENT',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  Text(
                    'MONEYLINE',
                    style: TextStyle(
                      color: Colors.cyanAccent,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildOddsButton(
                      fighter: 'H. Ewart',
                      odds: '-150',
                      isFavorite: true,
                      onTap: () =>
                          _handleAddToSlip('H. Ewart ML', '-150', 100, 166.67),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12.0),
                    child: Text(
                      'VS',
                      style: TextStyle(
                        color: Colors.white24,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  Expanded(
                    child: _buildOddsButton(
                      fighter: 'K. Johnson',
                      odds: '+130',
                      isFavorite: false,
                      onTap: () => _handleAddToSlip(
                        'K. Johnson ML',
                        '+130',
                        100,
                        230.00,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              const Text(
                'Tap odds to add \$100 Quick Bet to slip',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // ─── 4. PROP BETS ────────────────────────────────────────────────
        _buildSectionHeader(
          Icons.list_alt,
          'METHOD OF VICTORY PROPS',
          Colors.purpleAccent,
        ),
        Column(
          children: [
            _buildPropRow(
              propName: 'Ewart by KO/TKO',
              odds: '+180',
              onTap: () => _handleAddToSlip('Ewart KO/TKO', '+180', 50, 140.0),
            ),
            const SizedBox(height: 8),
            _buildPropRow(
              propName: 'Johnson by Submission',
              odds: '+350',
              onTap: () => _handleAddToSlip('Johnson SUB', '+350', 50, 225.0),
            ),
            const SizedBox(height: 8),
            _buildPropRow(
              propName: 'Fight Goes to Decision',
              odds: '-110',
              isFavorite: true,
              onTap: () =>
                  _handleAddToSlip('Fight Goes to DEC', '-110', 50, 95.45),
            ),
          ],
        ),
        const SizedBox(height: 32),

        // ─── 5. ACTIVE BET SLIP SUMMARY ──────────────────────────────────
        if (_controller.slipCount > 0) ...[
          _buildSectionHeader(
            Icons.receipt_long,
            'MY BET SLIP',
            Colors.amberAccent,
          ),
          _DfcCard(
            height: 140,
            glow: true,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'TOTAL WAGER',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '\$${_controller.totalWagered.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.0),
                  child: Divider(color: Colors.white10),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'TO WIN',
                      style: TextStyle(
                        color: Colors.amberAccent,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      '\$${_controller.potentialPayout.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amberAccent,
                      foregroundColor: Colors.black,
                    ),
                    onPressed: _handleSubmitBets,
                    child: const Text(
                      'SUBMIT BETS',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),
        ],
      ],
    );
  }

  // ─── HELPER WIDGETS ────────────────────────────────────────────────────────

  Widget _buildSectionHeader(IconData icon, String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              color: color.withValues(alpha: 0.8),
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOddsButton({
    required String fighter,
    required String odds,
    required bool isFavorite,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isFavorite
              ? Colors.cyanAccent.withValues(alpha: 0.1)
              : Colors.white10,
          border: Border.all(
            color: isFavorite ? Colors.cyanAccent : Colors.white24,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              fighter,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              odds,
              style: TextStyle(
                color: isFavorite ? Colors.cyanAccent : Colors.greenAccent,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPropRow({
    required String propName,
    required String odds,
    bool isFavorite = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF0A0E17),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              propName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isFavorite
                    ? Colors.cyanAccent.withValues(alpha: 0.1)
                    : Colors.white10,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isFavorite ? Colors.cyanAccent : Colors.transparent,
                ),
              ),
              child: Text(
                odds,
                style: TextStyle(
                  color: isFavorite ? Colors.cyanAccent : Colors.greenAccent,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DfcCard extends StatelessWidget {
  final double height;
  final bool glow;
  final Widget child;

  const _DfcCard({
    required this.height,
    this.glow = false,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0E17),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
        boxShadow: glow
            ? [
                BoxShadow(
                  color: Colors.amberAccent.withValues(alpha: 0.05),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ]
            : [],
      ),
      child: child,
    );
  }
}
