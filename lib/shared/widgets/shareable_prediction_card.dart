// ═══════════════════════════════════════════════════════════════════════════
// DFC SHAREABLE PREDICTION CARD
// ═══════════════════════════════════════════════════════════════════════════
// "My Pick: Fighter X by KO R2" — viral prediction sharing
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../../core/constants/image_assets.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import '../../core/theme/app_theme.dart';
import '../services/share_service.dart';

/// Prediction data for card generation
class PredictionCardData {
  final String eventName;
  final DateTime eventDate;
  final String fighter1Name;
  final String fighter2Name;
  final String? fighter1Photo;
  final String? fighter2Photo;
  final String? fighter1Record;
  final String? fighter2Record;
  final String? fighter1Country;
  final String? fighter2Country;
  final String pickedFighter; // '1' or '2'
  final String method; // 'KO/TKO', 'Submission', 'Decision', 'Draw'
  final int? round;
  final String userName;
  final String? userPhoto;
  final double? confidence; // 0.0 - 1.0
  final bool isVerified;

  const PredictionCardData({
    required this.eventName,
    required this.eventDate,
    required this.fighter1Name,
    required this.fighter2Name,
    this.fighter1Photo,
    this.fighter2Photo,
    this.fighter1Record,
    this.fighter2Record,
    this.fighter1Country,
    this.fighter2Country,
    required this.pickedFighter,
    required this.method,
    this.round,
    required this.userName,
    this.userPhoto,
    this.confidence,
    this.isVerified = false,
  });

  String get pickedFighterName =>
      pickedFighter == '1' ? fighter1Name : fighter2Name;
  String get opponentName => pickedFighter == '1' ? fighter2Name : fighter1Name;

  String get predictionText {
    final methodText = method;
    final roundText = round != null ? ' R$round' : '';
    return '$methodText$roundText';
  }

  String get fullPrediction => '$pickedFighterName by $predictionText';
}

/// Card style variants
enum PredictionCardStyle {
  versus, // Split screen VS style
  spotlight, // Focus on picked fighter
  minimal, // Clean Instagram story style
  hype, // Bold/aggressive style
}

/// ═══════════════════════════════════════════════════════════════════════════
/// SHAREABLE PREDICTION CARD WIDGET
/// ═══════════════════════════════════════════════════════════════════════════
class ShareablePredictionCard extends StatelessWidget {
  final PredictionCardData prediction;
  final PredictionCardStyle style;
  final GlobalKey? repaintKey;
  final double width;
  final double height;

