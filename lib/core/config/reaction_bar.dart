import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/design_tokens.dart';

class ReactionBar extends StatefulWidget {
  const ReactionBar({super.key});

  @override
  State<ReactionBar> createState() => _ReactionBarState();
}

class _ReactionBarState extends State<ReactionBar> {
  bool _liked = false;
  bool _respected = false;
  bool _fired = false;

  void _toggle(VoidCallback action) {
    HapticFeedback.selectionClick();
    action();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ReactionButton(
          icon: _liked ? Icons.favorite : Icons.favorite_border,
          color: _liked ? DesignTokens.neonRed : DesignTokens.textMuted,
          onTap: () => _toggle(() => setState(() => _liked = !_liked)),
        ),
        _ReactionButton(
          icon: _respected ? Icons.military_tech : Icons.military_tech_outlined,
          color: _respected ? DesignTokens.neonGold : DesignTokens.textMuted,
          onTap: () => _toggle(() => setState(() => _respected = !_respected)),
        ),
        _ReactionButton(
          icon: _fired
              ? Icons.local_fire_department
              : Icons.local_fire_department_outlined,
          color: _fired ? DesignTokens.neonOrange : DesignTokens.textMuted,
          onTap: () => _toggle(() => setState(() => _fired = !_fired)),
        ),
        _ReactionButton(
          icon: Icons.share_outlined,
          color: DesignTokens.textMuted,
          onTap: () => HapticFeedback.lightImpact(),
        ),
      ],
    );
  }
}

class _ReactionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ReactionButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, color: color, size: 22),
      onPressed: onTap,
    );
  }
}
