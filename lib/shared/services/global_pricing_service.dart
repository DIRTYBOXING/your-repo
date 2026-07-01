import 'package:cloud_firestore/cloud_firestore.dart';

/// Immutable data class for a single region's PPV pricing.
class RegionPricingEntry {
  final String code;
  final String name;
  final String flag;
  final String currency;
  final String symbol;
  final String displayPrice;
  final double usdPrice;

  const RegionPricingEntry({
    required this.code,
    required this.name,
    required this.flag,
    required this.currency,
    required this.symbol,
    required this.displayPrice,
    required this.usdPrice,
  });
}

/// GlobalPricingService — region-aware PPV pricing with Firestore override support.
/// Falls back to built-in static table when Firestore is unavailable (demo mode safe).
class GlobalPricingService {
  static final GlobalPricingService _instance =
      GlobalPricingService._internal();
  factory GlobalPricingService() => _instance;
  GlobalPricingService._internal();

  static const List<RegionPricingEntry> _staticEntries = [
    RegionPricingEntry(
      code: 'AU',
      name: 'Australia',
      flag: '🇦🇺',
      currency: 'AUD',
      symbol: 'A\$',
      displayPrice: 'A\$14.99',
      usdPrice: 14.99,
    ),
    RegionPricingEntry(
      code: 'US',
      name: 'United States',
      flag: '🇺🇸',
      currency: 'USD',
      symbol: '\$',
      displayPrice: '\$9.99',
      usdPrice: 9.99,
    ),
    RegionPricingEntry(
      code: 'GB',
      name: 'United Kingdom',
      flag: '🇬🇧',
      currency: 'GBP',
      symbol: '£',
      displayPrice: '£7.99',
      usdPrice: 7.99,
    ),
    RegionPricingEntry(
      code: 'EU',
      name: 'Europe',
      flag: '🇪🇺',
      currency: 'EUR',
      symbol: '€',
      displayPrice: '€8.99',
      usdPrice: 8.99,
    ),
    RegionPricingEntry(
      code: 'IN',
      name: 'India',
      flag: '🇮🇳',
      currency: 'INR',
      symbol: '₹',
      displayPrice: '₹199',
      usdPrice: 2.39,
    ),
    RegionPricingEntry(
      code: 'PK',
      name: 'Pakistan',
      flag: '🇵🇰',
      currency: 'PKR',
      symbol: '₨',
      displayPrice: '₨499',
      usdPrice: 1.79,
    ),
    RegionPricingEntry(
      code: 'PH',
      name: 'Philippines',
      flag: '🇵🇭',
      currency: 'PHP',
      symbol: '₱',
      displayPrice: '₱199',
      usdPrice: 3.49,
    ),
    RegionPricingEntry(
      code: 'NG',
      name: 'Nigeria',
      flag: '🇳🇬',
      currency: 'NGN',
      symbol: '₦',
      displayPrice: '₦999',
      usdPrice: 2.19,
    ),
    RegionPricingEntry(
      code: 'BR',
      name: 'Brazil',
      flag: '🇧🇷',
      currency: 'BRL',
      symbol: 'R\$',
      displayPrice: 'R\$9.99',
      usdPrice: 1.99,
    ),
    RegionPricingEntry(
      code: 'JP',
      name: 'Japan',
      flag: '🇯🇵',
      currency: 'JPY',
      symbol: '¥',
      displayPrice: '¥999',
      usdPrice: 8.99,
    ),
    RegionPricingEntry(
      code: 'AE',
      name: 'UAE / Middle East',
      flag: '🇦🇪',
      currency: 'AED',
      symbol: 'AED',
      displayPrice: 'AED 19',
      usdPrice: 5.19,
    ),
    RegionPricingEntry(
      code: 'ZA',
      name: 'South Africa',
      flag: '🇿🇦',
      currency: 'ZAR',
      symbol: 'R',
      displayPrice: 'R49',
      usdPrice: 2.59,
    ),
    RegionPricingEntry(
      code: 'TH',
      name: 'Thailand',
      flag: '🇹🇭',
      currency: 'THB',
      symbol: '฿',
      displayPrice: '฿149',
      usdPrice: 4.19,
    ),
  ];

  List<RegionPricingEntry> get allEntries => _staticEntries;

  RegionPricingEntry? getEntry(String countryCode) {
    final code = countryCode.toUpperCase();
    for (final e in _staticEntries) {
      if (e.code == code) return e;
    }
    return null;
  }

  /// Detects the most likely region from a locale string (e.g. "en_AU" → "AU").
  /// Falls back to "US" when the locale country cannot be matched.
  String detectRegionFromLocale(String locale) {
    final parts = locale.split(RegExp(r'[_\-]'));
    if (parts.length >= 2) {
      final candidate = parts.last.toUpperCase();
      if (_staticEntries.any((e) => e.code == candidate)) return candidate;
    }
    return 'US';
  }

  double getPriceUSD(String countryCode) =>
      getEntry(countryCode)?.usdPrice ?? 9.99;
  String getDisplayPrice(String countryCode) =>
      getEntry(countryCode)?.displayPrice ?? '\$9.99';
  Map<String, String> getAllDisplayPrices() => {
    for (final e in _staticEntries) e.code: e.displayPrice,
  };

  /// Live Firestore pricing override for a region.
  /// Reads from `global_pricing/{countryCode}` and merges with static fallback.
  /// Safe to call in demo mode — returns static data if Firestore is unavailable.
  Future<RegionPricingEntry> getLivePricing(String countryCode) async {
    final fallback = getEntry(countryCode) ?? _staticEntries.first;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('global_pricing')
          .doc(countryCode.toUpperCase())
          .get();
      if (doc.exists) {
        final d = doc.data()!;
        return RegionPricingEntry(
          code: fallback.code,
          name: d['name'] as String? ?? fallback.name,
          flag: fallback.flag,
          currency: d['currency'] as String? ?? fallback.currency,
          symbol: d['symbol'] as String? ?? fallback.symbol,
          displayPrice: d['displayPrice'] as String? ?? fallback.displayPrice,
          usdPrice: (d['price'] as num?)?.toDouble() ?? fallback.usdPrice,
        );
      }
    } catch (_) {
      // Firestore unavailable — static fallback used
    }
    return fallback;
  }

  /// Writes a pricing override to Firestore `global_pricing/{code}`.
  Future<void> setRegionPrice({
    required String countryCode,
    required double price,
    required String displayPrice,
    required String currency,
    required String symbol,
  }) async {
    await FirebaseFirestore.instance
        .collection('global_pricing')
        .doc(countryCode.toUpperCase())
        .set({
          'price': price,
          'displayPrice': displayPrice,
          'currency': currency,
          'symbol': symbol,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }
}
