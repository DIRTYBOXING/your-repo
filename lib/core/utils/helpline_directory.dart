/// ═══════════════════════════════════════════════════════════════════════════
/// HELPLINE DIRECTORY — Location-aware crisis support numbers
///
/// Maps country codes to local crisis helplines.
/// Used by FightWire, Fighter Safety, and any support surface.
/// Falls back to findahelpline.com for unlisted countries.
/// ═══════════════════════════════════════════════════════════════════════════
library;

class HelplineEntry {
  final String name;
  final String number;
  final String? url;

  const HelplineEntry(this.name, this.number, {this.url});
}

class CountryHelplines {
  final String countryCode;
  final String countryName;
  final String flag;
  final String emergency;
  final List<HelplineEntry> helplines;

  const CountryHelplines({
    required this.countryCode,
    required this.countryName,
    required this.flag,
    required this.emergency,
    required this.helplines,
  });
}

class HelplineDirectory {
  HelplineDirectory._();

  /// All supported countries with helplines
  static const List<String> supportedCountries = [
    'Australia',
    'United States',
    'United Kingdom',
    'Canada',
    'New Zealand',
    'Ireland',
    'South Africa',
    'Philippines',
    'Thailand',
    'Japan',
    'Brazil',
    'Germany',
    'France',
    'Mexico',
    'India',
    'Indonesia',
    'Netherlands',
    'Sweden',
    'Singapore',
    'South Korea',
  ];

