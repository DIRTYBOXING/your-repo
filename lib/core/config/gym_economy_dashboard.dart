import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../services/economy_service.dart';

class GymEconomyDashboard extends StatefulWidget {
  final String gymId;
  const GymEconomyDashboard({super.key, required this.gymId});

  @override
  State<GymEconomyDashboard> createState() => _GymEconomyDashboardState();
}

class _GymEconomyDashboardState extends State<GymEconomyDashboard> {
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
    final balance = await _economy.getPayoutBalance('gym', widget.gymId);
    final statements = await _economy.getPayoutStatements('gym', widget.gymId);
    final events = await _economy.getRevenueEventsForOwner('gym', widget.gymId);

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
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.neonBlue),
        ),
      );
    }

    final currentBalance = (_balance?['balanceCents'] ?? 0) / 100.0;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          'GYM REVENUE',
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
              color: AppColors.neonBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.neonBlue.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                const Text(
                  'TEAM EARNINGS',
                  style: TextStyle(
                    color: AppColors.neonBlue,
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
            'AFFILIATE & PPV CUTS',
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
              'No revenue events yet.',
              style: TextStyle(color: Colors.white38),
            ),
          // TODO: Map over _statements and display custom ListTile widgets
        ],
      ),
    );
  }
}
