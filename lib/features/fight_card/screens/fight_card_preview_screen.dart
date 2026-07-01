import 'dart:js_interop';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:web/web.dart' as web;

import '../../../core/theme/app_theme.dart';
import '../../../shared/models/fight_card_template.dart';
import '../../../shared/services/auth_service.dart';
import '../../../shared/services/fight_card_template_service.dart';
import '../../../shared/services/social_service.dart';
import '../../../shared/services/share_service.dart';
import '../../../shared/widgets/dfc_network_image.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// FIGHT CARD PREVIEW — Print / Download / Share
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Renders the fight card in a professional, print-ready layout.
/// Actions: Print (browser print dialog), Download (HTML file),
/// Send to connected members.
///
/// ═══════════════════════════════════════════════════════════════════════════
class FightCardPreviewScreen extends StatefulWidget {
  final FightCardTemplate card;
  const FightCardPreviewScreen({required this.card, super.key});

  @override
  State<FightCardPreviewScreen> createState() => _FightCardPreviewScreenState();
}

class _FightCardPreviewScreenState extends State<FightCardPreviewScreen> {
  bool _sending = false;

  @override
  Widget build(BuildContext context) {
    final card = widget.card;
    final sorted = card.sortedBouts;

    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      appBar: AppBar(
        title: const Text(
          'FIGHT CARD PREVIEW',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.5),
        ),
        backgroundColor: AppTheme.secondaryBackground,
        actions: [
          IconButton(
            icon: const Icon(Icons.print, color: AppTheme.neonCyan),
            tooltip: 'Print',
            onPressed: () => _printCard(card),
          ),
          IconButton(
            icon: const Icon(Icons.download, color: AppTheme.neonGreen),
            tooltip: 'Download',
            onPressed: () => _downloadCard(card),
          ),
          IconButton(
            icon: _sending
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.neonMagenta,
                    ),
                  )
                : const Icon(Icons.send, color: AppTheme.neonMagenta),
            tooltip: 'Send to Member',
            onPressed: _sending ? null : () => _showSendDialog(card),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ── Card Header ──────────────────────────────────────
            _buildHeader(card),
            const SizedBox(height: 20),

            // ── Bouts ────────────────────────────────────────────
            ...sorted.map(_buildBoutCard),

            // ── Notes ────────────────────────────────────────────
            if (card.notes != null && card.notes!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'NOTES',
                      style: TextStyle(
                        color: AppTheme.neonCyan,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      card.notes!,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // ── Action Buttons (bottom) ──────────────────────────
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.print),
                    label: const Text('PRINT'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.neonCyan,
                      side: const BorderSide(color: AppTheme.neonCyan),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () => _printCard(card),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.download),
                    label: const Text('DOWNLOAD'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.neonGreen,
                      side: const BorderSide(color: AppTheme.neonGreen),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () => _downloadCard(card),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.send),
                    label: const Text('SEND'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.neonMagenta,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () => _showSendDialog(card),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Post to FightWire ────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.cell_tower, size: 18),
                label: const Text(
                  'POST TO FIGHTWIRE',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.neonPurple,
                  side: const BorderSide(color: AppTheme.neonPurple),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () => _postToFightWire(card),
              ),
            ),
            const SizedBox(height: 8),

            // ── Send directly to fighters / promoters ────────────
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.groups, size: 18),
                label: const Text(
                  'SEND TO FIGHTERS & PROMOTERS',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.neonOrange,
                  side: const BorderSide(color: AppTheme.neonOrange),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () => _showSendDialog(card),
              ),
            ),
            const SizedBox(height: 8),

            // ── Share to Social Media ───────────────────────────
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.share, size: 18),
                label: const Text(
                  'SHARE TO SOCIAL MEDIA',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.neonCyan,
                  side: const BorderSide(color: AppTheme.neonCyan),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  final dateStr =
                      '${card.eventDate.day}/${card.eventDate.month}/${card.eventDate.year}';
                  ShareService.instance.shareFightCard(
                    cardId: card.id.isNotEmpty ? card.id : 'card',
                    eventName: card.eventName.isEmpty
                        ? 'Fight Card'
                        : card.eventName,
                    dateStr: dateStr,
                    venue: card.venue,
                  );
                },
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HEADER
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildHeader(FightCardTemplate card) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.secondaryBackground, AppTheme.primaryBackground],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.neonCyan.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          if (card.promotionName.isNotEmpty) ...[
            Text(
              card.promotionName.toUpperCase(),
              style: const TextStyle(
                color: AppTheme.neonCyan,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 8),
          ],
          Text(
            card.eventName.isEmpty ? 'UNTITLED EVENT' : card.eventName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 4,
            children: [
              _metaChip(Icons.calendar_today, _fmtDate(card.eventDate)),
              if (card.venue.isNotEmpty)
                _metaChip(Icons.location_on, card.venue),
              if (card.city.isNotEmpty)
                _metaChip(Icons.location_city, '${card.city}, ${card.country}'),
              _metaChip(Icons.sports_mma, card.sportType),
            ],
          ),
          if (card.sanctioningBody.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Sanctioned by ${card.sanctioningBody}',
              style: const TextStyle(
                color: Color(0xFFFFD700),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            '${card.totalBouts} BOUTS',
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metaChip(IconData icon, String text) {
    return Chip(
      avatar: Icon(icon, size: 14, color: AppTheme.textSecondary),
      label: Text(text, style: const TextStyle(fontSize: 11)),
      backgroundColor: AppTheme.surfaceColor,
      labelStyle: const TextStyle(color: AppTheme.textSecondary),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BOUT CARD
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildBoutCard(FightCardBout bout) {
    final isMain = bout.position == BoutPosition.mainEvent;
    final posColor = isMain
        ? const Color(0xFFFFD700)
        : bout.position == BoutPosition.semiMain
        ? AppTheme.neonOrange
        : AppTheme.neonCyan;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isMain ? const Color(0xFF1A1A2E) : AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: posColor, width: isMain ? 5 : 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Position + Title
          Row(
            children: [
              Text(
                bout.position.label,
                style: TextStyle(
                  color: posColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
              if (bout.titleFight != null && bout.titleFight!.isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    bout.titleFight!,
                    style: const TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),

          // Matchup
          Row(
            children: [
              // Red corner
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      bout.redCornerName.isEmpty ? 'TBA' : bout.redCornerName,
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: isMain ? 17 : 15,
                      ),
                      textAlign: TextAlign.right,
                    ),
                    if (bout.redCornerRecord.isNotEmpty)
                      Text(
                        '(${bout.redCornerRecord})',
                        style: TextStyle(
                          color: Colors.redAccent.withValues(alpha: 0.6),
                          fontSize: 11,
                        ),
                      ),
                    if (bout.redCornerGym.isNotEmpty)
                      Text(
                        bout.redCornerGym,
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 11,
                        ),
                        textAlign: TextAlign.right,
                      ),
                  ],
                ),
              ),

              // VS
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'VS',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontWeight: FontWeight.w900,
                    fontSize: isMain ? 18 : 14,
                  ),
                ),
              ),

              // Blue corner
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bout.blueCornerName.isEmpty ? 'TBA' : bout.blueCornerName,
                      style: TextStyle(
                        color: Colors.blueAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: isMain ? 17 : 15,
                      ),
                    ),
                    if (bout.blueCornerRecord.isNotEmpty)
                      Text(
                        '(${bout.blueCornerRecord})',
                        style: TextStyle(
                          color: Colors.blueAccent.withValues(alpha: 0.6),
                          fontSize: 11,
                        ),
                      ),
                    if (bout.blueCornerGym.isNotEmpty)
                      Text(
                        bout.blueCornerGym,
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Details
          Center(
            child: Text(
              [
                bout.weightClass,
                '${bout.rounds} × ${bout.roundMinutes} min',
                bout.rules,
                bout.sportType,
              ].where((s) => s.isNotEmpty).join('  •  '),
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PRINT
  // ═══════════════════════════════════════════════════════════════════════════
  void _printCard(FightCardTemplate card) {
    final svc = context.read<FightCardTemplateService>();
    final htmlContent = svc.generatePrintHtml(card);

    // Open in new window and trigger print
    final blob = web.Blob(
      [htmlContent.toJS].toJS,
      web.BlobPropertyBag(type: 'text/html'),
    );
    final url = web.URL.createObjectURL(blob);
    web.window.open(url, '_blank');
    // User can print from the opened tab via Ctrl+P
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DOWNLOAD
  // ═══════════════════════════════════════════════════════════════════════════
  void _downloadCard(FightCardTemplate card) {
    final svc = context.read<FightCardTemplateService>();
    final htmlContent = svc.generatePrintHtml(card);

    final blob = web.Blob(
      [htmlContent.toJS].toJS,
      web.BlobPropertyBag(type: 'text/html'),
    );
    final url = web.URL.createObjectURL(blob);

    final fileName = card.eventName.isEmpty
        ? 'fight_card.html'
        : '${card.eventName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_').toLowerCase()}_fight_card.html';

    web.HTMLAnchorElement()
      ..href = url
      ..download = fileName
      ..click();

    web.URL.revokeObjectURL(url);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fight card downloaded!'),
        backgroundColor: AppTheme.success,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SEND TO MEMBER
  // ═══════════════════════════════════════════════════════════════════════════
  void _showSendDialog(FightCardTemplate card) {
    final searchCtrl = TextEditingController();
    List<Map<String, dynamic>> results = [];
    bool searching = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDState) => AlertDialog(
          backgroundColor: AppTheme.cardBackground,
          title: const Row(
            children: [
              Icon(Icons.send, color: AppTheme.neonMagenta, size: 22),
              SizedBox(width: 8),
              Text(
                'SEND FIGHT CARD',
                style: TextStyle(
                  color: AppTheme.neonMagenta,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: searchCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search member by name...',
                    hintStyle: const TextStyle(color: AppTheme.textMuted),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppTheme.textMuted,
                    ),
                    suffixIcon: searching
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onChanged: (q) async {
                    if (q.length < 2) {
                      setDState(() => results = []);
                      return;
                    }
                    setDState(() => searching = true);
                    final svc = context.read<FightCardTemplateService>();
                    final r = await svc.searchUsers(q);
                    setDState(() {
                      results = r;
                      searching = false;
                    });
                  },
                ),
                const SizedBox(height: 12),
                if (results.isEmpty && searchCtrl.text.length >= 2)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      'No members found',
                      style: TextStyle(color: AppTheme.textMuted),
                    ),
                  ),
                ...results.map(
                  (user) => ListTile(
                    leading: DfcCircleAvatar(
                      imageUrl: user['photoUrl'] as String?,
                      backgroundColor: AppTheme.surfaceColor,
                      fallbackIconColor: AppTheme.textSecondary,
                    ),
                    title: Text(
                      user['displayName'] ?? '',
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      user['role'] ?? '',
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 12,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.send,
                      color: AppTheme.neonMagenta,
                      size: 18,
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      _sendToUser(card, user);
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendToUser(
    FightCardTemplate card,
    Map<String, dynamic> user,
  ) async {
    if (card.id.isEmpty || card.id == 'preview') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Save the fight card first before sending'),
          backgroundColor: AppTheme.warning,
        ),
      );
      return;
    }

    setState(() => _sending = true);
    final svc = context.read<FightCardTemplateService>();
    final ok = await svc.shareCard(card.id, user['id']);
    setState(() => _sending = false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Fight card sent to ${user['displayName']}!' : 'Failed to send',
        ),
        backgroundColor: ok ? AppTheme.success : AppTheme.error,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // POST TO FIGHTWIRE
  // ═══════════════════════════════════════════════════════════════════════════
  Future<void> _postToFightWire(FightCardTemplate card) async {
    final sorted = card.sortedBouts;
    final buffer = StringBuffer();

    buffer.writeln('🥊 FIGHT CARD ANNOUNCEMENT');
    buffer.writeln('═══════════════════════════');
    if (card.promotionName.isNotEmpty) buffer.writeln(card.promotionName);
    buffer.writeln('📢 ${card.eventName}');
    buffer.writeln('📅 ${_fmtDate(card.eventDate)}');
    if (card.venue.isNotEmpty) {
      buffer.writeln('📍 ${card.venue}, ${card.city}, ${card.country}');
    }
    buffer.writeln();

    for (final bout in sorted) {
      final isTitle = bout.titleFight != null && bout.titleFight!.isNotEmpty;
      buffer.write(bout.position.label);
      if (isTitle) buffer.write(' — ${bout.titleFight}');
      buffer.writeln();
      buffer.writeln(
        '🔴 ${bout.redCornerName.isEmpty ? "TBA" : bout.redCornerName} ${bout.redCornerRecord.isEmpty ? "" : "(${bout.redCornerRecord})"}',
      );
      buffer.writeln('  VS');
      buffer.writeln(
        '🔵 ${bout.blueCornerName.isEmpty ? "TBA" : bout.blueCornerName} ${bout.blueCornerRecord.isEmpty ? "" : "(${bout.blueCornerRecord})"}',
      );
      buffer.writeln(
        '${bout.weightClass} • ${bout.rounds}×${bout.roundMinutes}min • ${bout.rules}',
      );
      buffer.writeln();
    }

    buffer.writeln('#FightCard #${card.sportType.replaceAll(' ', '')} #DFC');

    // Post via SocialService
    try {
      final auth = context.read<AuthService>();
      final uid = auth.currentUser?.uid ?? 'anonymous';
      final socialSvc = Provider.of<SocialService>(context, listen: false);
      await socialSvc.createPost(authorId: uid, content: buffer.toString());

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fight card posted to FightWire! 🥊'),
          backgroundColor: AppTheme.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to post: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // UTILITIES
  // ═══════════════════════════════════════════════════════════════════════════
  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}
