import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/streaming_platforms.dart';
import '../../core/theme/app_theme.dart';

/// Detects the user's region from device locale.
String _detectUserRegion() {
  final locale = ui.PlatformDispatcher.instance.locale;
  final code = locale.countryCode?.toUpperCase();
  if (code != null && code.isNotEmpty) return code;
  // Fallback: infer from language
  switch (locale.languageCode) {
    case 'ur':
      return 'PK';
    case 'hi':
      return 'IN';
    case 'th':
      return 'TH';
    case 'ja':
      return 'JP';
    case 'ko':
      return 'KR';
    case 'ar':
      return 'AE';
    case 'pt':
      return 'BR';
    case 'es':
      return 'MX';
    case 'id':
      return 'ID';
    case 'zh':
      return 'CN';
    default:
      return 'US';
  }
}

/// Region-aware "Where to Watch" panel.
///
/// Shows streaming platforms relevant to the VIEWER's region,
/// not the event location. A user in Pakistan watching a Sydney
/// event sees PTV Sports, Tapmad, etc.
///
/// [eventPlatforms] — platforms the event is broadcast on (from Firestore).
/// If empty, falls back to the user's regional defaults.
/// [eventCountry] — ISO code of the country where the event takes place.
/// [overrideRegion] — force a specific viewer region (for testing / manual).
class RegionalWhereToWatch extends StatelessWidget {
  final List<String> eventPlatforms;
  final String? eventCountry;
  final String? overrideRegion;
  final bool compact;

  const RegionalWhereToWatch({
    super.key,
    this.eventPlatforms = const [],
    this.eventCountry,
    this.overrideRegion,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final viewerRegion = overrideRegion ?? _detectUserRegion();
    final regionalPlatforms =
        StreamingPlatforms.platformsForRegion(viewerRegion);

    // Merge: event-specific platforms + viewer's regional platforms (deduped)
    final Set<String> merged = {};

    // First add any event-specific platforms that match the viewer's region
    for (final p in eventPlatforms) {
      merged.add(p);
    }

    // Then add regional defaults (viewer always sees their local options)
    for (final p in regionalPlatforms) {
      merged.add(p);
    }

    final platforms = merged.toList();

    if (compact) {
      return _buildCompact(context, platforms, viewerRegion);
    }
    return _buildFull(context, platforms, viewerRegion);
  }

  Widget _buildFull(
    BuildContext context,
    List<String> platforms,
    String viewerRegion,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.deepPurple.shade900.withValues(alpha: 0.4),
            Colors.blue.shade900.withValues(alpha: 0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.cyanAccent.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.live_tv, color: Colors.cyanAccent, size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'WHERE TO WATCH',
                  style: TextStyle(
                    color: Colors.cyanAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              // Region badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _regionLabel(viewerRegion),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            eventCountry != null
                ? 'Showing platforms available in your region'
                : 'Available streaming platforms',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 14),

          // Platform list
          ...platforms.map((name) => _PlatformRow(platformName: name)),
        ],
      ),
    );
  }

  Widget _buildCompact(
    BuildContext context,
    List<String> platforms,
    String viewerRegion,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children:
          platforms.take(6).map((name) {
            final info = StreamingPlatforms.get(name);
            final color =
                info != null ? Color(info.colorValue) : Colors.grey.shade600;
            return ActionChip(
              avatar: Icon(
                StreamingPlatforms.iconFor(name),
                size: 16,
                color: color,
              ),
              label: Text(
                name,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
              backgroundColor: color.withValues(alpha: 0.15),
              side: BorderSide(color: color.withValues(alpha: 0.3)),
              onPressed: () {
                final url = StreamingPlatforms.urlFor(name);
                if (url.isNotEmpty) {
                  launchUrl(
                    Uri.parse(url),
                    mode: LaunchMode.externalApplication,
                  );
                }
              },
            );
          }).toList(),
    );
  }

  static String _regionLabel(String code) {
    const labels = {
      'AU': '🇦🇺 Australia',
      'US': '🇺🇸 USA',
      'GB': '🇬🇧 UK',
      'IN': '🇮🇳 India',
      'PK': '🇵🇰 Pakistan',
      'AE': '🇦🇪 UAE',
      'SA': '🇸🇦 Saudi Arabia',
      'TH': '🇹🇭 Thailand',
      'JP': '🇯🇵 Japan',
      'KR': '🇰🇷 Korea',
      'ZA': '🇿🇦 South Africa',
      'KE': '🇰🇪 Kenya',
      'NG': '🇳🇬 Nigeria',
      'MX': '🇲🇽 Mexico',
      'BR': '🇧🇷 Brazil',
      'DE': '🇩🇪 Germany',
      'FR': '🇫🇷 France',
      'NZ': '🇳🇿 New Zealand',
      'PH': '🇵🇭 Philippines',
      'SG': '🇸🇬 Singapore',
      'ID': '🇮🇩 Indonesia',
      'CA': '🇨🇦 Canada',
      'EG': '🇪🇬 Egypt',
      'QA': '🇶🇦 Qatar',
      'CN': '🇨🇳 China',
      'AR': '🇦🇷 Argentina',
      'CO': '🇨🇴 Colombia',
    };
    return labels[code] ?? '🌏 $code';
  }
}

