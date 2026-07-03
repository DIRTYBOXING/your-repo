import 'package:flutter/material.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/neon_glow_button.dart';

class FanFundingScreen extends StatefulWidget {
  final String entityId;
  final String entityName;
  final String entityType; // 'fighter', 'coach', 'gym', 'creator'

  const FanFundingScreen({
    Key? key,
    required this.entityId,
    required this.entityName,
    this.entityType = 'fighter',
  }) : super(key: key);

  @override
  State<FanFundingScreen> createState() => _FanFundingScreenState();
}

class _FanFundingScreenState extends State<FanFundingScreen> {
  int _selectedTier = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('SEND A THANK YOU', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Verified Identity Header
            Row(
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundImage: NetworkImage('https://images.unsplash.com/photo-1555597673-b21d5c935865?auto=format&fit=crop&w=150&q=80'),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            widget.entityName,
                            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.verified, color: Colors.blueAccent, size: 20),
                        ],
                      ),
                      const Text(
                        'VERIFIED CREATOR & ATHLETE',
                        style: TextStyle(color: Colors.blueAccent, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold),
                      )
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            const Text(
              'HOW WOULD YOU LIKE TO SAY THANKS?',
              style: TextStyle(color: Colors.cyanAccent, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.5),
            ),
            const SizedBox(height: 16),

            // Tiers
            _buildFundingTier(
              index: 0,
              icon: Icons.local_cafe,
              title: 'Buy a Coffee',
              subtitle: 'Fuel the daily grind. My shout!',
              amount: '\$5.00',
              fitCoins: '50 FIT',
            ),
            _buildFundingTier(
              index: 1,
              icon: Icons.restaurant,
              title: 'Post-Fight Meal',
              subtitle: 'Treat them to a well-deserved feast.',
              amount: '\$20.00',
              fitCoins: '200 FIT',
            ),
            _buildFundingTier(
              index: 2,
              icon: Icons.local_fire_department,
              title: 'Fight Bonus',
              subtitle: 'Performance of the night! Fan-tipped bonus.',
              amount: '\$50.00',
              fitCoins: '500 FIT',
            ),
            _buildFundingTier(
              index: 3,
              icon: Icons.healing,
              title: 'Recovery & Ice Bath',
              subtitle: 'Help them recover and heal up right.',
              amount: '\$100.00',
              fitCoins: '1000 FIT',
            ),

            const SizedBox(height: 24),
            const Text(
              'LEAVE A MESSAGE',
              style: TextStyle(color: Colors.cyanAccent, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.5),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24),
              ),
              child: const TextField(
                style: TextStyle(color: Colors.white),
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "E.g., Incredible fight last night! Hope you heal up fast. My shout for the coffee!",
                  hintStyle: TextStyle(color: Colors.white30),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 32),
            NeonGlowButton(
              text: 'Send Thank You',
              onPressed: () {
                // Triggers Stripe / FIT Coin logic
              },
            ),
            const SizedBox(height: 16),
            const Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock, color: Colors.greenAccent, size: 14),
                  SizedBox(width: 8),
                  Text(
                    '100% Secure. Funds go directly to the verified athlete.',
                    style: TextStyle(color: Colors.greenAccent, fontSize: 12),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildFundingTier({
    required int index,
    required IconData icon,
    required String title,
    required String subtitle,
    required String amount,
    required String fitCoins,
  }) {
    final bool isSelected = _selectedTier == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTier = index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          border: Border.all(color: isSelected ? Colors.cyanAccent : Colors.transparent, width: 2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: GlassCard(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(icon, color: isSelected ? Colors.cyanAccent : Colors.white54, size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white70,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(color: isSelected ? Colors.white70 : Colors.white30, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      amount,
                      style: TextStyle(
                        color: isSelected ? Colors.greenAccent : Colors.white70,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      fitCoins,
                      style: const TextStyle(color: Colors.cyanAccent, fontSize: 10),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
