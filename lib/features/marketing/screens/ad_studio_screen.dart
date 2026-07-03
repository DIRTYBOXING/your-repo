import 'package:flutter/material.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/neon_glow_button.dart';

class AdStudioScreen extends StatelessWidget {
  const AdStudioScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('DFC Ad Studio', style: TextStyle(color: Colors.cyanAccent)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'GROW YOUR GYM & EVENT',
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Turn your free posts into Sponsored Ads to reach local fighters and fans.',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 24),
            GlassCard(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.campaign, color: Colors.purpleAccent, size: 30),
                        SizedBox(width: 12),
                        Text('Boost Recent Post', style: TextStyle(color: Colors.white, fontSize: 18)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.image, color: Colors.grey),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '"Open Mat Saturday @ 10AM! All levels welcome!"',
                              style: TextStyle(color: Colors.white70, fontStyle: FontStyle.italic),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text('Budget & Duration', style: TextStyle(color: Colors.white)),
                    const SizedBox(height: 8),
                    Slider(
                      value: 50,
                      min: 10,
                      max: 500,
                      activeColor: Colors.cyanAccent,
                      inactiveColor: Colors.white24,
                      onChanged: (val) {},
                    ),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('100 DFC Coins', style: TextStyle(color: Colors.white54)),
                        Text('Est. 5k Views', style: TextStyle(color: Colors.cyanAccent)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    NeonGlowButton(
                      text: 'Launch Campaign',
                      onPressed: () {},
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
