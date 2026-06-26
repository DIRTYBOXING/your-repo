import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/design_tokens.dart';
import '../providers/fight_collect_provider.dart';
import '../widgets/holographic_card.dart';

class FightCollectScreen extends ConsumerStatefulWidget {
  const FightCollectScreen({super.key});

  @override
  ConsumerState<FightCollectScreen> createState() => _FightCollectScreenState();
}

class _FightCollectScreenState extends ConsumerState<FightCollectScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

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
    final vaultAsync = ref.watch(myVaultProvider);

    return vaultAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: DesignTokens.neonGold),
      ),
      error: (e, _) => Center(
        child: Text(
          "Error: $e",
          style: const TextStyle(color: DesignTokens.neonRed),
        ),
      ),
      data: (items) {
        if (items.isEmpty) {
          return const Center(
            child: Text(
              "Your vault is empty.",
              style: TextStyle(color: DesignTokens.textMuted),
            ),
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          physics: const BouncingScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.7,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            return HolographicCard(collectible: items[index]);
          },
        );
      },
    );
  }

  Widget _buildPackDropsTab() {
    final drops = ref.watch(activeDropsProvider);

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
