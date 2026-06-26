import 'package:flutter/material.dart';

import 'app_constants.dart';

/// Centralized registry of all streaming platforms DFC collaborates with.
/// DFC embraces ALL promotions and platforms — the betaverse hub.
class StreamingPlatforms {
  StreamingPlatforms._();

  static const Map<String, StreamingPlatformInfo> registry = {
    // ── DFC (always first) ──
    'DFC': StreamingPlatformInfo(
      name: 'DFC',
      url: AppConstants.publicWebBaseUrl,
      colorValue: 0xFF00E5FF, // cyanAccent
      iconData: 0xf046b, // Icons.sports_mma
    ),
    // ── Australian Platforms ──
    'Kayo': StreamingPlatformInfo(
      name: 'Kayo',
      url: 'https://kayosports.com.au',
      colorValue: 0xFF4CAF50, // green
      iconData: 0xe532, // Icons.sports
    ),
    'Main Event': StreamingPlatformInfo(
      name: 'Main Event',
      url: 'https://www.mainevent.com.au',
      colorValue: 0xFFFF6D00, // deep orange accent
      iconData: 0xe40d, // Icons.live_tv
    ),
    'Thrillx': StreamingPlatformInfo(
      name: 'Thrillx',
      url: 'https://www.thrillx.com.au',
      colorValue: 0xFFE040FB, // purple accent
      iconData: 0xe63e, // Icons.theaters
    ),
    // ── US / Global Platforms ──
    'ESPN+': StreamingPlatformInfo(
      name: 'ESPN+',
      url: 'https://plus.espn.com',
      colorValue: 0xFFD32F2F, // red
      iconData: 0xe40d, // Icons.live_tv
    ),
    'DAZN': StreamingPlatformInfo(
      name: 'DAZN',
      url: 'https://www.dazn.com',
      colorValue: 0xFFFFD600, // yellow accent
      iconData: 0xe40d, // Icons.live_tv
    ),
    'Paramount+': StreamingPlatformInfo(
      name: 'Paramount+',
      url: 'https://www.paramountplus.com',
      colorValue: 0xFF2196F3, // blue
      iconData: 0xe40d, // Icons.live_tv
    ),
    'UFC Fight Pass': StreamingPlatformInfo(
      name: 'UFC Fight Pass',
      url: 'https://www.ufc.com/fight-pass',
      colorValue: 0xFFC62828, // dark red
      iconData: 0xf046b, // Icons.sports_mma
    ),
    'TrillerTV+': StreamingPlatformInfo(
      name: 'TrillerTV+',
      url: 'https://www.trillertvplus.com',
      colorValue: 0xFF7C4DFF, // deep purple accent
      iconData: 0xe333, // Icons.tv
    ),
    'BKFC App': StreamingPlatformInfo(
      name: 'BKFC App',
      url: 'https://www.bkfc.com',
      colorValue: 0xFFFF3D00, // deep orange
      iconData: 0xf046b, // Icons.sports_mma
    ),
    'ONE App': StreamingPlatformInfo(
      name: 'ONE App',
      url: 'https://www.onefc.com/watch',
      colorValue: 0xFFFFAB00, // amber accent
      iconData: 0xe532, // Icons.sports
    ),
    'TNT Sports': StreamingPlatformInfo(
      name: 'TNT Sports',
      url: 'https://www.tntsports.co.uk',
      colorValue: 0xFF00BFA5, // teal accent
      iconData: 0xe40d, // Icons.live_tv
    ),
    'Prime Video': StreamingPlatformInfo(
      name: 'Prime Video',
      url: 'https://www.primevideo.com',
      colorValue: 0xFF00A8E1, // light blue
      iconData: 0xe40d, // Icons.live_tv
    ),
    'Live Combat Sports': StreamingPlatformInfo(
      name: 'Live Combat Sports',
      url: 'https://www.livecombatsports.com',
      colorValue: 0xFFFF1744, // red accent
      iconData: 0xf046b, // Icons.sports_mma
    ),
    'Eventbrite': StreamingPlatformInfo(
      name: 'Eventbrite',
      url: 'https://www.eventbrite.com.au',
      colorValue: 0xFFFF9800, // orange
      iconData: 0xe16a, // Icons.confirmation_number
    ),
    // ── Additional Promotions / Platforms ──
    'Bellator': StreamingPlatformInfo(
      name: 'Bellator',
      url: 'https://www.bellator.com',
      colorValue: 0xFF1A237E, // indigo 900
      iconData: 0xf046b, // Icons.sports_mma
    ),
    'Fox Nation': StreamingPlatformInfo(
      name: 'Fox Nation',
      url: 'https://nation.foxnews.com',
      colorValue: 0xFF003580, // navy
      iconData: 0xe40d, // Icons.live_tv
    ),
    'fuboTV': StreamingPlatformInfo(
      name: 'fuboTV',
      url: 'https://www.fubo.tv',
      colorValue: 0xFFE91E63, // pink
      iconData: 0xe40d, // Icons.live_tv
    ),
    'YouTube': StreamingPlatformInfo(
      name: 'YouTube',
      url: 'https://www.youtube.com',
      colorValue: 0xFFFF0000, // red
      iconData: 0xe40d, // Icons.live_tv
    ),
    'BKB': StreamingPlatformInfo(
      name: 'BKB',
      url: 'https://www.bkb.events',
      colorValue: 0xFF304FFE, // indigo accent
      iconData: 0xf046b, // Icons.sports_mma
    ),
    'HYPE Fighting': StreamingPlatformInfo(
      name: 'HYPE Fighting',
      url: 'https://www.trillertv.com',
      colorValue: 0xFFFF6D00, // deep orange accent
      iconData: 0xf046b, // Icons.sports_mma
    ),
    'No Limit Boxing': StreamingPlatformInfo(
      name: 'No Limit Boxing',
      url: 'https://www.nolimitboxing.com.au',
      colorValue: 0xFFD50000, // red accent
      iconData: 0xf046a, // Icons.sports_kabaddi
    ),

    // ── South Asia — India ──
    'Sony LIV': StreamingPlatformInfo(
      name: 'Sony LIV',
      url: 'https://www.sonyliv.com',
      colorValue: 0xFF1565C0, // blue 800
      iconData: 0xe40d, // Icons.live_tv
    ),
    'JioCinema': StreamingPlatformInfo(
      name: 'JioCinema',
      url: 'https://www.jiocinema.com',
      colorValue: 0xFF0D47A1, // blue 900
      iconData: 0xe40d, // Icons.live_tv
    ),
    'Star Sports': StreamingPlatformInfo(
      name: 'Star Sports',
      url: 'https://www.hotstar.com/in/sports',
      colorValue: 0xFFFFD600, // yellow accent 700
      iconData: 0xe532, // Icons.sports
    ),
    'Hotstar': StreamingPlatformInfo(
      name: 'Hotstar',
      url: 'https://www.hotstar.com',
      colorValue: 0xFF1A237E, // indigo 900
      iconData: 0xe40d, // Icons.live_tv
    ),
    'FanCode': StreamingPlatformInfo(
      name: 'FanCode',
      url: 'https://www.fancode.com',
      colorValue: 0xFF6200EA, // deep purple accent 700
      iconData: 0xe532, // Icons.sports
    ),
    'Zee5': StreamingPlatformInfo(
      name: 'Zee5',
      url: 'https://www.zee5.com',
      colorValue: 0xFF7C4DFF, // deep purple accent 200
      iconData: 0xe40d, // Icons.live_tv
    ),

    // ── South Asia — Pakistan ──
    'PTV Sports': StreamingPlatformInfo(
      name: 'PTV Sports',
      url: 'https://ptvsports.tv',
      colorValue: 0xFF00C853, // green accent 700
      iconData: 0xe532, // Icons.sports
    ),
    'Ten Sports PK': StreamingPlatformInfo(
      name: 'Ten Sports PK',
      url: 'https://www.tensports.com',
      colorValue: 0xFFFF6D00, // deep orange accent
      iconData: 0xe532, // Icons.sports
    ),
    'ARY Digital': StreamingPlatformInfo(
      name: 'ARY Digital',
      url: 'https://arydigital.tv',
      colorValue: 0xFF2962FF, // blue accent 700
      iconData: 0xe40d, // Icons.live_tv
    ),
    'Geo Super': StreamingPlatformInfo(
      name: 'Geo Super',
      url: 'https://www.geo.tv/geo-super',
      colorValue: 0xFF00E676, // green accent
      iconData: 0xe532, // Icons.sports
    ),
    'Tapmad': StreamingPlatformInfo(
      name: 'Tapmad',
      url: 'https://www.tapmad.com',
      colorValue: 0xFFFF1744, // red accent
      iconData: 0xe40d, // Icons.live_tv
    ),

    // ── Middle East / MENA ──
    'MBC Action': StreamingPlatformInfo(
      name: 'MBC Action',
      url: 'https://www.mbc.net/en/mbc-action',
      colorValue: 0xFFFF6F00, // amber 800
      iconData: 0xe40d, // Icons.live_tv
    ),
    'Abu Dhabi Sports': StreamingPlatformInfo(
      name: 'Abu Dhabi Sports',
      url: 'https://www.admediatv.ae',
      colorValue: 0xFF00695C, // teal 800
      iconData: 0xe532, // Icons.sports
    ),
    'beIN Sports': StreamingPlatformInfo(
      name: 'beIN Sports',
      url: 'https://www.bein.com',
      colorValue: 0xFF827717, // lime 900
      iconData: 0xe532, // Icons.sports
    ),
    'Shahid': StreamingPlatformInfo(
      name: 'Shahid',
      url: 'https://shahid.mbc.net',
      colorValue: 0xFF6A1B9A, // purple 800
      iconData: 0xe40d, // Icons.live_tv
    ),
    'StarzPlay': StreamingPlatformInfo(
      name: 'StarzPlay',
      url: 'https://www.starzplay.com',
      colorValue: 0xFF4A148C, // purple 900
      iconData: 0xe40d, // Icons.live_tv
    ),

    // ── Southeast Asia ──
    'iQIYI': StreamingPlatformInfo(
      name: 'iQIYI',
      url: 'https://www.iq.com',
      colorValue: 0xFF00E676, // green accent
      iconData: 0xe40d, // Icons.live_tv
    ),
    'TrueVisions': StreamingPlatformInfo(
      name: 'TrueVisions',
      url: 'https://www.truevisions.co.th',
      colorValue: 0xFFD50000, // red accent
      iconData: 0xe40d, // Icons.live_tv
    ),
    'Vidio': StreamingPlatformInfo(
      name: 'Vidio',
      url: 'https://www.vidio.com',
      colorValue: 0xFF2196F3, // blue
      iconData: 0xe40d, // Icons.live_tv
    ),
    'Tap Go': StreamingPlatformInfo(
      name: 'Tap Go',
      url: 'https://www.tapgo.ph',
      colorValue: 0xFFFF9100, // orange accent 700
      iconData: 0xe40d, // Icons.live_tv
    ),

    // ── Japan / Korea ──
    'ABEMA': StreamingPlatformInfo(
      name: 'ABEMA',
      url: 'https://abema.tv',
      colorValue: 0xFF00C853, // green accent 700
      iconData: 0xe40d, // Icons.live_tv
    ),
    'U-NEXT': StreamingPlatformInfo(
      name: 'U-NEXT',
      url: 'https://video.unext.jp',
      colorValue: 0xFF1A237E, // indigo 900
      iconData: 0xe40d, // Icons.live_tv
    ),
    'TVING': StreamingPlatformInfo(
      name: 'TVING',
      url: 'https://www.tving.com',
      colorValue: 0xFFB71C1C, // red 900
      iconData: 0xe40d, // Icons.live_tv
    ),

    // ── Africa ──
    'SuperSport': StreamingPlatformInfo(
      name: 'SuperSport',
      url: 'https://supersport.com',
      colorValue: 0xFF2E7D32, // green 800
      iconData: 0xe532, // Icons.sports
    ),
    'Showmax': StreamingPlatformInfo(
      name: 'Showmax',
      url: 'https://www.showmax.com',
      colorValue: 0xFFD32F2F, // red 700
      iconData: 0xe40d, // Icons.live_tv
    ),
    'StarTimes': StreamingPlatformInfo(
      name: 'StarTimes',
      url: 'https://www.startimes.com',
      colorValue: 0xFFFF6F00, // amber 800
      iconData: 0xe40d, // Icons.live_tv
    ),

    // ── Latin America ──
    'ESPN Deportes': StreamingPlatformInfo(
      name: 'ESPN Deportes',
      url: 'https://espndeportes.espn.com',
      colorValue: 0xFFC62828, // red 800
      iconData: 0xe532, // Icons.sports
    ),
    'Star+': StreamingPlatformInfo(
      name: 'Star+',
      url: 'https://www.starplus.com',
      colorValue: 0xFF283593, // indigo 800
      iconData: 0xe40d, // Icons.live_tv
    ),
    'Combate Global': StreamingPlatformInfo(
      name: 'Combate Global',
      url: 'https://www.combateglobal.com',
      colorValue: 0xFFFF3D00, // deep orange accent
      iconData: 0xf046b, // Icons.sports_mma
    ),
    'TV Azteca': StreamingPlatformInfo(
      name: 'TV Azteca',
      url: 'https://www.tvazteca.com/aztecadeportes',
      colorValue: 0xFF1B5E20, // green 900
      iconData: 0xe40d, // Icons.live_tv
    ),
    'Globo': StreamingPlatformInfo(
      name: 'Globo',
      url: 'https://globoplay.globo.com',
      colorValue: 0xFFE65100, // orange 900
      iconData: 0xe40d, // Icons.live_tv
    ),

    // ── Russia / CIS ──
    'Match TV': StreamingPlatformInfo(
      name: 'Match TV',
      url: 'https://matchtv.ru',
      colorValue: 0xFF0277BD, // light blue 800
      iconData: 0xe40d, // Icons.live_tv
    ),

    // ── China ──
    'Migu Sports': StreamingPlatformInfo(
      name: 'Migu Sports',
      url: 'https://www.miguvideo.com',
      colorValue: 0xFFEF6C00, // orange 800
      iconData: 0xe532, // Icons.sports
    ),

    // ── Europe (additional) ──
    'VIAPLAY': StreamingPlatformInfo(
      name: 'VIAPLAY',
      url: 'https://viaplay.com',
      colorValue: 0xFF6A1B9A, // purple 800
      iconData: 0xe40d, // Icons.live_tv
    ),
    'Canal+': StreamingPlatformInfo(
      name: 'Canal+',
      url: 'https://www.canalplus.com',
      colorValue: 0xFF212121, // grey 900
      iconData: 0xe40d, // Icons.live_tv
    ),
    'RTL': StreamingPlatformInfo(
      name: 'RTL',
      url: 'https://www.rtl.de',
      colorValue: 0xFFE91E63, // pink
      iconData: 0xe40d, // Icons.live_tv
    ),
    'Sky Sports': StreamingPlatformInfo(
      name: 'Sky Sports',
      url: 'https://www.skysports.com',
      colorValue: 0xFF01579B, // light blue 900
      iconData: 0xe532, // Icons.sports
    ),
  };