  /// Map of country name → helpline data
  static final Map<String, CountryHelplines> _directory = {
    'australia': const CountryHelplines(
      countryCode: 'AU',
      countryName: 'Australia',
      flag: '🇦🇺',
      emergency: '000',
      helplines: [
        HelplineEntry(
          'Lifeline',
          '13 11 14',
          url: 'https://www.lifeline.org.au',
        ),
        HelplineEntry(
          'Beyond Blue',
          '1300 22 4636',
          url: 'https://www.beyondblue.org.au',
        ),
        HelplineEntry(
          'Kids Helpline',
          '1800 55 1800',
          url: 'https://kidshelpline.com.au',
        ),
        HelplineEntry('Suicide Call Back', '1300 659 467'),
        HelplineEntry('MensLine Australia', '1300 78 99 78'),
      ],
    ),
    'united states': const CountryHelplines(
      countryCode: 'US',
      countryName: 'United States',
      flag: '🇺🇸',
      emergency: '911',
      helplines: [
        HelplineEntry(
          'Suicide & Crisis Lifeline',
          '988',
          url: 'https://988lifeline.org',
        ),
        HelplineEntry(
          'Crisis Text Line',
          'Text HOME to 741741',
          url: 'https://www.crisistextline.org',
        ),
        HelplineEntry('SAMHSA Helpline', '1-800-662-4357'),
        HelplineEntry('Veterans Crisis Line', '988 (press 1)'),
        HelplineEntry('Trevor Project (LGBTQ+)', '1-866-488-7386'),
      ],
    ),
    'united kingdom': const CountryHelplines(
      countryCode: 'GB',
      countryName: 'United Kingdom',
      flag: '🇬🇧',
      emergency: '999',
      helplines: [
        HelplineEntry(
          'Samaritans',
          '116 123',
          url: 'https://www.samaritans.org',
        ),
        HelplineEntry(
          'CALM',
          '0800 58 58 58',
          url: 'https://www.thecalmzone.net',
        ),
        HelplineEntry('Shout', 'Text SHOUT to 85258'),
        HelplineEntry('Mind', '0300 123 3393', url: 'https://www.mind.org.uk'),
        HelplineEntry('Papyrus (Under 35)', '0800 068 41 41'),
      ],
    ),
    'canada': const CountryHelplines(
      countryCode: 'CA',
      countryName: 'Canada',
      flag: '🇨🇦',
      emergency: '911',
      helplines: [
        HelplineEntry(
          'Talk Suicide Canada',
          '988',
          url: 'https://talksuicide.ca',
        ),
        HelplineEntry('Crisis Services Canada', '1-833-456-4566'),
        HelplineEntry('Kids Help Phone', '1-800-668-6868'),
        HelplineEntry('Crisis Text Line', 'Text HOME to 686868'),
      ],
    ),
    'new zealand': const CountryHelplines(
      countryCode: 'NZ',
      countryName: 'New Zealand',
      flag: '🇳🇿',
      emergency: '111',
      helplines: [
        HelplineEntry(
          'Lifeline NZ',
          '0800 543 354',
          url: 'https://www.lifeline.org.nz',
        ),
        HelplineEntry('Need to Talk?', '1737'),
        HelplineEntry('Youthline', '0800 376 633'),
        HelplineEntry('Depression Helpline', '0800 111 757'),
      ],
    ),
    'ireland': const CountryHelplines(
      countryCode: 'IE',
      countryName: 'Ireland',
      flag: '🇮🇪',
      emergency: '112',
      helplines: [
        HelplineEntry('Samaritans Ireland', '116 123'),
        HelplineEntry(
          'Pieta House',
          '1800 247 247',
          url: 'https://www.pieta.ie',
        ),
        HelplineEntry('Childline', '1800 66 66 66'),
        HelplineEntry('Aware', '1800 80 48 48'),
      ],
    ),
    'south africa': const CountryHelplines(
      countryCode: 'ZA',
      countryName: 'South Africa',
      flag: '🇿🇦',
      emergency: '10111',
      helplines: [
        HelplineEntry('SADAG', '0800 567 567', url: 'https://www.sadag.org'),
        HelplineEntry('Lifeline SA', '0861 322 322'),
        HelplineEntry('Childline SA', '116'),
      ],
    ),
    'philippines': const CountryHelplines(
      countryCode: 'PH',
      countryName: 'Philippines',
      flag: '🇵🇭',
      emergency: '911',
      helplines: [
        HelplineEntry('NCMH Crisis Line', '0917-899-8727'),
        HelplineEntry('Hopeline', '(02) 804-4673'),
        HelplineEntry('In Touch', '(02) 893-7603'),
      ],
    ),
    'thailand': const CountryHelplines(
      countryCode: 'TH',
      countryName: 'Thailand',
      flag: '🇹🇭',
      emergency: '191',
      helplines: [
        HelplineEntry('Samaritans Thailand', '02-713-6793'),
        HelplineEntry('DMH Hotline', '1323'),
        HelplineEntry('Tourist Police', '1155'),
      ],
    ),
    'japan': const CountryHelplines(
      countryCode: 'JP',
      countryName: 'Japan',
      flag: '🇯🇵',
      emergency: '110',
      helplines: [
        HelplineEntry(
          'TELL Lifeline',
          '03-5774-0992',
          url: 'https://telljp.com',
        ),
        HelplineEntry('Befrienders Worldwide', '03-4550-1146'),
        HelplineEntry('Yorisoi Hotline', '0120-279-338'),
      ],
    ),
    'brazil': const CountryHelplines(
      countryCode: 'BR',
      countryName: 'Brazil',
      flag: '🇧🇷',
      emergency: '190',
      helplines: [
        HelplineEntry('CVV', '188', url: 'https://www.cvv.org.br'),
        HelplineEntry('SAMU', '192'),
      ],
    ),
    'germany': const CountryHelplines(
      countryCode: 'DE',
      countryName: 'Germany',
      flag: '🇩🇪',
      emergency: '112',
      helplines: [
        HelplineEntry('Telefonseelsorge', '0800 111 0 111'),
        HelplineEntry('Telefonseelsorge (2)', '0800 111 0 222'),
        HelplineEntry('Kinder- und Jugendtelefon', '0800 111 0 333'),
      ],
    ),
    'france': const CountryHelplines(
      countryCode: 'FR',
      countryName: 'France',
      flag: '🇫🇷',
      emergency: '112',
      helplines: [
        HelplineEntry('SOS Amitié', '09 72 39 40 50'),
        HelplineEntry('Fil Santé Jeunes', '0 800 235 236'),
        HelplineEntry('3114 (National)', '3114'),
      ],
    ),
    'mexico': const CountryHelplines(
      countryCode: 'MX',
      countryName: 'Mexico',
      flag: '🇲🇽',
      emergency: '911',
      helplines: [
        HelplineEntry('SAPTEL', '55 5259-8121'),
        HelplineEntry('Línea de la Vida', '800 911 2000'),
      ],
    ),
    'india': const CountryHelplines(
      countryCode: 'IN',
      countryName: 'India',
      flag: '🇮🇳',
      emergency: '112',
      helplines: [
        HelplineEntry('Vandrevala Foundation', '1860-2662-345'),
        HelplineEntry('iCall', '9152987821', url: 'https://icallhelpline.org'),
        HelplineEntry('AASRA', '91-22-27546669'),
      ],
    ),
    'indonesia': const CountryHelplines(
      countryCode: 'ID',
      countryName: 'Indonesia',
      flag: '🇮🇩',
      emergency: '112',
      helplines: [
        HelplineEntry('Into the Light', '119 ext 8'),
        HelplineEntry('RSJ Soeharto Heerdjan', '(021) 500-454'),
      ],
    ),
    'netherlands': const CountryHelplines(
      countryCode: 'NL',
      countryName: 'Netherlands',
      flag: '🇳🇱',
      emergency: '112',
      helplines: [
        HelplineEntry(
          '113 Zelfmoordpreventie',
          '0900-0113',
          url: 'https://www.113.nl',
        ),
        HelplineEntry('Kindertelefoon', '0800-0432'),
      ],
    ),
    'sweden': const CountryHelplines(
      countryCode: 'SE',
      countryName: 'Sweden',
      flag: '🇸🇪',
      emergency: '112',
      helplines: [
        HelplineEntry('Mind Självmordslinjen', '90101', url: 'https://mind.se'),
        HelplineEntry('BRIS', '116 111'),
      ],
    ),
    'singapore': const CountryHelplines(
      countryCode: 'SG',
      countryName: 'Singapore',
      flag: '🇸🇬',
      emergency: '999',
      helplines: [
        HelplineEntry(
          'Samaritans of Singapore',
          '1-767',
          url: 'https://www.sos.org.sg',
        ),
        HelplineEntry('IMH Mental Health', '6389 2222'),
        HelplineEntry('TOUCHline', '1800 377 2252'),
      ],
    ),
    'south korea': const CountryHelplines(
      countryCode: 'KR',
      countryName: 'South Korea',
      flag: '🇰🇷',
      emergency: '112',
      helplines: [
        HelplineEntry('Mental Health Crisis', '1577-0199'),
        HelplineEntry('Suicide Prevention', '1393'),
        HelplineEntry('Korea Lifeline', '1588-9191'),
      ],
    ),
  };

  /// Lookup helplines by country name (case-insensitive)
  static CountryHelplines? forCountry(String? country) {
    if (country == null || country.isEmpty) return null;
    return _directory[country.toLowerCase()];
  }

  /// Default fallback helplines for unrecognized countries
  static const CountryHelplines fallback = CountryHelplines(
    countryCode: 'INTL',
    countryName: 'International',
    flag: '🌍',
    emergency: '112 / 911',
    helplines: [
      HelplineEntry(
        'Find A Helpline',
        'findahelpline.com',
        url: 'https://findahelpline.com',
      ),
      HelplineEntry(
        'Befrienders Worldwide',
        'befrienders.org',
        url: 'https://www.befrienders.org',
      ),
      HelplineEntry(
        'IASP Crisis Centres',
        'iasp.info/resources',
        url: 'https://www.iasp.info/resources/Crisis_Centres/',
      ),
    ],
  );

  /// Get helplines: tries user's country first, falls back to international
  static CountryHelplines resolve(String? country) {
    return forCountry(country) ?? fallback;
  }
}
