import 'package:intl/intl.dart';

class PpvRegionalPriceQuote {
  final String countryCode;
  final String baseDisplay;
  final String? localDisplay;
  final String? localCurrencyCode;

  const PpvRegionalPriceQuote({
    required this.countryCode,
    required this.baseDisplay,
    this.localDisplay,
    this.localCurrencyCode,
  });

  bool get isLocalized => localDisplay != null;
}

class PpvRegionalPricing {
  PpvRegionalPricing._();

  static const Map<String, _SouthAsiaCurrency> _southAsiaCurrencies = {
    'IN': _SouthAsiaCurrency(
      currencyCode: 'INR',
      locale: 'en_IN',
      symbol: '₹',
      audRate: 55,
    ),
    'PK': _SouthAsiaCurrency(
      currencyCode: 'PKR',
      locale: 'en_PK',
      symbol: '₨',
      audRate: 178,
    ),
  };

  static PpvRegionalPriceQuote quote({
    required double amount,
    required String baseCurrency,
    required String countryCode,
  }) {
    final normalizedCountry = countryCode.toUpperCase();
    final normalizedCurrency = baseCurrency.toUpperCase();
    final baseDisplay =
        '${_baseSymbol(normalizedCurrency)}${amount.toStringAsFixed(2)} $normalizedCurrency';

    final southAsiaCurrency = _southAsiaCurrencies[normalizedCountry];
    if (normalizedCurrency != 'AUD' || southAsiaCurrency == null) {
      return PpvRegionalPriceQuote(
        countryCode: normalizedCountry,
        baseDisplay: baseDisplay,
      );
    }

    final convertedAmount = amount * southAsiaCurrency.audRate;
    final formatter = NumberFormat.currency(
      locale: southAsiaCurrency.locale,
      symbol: southAsiaCurrency.symbol,
      decimalDigits: 0,
    );

    return PpvRegionalPriceQuote(
      countryCode: normalizedCountry,
      baseDisplay: baseDisplay,
      localDisplay:
          '${formatter.format(convertedAmount)} ${southAsiaCurrency.currencyCode}',
      localCurrencyCode: southAsiaCurrency.currencyCode,
    );
  }

  static String _baseSymbol(String currencyCode) {
    switch (currencyCode) {
      case 'USD':
      case 'AUD':
      case 'NZD':
        return r'$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      default:
        return '';
    }
  }
}

class _SouthAsiaCurrency {
  final String currencyCode;
  final String locale;
  final String symbol;
  final double audRate;

  const _SouthAsiaCurrency({
    required this.currencyCode,
    required this.locale,
    required this.symbol,
    required this.audRate,
  });
}
