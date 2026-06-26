import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// DFC MULTI-CURRENCY ENGINE
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Handles currency conversion, display, and regional pricing:
///
///   1. Exchange Rates — cached from Firestore, refreshed hourly
///   2. Regional Pricing — integrates with DfcPricingEngine tiers
///   3. Tax Calculation — GST/VAT/IVA per country
///   4. Display Formatting — locale-aware currency symbols
///   5. Stripe Amount Conversion — converts display amounts to Stripe cents
///
/// Supported Currencies (15):
///   AUD, USD, GBP, EUR, NZD, THB, SGD, CAD, JPY, ZAR,
///   NGN, BRL, MXN, INR, PHP
///
/// Base Currency: AUD (all internal calculations in AUD)
///
/// Firestore Collections:
///   exchange_rates/latest     — Current exchange rates
///   exchange_rates/history    — Rate history for auditing
///
/// ═══════════════════════════════════════════════════════════════════════════
class MultiCurrencyEngine with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ── Cached Rates ──
  Map<String, double> _rates = {};
  DateTime? _ratesUpdatedAt;
  bool _isLoading = false;
  String? _error;

  Map<String, double> get rates => _rates;
  DateTime? get ratesUpdatedAt => _ratesUpdatedAt;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ── Currency Definitions ──
  static const Map<String, CurrencyDef> currencies = {
    'AUD': CurrencyDef(
      code: 'AUD',
      symbol: r'A$',
      name: 'Australian Dollar',
      decimals: 2,
      stripeMinCents: 50,
    ),
    'USD': CurrencyDef(
      code: 'USD',
      symbol: r'$',
      name: 'US Dollar',
      decimals: 2,
      stripeMinCents: 50,
    ),
    'GBP': CurrencyDef(
      code: 'GBP',
      symbol: '£',
      name: 'British Pound',
      decimals: 2,
      stripeMinCents: 30,
    ),
    'EUR': CurrencyDef(
      code: 'EUR',
      symbol: '€',
      name: 'Euro',
      decimals: 2,
      stripeMinCents: 50,
    ),
    'NZD': CurrencyDef(
      code: 'NZD',
      symbol: r'NZ$',
      name: 'New Zealand Dollar',
      decimals: 2,
      stripeMinCents: 50,
    ),
    'THB': CurrencyDef(
      code: 'THB',
      symbol: '฿',
      name: 'Thai Baht',
      decimals: 2,
      stripeMinCents: 1000,
    ),
    'SGD': CurrencyDef(
      code: 'SGD',
      symbol: r'S$',
      name: 'Singapore Dollar',
      decimals: 2,
      stripeMinCents: 50,
    ),
    'CAD': CurrencyDef(
      code: 'CAD',
      symbol: r'C$',
      name: 'Canadian Dollar',
      decimals: 2,
      stripeMinCents: 50,
    ),
    'JPY': CurrencyDef(
      code: 'JPY',
      symbol: '¥',
      name: 'Japanese Yen',
      decimals: 0,
      stripeMinCents: 50,
    ),
    'ZAR': CurrencyDef(
      code: 'ZAR',
      symbol: 'R',
      name: 'South African Rand',
      decimals: 2,
      stripeMinCents: 500,
    ),
    'NGN': CurrencyDef(
      code: 'NGN',
      symbol: '₦',
      name: 'Nigerian Naira',
      decimals: 2,
      stripeMinCents: 5000,
    ),
    'BRL': CurrencyDef(
      code: 'BRL',
      symbol: r'R$',
      name: 'Brazilian Real',
      decimals: 2,
      stripeMinCents: 50,
    ),
    'MXN': CurrencyDef(
      code: 'MXN',
      symbol: r'MX$',
      name: 'Mexican Peso',
      decimals: 2,
      stripeMinCents: 1000,
    ),
    'INR': CurrencyDef(
      code: 'INR',
      symbol: '₹',
      name: 'Indian Rupee',
      decimals: 2,
      stripeMinCents: 50,
    ),
    'PHP': CurrencyDef(
      code: 'PHP',
      symbol: '₱',
      name: 'Philippine Peso',
      decimals: 2,
      stripeMinCents: 2500,
    ),
  };

  // ── Country → Currency Mapping ──
  static const Map<String, String> countryCurrency = {
    'AU': 'AUD', 'US': 'USD', 'GB': 'GBP', 'IE': 'EUR',
    'DE': 'EUR', 'FR': 'EUR', 'NL': 'EUR', 'BE': 'EUR',
    'IT': 'EUR', 'ES': 'EUR', 'PT': 'EUR', 'AT': 'EUR',
    'NZ': 'NZD', 'TH': 'THB', 'SG': 'SGD', 'CA': 'CAD',
    'JP': 'JPY', 'ZA': 'ZAR', 'NG': 'NGN', 'BR': 'BRL',
    'MX': 'MXN', 'IN': 'INR', 'PH': 'PHP',
    // Caribbean & Pacific (USD-pegged or use USD)
    'TT': 'USD', 'JM': 'USD', 'BB': 'USD', 'GY': 'USD',
    // African (use ZAR or NGN)
    'KE': 'USD', 'GH': 'USD', 'TZ': 'USD', 'UG': 'USD',
  };

  // ── Default Exchange Rates (AUD base) — used when Firestore unavailable ──
  static const Map<String, double> _fallbackRates = {
    'AUD': 1.00,
    'USD': 0.65,
    'GBP': 0.52,
    'EUR': 0.60,
    'NZD': 1.08,
    'THB': 22.50,
    'SGD': 0.87,
    'CAD': 0.88,
    'JPY': 97.00,
    'ZAR': 12.10,
    'NGN': 950.00,
    'BRL': 3.25,
    'MXN': 11.20,
    'INR': 54.00,
    'PHP': 36.50,
  };

  // ═══════════════════════════════════════════════════════════════════════
  // RATE MANAGEMENT
  // ═══════════════════════════════════════════════════════════════════════

  /// Load exchange rates from Firestore (or use fallback)
  Future<void> loadRates() async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();

    try {
      final doc = await _firestore
          .collection('exchange_rates')
          .doc('latest')
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        final ratesMap = data['rates'] as Map<String, dynamic>? ?? {};
        _rates = ratesMap.map((k, v) => MapEntry(k, (v as num).toDouble()));
        _ratesUpdatedAt = (data['updatedAt'] as Timestamp?)?.toDate();
      } else {
        _rates = Map.from(_fallbackRates);
        _ratesUpdatedAt = DateTime.now();
      }
    } catch (e) {
      debugPrint('MultiCurrencyEngine.loadRates error: $e');
      _rates = Map.from(_fallbackRates);
      _ratesUpdatedAt = DateTime.now();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get rate for a currency (AUD base). Returns fallback if not loaded.
  double getRate(String currencyCode) {
    if (_rates.isEmpty) return _fallbackRates[currencyCode] ?? 1.0;
    return _rates[currencyCode] ?? _fallbackRates[currencyCode] ?? 1.0;
  }

  // ═══════════════════════════════════════════════════════════════════════
  // CONVERSION
  // ═══════════════════════════════════════════════════════════════════════

  /// Convert amount from one currency to another
  double convert(double amount, String from, String to) {
    if (from == to) return amount;
    final fromRate = getRate(from);
    final toRate = getRate(to);
    if (fromRate == 0) return amount;
    // Convert: amount in FROM → AUD → TO
    final audAmount = amount / fromRate;
    return audAmount * toRate;
  }

  /// Convert an AUD amount to target currency
  double fromAud(double audAmount, String toCurrency) {
    return audAmount * getRate(toCurrency);
  }

  /// Convert any currency amount to AUD
  double toAud(double amount, String fromCurrency) {
    final rate = getRate(fromCurrency);
    if (rate == 0) return amount;
    return amount / rate;
  }

  /// Convert display amount to Stripe "smallest unit" (cents, etc.)
  int toStripeCents(double displayAmount, String currency) {
    final def = currencies[currency];
    if (def == null) return (displayAmount * 100).round();
    if (def.decimals == 0) return displayAmount.round(); // JPY
    return (displayAmount * 100).round();
  }

  /// Convert Stripe cents back to display amount
  double fromStripeCents(int cents, String currency) {
    final def = currencies[currency];
    if (def == null) return cents / 100;
    if (def.decimals == 0) return cents.toDouble(); // JPY
    return cents / 100;
  }

  // ═══════════════════════════════════════════════════════════════════════
  // DISPLAY FORMATTING
  // ═══════════════════════════════════════════════════════════════════════

  /// Format amount with currency symbol
  String format(double amount, String currencyCode) {
    final def = currencies[currencyCode];
    if (def == null) return '$currencyCode ${amount.toStringAsFixed(2)}';

    if (def.decimals == 0) {
      return '${def.symbol}${amount.round()}';
    }
    return '${def.symbol}${amount.toStringAsFixed(def.decimals)}';
  }

  /// Get currency for a country code
  String currencyForCountry(String countryCode) {
    return countryCurrency[countryCode.toUpperCase()] ?? 'USD';
  }

  /// Check if amount meets Stripe minimum for currency
  bool meetsStripeMinimum(double amount, String currency) {
    final def = currencies[currency];
    if (def == null) return amount >= 0.50;
    final cents = toStripeCents(amount, currency);
    return cents >= def.stripeMinCents;
  }

  // ═══════════════════════════════════════════════════════════════════════
  // TAX CALCULATION
  // ═══════════════════════════════════════════════════════════════════════

  /// Calculate tax for a given country
  TaxCalculation calculateTax(double amount, String countryCode) {
    final config = _taxConfigForCountry(countryCode);
    if (config == null) {
      return TaxCalculation(subtotal: amount, taxAmount: 0, total: amount);
    }

    final taxAmount = amount * config.rate;
    return TaxCalculation(
      subtotal: amount,
      taxName: config.name,
      taxRate: config.rate,
      taxAmount: taxAmount,
      total: amount + taxAmount,
    );
  }

  /// Get tax config for country (uses InvoiceGenerationService rates)
  static const Map<String, _TaxRate> _taxRateMap = {
    'AU': _TaxRate('GST', 0.10),
    'NZ': _TaxRate('GST', 0.15),
    'GB': _TaxRate('VAT', 0.20),
    'DE': _TaxRate('MwSt', 0.19),
    'FR': _TaxRate('TVA', 0.20),
    'IE': _TaxRate('VAT', 0.23),
    'NL': _TaxRate('BTW', 0.21),
    'BE': _TaxRate('BTW', 0.21),
    'SG': _TaxRate('GST', 0.09),
    'JP': _TaxRate('CT', 0.10),
    'TH': _TaxRate('VAT', 0.07),
    'CA': _TaxRate('GST', 0.05),
    'IN': _TaxRate('GST', 0.18),
    'ZA': _TaxRate('VAT', 0.15),
    'BR': _TaxRate('ICMS', 0.17),
    'MX': _TaxRate('IVA', 0.16),
    'PH': _TaxRate('VAT', 0.12),
    'NG': _TaxRate('VAT', 0.075),
  };

  _TaxRate? _taxConfigForCountry(String countryCode) {
    return _taxRateMap[countryCode.toUpperCase()];
  }

  // ═══════════════════════════════════════════════════════════════════════
  // REGIONAL PRICING
  // ═══════════════════════════════════════════════════════════════════════

  /// Get localized price for a product in user's country
  LocalizedPrice getLocalizedPrice({
    required double baseAudPrice,
    required String userCountry,
  }) {
    final currency = currencyForCountry(userCountry);
    final localAmount = fromAud(baseAudPrice, currency);
    final tax = calculateTax(localAmount, userCountry);

    return LocalizedPrice(
      currency: currency,
      displayAmount: localAmount,
      displayFormatted: format(localAmount, currency),
      taxInclusive: tax.total,
      taxFormatted: format(tax.total, currency),
      taxName: tax.taxName,
      taxRate: tax.taxRate,
    );
  }

  /// Bulk price conversion for price tables (subscription tiers, etc.)
  Map<String, LocalizedPrice> getLocalizedPriceTable({
    required Map<String, double> audPrices,
    required String userCountry,
  }) {
    return audPrices.map(
      (key, audPrice) => MapEntry(
        key,
        getLocalizedPrice(baseAudPrice: audPrice, userCountry: userCountry),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// MODELS
// ═══════════════════════════════════════════════════════════════════════════

class CurrencyDef {
  final String code;
  final String symbol;
  final String name;
  final int decimals;
  final int stripeMinCents;

  const CurrencyDef({
    required this.code,
    required this.symbol,
    required this.name,
    required this.decimals,
    required this.stripeMinCents,
  });
}

class TaxCalculation {
  final double subtotal;
  final String? taxName;
  final double taxRate;
  final double taxAmount;
  final double total;

  const TaxCalculation({
    required this.subtotal,
    this.taxName,
    this.taxRate = 0,
    required this.taxAmount,
    required this.total,
  });
}

class LocalizedPrice {
  final String currency;
  final double displayAmount;
  final String displayFormatted;
  final double taxInclusive;
  final String taxFormatted;
  final String? taxName;
  final double taxRate;

  const LocalizedPrice({
    required this.currency,
    required this.displayAmount,
    required this.displayFormatted,
    required this.taxInclusive,
    required this.taxFormatted,
    this.taxName,
    this.taxRate = 0,
  });
}

class _TaxRate {
  final String name;
  final double rate;
  const _TaxRate(this.name, this.rate);
}
