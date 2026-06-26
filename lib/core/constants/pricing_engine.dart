/// ═══════════════════════════════════════════════════════════════════════════
/// DFC GLOBAL PRICING ENGINE
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Prices benchmarked against how major platforms (Spotify, Netflix, YouTube
/// Premium) price locally across the same markets DFC serves — Africa,
/// Caribbean, South/Southeast Asia, and Latin America — then adjusted for
/// combat-sport community affordability.
///
///  T1  High-income    (US/UK/CA/AU/EU/SG/JP...)       — base rate
///  T2  Upper-middle   (ZA/BR/MX/TH/TR/TT/PL...)       — ~67 % of base
///  T3  Lower-middle   (NG/KE/GH/JM/IN/PH/TZ...)       — ~33 % of base
///  T4  Low-income     (PK/ET/ZW/HT/SS/CD...)           — ~26 % of base
///
/// Loyalty rewards are stacked on top:
///    3–5  months  → Bronze  · 5 % off
///    6–11 months  → Silver  · 10 % off
///   12–23 months  → Gold    · 15 % off
///   24–35 months  → Platinum· 20 % off
///   36+  months   → Diamond · 25 % off
/// ═══════════════════════════════════════════════════════════════════════════
library;

import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════════════════
// ENUMS
// ═══════════════════════════════════════════════════════════════════════════

enum PricingRegion { tier1, tier2, tier3, tier4 }

enum LoyaltyTier { none, bronze, silver, gold, platinum, diamond }

// ═══════════════════════════════════════════════════════════════════════════
// DATA CLASSES
// ═══════════════════════════════════════════════════════════════════════════

class RegionalPrice {
  /// USD amount — what Stripe charges
  final double usd;

  /// Formatted USD string, e.g. '\$0.99'
  final String display;

  /// Local currency equivalent shown for context, e.g. '≈ ₦1,600'
  final String? localDisplay;

  /// Short affordability line shown in the UI
  final String context;

  const RegionalPrice({
    required this.usd,
    required this.display,
    this.localDisplay,
    required this.context,
  });
}

class LoyaltyStatus {
  final LoyaltyTier tier;
  final int monthsActive;

  /// Fractional discount, e.g. 0.15 = 15 %
  final double discountPct;
  final String label;
  final String badge;
  final Color color;

  const LoyaltyStatus({
    required this.tier,
    required this.monthsActive,
    required this.discountPct,
    required this.label,
    required this.badge,
    required this.color,
  });

  bool get hasDiscount => discountPct > 0;

  String get discountLabel =>
      hasDiscount ? '${(discountPct * 100).round()}% OFF' : '';
}

// ═══════════════════════════════════════════════════════════════════════════
// ENGINE
// ═══════════════════════════════════════════════════════════════════════════

class DfcPricingEngine {
  DfcPricingEngine._();

  // ── Country → Region map ──────────────────────────────────────────────
  // Coverage: 100+ countries. Unknown defaults to T1 (no one should be
  // penalised for a locale that isn't mapped yet).
  static const Map<String, PricingRegion> _countryRegion = {
    // ── TIER 1 — High income ─────────────────────────────────────────
    'US': PricingRegion.tier1, 'CA': PricingRegion.tier1,
    'GB': PricingRegion.tier1, 'AU': PricingRegion.tier1,
    'NZ': PricingRegion.tier1, 'IE': PricingRegion.tier1,
    'DE': PricingRegion.tier1, 'FR': PricingRegion.tier1,
    'NL': PricingRegion.tier1, 'BE': PricingRegion.tier1,
    'CH': PricingRegion.tier1, 'AT': PricingRegion.tier1,
    'SE': PricingRegion.tier1, 'NO': PricingRegion.tier1,
    'DK': PricingRegion.tier1, 'FI': PricingRegion.tier1,
    'SG': PricingRegion.tier1, 'JP': PricingRegion.tier1,
    'KR': PricingRegion.tier1, 'HK': PricingRegion.tier1,
    'TW': PricingRegion.tier1, 'AE': PricingRegion.tier1,
    'QA': PricingRegion.tier1, 'SA': PricingRegion.tier1,
    'IL': PricingRegion.tier1, 'IT': PricingRegion.tier1,
    'ES': PricingRegion.tier1, 'PT': PricingRegion.tier1,
    'LU': PricingRegion.tier1, 'IS': PricingRegion.tier1,

    // ── TIER 2 — Upper-middle income ─────────────────────────────────
    'ZA': PricingRegion.tier2, 'BR': PricingRegion.tier2,
    'MX': PricingRegion.tier2, 'CL': PricingRegion.tier2,
    'CO': PricingRegion.tier2, 'PE': PricingRegion.tier2,
    'AR': PricingRegion.tier2, 'TH': PricingRegion.tier2,
    'MY': PricingRegion.tier2, 'TR': PricingRegion.tier2,
    'PL': PricingRegion.tier2, 'CZ': PricingRegion.tier2,
    'HU': PricingRegion.tier2, 'RO': PricingRegion.tier2,
    'TT': PricingRegion.tier2, 'BB': PricingRegion.tier2,
    'SR': PricingRegion.tier2, 'GY': PricingRegion.tier2,
    'MU': PricingRegion.tier2, 'CV': PricingRegion.tier2,
    'NA': PricingRegion.tier2, 'BW': PricingRegion.tier2,
    'EC': PricingRegion.tier2, 'DO': PricingRegion.tier2,
    'PA': PricingRegion.tier2, 'CR': PricingRegion.tier2,
    'GT': PricingRegion.tier2, 'JO': PricingRegion.tier2,
    'RU': PricingRegion.tier2, 'UA': PricingRegion.tier2,
    'RS': PricingRegion.tier2, 'HR': PricingRegion.tier2,
    'BA': PricingRegion.tier2, 'ME': PricingRegion.tier2,

    // ── TIER 3 — Lower-middle income (key DFC markets) ───────────────
    'NG': PricingRegion.tier3, 'KE': PricingRegion.tier3,
    'GH': PricingRegion.tier3, 'TZ': PricingRegion.tier3,
    'UG': PricingRegion.tier3, 'JM': PricingRegion.tier3,
    'EG': PricingRegion.tier3, 'MA': PricingRegion.tier3,
    'TN': PricingRegion.tier3, 'CI': PricingRegion.tier3,
    'SN': PricingRegion.tier3, 'CM': PricingRegion.tier3,
    'RW': PricingRegion.tier3, 'AO': PricingRegion.tier3,
    'ZM': PricingRegion.tier3, 'MG': PricingRegion.tier3,
    'MW': PricingRegion.tier3, 'MZ': PricingRegion.tier3,
    'LR': PricingRegion.tier3, 'SL': PricingRegion.tier3,
    'BO': PricingRegion.tier3, 'PY': PricingRegion.tier3,
    'HN': PricingRegion.tier3, 'NI': PricingRegion.tier3,
    'SV': PricingRegion.tier3, 'IN': PricingRegion.tier3,
    'PH': PricingRegion.tier3, 'ID': PricingRegion.tier3,
    'VN': PricingRegion.tier3, 'BD': PricingRegion.tier3,
    'LK': PricingRegion.tier3, 'NP': PricingRegion.tier3,
    'KH': PricingRegion.tier3, 'LA': PricingRegion.tier3,
    'PG': PricingRegion.tier3, 'FJ': PricingRegion.tier3,
    'BJ': PricingRegion.tier3, 'TG': PricingRegion.tier3,
    'BF': PricingRegion.tier3,

    // ── TIER 4 — Low income / economic hardship ──────────────────────
    'ZW': PricingRegion.tier4, 'PK': PricingRegion.tier4,
    'ET': PricingRegion.tier4, 'SS': PricingRegion.tier4,
    'BI': PricingRegion.tier4, 'SD': PricingRegion.tier4,
    'YE': PricingRegion.tier4, 'AF': PricingRegion.tier4,
    'HT': PricingRegion.tier4, 'CD': PricingRegion.tier4,
    'CF': PricingRegion.tier4, 'ML': PricingRegion.tier4,
    'NE': PricingRegion.tier4, 'TD': PricingRegion.tier4,
    'SO': PricingRegion.tier4, 'GM': PricingRegion.tier4,
    'GN': PricingRegion.tier4, 'GW': PricingRegion.tier4,
    'MM': PricingRegion.tier4, 'CG': PricingRegion.tier4,
    'ER': PricingRegion.tier4, 'DJ': PricingRegion.tier4,
  };

  // ── USD prices per region ─────────────────────────────────────────────
  // Keys: 'fighter_pro' | 'promoter_cmd' | 'supporter' | 'coach_mentor'
  static const Map<PricingRegion, Map<String, double>> _usdPrices = {
    PricingRegion.tier1: {
      'fighter_pro': 2.99,
      'promoter_cmd': 9.99,
      'supporter': 1.99,
      'coach_mentor': 4.99,
    },
    PricingRegion.tier2: {
      'fighter_pro': 1.99,
      'promoter_cmd': 6.49,
      'supporter': 1.29,
      'coach_mentor': 3.49,
    },
    PricingRegion.tier3: {
      'fighter_pro': 0.99,
      'promoter_cmd': 3.49,
      'supporter': 0.69,
      'coach_mentor': 1.99,
    },
    PricingRegion.tier4: {
      'fighter_pro': 0.79,
      'promoter_cmd': 2.49,
      'supporter': 0.49,
      'coach_mentor': 1.49,
    },
  };

  // ── Local currency display ────────────────────────────────────────────
  // Display only — Stripe charges in USD.
  // Exchange rates approximate Q1 2026.
  static const Map<String, String> _localSymbol = {
    'NG': '₦',
    'KE': 'KSh',
    'GH': 'GH₵',
    'TZ': 'TSh',
    'UG': 'USh',
    'ZA': 'R',
    'NA': 'N\$',
    'ZW': 'US\$',
    'JM': 'J\$',
    'TT': 'TT\$',
    'BB': 'Bd\$',
    'GY': 'G\$',
    'IN': '₹',
    'PH': '₱',
    'ID': 'Rp',
    'PK': '₨',
    'BD': '৳',
    'VN': '₫',
    'BR': 'R\$',
    'MX': 'MX\$',
    'CO': 'COP',
    'AR': 'ARS',
    'ZM': 'K',
    'MW': 'MK',
    'EG': 'E£',
    'MA': 'DH',
    'TN': 'DT',
    'ET': 'Br',
    'RW': 'RF',
    'SN': 'CFA',
    'CI': 'CFA',
    'CM': 'CFA',
  };

  static const Map<String, double> _usdToLocalRate = {
    'NG': 1600,
    'KE': 130,
    'GH': 16,
    'TZ': 2700,
    'UG': 3800,
    'ZA': 19,
    'NA': 19,
    'ZW': 1,
    'JM': 157,
    'TT': 6.8,
    'BB': 2,
    'GY': 209,
    'IN': 84,
    'PH': 57,
    'ID': 16500,
    'PK': 280,
    'BD': 110,
    'VN': 25000,
    'BR': 5.8,
    'MX': 20,
    'CO': 4200,
    'AR': 1100,
    'ZM': 27,
    'MW': 1750,
    'EG': 50,
    'MA': 10,
    'TN': 3.1,
    'ET': 58,
    'RW': 1350,
    'SN': 620,
    'CI': 620,
    'CM': 620,
  };

  // ── Context messaging per region + product ────────────────────────────
  static const Map<PricingRegion, Map<String, String>> _affordabilityMsg = {
    PricingRegion.tier1: {
      'fighter_pro': 'Less than a coffee. Full AI coaching included.',
      'promoter_cmd': 'Professional event tools at a fair rate.',
      'supporter': 'Support the community. Go ad-free.',
    },
    PricingRegion.tier2: {
      'fighter_pro': 'Less than a data bundle. Unlimited fight intelligence.',
      'promoter_cmd': 'Event management tools priced for your market.',
      'supporter': 'Ad-free feed. Community badge. Local rate.',
    },
    PricingRegion.tier3: {
      'fighter_pro':
          'Under \$1. Full platform access — built for fighters everywhere.',
      'promoter_cmd': 'Grassroots event tools. Priced for your community.',
      'supporter': 'Less than a text message. Remove all ads.',
    },
    PricingRegion.tier4: {
      'fighter_pro': 'Maximum access, minimum price. Your journey matters.',
      'promoter_cmd': 'Built to grow grassroots combat sports globally.',
      'supporter': 'Every subscription helps build the global fight community.',
    },
  };

  // ── Public API ────────────────────────────────────────────────────────

  static PricingRegion regionFor(String countryCode) =>
      _countryRegion[countryCode.toUpperCase()] ?? PricingRegion.tier1;

  static RegionalPrice priceFor({
    required String productKey,
    required String countryCode,
  }) {
    final region = regionFor(countryCode);
    final prices = _usdPrices[region]!;
    final usd = prices[productKey] ?? prices['fighter_pro']!;
    final display = '\$${usd.toStringAsFixed(2)}';

    String? localDisplay;
    final symbol = _localSymbol[countryCode.toUpperCase()];
    final rate = _usdToLocalRate[countryCode.toUpperCase()];
    if (symbol != null && rate != null) {
      final localAmt = usd * rate;
      final formatted = localAmt >= 100000
          ? '${(localAmt / 1000).round()}k'
          : localAmt >= 1000
          ? '${(localAmt / 1000).toStringAsFixed(1)}k'
          : localAmt.toStringAsFixed(0);
      localDisplay = '≈ $symbol$formatted';
    }

    final msgMap = _affordabilityMsg[region]!;
    final context = msgMap[productKey] ?? msgMap['fighter_pro']!;

    return RegionalPrice(
      usd: usd,
      display: display,
      localDisplay: localDisplay,
      context: context,
    );
  }

  /// Annual price = 10 months (2 months free).
  static double yearlyPrice({
    required String productKey,
    required String countryCode,
  }) {
    final monthly = priceFor(
      productKey: productKey,
      countryCode: countryCode,
    ).usd;
    return double.parse((monthly * 10).toStringAsFixed(2));
  }

  // ── Loyalty ───────────────────────────────────────────────────────────

  static LoyaltyStatus loyaltyFor(DateTime? memberSince) {
    if (memberSince == null) {
      return const LoyaltyStatus(
        tier: LoyaltyTier.none,
        monthsActive: 0,
        discountPct: 0,
        label: 'New Member',
        badge: '🥊',
        color: Color(0xFF777777),
      );
    }

    final months = _monthsBetween(memberSince, DateTime.now());

    if (months >= 36) {
      return LoyaltyStatus(
        tier: LoyaltyTier.diamond,
        monthsActive: months,
        discountPct: 0.25,
        label: 'Diamond Legend',
        badge: '💎',
        color: const Color(0xFF00D4FF),
      );
    }
    if (months >= 24) {
      return LoyaltyStatus(
        tier: LoyaltyTier.platinum,
        monthsActive: months,
        discountPct: 0.20,
        label: 'Platinum Champion',
        badge: '🏆',
        color: const Color(0xFFE5C100),
      );
    }
    if (months >= 12) {
      return LoyaltyStatus(
        tier: LoyaltyTier.gold,
        monthsActive: months,
        discountPct: 0.15,
        label: 'Gold Veteran',
        badge: '🥇',
        color: const Color(0xFFFFD700),
      );
    }
    if (months >= 6) {
      return LoyaltyStatus(
        tier: LoyaltyTier.silver,
        monthsActive: months,
        discountPct: 0.10,
        label: 'Silver Fighter',
        badge: '🥈',
        color: const Color(0xFFC0C0C0),
      );
    }
    if (months >= 3) {
      return LoyaltyStatus(
        tier: LoyaltyTier.bronze,
        monthsActive: months,
        discountPct: 0.05,
        label: 'Bronze Rookie',
        badge: '🥉',
        color: const Color(0xFFCD7F32),
      );
    }

    return LoyaltyStatus(
      tier: LoyaltyTier.none,
      monthsActive: months,
      discountPct: 0,
      label: 'New Member',
      badge: '🥊',
      color: const Color(0xFF777777),
    );
  }

  static double applyLoyaltyDiscount(double price, double discountPct) =>
      double.parse((price * (1 - discountPct)).toStringAsFixed(2));

  static int _monthsBetween(DateTime from, DateTime to) =>
      (to.year - from.year) * 12 + (to.month - from.month);

  // ── Region label helpers ──────────────────────────────────────────────

  static String regionLabel(String countryCode) {
    switch (regionFor(countryCode)) {
      case PricingRegion.tier1:
        return 'Global Standard';
      case PricingRegion.tier2:
        return 'Regional Rate';
      case PricingRegion.tier3:
        return 'Community Rate';
      case PricingRegion.tier4:
        return 'Access Rate';
    }
  }
}
