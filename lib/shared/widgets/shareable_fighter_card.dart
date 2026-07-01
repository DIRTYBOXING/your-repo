// ═══════════════════════════════════════════════════════════════════════════
// DFC SHAREABLE FIGHTER CARD
// ═══════════════════════════════════════════════════════════════════════════
// Auto-generated social graphics with fighter stats — viral loop mechanism
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../../core/constants/image_assets.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../services/share_service.dart';

/// Fighter data for card generation
class FighterCardData {
  final String id;
  final String name;
  final String? nickname;
  final String? photoUrl;
  final int wins;
  final int losses;
  final int draws;
  final int knockouts;
  final int submissions;
  final String? weightClass;
  final String? lastFightResult;
  final String? lastOpponent;
  final String? gym;
  final String? country;
  final String? flagEmoji;
  final bool isVerified;
  final int? ranking;

  const FighterCardData({
    required this.id,
    required this.name,
    this.nickname,
    this.photoUrl,
    this.wins = 0,
    this.losses = 0,
    this.draws = 0,
    this.knockouts = 0,
    this.submissions = 0,
    this.weightClass,
    this.lastFightResult,
    this.lastOpponent,
    this.gym,
    this.country,
    this.flagEmoji,
    this.isVerified = false,
    this.ranking,
  });

  String get record => '$wins-$losses${draws > 0 ? '-$draws' : ''}';
  double get winRate =>
      (wins + losses + draws) > 0 ? wins / (wins + losses + draws) : 0;
  int get finishRate =>
      wins > 0 ? (((knockouts + submissions) / wins) * 100).round() : 0;
}

/// Card style variants
enum FighterCardStyle {
  standard, // Clean white card
  dark, // Dark/neon style
  legacy, // Vintage combat look
  stats, // Stats-focused
  minimal, // Instagram story format
}

/// ═══════════════════════════════════════════════════════════════════════════
/// SHAREABLE FIGHTER CARD WIDGET
/// ═══════════════════════════════════════════════════════════════════════════
class ShareableFighterCard extends StatelessWidget {
  final FighterCardData fighter;
  final FighterCardStyle style;
  final GlobalKey? repaintKey;
  final double width;
  final double height;

  const ShareableFighterCard({
    super.key,
    required this.fighter,
    this.style = FighterCardStyle.dark,
    this.repaintKey,
    this.width = 400,
    this.height = 500,
  });

