// ═══════════════════════════════════════════════════════════════════════════
// DFC GYM QR ONBOARDING KIT
// ═══════════════════════════════════════════════════════════════════════════
// Printable QR posters for gyms to onboard members — offline to online bridge
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../../../core/constants/image_assets.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_theme.dart';

/// Gym data for QR generation
class GymQRData {
  final String gymId;
  final String gymName;
  final String? logoUrl;
  final String? tagline;
  final String? address;
  final String? phone;
  final String qrCode;
  final String joinLink;
  final List<String> disciplines; // MMA, BJJ, Boxing, etc.
  final String? referralCode;

  const GymQRData({
    required this.gymId,
    required this.gymName,
    this.logoUrl,
    this.tagline,
    this.address,
    this.phone,
    required this.qrCode,
    required this.joinLink,
    this.disciplines = const [],
    this.referralCode,
  });
}

/// Poster style variants
enum GymPosterStyle {
  professional, // Clean, corporate look
  fighter, // Aggressive, combat-focused
  minimal, // Simple, modern
  vintage, // Classic boxing gym feel
}

/// ═══════════════════════════════════════════════════════════════════════════
/// GYM QR SERVICE
/// ═══════════════════════════════════════════════════════════════════════════
class GymQRService {
  static final GymQRService _instance = GymQRService._internal();
  factory GymQRService() => _instance;
  GymQRService._internal();

  final _db = FirebaseFirestore.instance;

  /// Generate QR code for gym
  Future<GymQRData> generateGymQR({
    required String gymId,
    required String gymName,
    String? logoUrl,
    String? tagline,
    String? address,
    String? phone,
    List<String> disciplines = const [],
  }) async {
    // Generate unique QR code
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final qrCode = 'GYM${gymId.substring(0, 6).toUpperCase()}$timestamp';

    // Generate join link
    final joinLink = 'https://datafightcentral.com/join/gym/$gymId?qr=$qrCode';

    // Store QR code mapping
    await _db.collection('gym_qr_codes').doc(qrCode).set({
      'gymId': gymId,
      'gymName': gymName,
      'joinLink': joinLink,
      'scans': 0,
      'signups': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'active': true,
    });

    // Update gym document
    await _db.collection('gyms').doc(gymId).update({
      'qrCodes': FieldValue.arrayUnion([qrCode]),
      'primaryQRCode': qrCode,
    });

    return GymQRData(
      gymId: gymId,
      gymName: gymName,
      logoUrl: logoUrl,
      tagline: tagline,
      address: address,
      phone: phone,
      qrCode: qrCode,
      joinLink: joinLink,
      disciplines: disciplines,
    );
  }

