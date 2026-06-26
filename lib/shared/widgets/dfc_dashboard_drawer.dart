import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/design_tokens.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// DFC DASHBOARD DRAWER — Session-scoped quick actions (right side)
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Quick actions, live status, and controls used during active sessions.
/// Keeps ephemeral, high-frequency controls separate from persistent settings
/// which live in the left DFC Command drawer.
///
/// Usage: Add to any Scaffold via `endDrawer: const DFCDashboardDrawer()`.
/// ═══════════════════════════════════════════════════════════════════════════

class DFCDashboardDrawer extends StatelessWidget {
  const DFCDashboardDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: DesignTokens.bgPrimary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(left: Radius.circular(16)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // ── HEADER ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: DesignTokens.neonCyan.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.dashboard_rounded,
                      color: DesignTokens.neonCyan,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dashboard',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Session controls & status',
                          style: TextStyle(color: Colors.white38, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white38,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(
              color: DesignTokens.neonCyan.withValues(alpha: 0.1),
              height: 1,
            ),

            // ── SCROLLABLE CONTENT ──
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  // ─── QUICK ACTIONS ───
                  const _SectionTitle(title: 'QUICK ACTIONS'),
                  _ActionTile(
                    icon: Icons.play_circle_fill,
                    label: 'Start Stream',
                    subtitle: 'Go live now',
                    accentColor: AppTheme.neonGreen,
                    onTap: () => _act(context, '/live-streaming'),
                  ),
                  _ActionTile(
                    icon: Icons.movie_creation,
                    label: 'Create Clip',
                    subtitle: 'Capture a highlight',
                    accentColor: DesignTokens.neonAmber,
                    onTap: () => _act(context, '/combat-reels'),
                  ),
                  _ActionTile(
                    icon: Icons.publish,
                    label: 'Publish Highlight',
                    subtitle: 'Push to feed',
                    accentColor: DesignTokens.neonMagenta,
                    onTap: () => _act(context, '/social-media-toolkit'),
                  ),
                  _ActionTile(
                    icon: Icons.share,
                    label: 'Quick Share',
                    subtitle: 'Copy event link',
                    accentColor: DesignTokens.neonCyan,
                    onTap: () => _act(context, '/promotion-engine'),
                  ),

                  // ─── LIVE STATUS ───
                  const _SectionTitle(title: 'LIVE STATUS'),
                  const _StatusTile(
                    icon: Icons.visibility,
                    label: 'Viewer Count',
                    value: '—',
                    accentColor: DesignTokens.neonCyan,
                  ),
                  const _StatusTile(
                    icon: Icons.signal_cellular_alt,
                    label: 'Stream Health',
                    value: 'IDLE',
                    accentColor: AppTheme.neonGreen,
                  ),
                  const _StatusTile(
                    icon: Icons.speed,
                    label: 'Bitrate',
                    value: '— kbps',
                    accentColor: DesignTokens.neonAmber,
                  ),
                  const _StatusTile(
                    icon: Icons.warning_amber_rounded,
                    label: 'Active Alerts',
                    value: '0',
                    accentColor: Color(0xFFFF3366),
                  ),

                  // ─── SESSION TOGGLES ───
                  const _SectionTitle(title: 'SESSION TOGGLES'),
                  const _ToggleTile(icon: Icons.mic, label: 'Audio'),
                  const _ToggleTile(icon: Icons.videocam, label: 'Camera'),
                  const _ToggleTile(
                    icon: Icons.notifications_active,
                    label: 'Notifications',
                  ),

                  // ─── SHORTCUTS ───
                  const _SectionTitle(title: 'SHORTCUTS'),
                  _ActionTile(
                    icon: Icons.event,
                    label: 'Event Manager',
                    subtitle: 'View & manage events',
                    accentColor: AppTheme.neonCyan,
                    onTap: () => _act(context, '/event-manager'),
                  ),
                  _ActionTile(
                    icon: Icons.chat_bubble_outline,
                    label: 'Open Chat',
                    subtitle: 'Jump to messages',
                    accentColor: AppTheme.neonCyan,
                    onTap: () => _act(context, '/messaging'),
                  ),
                  _ActionTile(
                    icon: Icons.radar,
                    label: 'Safety Radar',
                    subtitle: 'Acknowledge alerts',
                    accentColor: const Color(0xFFFF3366),
                    onTap: () => _act(context, '/safety-radar'),
                  ),
                  _ActionTile(
                    icon: Icons.group_add,
                    label: 'Assign Moderator',
                    subtitle: 'Manage roles',
                    accentColor: DesignTokens.neonMagenta,
                    onTap: () => _act(context, '/war-room'),
                  ),
                ],
              ),
            ),

            // ── FOOTER ──
            Divider(
              color: DesignTokens.neonCyan.withValues(alpha: 0.1),
              height: 1,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
              child: Text(
                'Session-scoped \u2022 Resets on exit',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.2),
                  fontSize: 9,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _act(BuildContext context, String path) {
    Navigator.of(context).pop();
    context.push(path);
  }
}

// ──────────────────────────────────────────────────────
// INTERNAL COMPONENTS
// ──────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
      child: Text(
        title,
        style: TextStyle(
          color: DesignTokens.neonCyan.withValues(alpha: 0.5),
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color accentColor;
  final VoidCallback? onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.accentColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: accentColor, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.3),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Colors.white.withValues(alpha: 0.15),
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accentColor;

  const _StatusTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: accentColor.withValues(alpha: 0.6), size: 16),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                value,
                style: TextStyle(
                  color: accentColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleTile extends StatefulWidget {
  final IconData icon;
  final String label;

  const _ToggleTile({required this.icon, required this.label});

  @override
  State<_ToggleTile> createState() => _ToggleTileState();
}

class _ToggleTileState extends State<_ToggleTile> {
  bool _on = true;

  @override
  Widget build(BuildContext context) {
    final color = _on ? AppTheme.neonGreen : Colors.white38;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => setState(() => _on = !_on),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Row(
              children: [
                Icon(widget.icon, color: color, size: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  width: 36,
                  height: 20,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: _on
                        ? AppTheme.neonGreen.withValues(alpha: 0.2)
                        : Colors.white.withValues(alpha: 0.06),
                  ),
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 150),
                    alignment: _on
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      width: 16,
                      height: 16,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _on ? AppTheme.neonGreen : Colors.white38,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
