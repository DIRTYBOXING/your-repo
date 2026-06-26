import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_logos.dart';
import '../genie_persona.dart';
import '../screens/genie_chat_screen.dart';
import '../../../shared/services/video_intro_service.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// GENIE VIDEO INTEGRATION SERVICE
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Connects the video intro system with Genie AI mentor system.
/// Ensures Samurai Shido is featured as the primary AI coach.
///
/// FLOW:
/// 1. User triggers "Ask Genie" or "Meet Samurai Shido"
/// 2. Play Genie intro video (if first time)
/// 3. Open Genie chat with Samurai Shido as default persona
/// 4. Save that user has seen Genie intro

class GenieVideoService {
  // Future use: SharedPreferences key for tracking intro completion
  // static const String _genieIntroSeenKey = 'genie_intro_seen';

  /// Show Genie intro video and launch chat with Samurai Shido
  static Future<void> launchGenieWithIntro(
    BuildContext context, {
    bool forceVideo = false,
    GeniePersona? initialPersona,
  }) async {
    // Check if user has seen Genie intro before
    final hasSeenIntro = await _hasSeenGenieIntro();

    if (!context.mounted) return;

    if (!hasSeenIntro || forceVideo) {
      // Show Genie intro video
      await DfcVideoIntroService.showVideoIntro(
        context,
        DfcVideoType.genie,
        onComplete: () {
          _markGenieIntroSeen();
          _openGenieChat(context, initialPersona);
        },
      );
    } else {
      // Skip video, go straight to chat
      _openGenieChat(context, initialPersona);
    }
  }

  /// Open Genie chat screen with Samurai Shido as default
  static void _openGenieChat(
    BuildContext context,
    GeniePersona? initialPersona,
  ) {
    // Default to Samurai Shido if no persona specified
    final persona = initialPersona ?? _getSamuraiShido();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GenieChatScreen(initialPersona: persona),
      ),
    );
  }

  /// Get Samurai Shido persona
  static GeniePersona _getSamuraiShido() {
    return geniePersonas.firstWhere(
      (p) => p.id == 'shido',
      orElse: () => geniePersonas.first,
    );
  }

  /// Show just the Genie intro video (for onboarding or tutorials)
  static Future<void> showGenieIntroVideo(
    BuildContext context, {
    VoidCallback? onComplete,
    bool skippable = true,
  }) async {
    await DfcVideoIntroService.showVideoIntro(
      context,
      DfcVideoType.genie,
      onComplete: () {
        _markGenieIntroSeen();
        onComplete?.call();
      },
      skippable: skippable,
    );
  }

  /// Quick launch Genie with Samurai Shido (no video)
  static void quickLaunchShido(BuildContext context) {
    _openGenieChat(context, _getSamuraiShido());
  }

  /// Quick launch Genie with specific persona
  static void quickLaunchPersona(BuildContext context, String personaId) {
    final persona = geniePersonas.firstWhere(
      (p) => p.id == personaId,
      orElse: _getSamuraiShido,
    );
    _openGenieChat(context, persona);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PERSISTENCE HELPERS (using SharedPreferences or Firestore)
  // ═══════════════════════════════════════════════════════════════════════════

  static const _genieIntroSeenKey = 'genie_intro_seen';

  static Future<bool> _hasSeenGenieIntro() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_genieIntroSeenKey) ?? false;
  }

  static Future<void> _markGenieIntroSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_genieIntroSeenKey, true);
    debugPrint('✅ Genie intro marked as seen');
  }

  /// Reset Genie intro status (for testing or user preference)
  static Future<void> resetGenieIntroStatus() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_genieIntroSeenKey);
    debugPrint('🔄 Genie intro status reset');
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// GENIE QUICK ACCESS WIDGET — Floating Samurai Shido Button
/// ═══════════════════════════════════════════════════════════════════════════

class GenieQuickAccessButton extends StatefulWidget {
  final String? customMessage;
  final bool showOnboarding;

  const GenieQuickAccessButton({
    super.key,
    this.customMessage,
    this.showOnboarding = false,
  });

  @override
  State<GenieQuickAccessButton> createState() => _GenieQuickAccessButtonState();
}

class _GenieQuickAccessButtonState extends State<GenieQuickAccessButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 20,
      right: 20,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: GestureDetector(
              onTap: () => GenieVideoService.launchGenieWithIntro(
                context,
                forceVideo: widget.showOnboarding,
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B35), Color(0xFFFFD60A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF6B35).withValues(alpha: 0.5),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.self_improvement,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// SHIDO BANNER WIDGET — Samurai Shido CTA for Landing Page
/// ═══════════════════════════════════════════════════════════════════════════

class GenieBannerCTA extends StatelessWidget {
  final bool compact;

  const GenieBannerCTA({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(compact ? 12 : 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF4A148C), // Deep purple
            Color(0xFF880E4F), // Deep pink
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4A148C).withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6A1B9A).withValues(alpha: 0.4),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                AppLogos.icon,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Samurai Shido',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: compact ? 16 : 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  compact
                      ? 'Your AI Corner Coach'
                      : 'Your AI corner coach. Heart, Soul & Brain of the fight community.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: compact ? 11 : 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () => GenieVideoService.launchGenieWithIntro(
              context,
              forceVideo: true,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF7F8FF),
              foregroundColor: const Color(0xFF35105F),
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 18 : 22,
                vertical: compact ? 11 : 13,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: const Color(0xFF6A1B9A).withValues(alpha: 0.25),
                ),
              ),
              elevation: 0,
              shadowColor: Colors.transparent,
              textStyle: TextStyle(
                fontSize: compact ? 11.5 : 12.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
              ),
            ),
            child: Text(
              'Meet Shido',
              style: TextStyle(
                fontSize: compact ? 11.5 : 12.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
                height: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