/// Single row for a streaming platform with icon, name, URL, and tap action.
class _PlatformRow extends StatelessWidget {
  final String platformName;

  const _PlatformRow({required this.platformName});

  @override
  Widget build(BuildContext context) {
    final info = StreamingPlatforms.get(platformName);
    final color =
        info != null ? Color(info.colorValue) : Colors.grey.shade400;
    final icon = StreamingPlatforms.iconFor(platformName);
    final url = StreamingPlatforms.urlFor(platformName);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap:
            url.isNotEmpty
                ? () => launchUrl(
                  Uri.parse(url),
                  mode: LaunchMode.externalApplication,
                )
                : null,
        borderRadius: BorderRadius.circular(8),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    platformName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  if (url.isNotEmpty)
                    Text(
                      Uri.parse(url).host,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
            if (url.isNotEmpty)
              Icon(
                Icons.open_in_new,
                size: 14,
                color: Colors.white.withValues(alpha: 0.4),
              ),
          ],
        ),
      ),
    );
  }
}

/// Dropdown that lets users manually switch their viewing region.
/// Use this alongside [RegionalWhereToWatch] to let users override
/// auto-detected region.
class RegionSelector extends StatelessWidget {
  final String selectedRegion;
  final ValueChanged<String> onChanged;

  const RegionSelector({
    super.key,
    required this.selectedRegion,
    required this.onChanged,
  });

  static const _regions = [
    ('AU', '🇦🇺 Australia'),
    ('US', '🇺🇸 USA'),
    ('GB', '🇬🇧 UK'),
    ('IN', '🇮🇳 India'),
    ('PK', '🇵🇰 Pakistan'),
    ('AE', '🇦🇪 UAE'),
    ('SA', '🇸🇦 Saudi Arabia'),
    ('TH', '🇹🇭 Thailand'),
    ('JP', '🇯🇵 Japan'),
    ('KR', '🇰🇷 Korea'),
    ('ZA', '🇿🇦 South Africa'),
    ('KE', '🇰🇪 Kenya'),
    ('NG', '🇳🇬 Nigeria'),
    ('MX', '🇲🇽 Mexico'),
    ('BR', '🇧🇷 Brazil'),
    ('DE', '🇩🇪 Germany'),
    ('FR', '🇫🇷 France'),
    ('NZ', '🇳🇿 New Zealand'),
    ('PH', '🇵🇭 Philippines'),
    ('SG', '🇸🇬 Singapore'),
    ('ID', '🇮🇩 Indonesia'),
    ('CA', '🇨🇦 Canada'),
    ('EG', '🇪🇬 Egypt'),
    ('QA', '🇶🇦 Qatar'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.cyanAccent.withValues(alpha: 0.2),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedRegion,
          dropdownColor: AppTheme.surfaceColor,
          isExpanded: true,
          icon: const Icon(
            Icons.public,
            color: Colors.cyanAccent,
            size: 18,
          ),
          items:
              _regions.map((r) {
                return DropdownMenuItem(
                  value: r.$1,
                  child: Text(
                    r.$2,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                );
              }).toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}
