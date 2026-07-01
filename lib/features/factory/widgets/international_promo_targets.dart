import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/services/war_room_engine.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// INTERNATIONAL PROMO TARGETS — Global Fight Promotion Command
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Region selection, sport targeting, platform distribution, and live bot
/// activity feed. Fire campaign blasts to any region on earth.
///
/// Real regions. Real platforms. Real bots. Real international promotion.
/// ═══════════════════════════════════════════════════════════════════════════
class InternationalPromoTargets extends StatelessWidget {
  final Set<String> selectedRegions;
  final Set<String> selectedSports;
  final Set<String> selectedPlatforms;
  final List<BotActivityEvent> botActivity;
  final List<WarRoomCampaignBlast> blasts;
  final ValueChanged<String> onRegionToggle;
  final ValueChanged<String> onSportToggle;
  final ValueChanged<String> onPlatformToggle;
  final VoidCallback onFireBlast;

  const InternationalPromoTargets({
    super.key,
    required this.selectedRegions,
    required this.selectedSports,
    required this.selectedPlatforms,
    required this.botActivity,
    required this.blasts,
    required this.onRegionToggle,
    required this.onSportToggle,
    required this.onPlatformToggle,
    required this.onFireBlast,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'TARGET REGIONS',
            Icons.public,
            AppTheme.neonCyan,
          ),
          const SizedBox(height: 12),
          _buildRegionGrid(),
          const SizedBox(height: 24),
          _buildSectionHeader(
            'COMBAT SPORTS',
            Icons.sports_mma,
            AppTheme.neonMagenta,
          ),
          const SizedBox(height: 12),
          _buildSportGrid(),
          const SizedBox(height: 24),
          _buildSectionHeader(
            'DISTRIBUTION PLATFORMS',
            Icons.share,
            AppTheme.neonOrange,
          ),
          const SizedBox(height: 12),
          _buildPlatformGrid(),
          const SizedBox(height: 24),
          _buildFireBlastButton(),
          const SizedBox(height: 24),
          _buildSectionHeader(
            'LIVE BOT ACTIVITY',
            Icons.smart_toy,
            AppTheme.neonGreen,
          ),
          const SizedBox(height: 12),
          _buildBotActivityFeed(),
          const SizedBox(height: 24),
          _buildSectionHeader(
            'CAMPAIGN BLASTS',
            Icons.campaign,
            AppTheme.neonMagenta,
          ),
          const SizedBox(height: 12),
          _buildBlastHistory(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String label, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // REGION GRID — International targeting
  // ═════════════════════════════════════════════════════════════════════════
  Widget _buildRegionGrid() {
    const regions = [
      _RegionInfo('Global', '🌍', 'Worldwide'),
      _RegionInfo('AU', '🇦🇺', 'Australia'),
      _RegionInfo('NZ', '🇳🇿', 'New Zealand'),
      _RegionInfo('US', '🇺🇸', 'United States'),
      _RegionInfo('UK', '🇬🇧', 'United Kingdom'),
      _RegionInfo('Asia', '🌏', 'Asia Pacific'),
      _RegionInfo('Europe', '🇪🇺', 'Europe'),
      _RegionInfo('Middle East', '🌍', 'Middle East'),
      _RegionInfo('Africa', '🌍', 'Africa'),
      _RegionInfo('South America', '🌎', 'South America'),
      _RegionInfo('Canada', '🇨🇦', 'Canada'),
      _RegionInfo('Japan', '🇯🇵', 'Japan'),
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: regions.map((r) {
        final selected = selectedRegions.contains(r.code);
        return GestureDetector(
          onTap: () => onRegionToggle(r.code),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 130,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: selected
                  ? AppTheme.neonCyan.withValues(alpha: 0.1)
                  : const Color(0xFF0D1B2A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected
                    ? AppTheme.neonCyan
                    : AppTheme.neonCyan.withValues(alpha: 0.15),
                width: selected ? 2 : 1,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: AppTheme.neonCyan.withValues(alpha: 0.15),
                        blurRadius: 8,
                      ),
                    ]
                  : null,
            ),
            child: Column(
              children: [
                Text(r.flag, style: const TextStyle(fontSize: 24)),
                const SizedBox(height: 6),
                Text(
                  r.code,
                  style: TextStyle(
                    color: selected ? AppTheme.neonCyan : Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  r.name,
                  style: TextStyle(
                    color: selected
                        ? AppTheme.neonCyan.withValues(alpha: 0.6)
                        : Colors.white38,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // SPORT GRID — Combat sport targeting
  // ═════════════════════════════════════════════════════════════════════════
  Widget _buildSportGrid() {
    const sports = [
      _SportInfo('MMA', '🥊', Colors.red),
      _SportInfo('Boxing', '🥋', Colors.blue),
      _SportInfo('BKFC', '👊', Colors.orange),
      _SportInfo('Brawling', '💪', Colors.amber),
      _SportInfo('Muay Thai', '🦵', Colors.deepOrange),
      _SportInfo('Kickboxing', '🦶', Colors.purple),
      _SportInfo('BJJ', '🤼', Colors.teal),
      _SportInfo('Wrestling', '🏋️', Colors.indigo),
      _SportInfo('Judo', '🥋', Colors.green),
      _SportInfo('Karate', '✋', Colors.cyan),
      _SportInfo('Taekwondo', '🦶', Colors.pink),
      _SportInfo('Sambo', '🤝', Colors.brown),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: sports.map((s) {
        final selected = selectedSports.contains(s.name);
        return GestureDetector(
          onTap: () => onSportToggle(s.name),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: selected
                  ? AppTheme.neonMagenta.withValues(alpha: 0.12)
                  : const Color(0xFF0D1B2A),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected
                    ? AppTheme.neonMagenta
                    : AppTheme.neonMagenta.withValues(alpha: 0.15),
                width: selected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(s.emoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(
                  s.name,
                  style: TextStyle(
                    color: selected ? AppTheme.neonMagenta : Colors.white60,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (selected) ...[
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.check_circle,
                    color: AppTheme.neonMagenta,
                    size: 14,
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // PLATFORM GRID — Distribution channel targeting
  // ═════════════════════════════════════════════════════════════════════════
  Widget _buildPlatformGrid() {
    const platforms = [
      _PlatformInfo('DFC App', Icons.phone_android, '0xFF00F5FF'),
      _PlatformInfo('DFC Web', Icons.language, '0xFF00F5FF'),
      _PlatformInfo('Instagram', Icons.camera_alt, '0xFFE1306C'),
      _PlatformInfo('TikTok', Icons.music_note, '0xFF000000'),
      _PlatformInfo('YouTube', Icons.play_circle, '0xFFFF0000'),
      _PlatformInfo('Facebook', Icons.facebook, '0xFF1877F2'),
      _PlatformInfo('Twitter', Icons.alternate_email, '0xFF1DA1F2'),
      _PlatformInfo('Threads', Icons.forum, '0xFF000000'),
      _PlatformInfo('Snapchat', Icons.photo_camera_front, '0xFFFFFC00'),
      _PlatformInfo('LinkedIn', Icons.work, '0xFF0A66C2'),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: platforms.map((p) {
        final selected = selectedPlatforms.contains(p.name);
        final color = Color(int.parse(p.colorHex));

        return GestureDetector(
          onTap: () => onPlatformToggle(p.name),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: selected
                  ? color.withValues(alpha: 0.12)
                  : const Color(0xFF0D1B2A),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected
                    ? color == Colors.black
                          ? AppTheme.neonCyan
                          : color
                    : Colors.white.withValues(alpha: 0.1),
                width: selected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  p.icon,
                  size: 16,
                  color: selected
                      ? (color == Colors.black ? AppTheme.neonCyan : color)
                      : Colors.white38,
                ),
                const SizedBox(width: 6),
                Text(
                  p.name,
                  style: TextStyle(
                    color: selected ? Colors.white : Colors.white54,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // FIRE BLAST BUTTON
  // ═════════════════════════════════════════════════════════════════════════
  Widget _buildFireBlastButton() {
    final canFire = selectedRegions.isNotEmpty && selectedSports.isNotEmpty;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: canFire ? onFireBlast : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: canFire
              ? AppTheme.neonMagenta
              : const Color(0xFF1A2744),
          foregroundColor: canFire ? Colors.white : Colors.grey,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: canFire ? 6 : 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(canFire ? Icons.campaign : Icons.block, size: 24),
            const SizedBox(width: 12),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'FIRE CAMPAIGN BLAST',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                if (canFire)
                  Text(
                    '→ ${selectedRegions.join(", ")} • ${selectedSports.join(", ")}',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            if (canFire) const Text('🚀', style: TextStyle(fontSize: 20)),
          ],
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // LIVE BOT ACTIVITY FEED
  // ═════════════════════════════════════════════════════════════════════════
  Widget _buildBotActivityFeed() {
    if (botActivity.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF0D1B2A),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.smart_toy,
                color: Colors.white.withValues(alpha: 0.1),
                size: 40,
              ),
              const SizedBox(height: 8),
              Text(
                'Bots are idle — start the engine to see activity',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(maxHeight: 300),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: botActivity.length,
        itemBuilder: (_, i) {
          final event = botActivity[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1B2A),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppTheme.neonGreen.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              children: [
                // Bot emoji
                Text(event.emoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            event.botName,
                            style: const TextStyle(
                              color: AppTheme.neonGreen,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            event.action,
                            style: TextStyle(
                              color: AppTheme.neonCyan.withValues(alpha: 0.7),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        event.detail,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Hype score
                if (event.hypeScore > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _hypeColor(event.hypeScore).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${(event.hypeScore * 100).toInt()}',
                      style: TextStyle(
                        color: _hypeColor(event.hypeScore),
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _hypeColor(double score) {
    if (score >= 0.9) return AppTheme.neonGreen;
    if (score >= 0.7) return AppTheme.neonCyan;
    if (score >= 0.5) return AppTheme.neonOrange;
    return Colors.grey;
  }

  // ═════════════════════════════════════════════════════════════════════════
  // BLAST HISTORY
  // ═════════════════════════════════════════════════════════════════════════
  Widget _buildBlastHistory() {
    if (blasts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF0D1B2A),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            'No blasts fired yet — select targets and fire',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 12,
            ),
          ),
        ),
      );
    }

    return Column(
      children: blasts.map((blast) {
        final statusColor = blast.status == WarRoomBlastStatus.complete
            ? AppTheme.neonGreen
            : blast.status == WarRoomBlastStatus.delivered
            ? AppTheme.neonCyan
            : AppTheme.neonMagenta;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF0D1B2A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: statusColor.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.campaign, color: statusColor, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      blast.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      blast.status.name.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _blastStat('REGION', blast.targetRegion, AppTheme.neonCyan),
                  const SizedBox(width: 16),
                  _blastStat(
                    'SPORTS',
                    blast.sportTypes.join(', '),
                    AppTheme.neonMagenta,
                  ),
                  const SizedBox(width: 16),
                  _blastStat(
                    'FIRED',
                    '${blast.contentPiecesFired}',
                    AppTheme.neonOrange,
                  ),
                  const SizedBox(width: 16),
                  _blastStat(
                    'REACH',
                    _formatNumber(blast.estimatedReach),
                    AppTheme.neonGreen,
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _blastStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: color.withValues(alpha: 0.5),
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}

// ─── Models ──────────────────────────────────────────────────────────────
class _RegionInfo {
  final String code;
  final String flag;
  final String name;
  const _RegionInfo(this.code, this.flag, this.name);
}

class _SportInfo {
  final String name;
  final String emoji;
  final Color color;
  const _SportInfo(this.name, this.emoji, this.color);
}

class _PlatformInfo {
  final String name;
  final IconData icon;
  final String colorHex;
  const _PlatformInfo(this.name, this.icon, this.colorHex);
}