  const ShareablePredictionCard({
    super.key,
    required this.prediction,
    this.style = PredictionCardStyle.versus,
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
        child: Stack(children: [_buildBackground(), _buildContent()]),
      ),
    );
  }

  BoxDecoration _getCardDecoration() {
    switch (style) {
      case PredictionCardStyle.versus:
        return BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0A0A15), Color(0xFF1A1A2E)],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppTheme.neonCyan.withValues(alpha: 0.4),
            width: 2,
          ),
        );
      case PredictionCardStyle.hype:
        return BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A0A0A), Color(0xFF0A0A0A)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.red, width: 3),
        );
      case PredictionCardStyle.spotlight:
      case PredictionCardStyle.minimal:
        return BoxDecoration(
          color: const Color(0xFF121212),
          borderRadius: BorderRadius.circular(20),
        );
    }
  }

  Widget _buildBackground() {
    if (style == PredictionCardStyle.versus) {
      return Positioned.fill(
        child: Row(
          children: [
            // Left side (Fighter 1)
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      prediction.pickedFighter == '1'
                          ? AppTheme.neonCyan.withValues(alpha: 0.15)
                          : Colors.red.withValues(alpha: 0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Right side (Fighter 2)
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                    colors: [
                      prediction.pickedFighter == '2'
                          ? AppTheme.neonCyan.withValues(alpha: 0.15)
                          : Colors.red.withValues(alpha: 0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildEventInfo(),
          const SizedBox(height: 20),
          Expanded(child: _buildMatchup()),
          const SizedBox(height: 16),
          _buildPrediction(),
          const SizedBox(height: 16),
          _buildUserInfo(),
          const SizedBox(height: 12),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // DFC Logo
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.neonCyan,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'DFC',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'PREDICTION',
              style: TextStyle(
                color: Colors.white60,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        // Confidence meter
        if (prediction.confidence != null) _buildConfidenceMeter(),
      ],
    );
  }

  Widget _buildConfidenceMeter() {
    final confidence = prediction.confidence!;
    final percentage = (confidence * 100).round();
    Color color;
    if (confidence >= 0.8) {
      color = Colors.green;
    } else if (confidence >= 0.6) {
      color = Colors.orange;
    } else {
      color = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.trending_up, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            '$percentage%',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventInfo() {
    return Column(
      children: [
        Text(
          prediction.eventName.toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          _formatDate(prediction.eventDate),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Widget _buildMatchup() {
    return Row(
      children: [
        // Fighter 1
        Expanded(
          child: _buildFighterSide(
            name: prediction.fighter1Name,
            record: prediction.fighter1Record,
            photo: prediction.fighter1Photo,
            country: prediction.fighter1Country,
            isPicked: prediction.pickedFighter == '1',
            alignment: CrossAxisAlignment.start,
          ),
        ),
        // VS
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.1),
            border: Border.all(color: Colors.white24),
          ),
          child: const Center(
            child: Text(
              'VS',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        // Fighter 2
        Expanded(
          child: _buildFighterSide(
            name: prediction.fighter2Name,
            record: prediction.fighter2Record,
            photo: prediction.fighter2Photo,
            country: prediction.fighter2Country,
            isPicked: prediction.pickedFighter == '2',
            alignment: CrossAxisAlignment.end,
          ),
        ),
      ],
    );
  }

  Widget _buildFighterSide({
    required String name,
    String? record,
    String? photo,
    String? country,
    required bool isPicked,
    required CrossAxisAlignment alignment,
  }) {
    return Column(
      crossAxisAlignment: alignment,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Photo
        Stack(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isPicked ? AppTheme.neonCyan : Colors.white24,
                  width: isPicked ? 3 : 1,
                ),
                image: photo != null
                    ? DecorationImage(
                        image: ImageAssets.resolveImage(photo),
                        fit: BoxFit.cover,
                        onError: (_, _) {},
                      )
                    : null,
                boxShadow: isPicked
                    ? [
                        BoxShadow(
                          color: AppTheme.neonCyan.withValues(alpha: 0.4),
                          blurRadius: 12,
                        ),
                      ]
                    : null,
              ),
              child: photo == null
                  ? const Icon(Icons.person, color: Colors.white30, size: 35)
                  : null,
            ),
            if (isPicked)
              Positioned(
                right: -4,
                top: -4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppTheme.neonCyan,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.black, size: 12),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        // Name
        Text(
          name.toUpperCase(),
          style: TextStyle(
            color: isPicked ? AppTheme.neonCyan : Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
          textAlign: alignment == CrossAxisAlignment.start
              ? TextAlign.left
              : TextAlign.right,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (record != null) ...[
          const SizedBox(height: 2),
          Text(
            record,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 10,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPrediction() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.neonCyan.withValues(alpha: 0.3),
            AppTheme.neonCyan.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.neonCyan.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          const Text(
            'MY PICK',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            prediction.pickedFighterName.toUpperCase(),
            style: const TextStyle(
              color: AppTheme.neonCyan,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: _getMethodColor().withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              prediction.predictionText,
              style: TextStyle(
                color: _getMethodColor(),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getMethodColor() {
    switch (prediction.method.toLowerCase()) {
      case 'ko/tko':
      case 'ko':
      case 'tko':
        return Colors.orange;
      case 'submission':
        return Colors.purple;
      case 'decision':
        return Colors.blue;
      case 'draw':
        return Colors.grey;
      default:
        return AppTheme.neonCyan;
    }
  }

  Widget _buildUserInfo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // User photo
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: Colors.white12,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white24),
            image: prediction.userPhoto != null
                ? DecorationImage(
                    image: ImageAssets.resolveImage(prediction.userPhoto!),
                    fit: BoxFit.cover,
                    onError: (_, _) {},
                  )
                : null,
          ),
          child: prediction.userPhoto == null
              ? const Icon(Icons.person, color: Colors.white30, size: 16)
              : null,
        ),
        const SizedBox(width: 8),
        Text(
          prediction.userName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (prediction.isVerified) ...[
          const SizedBox(width: 4),
          const Icon(Icons.verified, color: AppTheme.neonCyan, size: 14),
        ],
      ],
    );
  }

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '#MyPick',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 10,
          ),
        ),
        Text(
          'datafightcentral.com',
          style: TextStyle(
            color: AppTheme.neonCyan.withValues(alpha: 0.6),
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// PREDICTION CARD SERVICE
/// ═══════════════════════════════════════════════════════════════════════════
class PredictionCardService {
  static final PredictionCardService _instance =
      PredictionCardService._internal();
  factory PredictionCardService() => _instance;
  PredictionCardService._internal();

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
      debugPrint('[PredictionCard] Error capturing: $e');
      return null;
    }
  }

  /// Get share caption
  String getShareCaption(PredictionCardData prediction) {
    return '🎯 MY PICK: ${prediction.pickedFighterName}\n'
        '⚡ ${prediction.predictionText}\n'
        '🥊 ${prediction.eventName}\n'
        '\n'
        'Make your predictions on @DataFightCentral\n'
        '#MyPick #DFC #MMA #FightPredictions';
  }

  /// Capture and share a prediction card as a real PNG image.
  Future<bool> shareCard(GlobalKey key, PredictionCardData prediction) async {
    final bytes = await captureCard(key);
    if (bytes == null) return false;

    await ShareService.instance.shareImageBytes(
      bytes: bytes,
      fileName: '${prediction.eventName}_prediction_card.png',
      text: getShareCaption(prediction),
      subject: '${prediction.eventName} Prediction Card',
    );
    return true;
  }
}
