import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../shared/widgets/dfc_logo_backdrop.dart';
import '../genie_persona.dart';
import 'bot_chat_screen.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// AI BOT HUB — "Your Corner Team"
///
/// Each AI bot gets its own dedicated card & chat page.
/// Samurai Shido & PosterBoy as the primary bots.
/// ═══════════════════════════════════════════════════════════════════════════
class AiBotHubScreen extends StatelessWidget {
  const AiBotHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bots = geniePersonas.toList();

    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      body: Stack(
        children: [
          const DfcLogoBackdrop.topRight(),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                // ── Header ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                              ),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                            const SizedBox(width: 8),
                            ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [
                                  DesignTokens.neonCyan,
                                  DesignTokens.neonMagenta,
                                ],
                              ).createShader(bounds),
                              child: const Text(
                                'AI CORNER TEAM',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.only(left: 48),
                          child: Text(
                            'Each bot has its own chat. Pick your corner.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Bot Cards (hero cards) ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionLabel('YOUR AI TEAM'),
                        const SizedBox(height: 12),
                        ...bots.map((bot) => _HeroBotCard(bot: bot)),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _sectionLabel(String text) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: DesignTokens.neonCyan,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HERO BOT CARD (Samurai Shido, PosterBoy)
// ─────────────────────────────────────────────────────────────────────────────
class _HeroBotCard extends StatelessWidget {
  final GeniePersona bot;
  const _HeroBotCard({required this.bot});

  @override
  Widget build(BuildContext context) {
    final isShido = bot.id == 'shido';
    final gradient = isShido
        ? const [Color(0xFF6A0DAD), Color(0xFFFF00FF)]
        : const [Color(0xFF8B6914), Color(0xFFFFD700)];

    return GestureDetector(
      onTap: () => _openBotChat(context, bot),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              gradient[0].withValues(alpha: 0.25),
              gradient[1].withValues(alpha: 0.08),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: bot.accentColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: gradient),
                boxShadow: [
                  BoxShadow(
                    color: bot.accentColor.withValues(alpha: 0.4),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Center(
                child: isShido
                    ? Icon(bot.icon, color: Colors.white, size: 32)
                    : Text(bot.emoji, style: const TextStyle(fontSize: 30)),
              ),
            ),
            const SizedBox(width: 18),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bot.displayName,
                    style: TextStyle(
                      color: bot.accentColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    bot.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: bot.accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isShido
                          ? 'CHAT WITH SHIDO \u2192'
                          : 'CHAT WITH NANO \u2192',
                      style: TextStyle(
                        color: bot.accentColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openBotChat(BuildContext context, GeniePersona bot) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => BotChatScreen(persona: bot)));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
