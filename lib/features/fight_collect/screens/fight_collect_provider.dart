import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/collectible_model.dart';

final myVaultProvider = FutureProvider<List<Collectible>>((ref) async {
  await Future.delayed(const Duration(milliseconds: 600)); // Simulate loading
  return [
    const Collectible(
      id: '1',
      title: 'Jay Cutler',
      subtitle: 'IBC III Main Event',
      rarity: Rarity.mythic,
      mintNumber: 1,
      totalMinted: 50,
      imageUrl: 'assets/dfc_backgrounds/new_dfc_image_1.png',
    ),
    const Collectible(
      id: '2',
      title: 'Luke Modini',
      subtitle: 'LHW Title Challenger',
      rarity: Rarity.legendary,
      mintNumber: 42,
      totalMinted: 250,
      imageUrl: 'assets/dfc_backgrounds/dfc_and_back_ground.png',
    ),
    const Collectible(
      id: '3',
      title: 'Fight Night 14',
      subtitle: 'Official Poster',
      rarity: Rarity.epic,
      mintNumber: 112,
      totalMinted: 500,
      imageUrl: 'assets/dfc_backgrounds/datafight_central_with_logo.png',
    ),
    const Collectible(
      id: '4',
      title: 'Isaac Hardman',
      subtitle: 'KO of the Night',
      rarity: Rarity.rare,
      mintNumber: 890,
      totalMinted: 2000,
      imageUrl: 'assets/dfc_backgrounds/new_dfc_image_1.png',
    ),
    const Collectible(
      id: '5',
      title: 'DFC Genesis',
      subtitle: 'Platform Launch Token',
      rarity: Rarity.common,
      mintNumber: 4051,
      totalMinted: 10000,
      imageUrl: 'assets/dfc_backgrounds/dfc_and_back_ground.png',
    ),
  ];
});

final activeDropsProvider = Provider<List<Map<String, dynamic>>>((ref) {
  return [
    {
      "title": "IBC III Championship Pack",
      "price": "\$19.99",
      "remaining": 1420,
      "color": DesignTokens.neonGold,
    },
    {
      "title": "Rising Stars Base Set",
      "price": "\$4.99",
      "remaining": 8500,
      "color": DesignTokens.neonCyan,
    },
  ];
});
