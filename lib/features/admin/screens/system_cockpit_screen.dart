import 'package:flutter/material.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/neon_glow_button.dart';

class SystemCockpitScreen extends StatelessWidget {
  const SystemCockpitScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030810), // Deep NASA control room blue/black
      appBar: AppBar(
        title: const Text(
          'DFC MASTER COCKPIT',
          style: TextStyle(color: Colors.cyanAccent, letterSpacing: 3.0, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          const Center(
            child: Text(
              'SYS: OPTIMAL',
              style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, marginRight: 20),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.security, color: Colors.white),
            onPressed: () {},
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Metrics Row
            Row(
              children: [
                Expanded(child: _buildMetricGlassCard('ACTIVE STREAMS (MUX)', '24', Colors.redAccent)),
                const SizedBox(width: 16),
                Expanded(child: _buildMetricGlassCard('PLATFORM REVENUE', '\$142.5K', Colors.greenAccent)),
                const SizedBox(width: 16),
                Expanded(child: _buildMetricGlassCard('LIVE TELEMETRY', '1.2K', Colors.purpleAccent)),
              ],
            ),
            const SizedBox(height: 24),
            
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column - Infrastructure
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      _buildSectionHeader('INFRASTRUCTURE STATUS', Icons.router),
                      GlassCard(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              _buildStatusRow('Firebase Engine', 'ONLINE', Colors.greenAccent),
                              _buildStatusRow('Stripe Payment Gateway', 'SECURE', Colors.greenAccent),
                              _buildStatusRow('Mux Video Engine', 'ONLINE', Colors.greenAccent),
                              _buildStatusRow('AstroHealth Core', 'SYNCED', Colors.cyanAccent),
                              _buildStatusRow('Matchmaking Radar', 'ACTIVE', Colors.cyanAccent),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildSectionHeader('AI PERSONA ORCHESTRATION', Icons.psychology),
                      GlassCard(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              _buildStatusRow('Shakura (Guardian AI)', 'AWAKE - 422 Active Sessions', Colors.pinkAccent),
                              _buildStatusRow('Sensei (Fight Logic)', 'AWAKE - 1.1K Matchmakings', Colors.orangeAccent),
                              _buildStatusRow('Oracle (Analytics)', 'PROCESSING', Colors.purpleAccent),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                // Right Column - Quick Actions & Economy
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      _buildSectionHeader('GLOBAL ECONOMY', Icons.account_balance),
                      GlassCard(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              const Text('Total FIT Coins in Circulation', style: TextStyle(color: Colors.white70)),
                              const SizedBox(height: 8),
                              const Text('4,250,000 FIT', style: TextStyle(color: Colors.cyanAccent, fontSize: 24, fontWeight: FontWeight.bold)),
                              const Divider(color: Colors.white10, height: 32),
                              NeonGlowButton(text: 'MINT FIT COINS', onPressed: () {}),
                              const SizedBox(height: 16),
                              NeonGlowButton(text: 'AUDIT STRIPE PAYOUTS', onPressed: () {}),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildSectionHeader('EMERGENCY CONTROLS', Icons.warning),
                      GlassCard(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent.withOpacity(0.2),
                                  side: const BorderSide(color: Colors.redAccent),
                                  minimumSize: const Size(double.infinity, 50),
                                ),
                                onPressed: () {},
                                child: const Text('KILLSWITCH: STOP ALL STREAMS', style: TextStyle(color: Colors.redAccent)),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orangeAccent.withOpacity(0.2),
                                  side: const BorderSide(color: Colors.orangeAccent),
                                  minimumSize: const Size(double.infinity, 50),
                                ),
                                onPressed: () {},
                                child: const Text('LOCK PLATFORM (MAINTENANCE)', style: TextStyle(color: Colors.orangeAccent)),
                              ),
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildMetricGlassCard(String title, String value, Color color) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 1.0)),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(color: color, fontSize: 28, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2.0),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String status, Color statusColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              border: Border.all(color: statusColor.withOpacity(0.5)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              status,
              style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0),
            ),
          )
        ],
      ),
    );
  }
}
