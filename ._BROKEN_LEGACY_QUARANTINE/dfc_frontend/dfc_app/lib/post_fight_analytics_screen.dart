import 'package:flutter/material.dart';

class PostFightAnalyticsScreen extends StatelessWidget {
  const PostFightAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05060A),
      body: SafeArea(
        child: ListView(
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
                    'POST-FIGHT ANALYTICS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.greenAccent.withValues(alpha: 0.5),
                    ),
                  ),
                  child: const Text(
                    'FINALIZED',
                    style: TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // ─── 2. MATCH RECAP ──────────────────────────────────────────────
            _buildSectionHeader(
              Icons.sports_mma,
              'MATCH RECAP & RESULT',
              Colors.redAccent,
            ),
            _DfcCard(
              height: 140,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'DFC 1: OPENING NIGHT',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text(
                        'HEATH EWART',
                        style: TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          'DEF.',
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        'KAI JOHNSON',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'TKO (Strikes) - Round 2, 3:14',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ─── 3. PAYOUT ENGINE ────────────────────────────────────────────
            _buildSectionHeader(
              Icons.payments,
              'PAYOUT ENGINE',
              Colors.greenAccent,
            ),
            _DfcCard(
              height: 220,
              glow: true,
              child: Column(
                children: [
                  _buildPayoutRow('Base Purse', '\$50,000.00'),
                  const SizedBox(height: 12),
                  _buildPayoutRow(
                    'Win Bonus',
                    '\$50,000.00',
                    color: Colors.greenAccent,
                  ),
                  const SizedBox(height: 12),
                  _buildPayoutRow(
                    'PPV Share (2.5%)',
                    '\$24,500.00',
                    color: Colors.cyanAccent,
                  ),
                  const SizedBox(height: 12),
                  _buildPayoutRow('Sponsor Pay', '\$10,000.00'),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.0),
                    child: Divider(color: Colors.white10),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        'TOTAL DISBURSED',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        '\$134,500.00',
                        style: TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ─── 4. FIGHT METRICS ────────────────────────────────────────────
            _buildSectionHeader(
              Icons.analytics,
              'PERFORMANCE METRICS',
              Colors.cyanAccent,
            ),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'SIG. STRIKES',
                    '48 / 62',
                    '77%',
                    Colors.cyanAccent,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricCard(
                    'TAKEDOWNS',
                    '2 / 2',
                    '100%',
                    Colors.blueAccent,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricCard(
                    'CONTROL',
                    '4:12',
                    'Round 1-2',
                    Colors.purpleAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ─── 5. MEDICAL / DAMAGE REPORT ──────────────────────────────────
            _buildSectionHeader(
              Icons.medical_services,
              'POST-FIGHT MEDICAL',
              Colors.orangeAccent,
            ),
            _DfcCard(
              height: 160,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.warning, color: Colors.orangeAccent, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'COMMISSION SUSPENSION: 30 DAYS',
                        style: TextStyle(
                          color: Colors.orangeAccent,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Notes:',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '• Laceration above right eyebrow (cleared, sutured).\n• Precautionary 30-day no-contact suspension.\n• Follow-up with ophthalmologist recommended.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

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

  Widget _buildPayoutRow(
    String label,
    String amount, {
    Color color = Colors.white,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 14),
        ),
        Text(
          amount,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String label,
    String value,
    String subValue,
    Color color,
  ) {
    return _DfcCard(
      height: 110,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subValue,
            style: const TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ],
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
                  color: Colors.greenAccent.withValues(alpha: 0.05),
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