  @override
  Widget build(BuildContext context) {
    final key = repaintKey ?? GlobalKey();

    return RepaintBoundary(
      key: key,
      child: Container(
        width: width,
        height: height,
        decoration: _getCardDecoration(),
        child: Stack(
          children: [
            // Background pattern
            _buildBackground(),
            // Content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const Spacer(),
                  _buildFighterInfo(),
                  const SizedBox(height: 16),
                  _buildRecord(),
                  const SizedBox(height: 16),
                  _buildStats(),
                  if (fighter.lastFightResult != null) ...[
                    const SizedBox(height: 16),
                    _buildLastFight(),
                  ],
                  const Spacer(),
                  _buildFooter(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _getCardDecoration() {
    switch (style) {
      case FighterCardStyle.dark:
        return BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1A2E), Color(0xFF0F0F1A)],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppTheme.neonCyan.withValues(alpha: 0.5),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.neonCyan.withValues(alpha: 0.3),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        );
      case FighterCardStyle.standard:
        return BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
            ),
          ],
        );
      case FighterCardStyle.legacy:
        return BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2D2D2D), Color(0xFF1A1A1A)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFD4AF37), width: 3),
        );
      case FighterCardStyle.stats:
      case FighterCardStyle.minimal:
        return BoxDecoration(
          color: const Color(0xFF121212),
          borderRadius: BorderRadius.circular(20),
        );
    }
  }

  Widget _buildBackground() {
    if (style == FighterCardStyle.dark) {
      return Positioned.fill(
        child: CustomPaint(painter: _GridPatternPainter()),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildHeader() {
    final isDark =
        style == FighterCardStyle.dark ||
        style == FighterCardStyle.legacy ||
        style == FighterCardStyle.stats ||
        style == FighterCardStyle.minimal;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // DFC Logo
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.neonCyan,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  'DFC',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'FIGHTER CARD',
              style: TextStyle(
                color: isDark ? Colors.white60 : Colors.black54,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        // Ranking badge
        if (fighter.ranking != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFD4AF37),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '#${fighter.ranking}',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFighterInfo() {
    final isDark = style != FighterCardStyle.standard;

    return Row(
      children: [
        // Photo
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: isDark ? Colors.white12 : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.neonCyan.withValues(alpha: 0.5),
              width: 2,
            ),
            image: fighter.photoUrl != null
                ? DecorationImage(
                    image: ImageAssets.resolveImage(fighter.photoUrl!),
                    fit: BoxFit.cover,
                    onError: (_, _) {},
                  )
                : null,
          ),
          child: fighter.photoUrl == null
              ? Icon(
                  Icons.person,
                  size: 40,
                  color: isDark ? Colors.white30 : Colors.grey,
                )
              : null,
        ),
        const SizedBox(width: 16),
        // Name & details
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      fighter.name.toUpperCase(),
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (fighter.isVerified) ...[
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.verified,
                      color: AppTheme.neonCyan,
                      size: 18,
                    ),
                  ],
                ],
              ),
              if (fighter.nickname != null)
                Text(
                  '"${fighter.nickname}"',
                  style: TextStyle(
                    color: isDark ? AppTheme.neonCyan : Colors.blue,
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              const SizedBox(height: 4),
              Row(
                children: [
                  if (fighter.flagEmoji != null) ...[
                    Text(
                      fighter.flagEmoji!,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 6),
                  ],
                  if (fighter.weightClass != null)
                    Text(
                      fighter.weightClass!,
                      style: TextStyle(
                        color: isDark ? Colors.white60 : Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecord() {
    final isDark = style != FighterCardStyle.standard;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.neonCyan.withValues(alpha: 0.1)
            : Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? AppTheme.neonCyan.withValues(alpha: 0.3)
              : Colors.blue.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildRecordItem('WINS', '${fighter.wins}', Colors.green),
          _buildRecordDivider(),
          _buildRecordItem('LOSSES', '${fighter.losses}', Colors.red),
          if (fighter.draws > 0) ...[
            _buildRecordDivider(),
            _buildRecordItem('DRAWS', '${fighter.draws}', Colors.grey),
          ],
        ],
      ),
    );
  }

  Widget _buildRecordItem(String label, String value, Color color) {
    final isDark = style != FighterCardStyle.standard;

    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.white60 : Colors.black54,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildRecordDivider() {
    return Container(width: 1, height: 40, color: Colors.white24);
  }

  Widget _buildStats() {
    final isDark = style != FighterCardStyle.standard;

    return Row(
      children: [
        Expanded(
          child: _buildStatBox(
            'KO/TKO',
            '${fighter.knockouts}',
            Icons.bolt,
            Colors.orange,
            isDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatBox(
            'SUBS',
            '${fighter.submissions}',
            Icons.sports_martial_arts,
            Colors.purple,
            isDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatBox(
            'FINISH%',
            '${fighter.finishRate}%',
            Icons.local_fire_department,
            Colors.red,
            isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildStatBox(
    String label,
    String value,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.white60 : Colors.black54,
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLastFight() {
    final isDark = style != FighterCardStyle.standard;
    final isWin =
        fighter.lastFightResult?.toLowerCase().contains('win') ?? false;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (isWin ? Colors.green : Colors.red).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (isWin ? Colors.green : Colors.red).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isWin ? Icons.emoji_events : Icons.sports_mma,
            color: isWin ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LAST FIGHT',
                  style: TextStyle(
                    color: isDark ? Colors.white60 : Colors.black54,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  '${fighter.lastFightResult}${fighter.lastOpponent != null ? ' vs ${fighter.lastOpponent}' : ''}',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    final isDark = style != FighterCardStyle.standard;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Gym
        if (fighter.gym != null)
          Row(
            children: [
              Icon(
                Icons.fitness_center,
                color: isDark ? Colors.white30 : Colors.black26,
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                fighter.gym!,
                style: TextStyle(
                  color: isDark ? Colors.white38 : Colors.black38,
                  fontSize: 11,
                ),
              ),
            ],
          )
        else
          const SizedBox(),
        // DFC branding
        Text(
          'datafightcentral.com',
          style: TextStyle(
            color: isDark
                ? AppTheme.neonCyan.withValues(alpha: 0.6)
                : Colors.blue.withValues(alpha: 0.6),
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Grid pattern painter for dark cards
class _GridPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..strokeWidth = 1;

    const spacing = 30.0;
    for (double x = 0; x <= size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// ═══════════════════════════════════════════════════════════════════════════
/// FIGHTER CARD SERVICE
/// ═══════════════════════════════════════════════════════════════════════════
class FighterCardService {
  static final FighterCardService _instance = FighterCardService._internal();
  factory FighterCardService() => _instance;
  FighterCardService._internal();

  /// Capture card as image bytes
  Future<Uint8List?> captureCard(GlobalKey key) async {
    try {
      final boundary =
          key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('[FighterCard] Error capturing: $e');
      return null;
    }
  }

  /// Get share caption
  String getShareCaption(FighterCardData fighter) {
    return '🥊 ${fighter.name}\n'
        '📊 Record: ${fighter.record}\n'
        '${fighter.weightClass != null ? '⚖️ ${fighter.weightClass}\n' : ''}'
        '\n'
        'Track fighters & predictions on @DataFightCentral\n'
        '#DFC #MMA #Boxing #CombatSports';
  }

  /// Capture and share a fighter card as a real PNG image.
  Future<bool> shareCard(GlobalKey key, FighterCardData fighter) async {
    final bytes = await captureCard(key);
    if (bytes == null) return false;

    await ShareService.instance.shareImageBytes(
      bytes: bytes,
      fileName: '${fighter.name}_fighter_card.png',
      text: getShareCaption(fighter),
      subject: '${fighter.name} Fighter Card',
    );
    return true;
  }
}