  /// Look up platform info by name (case-insensitive match).
  static StreamingPlatformInfo? get(String name) {
    return registry[name] ??
        registry.entries
            .cast<MapEntry<String, StreamingPlatformInfo>?>()
            .firstWhere(
              (e) => e!.key.toLowerCase() == name.toLowerCase(),
              orElse: () => null,
            )
            ?.value;
  }

  /// Get the Material [Color] for a platform.
  static Color colorFor(String name) {
    return Color(get(name)?.colorValue ?? 0xFF9E9E9E);
  }

  /// Get the Material [IconData] for a platform.
  static IconData iconFor(String name) {
    final platform = get(name);
    if (platform == null) {
      return Icons.open_in_new;
    }
    return iconForCodePoint(platform.iconData);
  }

  /// Maps stored code points back to constant Material icons so web builds can
  /// still tree-shake icon fonts.
  static IconData iconForCodePoint(int iconData) {
    switch (iconData) {
      case 0xf046b:
        return Icons.sports_mma;
      case 0xf046a:
        return Icons.sports_kabaddi;
      case 0xe532:
        return Icons.sports;
      case 0xe40d:
        return Icons.live_tv;
      case 0xe63e:
        return Icons.theaters;
      case 0xe333:
        return Icons.tv;
      case 0xe16a:
        return Icons.confirmation_number;
      default:
        return Icons.open_in_new;
    }
  }

