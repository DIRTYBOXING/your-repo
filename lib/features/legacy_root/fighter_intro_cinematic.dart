import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../admin/models/fighter_model.dart';
import '../../../core/glass/glass_panel.dart';
import '../../../core/neon/neon_ui.dart';

class FighterIntroCinematic extends StatefulWidget {
  final FighterModel fighter;

  const FighterIntroCinematic({super.key, required this.fighter});

  @override
  State<FighterIntroCinematic> createState() => _FighterIntroCinematicState();
}

class _FighterIntroCinematicState extends State<FighterIntroCinematic>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _bgFade;
  late Animation<double> _portraitScale;
  late Animation<Offset> _nameSlide;
  late Animation<double> _statsFade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );

    _bgFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
    );

    _portraitScale = Tween<double>(begin: 1.2, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.1, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _nameSlide = Tween<Offset>(begin: const Offset(-1.0, 0), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _ctrl,
            curve: const Interval(0.4, 0.7, curve: Curves.elasticOut),
          ),
        );

    _statsFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.7, 1.0, curve: Curves.easeIn),
    );

    _ctrl.addListener(() {
      // Heavy Haptic Impact exactly when the name slams in
      if (_ctrl.value > 0.4 && _ctrl.value < 0.42) {
        HapticFeedback.heavyImpact();
      }
      // Lighter impacts when the stats fade up
      if (_ctrl.value > 0.7 && _ctrl.value < 0.72) {
        HapticFeedback.mediumImpact();
      }
    });

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF02030A),
      body: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) {
          return Stack(
            fit: StackFit.expand,
            children: [
              // 1. Parallax / Scaled Background
              FadeTransition(
                opacity: _bgFade,
                child: Transform.scale(
                  scale: _portraitScale.value,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0, -0.2),
                        radius: 1.2,
                        colors: [
                          Colors.redAccent.withValues(alpha: 0.4),
                          const Color(0xFF02030A),
                        ],
                      ),
                    ),
                    child: widget.fighter.profileImageUrl.isNotEmpty
                        ? Image.network(
                            widget.fighter.profileImageUrl,
                            fit: BoxFit.cover,
                            colorBlendMode: BlendMode.dstIn,
                            color: Colors.black.withValues(alpha: 0.4),
                          )
                        : const Icon(
                            Icons.sports_mma,
                            size: 200,
                            color: Colors.white10,
                          ),
                  ),
                ),
              ),

              // 2. Scanline / Cyberpunk Overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.8),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.95),
                      ],
                      stops: const [0.0, 0.4, 1.0],
                    ),
                  ),
                ),
              ),

              // 3. Fighter Content
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nickname (Glitch / Neon)
                      FadeTransition(
                        opacity: _bgFade,
                        child: NeonText(
                          widget.fighter.nickname.isNotEmpty
                              ? '"${widget.fighter.nickname.toUpperCase()}"'
                              : 'THE CONTENDER',
                          color: Colors.cyanAccent,
                          fontSize: 18,
                          letterSpacing: 4,
                          textAlign: TextAlign.left,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Name Slam Animation
                      SlideTransition(
                        position: _nameSlide,
                        child: Text(
                          '${widget.fighter.firstName}\n${widget.fighter.lastName}'
                              .toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 64,
                            height: 0.9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Glass Panel Stats
                      FadeTransition(
                        opacity: _statsFade,
                        child: GlassPanel(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildStatColumn(
                                'DIVISION',
                                widget.fighter.weightClass,
                              ),
                              Container(
                                width: 1,
                                height: 40,
                                color: Colors.white24,
                              ),
                              _buildStatColumn(
                                'CAMP',
                                widget.fighter.gymId.toUpperCase(),
                              ),
                              Container(
                                width: 1,
                                height: 40,
                                color: Colors.white24,
                              ),
                              _buildStatColumn(
                                'STATUS',
                                'ACTIVE',
                                color: Colors.redAccent,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatColumn(
    String label,
    String value, {
    Color color = Colors.white,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}
