import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../services/economy_service.dart';

class FighterEconomyDashboard extends StatefulWidget {
  final String fighterId;
  const FighterEconomyDashboard({super.key, required this.fighterId});

  @override
  State<FighterEconomyDashboard> createState() =>
      _FighterEconomyDashboardState();
}

class _FighterEconomyDashboardState extends State<FighterEconomyDashboard> {
  final _economy = EconomyService();
  Map<String, dynamic>? _balance;
  List<Map<String, dynamic>> _statements = [];
  List<Map<String, dynamic>> _events = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final balance = await _economy.getPayoutBalance(
      'fighter',
      widget.fighterId,
    );
    final statements = await _economy.getPayoutStatements(
      'fighter',
      widget.fighterId,
    );
    final events = await _economy.getRevenueEventsForOwner(
      'fighter',
      widget.fighterId,
    );

    if (mounted) {
      setState(() {
        _balance = balance;
        _statements = statements;
        _events = events;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading)
      return const Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.neonCyan),
        ),
      );

    final currentBalance = (_balance?['balanceCents'] ?? 0) / 100.0;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          'FIGHTER EARNINGS',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.neonCyan.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.neonCyan.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                const Text(
                  'AVAILABLE PURSE',
                  style: TextStyle(
                    color: AppColors.neonCyan,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '\$${currentBalance.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'RECENT TRANSACTIONS',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          if (_events.isEmpty)
            const Text(
              'No transactions found.',
              style: TextStyle(color: Colors.white38),
            ),
          // TODO: Map over _events and display custom ListTile widgets
        ],
      ),
    );
  }
}
