import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';

enum Rarity { common, rare, epic, legendary, mythic }

extension RarityColors on Rarity {
  Color get color {
    switch (this) {
      case Rarity.common:
        return Colors.white54;
      case Rarity.rare:
        return DesignTokens.neonCyan;
      case Rarity.epic:
        return Colors.deepPurpleAccent;
      case Rarity.legendary:
        return DesignTokens.neonGold;
      case Rarity.mythic:
        return DesignTokens.neonMagenta;
    }
  }
}

class Collectible {
  final String id;
  final String title;
  final String subtitle;
  final Rarity rarity;
  final int mintNumber;
  final int totalMinted;
  final String imageUrl;

  const Collectible({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.rarity,
    required this.mintNumber,
    required this.totalMinted,
    required this.imageUrl,
  });
}
