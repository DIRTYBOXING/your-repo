import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';

class FightCollectScreen extends StatefulWidget {
  const FightCollectScreen({super.key});

  @override
  State<FightCollectScreen> createState() => _FightCollectScreenState();
}

class _FightCollectScreenState extends State<FightCollectScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  // Available collectible pack drops (product catalog).
  static const List<Map<String, dynamic>> _packDrops = [
    {
      "color": DesignTokens.neonGold,
      "title": "Championship Legends Pack",
      "remaining": 250,
      "price": "\$9.99",
    },
    {
      "color": DesignTokens.neonCyan,
      "title": "Rising Prospects Pack",
      "remaining": 500,
      "price": "\$4.99",
    },
    {
      "color": DesignTokens.neonMagenta,
      "title": "Knockout Moments Pack",
      "remaining": 100,
      "price": "\$14.99",
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgPrimary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          children: [
            const Icon(Icons.style, color: DesignTokens.neonGold),
            const SizedBox(width: 8),
            const Text(
              "COLLECTIBLES",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 16,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: DesignTokens.neonGold,
          labelColor: DesignTokens.neonGold,
          unselectedLabelColor: DesignTokens.textMuted,
          labelStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
          tabs: const [
            Tab(text: "THE VAULT"),
            Tab(text: "PACK DROPS"),
            Tab(text: "MARKET"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _buildVaultTab(),
          _buildPackDropsTab(),
          const Center(
            child: Text(
              "Trading Market coming soon...",
              style: TextStyle(color: DesignTokens.textMuted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVaultTab() {
    // Owned-collectibles backend is not wired yet — show an honest empty state.
    return const Center(
      child: Text(
        "Your vault is empty.",
        style: TextStyle(color: DesignTokens.textMuted),
      ),
    );
  }

  Widget _buildPackDropsTab() {
    final drops = _packDrops;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: drops.length,
      itemBuilder: (context, index) {
        final drop = drops[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: DesignTokens.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: drop["color"].withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.inventory_2, color: drop["color"], size: 40),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      drop["title"],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${drop["remaining"]} remaining",
                      style: const TextStyle(
                        color: DesignTokens.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: drop["color"],
                  foregroundColor: Colors.black,
                ),
                child: Text(
                  drop["price"],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