  /// Track QR scan
  Future<void> trackScan(String qrCode) async {
    await _db.collection('gym_qr_codes').doc(qrCode).update({
      'scans': FieldValue.increment(1),
      'lastScannedAt': FieldValue.serverTimestamp(),
    });

    // Log scan event
    await _db.collection('qr_scan_events').add({
      'qrCode': qrCode,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  /// Track signup from QR
  Future<void> trackSignup(String qrCode, String userId) async {
    final doc = await _db.collection('gym_qr_codes').doc(qrCode).get();
    if (!doc.exists) return;

    final gymId = doc.data()!['gymId'] as String;

    await _db.collection('gym_qr_codes').doc(qrCode).update({
      'signups': FieldValue.increment(1),
    });

    // Link user to gym
    await _db.collection('users').doc(userId).update({
      'gym': gymId,
      'joinedViaQR': qrCode,
      'joinedGymAt': FieldValue.serverTimestamp(),
    });

    // Add to gym members
    await _db
        .collection('gyms')
        .doc(gymId)
        .collection('members')
        .doc(userId)
        .set({
          'userId': userId,
          'joinedAt': FieldValue.serverTimestamp(),
          'source': 'qr_code',
          'qrCode': qrCode,
        });
  }

  /// Get QR stats
  Future<Map<String, dynamic>> getQRStats(String qrCode) async {
    final doc = await _db.collection('gym_qr_codes').doc(qrCode).get();
    if (!doc.exists) return {'scans': 0, 'signups': 0, 'conversionRate': 0};

    final data = doc.data()!;
    final scans = data['scans'] as int? ?? 0;
    final signups = data['signups'] as int? ?? 0;
    final conversionRate = scans > 0
        ? (signups / scans * 100).toStringAsFixed(1)
        : '0';

    return {
      'scans': scans,
      'signups': signups,
      'conversionRate': '$conversionRate%',
      'lastScanned': data['lastScannedAt'],
    };
  }

  /// Get all QR codes for gym
  Future<List<String>> getGymQRCodes(String gymId) async {
    final query = await _db
        .collection('gym_qr_codes')
        .where('gymId', isEqualTo: gymId)
        .get();

    return query.docs.map((d) => d.id).toList();
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// GYM QR POSTER WIDGET (Printable)
/// ═══════════════════════════════════════════════════════════════════════════
class GymQRPoster extends StatelessWidget {
  final GymQRData gymData;
  final GymPosterStyle style;
  final GlobalKey? repaintKey;
  final double width;
  final double height;

  const GymQRPoster({
    super.key,
    required this.gymData,
    this.style = GymPosterStyle.professional,
    this.repaintKey,
    this.width = 600,
    this.height = 800,
  });

  @override
  Widget build(BuildContext context) {
    final key = repaintKey ?? GlobalKey();

    return RepaintBoundary(
      key: key,
      child: Container(
        width: width,
        height: height,
        decoration: _getPosterDecoration(),
        child: Column(
          children: [
            _buildHeader(),
            const Spacer(),
            _buildQRSection(),
            const SizedBox(height: 24),
            _buildInstructions(),
            const Spacer(),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  BoxDecoration _getPosterDecoration() {
    switch (style) {
      case GymPosterStyle.professional:
        return const BoxDecoration(color: Colors.white);
      case GymPosterStyle.fighter:
        return const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A1A2E), Color(0xFF0F0F1A)],
          ),
        );
      case GymPosterStyle.minimal:
        return const BoxDecoration(color: Color(0xFFF5F5F5));
      case GymPosterStyle.vintage:
        return const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2D2D2D), Color(0xFF1A1A1A)],
          ),
        );
    }
  }

  bool get _isDark =>
      style == GymPosterStyle.fighter || style == GymPosterStyle.vintage;

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          // Gym logo
          if (gymData.logoUrl != null)
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _isDark ? Colors.white12 : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(16),
                image: DecorationImage(
                  image: ImageAssets.resolveImage(gymData.logoUrl!),
                  fit: BoxFit.cover,
                  onError: (_, _) {},
                ),
              ),
            )
          else
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _isDark ? AppTheme.neonCyan : Colors.blue,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.fitness_center,
                color: _isDark ? Colors.black : Colors.white,
                size: 40,
              ),
            ),
          const SizedBox(height: 16),
          // Gym name
          Text(
            gymData.gymName.toUpperCase(),
            style: TextStyle(
              color: _isDark ? Colors.white : Colors.black,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
            textAlign: TextAlign.center,
          ),
          if (gymData.tagline != null) ...[
            const SizedBox(height: 8),
            Text(
              gymData.tagline!,
              style: TextStyle(
                color: _isDark ? Colors.white60 : Colors.black54,
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          // Disciplines
          if (gymData.disciplines.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: gymData.disciplines
                  .map(
                    (d) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _isDark
                            ? AppTheme.neonCyan.withValues(alpha: 0.2)
                            : Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _isDark
                              ? AppTheme.neonCyan.withValues(alpha: 0.5)
                              : Colors.blue.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        d,
                        style: TextStyle(
                          color: _isDark ? AppTheme.neonCyan : Colors.blue,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQRSection() {
    return Column(
      children: [
        // "Scan to Join" text
        Text(
          'SCAN TO JOIN',
          style: TextStyle(
            color: _isDark ? AppTheme.neonCyan : Colors.blue,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 3,
          ),
        ),
        const SizedBox(height: 20),
        // QR Code placeholder (actual QR generation would use qr_flutter package)
        Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isDark ? AppTheme.neonCyan : Colors.blue,
              width: 4,
            ),
            boxShadow: _isDark
                ? [
                    BoxShadow(
                      color: AppTheme.neonCyan.withValues(alpha: 0.4),
                      blurRadius: 20,
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.qr_code_2,
                  size: 120,
                  color: _isDark ? AppTheme.neonCyan : Colors.blue,
                ),
                const SizedBox(height: 8),
                Text(
                  gymData.qrCode,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Short link
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: _isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'dfc.link/${gymData.gymId.substring(0, 8)}',
            style: TextStyle(
              color: _isDark ? Colors.white : Colors.black87,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInstructions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          _buildInstructionStep(1, 'Scan QR code with your phone camera'),
          const SizedBox(height: 12),
          _buildInstructionStep(2, 'Create your free DFC account'),
          const SizedBox(height: 12),
          _buildInstructionStep(3, 'Join our gym community'),
        ],
      ),
    );
  }

  Widget _buildInstructionStep(int number, String text) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: _isDark ? AppTheme.neonCyan : Colors.blue,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$number',
              style: TextStyle(
                color: _isDark ? Colors.black : Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: _isDark ? Colors.white : Colors.black87,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // DFC branding
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'POWERED BY',
                style: TextStyle(
                  color: _isDark ? Colors.white30 : Colors.black26,
                  fontSize: 10,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.neonCyan,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'DFC',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'DataFight Central',
                style: TextStyle(
                  color: _isDark ? Colors.white : Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'The Combat Sports OS',
            style: TextStyle(
              color: _isDark ? Colors.white38 : Colors.black38,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 16),
          // Gym contact
          if (gymData.address != null || gymData.phone != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: _isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  if (gymData.address != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.location_on,
                          color: _isDark ? Colors.white38 : Colors.black38,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          gymData.address!,
                          style: TextStyle(
                            color: _isDark ? Colors.white60 : Colors.black54,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  if (gymData.phone != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.phone,
                          color: _isDark ? Colors.white38 : Colors.black38,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          gymData.phone!,
                          style: TextStyle(
                            color: _isDark ? Colors.white60 : Colors.black54,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// POSTER CAPTURE SERVICE
/// ═══════════════════════════════════════════════════════════════════════════
class GymPosterService {
  static final GymPosterService _instance = GymPosterService._internal();
  factory GymPosterService() => _instance;
  GymPosterService._internal();

  /// Capture poster as high-res image
  Future<Uint8List?> capturePoster(
    GlobalKey key, {
    double pixelRatio = 3.0,
  }) async {
    try {
      final boundary =
          key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final image = await boundary.toImage(pixelRatio: pixelRatio);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('[GymPoster] Error capturing: $e');
      return null;
    }
  }
}