  /// Get the URL for a platform.
  static String urlFor(String name) {
    return get(name)?.url ?? '';
  }

  /// All platform names in display order.
  static List<String> get allNames => registry.keys.toList();

  /// Australian streaming platforms.
  static const List<String> auPlatforms = [
    'DFC',
    'Kayo',
    'Main Event',
    'Thrillx',
    'Paramount+',
  ];

  /// US streaming platforms.
  static const List<String> usPlatforms = [
    'DFC',
    'ESPN+',
    'DAZN',
    'UFC Fight Pass',
    'Prime Video',
  ];

  /// India streaming platforms.
  static const List<String> inPlatforms = [
    'DFC',
    'Sony LIV',
    'JioCinema',
    'Star Sports',
    'Hotstar',
    'FanCode',
    'Zee5',
  ];

  /// Pakistan streaming platforms.
  static const List<String> pkPlatforms = [
    'DFC',
    'PTV Sports',
    'Ten Sports PK',
    'ARY Digital',
    'Geo Super',
    'Tapmad',
  ];

  /// Middle East / MENA streaming platforms.
  static const List<String> menaPlatforms = [
    'DFC',
    'MBC Action',
    'Abu Dhabi Sports',
    'beIN Sports',
    'Shahid',
    'StarzPlay',
    'DAZN',
  ];

