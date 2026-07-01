import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/constants/image_assets.dart';
import '../../../shared/widgets/dfc_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/theme/design_tokens.dart';
import 'event_pass_creator_screen.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// MY FIGHT PASSES — View all issued passes with QR codes
/// Tap any pass → full-screen QR code for scanner entry
/// ═══════════════════════════════════════════════════════════════════════════

class MyPassesScreen extends StatefulWidget {
  const MyPassesScreen({super.key});

  @override
  State<MyPassesScreen> createState() => _MyPassesScreenState();
}

class _MyPassesScreenState extends State<MyPassesScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glowCtrl;

  // Demo passes — in production these come from Firestore
  final List<_EventPass> _passes = [
    _EventPass(
      id: 'DFC-FIGHTER-M2K9X4P',
      eventName: 'DFC Championship Series',
      venue: 'Brisbane Convention Centre',
      holderName: 'MARCUS TORRES',
      role: CredentialRole.fighter,
      eventDate: DateTime(2026, 8, 15),
      logoUrl: ImageAssets.dfcIcon,
      notes: 'Main Event — 84kg Division',
    ),
    _EventPass(
      id: 'DFC-CORNER-R7H3Z1W',
      eventName: 'DFC Championship Series',
      venue: 'Brisbane Convention Centre',
      holderName: 'COACH RAY MITCHELL',
      role: CredentialRole.corner,
      eventDate: DateTime(2026, 8, 15),
      logoUrl: ImageAssets.dfcIcon,
      notes: 'Corner for MARCUS TORRES',
    ),
    _EventPass(
      id: 'DFC-TRAINER-Q4N8T2V',
      eventName: 'Friday Night Fights XIV',
      venue: 'Gold Coast Sports Hub',
      holderName: 'JAKE MORRISON',
      role: CredentialRole.trainer,
      eventDate: DateTime(2026, 9, 5),
      logoUrl: ImageAssets.dfcIcon,
      notes: 'Head Trainer',
    ),
    _EventPass(
      id: 'DFC-VIP-A9C5E7K',
      eventName: 'DFC Championship Series',
      venue: 'Sydney Olympic Park',
      holderName: 'VIP GUEST',
      role: CredentialRole.vipGuest,
      eventDate: DateTime(2025, 10, 20),
      logoUrl: ImageAssets.dfcIcon,
      notes: 'Ringside + VIP Lounge',
    ),
    _EventPass(
      id: 'DFC-MEDIA-B3F6J8L',
      eventName: 'Friday Night Fights XIV',
      venue: 'Gold Coast Sports Hub',
      holderName: 'ALEX WATKINS',
      role: CredentialRole.mediaPress,
      eventDate: DateTime(2025, 9, 5),
      logoUrl: ImageAssets.dfcIcon,
      notes: 'Press Credential — Cage-side Photography',
    ),
    _EventPass(
      id: 'DFC-CUTMAN-D1G4H6M',
      eventName: 'DFC Championship Series',
      venue: 'Brisbane Convention Centre',
      holderName: 'ROB "STEADY HANDS" TAYLOR',
      role: CredentialRole.cutman,
      eventDate: DateTime(2025, 8, 15),
      logoUrl: ImageAssets.dfcIcon,
      notes: 'Assigned: Bouts 3, 5, 7 (Main Card)',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
            sliver: _passes.isEmpty
                ? SliverFillRemaining(child: _buildEmpty())
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildPassCard(_passes[i]),
                      ),
                      childCount: _passes.length,
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/fight-pass/create'),
        backgroundColor: DesignTokens.neonCyan,
        icon: const Icon(Icons.add, color: Colors.black),
        label: const Text(
          'New Pass',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      floating: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      expandedHeight: 60,
      flexibleSpace: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  DesignTokens.bgPrimary.withValues(alpha: 0.9),
                  DesignTokens.bgPrimary.withValues(alpha: 0.7),
                ],
              ),
            ),
          ),
        ),
      ),
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new,
          color: Colors.white,
          size: 18,
        ),
        onPressed: () => context.pop(),
      ),
      title: const Text(
        'My Fight Passes',
        style: TextStyle(
          color: DesignTokens.textPrimary,
          fontSize: DesignTokens.fontSizeTitle,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(
            Icons.qr_code_scanner,
            color: DesignTokens.neonCyan,
            size: 22,
          ),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Pass scanner — coming in next update'),
                backgroundColor: DesignTokens.neonCyan,
              ),
            );
          },
          tooltip: 'Scan Pass',
        ),
      ],
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.badge_outlined,
            color: Colors.white.withValues(alpha: 0.15),
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            'No passes yet',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Create event passes for fighters, corners,\ntrainers & staff',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PASS CARD
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildPassCard(_EventPass pass) {
    final roleColor = pass.role.color;
    final isExpired = pass.eventDate.isBefore(DateTime.now());

    return GestureDetector(
      onTap: () => _showFullScreenQR(pass),
      child: AnimatedBuilder(
        animation: _glowCtrl,
        builder: (context, _) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: DesignTokens.bgCard,
              border: Border.all(
                color: isExpired
                    ? Colors.white.withValues(alpha: 0.06)
                    : roleColor.withValues(alpha: 0.25),
              ),
              boxShadow: isExpired
                  ? null
                  : [
                      BoxShadow(
                        color: roleColor.withValues(
                          alpha: 0.06 + _glowCtrl.value * 0.04,
                        ),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ],
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(18),
                    ),
                    gradient: LinearGradient(
                      colors: [
                        roleColor.withValues(alpha: 0.1),
                        roleColor.withValues(alpha: 0.03),
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      // Pass logo / icon
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: roleColor.withValues(alpha: 0.12),
                          border: Border.all(
                            color: roleColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: pass.logoUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(9),
                                child: ImageAssets.isLocalAsset(pass.logoUrl!)
                                    ? Image.asset(
                                        pass.logoUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, _, _) => Icon(
                                          pass.role.icon,
                                          color: roleColor,
                                          size: 22,
                                        ),
                                      )
                                    : DfcNetworkImage(url: pass.logoUrl!),
                              )
                            : Icon(pass.role.icon, color: roleColor, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pass.eventName,
                              style: TextStyle(
                                color: isExpired
                                    ? Colors.white.withValues(alpha: 0.4)
                                    : Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              pass.venue,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.35),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Role badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: roleColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: roleColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          pass.role.label.toUpperCase(),
                          style: TextStyle(
                            color: roleColor,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Bottom: holder + date
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pass.holderName,
                              style: TextStyle(
                                color: isExpired
                                    ? Colors.white.withValues(alpha: 0.3)
                                    : Colors.white.withValues(alpha: 0.8),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                            if (pass.notes != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                pass.notes!,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  fontSize: 10,
                                  fontStyle: FontStyle.italic,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${pass.eventDate.day}/${pass.eventDate.month}/${pass.eventDate.year}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.4),
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isExpired
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : DesignTokens.neonGreen.withValues(
                                      alpha: 0.1,
                                    ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isExpired ? 'EXPIRED' : 'ACTIVE',
                              style: TextStyle(
                                color: isExpired
                                    ? Colors.white.withValues(alpha: 0.3)
                                    : DesignTokens.neonGreen,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.qr_code,
                        color: roleColor.withValues(alpha: 0.4),
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FULL-SCREEN QR VIEW
  // ═══════════════════════════════════════════════════════════════════════════
  void _showFullScreenQR(_EventPass pass) {
    final qrData =
        'DFC-PASS|${pass.id}|${pass.eventName}|${pass.holderName}|${pass.role.label}|${pass.eventDate.toIso8601String()}';
    final roleColor = pass.role.color;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(ctx).size.height * 0.88,
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [DesignTokens.bgSecondary, DesignTokens.bgPrimary],
            ),
          ),
          child: Column(
            children: [
              // Drag handle
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),

              // Event logo + name
              if (pass.logoUrl != null)
                Container(
                  width: 64,
                  height: 64,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    image: DecorationImage(
                      image: ImageAssets.resolveImage(pass.logoUrl!),
                      fit: BoxFit.cover,
                      onError: (_, _) {},
                    ),
                  ),
                )
              else
                Container(
                  width: 64,
                  height: 64,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: roleColor.withValues(alpha: 0.1),
                    border: Border.all(color: roleColor.withValues(alpha: 0.3)),
                  ),
                  child: Icon(
                    Icons.sports_mma,
                    color: roleColor.withValues(alpha: 0.5),
                    size: 32,
                  ),
                ),

              Text(
                pass.eventName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                pass.venue,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),

              // Role badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: roleColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: roleColor.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(pass.role.icon, color: roleColor, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      pass.role.label.toUpperCase(),
                      style: TextStyle(
                        color: roleColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                pass.holderName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 4),
              if (pass.notes != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    pass.notes!,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

              const Spacer(),

              // Giant QR Code
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: roleColor.withValues(alpha: 0.25),
                      blurRadius: 30,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: QrImageView(
                  data: qrData,
                  size: 240,
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Colors.black87,
                  ),
                ),
              ),

              const SizedBox(height: 16),
              Text(
                pass.id,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Present this QR code at entry for verification',
                style: TextStyle(
                  color: roleColor.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${pass.eventDate.day}/${pass.eventDate.month}/${pass.eventDate.year}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const Spacer(),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DATA MODEL
// ═══════════════════════════════════════════════════════════════════════════
class _EventPass {
  final String id;
  final String eventName;
  final String venue;
  final String holderName;
  final CredentialRole role;
  final DateTime eventDate;
  final String? logoUrl;
  final String? notes;

  const _EventPass({
    required this.id,
    required this.eventName,
    required this.venue,
    required this.holderName,
    required this.role,
    required this.eventDate,
    this.logoUrl,
    this.notes,
  });
}
