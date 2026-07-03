import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../services/economy_service.dart';

class PromoterEconomyDashboard extends StatefulWidget {
  final String promoterId;
  const PromoterEconomyDashboard({super.key, required this.promoterId});

  @override
  State<PromoterEconomyDashboard> createState() =>
      _PromoterEconomyDashboardState();
}

class _PromoterEconomyDashboardState extends State<PromoterEconomyDashboard> {
  final _economy = EconomyService();
  double _balance = 0.0;
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
      'promoter',
      widget.promoterId,
    );
    final statements = await _economy.getPayoutStatements(
      'promoter',
      widget.promoterId,
    );
    final events = await _economy.getRevenueEventsForOwner(
      'promoter',
      widget.promoterId,
    );

    if (mounted) {
      setState(() {
        _balance = balance;
        _statements = statements.cast<Map<String, dynamic>>();
        _events = events.cast<Map<String, dynamic>>();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.neonGreen),
        ),
      );
    }

    final currentBalance = _balance;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          'PROMOTER REVENUE',
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
              color: AppColors.neonGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.neonGreen.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                const Text(
                  'CURRENT BALANCE',
                  style: TextStyle(
                    color: AppColors.neonGreen,
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
            'PAYOUT STATEMENTS',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          if (_statements.isEmpty)
            const Text(
              'No payout statements yet.',
              style: TextStyle(color: Colors.white38),
            ),
          ..._statements
              .map(
                (statement) => ListTile(
                  title: Text(statement['period'] ?? 'Unknown Period'),
                  trailing: Text(
                    '\$${statement['total'] ?? '0.00'}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              )
              .toList(),
        ],
      ),
    );
  }
}