  /// UK / Europe streaming platforms.
  static const List<String> euPlatforms = [
    'DFC',
    'TNT Sports',
    'Sky Sports',
    'DAZN',
    'VIAPLAY',
    'Canal+',
    'RTL',
    'Prime Video',
  ];

  /// Southeast Asia streaming platforms.
  static const List<String> seaPlatforms = [
    'DFC',
    'ONE App',
    'iQIYI',
    'TrueVisions',
    'Vidio',
    'Tap Go',
  ];

  /// Japan streaming platforms.
  static const List<String> jpPlatforms = ['DFC', 'ABEMA', 'U-NEXT', 'DAZN'];

  /// Africa streaming platforms.
  static const List<String> afPlatforms = [
    'DFC',
    'SuperSport',
    'Showmax',
    'StarTimes',
  ];

  /// Latin America streaming platforms.
  static const List<String> latamPlatforms = [
    'DFC',
    'ESPN Deportes',
    'Star+',
    'Combate Global',
    'TV Azteca',
    'Globo',
    'DAZN',
  ];

  /// Look up region-specific platforms by ISO country code.
  static List<String> platformsForRegion(String regionCode) {
    switch (regionCode.toUpperCase()) {
      case 'AU':
      case 'NZ':
        return auPlatforms;
      case 'US':
      case 'CA':
        return usPlatforms;
      case 'IN':
        return inPlatforms;
      case 'PK':
        return pkPlatforms;
      case 'AE':
      case 'SA':
      case 'QA':
      case 'KW':
      case 'BH':
      case 'OM':
      case 'EG':
        return menaPlatforms;
      case 'GB':
      case 'DE':
      case 'FR':
      case 'ES':
      case 'IT':
      case 'SE':
      case 'NO':
      case 'DK':
      case 'NL':
        return euPlatforms;
      case 'TH':
      case 'PH':
      case 'SG':
      case 'MY':
      case 'ID':
      case 'VN':
        return seaPlatforms;
      case 'JP':
      case 'KR':
        return jpPlatforms;
      case 'ZA':
      case 'KE':
      case 'NG':
      case 'GH':
      case 'TZ':
        return afPlatforms;
      case 'BR':
      case 'MX':
      case 'AR':
      case 'CO':
      case 'CL':
      case 'PE':
        return latamPlatforms;
      default:
        return usPlatforms; // fallback to global/US
    }
  }
}

/// Immutable info for a single streaming platform.
class StreamingPlatformInfo {
  final String name;
  final String url;
  final int colorValue;
  final int iconData;

  const StreamingPlatformInfo({
    required this.name,
    required this.url,
    required this.colorValue,
    required this.iconData,
  });

  /// Constant-safe icon accessor — callers should prefer
  /// [StreamingPlatforms.iconFor] or [StreamingPlatforms.iconForCodePoint].
  IconData get icon => StreamingPlatforms.iconForCodePoint(iconData);
}
