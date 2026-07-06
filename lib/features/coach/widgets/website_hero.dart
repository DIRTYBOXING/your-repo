import 'package:flutter/material.dart';

// ── Stub: website_hero.dart ───────────────────────────────────────────────────
// Full hero implementation lives in dfc_landing_hero_screen.dart.
// This stub satisfies the import in website_home_screen.dart.

class WebsiteHero extends StatelessWidget {
  const WebsiteHero({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF050A14), Color(0xFF0A1628), Color(0xFF050A14)],
        ),
      ),
      child: Column(
        children: [
          const Text(
            'DATA FIGHT CENTRAL',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF00E5FF),
              fontSize: 48,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'The World\'s Most Advanced Combat Sports Intelligence Platform.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 18, height: 1.5),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00E5FF),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 18,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'ENTER PLATFORM',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                ),
              ),
              const SizedBox(width: 16),
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: const BorderSide(color: Colors.white24),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 18,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'WATCH DEMO',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
