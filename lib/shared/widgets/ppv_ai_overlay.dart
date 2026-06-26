import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/design_tokens.dart';
import '../models/ppv_model.dart';
import '../services/ppv_ai_service.dart';

// ═════════════════════════════════════════════════════════════════════════════
// PPV AI OVERLAY — DFC Intelligence Interface
// ═════════════════════════════════════════════════════════════════════════════
//
// Slides up from bottom as a draggable sheet. Full chat UI with:
//   • Neon DFC branding + glowing header
//   • AI message bubbles (dark card + neon border)
//   • User message bubbles (neon cyan accent)
//   • Event cards (poster + title + price + CTA)
//   • Fighter stat chips
//   • Quick-reply chips above input
//   • Typing indicator (3-dot pulse)
//
// Usage:
//   PpvAiOverlay.show(context, onNavigate: (route) { ... })
//
// ═════════════════════════════════════════════════════════════════════════════

class PpvAiOverlay extends StatefulWidget {
  final void Function(String route)? onNavigate;

  const PpvAiOverlay({super.key, this.onNavigate});

  /// Show the overlay as a modal bottom sheet
  static Future<void> show(
    BuildContext context, {
    void Function(String route)? onNavigate,
  }) {
    final service = PpvAiService();
    service.startSession();

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (_) => PpvAiOverlay(onNavigate: onNavigate),
    );
  }

  @override
  State<PpvAiOverlay> createState() => _PpvAiOverlayState();
}

class _PpvAiOverlayState extends State<PpvAiOverlay>
    with TickerProviderStateMixin {
  final PpvAiService _service = PpvAiService();
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  late AnimationController _glowCtrl;
  late Animation<double> _glowAnim;
  late AnimationController _slideCtrl;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(
      begin: 0.4,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));
    _slideCtrl.forward();
    _service.addListener(_onServiceUpdate);
  }

  @override
  void dispose() {
    _service.removeListener(_onServiceUpdate);
    _glowCtrl.dispose();
    _slideCtrl.dispose();
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onServiceUpdate() {
    if (!mounted) return;
    setState(() {});
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _send([String? text]) {
    final msg = (text ?? _inputCtrl.text).trim();
    if (msg.isEmpty) return;
    HapticFeedback.lightImpact();
    _inputCtrl.clear();
    _service.sendMessage(msg);
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return SlideTransition(
      position: _slideAnim,
      child: Container(
        height: screenHeight * 0.82,
        decoration: BoxDecoration(
          color: DesignTokens.bgPrimary,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(
            color: DesignTokens.neonCyan.withValues(alpha: 0.25),
          ),
          boxShadow: [
            BoxShadow(
              color: DesignTokens.neonCyan.withValues(alpha: 0.12),
              blurRadius: 40,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildHandle(),
            _buildHeader(),
            const Divider(height: 1, color: Color(0x1AFFFFFF)),
            Expanded(child: _buildMessageList()),
            if (_service.isThinking) _buildTypingIndicator(),
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  // ── Handle ────────────────────────────────────────────────────────────────

  Widget _buildHandle() {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 10, bottom: 6),
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: DesignTokens.neonCyan.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (_, _) => Container(
        padding: const EdgeInsets.fromLTRB(16, 4, 12, 12),
        child: Row(
          children: [
            // AI glyph
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    DesignTokens.neonCyan.withValues(
                      alpha: 0.25 * _glowAnim.value,
                    ),
                    DesignTokens.bgPrimary,
                  ],
                ),
                border: Border.all(
                  color: DesignTokens.neonCyan.withValues(
                    alpha: 0.6 * _glowAnim.value,
                  ),
                  width: 1.2,
                ),
              ),
              child: Icon(
                Icons.psychology_outlined,
                color: DesignTokens.neonCyan.withValues(alpha: _glowAnim.value),
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DFC INTELLIGENCE',
                  style: TextStyle(
                    color: DesignTokens.neonCyan,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    shadows: [
                      Shadow(
                        color: DesignTokens.neonCyan.withValues(
                          alpha: 0.6 * _glowAnim.value,
                        ),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
                const Text(
                  'PPV · Events · Fighters · Support',
                  style: TextStyle(
                    color: DesignTokens.textMuted,
                    fontSize: 10,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
            const Spacer(),
            // Reset
            GestureDetector(
              onTap: () {
                _service.reset();
                _service.startSession();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: DesignTokens.neonCyan.withValues(alpha: 0.25),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'RESET',
                  style: TextStyle(
                    color: DesignTokens.neonCyan.withValues(alpha: 0.6),
                    fontSize: 9,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: const Icon(Icons.close, color: DesignTokens.textMuted, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  // ── Message list ──────────────────────────────────────────────────────────

  Widget _buildMessageList() {
    final messages = _service.messages;
    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: messages.length,
      itemBuilder: (_, i) => _buildMessage(messages[i]),
    );
  }

  Widget _buildMessage(PpvAiMessage msg) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: msg.isUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          // Bubble
          _buildBubble(msg),

          // Event cards
          if (msg.events.isNotEmpty) ...[
            const SizedBox(height: 10),
            _buildEventCards(msg.events),
          ],

          // Fighter chips
          if (msg.fighters.isNotEmpty) ...[
            const SizedBox(height: 10),
            _buildFighterChips(msg.fighters),
          ],

          // Quick replies
          if (!msg.isUser && msg.quickReplies.isNotEmpty) ...[
            const SizedBox(height: 10),
            _buildQuickReplies(msg.quickReplies),
          ],
        ],
      ),
    );
  }

  Widget _buildBubble(PpvAiMessage msg) {
    if (msg.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.72,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                DesignTokens.neonCyan.withValues(alpha: 0.18),
                DesignTokens.neonCyan.withValues(alpha: 0.08),
              ],
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(4),
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
            border: Border.all(
              color: DesignTokens.neonCyan.withValues(alpha: 0.4),
              width: 0.8,
            ),
          ),
          child: Text(
            msg.text,
            style: const TextStyle(
              color: DesignTokens.textPrimary,
              fontSize: 13.5,
              height: 1.45,
            ),
          ),
        ),
      );
    }

    // AI bubble
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.84,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1520),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(4),
          topRight: Radius.circular(16),
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
        border: Border.all(
          color: DesignTokens.neonCyan.withValues(alpha: 0.18),
          width: 0.8,
        ),
      ),
      child: Text(
        msg.text,
        style: TextStyle(
          color: DesignTokens.textPrimary.withValues(alpha: 0.9),
          fontSize: 13.5,
          height: 1.55,
        ),
      ),
    );
  }

  // ── Event cards ───────────────────────────────────────────────────────────

  Widget _buildEventCards(List<PPVEvent> events) {
    return SizedBox(
      height: 190,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: events.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (_, i) => _buildEventCard(events[i]),
      ),
    );
  }

  Widget _buildEventCard(PPVEvent e) {
    final price = e.standardPriceCents == 0
        ? 'FREE'
        : _formatPrice(e.standardPriceCents, e.currency);
    final statusColor = switch (e.status) {
      PPVStatus.live => DesignTokens.neonRed,
      PPVStatus.onSale => DesignTokens.neonGreen,
      PPVStatus.presale => DesignTokens.neonAmber,
      _ => DesignTokens.textMuted,
    };
    final statusLabel = switch (e.status) {
      PPVStatus.live => 'LIVE',
      PPVStatus.onSale => 'ON SALE',
      PPVStatus.presale => 'PRESALE',
      PPVStatus.announced => 'ANNOUNCED',
      _ => e.status.name.toUpperCase(),
    };

    return Container(
      width: 158,
      decoration: BoxDecoration(
        color: const Color(0xFF0A1020),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: DesignTokens.neonCyan.withValues(alpha: 0.22),
          width: 0.9,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Poster
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
            child: SizedBox(
              height: 90,
              width: double.infinity,
              child: e.posterUrl != null
                  ? Image.network(
                      e.posterUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _placeholderPoster(),
                    )
                  : _placeholderPoster(),
            ),
          ),

          // Info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(9, 7, 9, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status chip
                  Row(
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: statusColor,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Title
                  Text(
                    e.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: DesignTokens.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                  const Spacer(),
                  // Price + sport
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        price,
                        style: const TextStyle(
                          color: DesignTokens.neonGreen,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (e.sport != null)
                        Text(
                          e.sport!.toUpperCase(),
                          style: TextStyle(
                            color: DesignTokens.neonAmber.withValues(
                              alpha: 0.75,
                            ),
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholderPoster() {
    return Container(
      color: const Color(0xFF0D1828),
      child: Center(
        child: Icon(
          Icons.sports_mma,
          color: DesignTokens.neonCyan.withValues(alpha: 0.2),
          size: 28,
        ),
      ),
    );
  }

  // ── Fighter chips ─────────────────────────────────────────────────────────

  Widget _buildFighterChips(List<Map<String, dynamic>> fighters) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: fighters.map((f) {
        final name = f['name'] ?? f['displayName'] ?? '—';
        final record = '${f['wins'] ?? 0}-${f['losses'] ?? 0}';
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFF0D1520),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: DesignTokens.neonMagenta.withValues(alpha: 0.35),
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.person_outline,
                size: 13,
                color: DesignTokens.neonMagenta.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 5),
              Text(
                name,
                style: const TextStyle(
                  color: DesignTokens.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                record,
                style: TextStyle(
                  color: DesignTokens.neonAmber.withValues(alpha: 0.8),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ── Quick replies ─────────────────────────────────────────────────────────

  Widget _buildQuickReplies(List<String> replies) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: replies.map((r) {
        return GestureDetector(
          onTap: () => _send(r),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(
                color: DesignTokens.neonAmber.withValues(alpha: 0.5),
                width: 0.9,
              ),
              borderRadius: BorderRadius.circular(20),
              color: DesignTokens.neonAmber.withValues(alpha: 0.06),
            ),
            child: Text(
              r,
              style: TextStyle(
                color: DesignTokens.neonAmber.withValues(alpha: 0.9),
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Typing indicator ──────────────────────────────────────────────────────

  Widget _buildTypingIndicator() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 0, 8),
      child: Row(
        children: [
          _Dot(delay: 0),
          SizedBox(width: 4),
          _Dot(delay: 150),
          SizedBox(width: 4),
          _Dot(delay: 300),
          SizedBox(width: 8),
          Text(
            'DFC Intelligence is thinking…',
            style: TextStyle(
              color: DesignTokens.textMuted,
              fontSize: 11,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  // ── Input bar ─────────────────────────────────────────────────────────────

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        12,
        10,
        12,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: DesignTokens.bgPrimary,
        border: Border(
          top: BorderSide(
            color: DesignTokens.neonCyan.withValues(alpha: 0.12),
            width: 0.8,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF0D1520),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: DesignTokens.neonCyan.withValues(alpha: 0.22),
                  width: 0.8,
                ),
              ),
              child: TextField(
                controller: _inputCtrl,
                style: const TextStyle(
                  color: DesignTokens.textPrimary,
                  fontSize: 13.5,
                ),
                decoration: InputDecoration(
                  hintText: 'Ask anything about PPV…',
                  hintStyle: TextStyle(
                    color: DesignTokens.textMuted.withValues(alpha: 0.5),
                    fontSize: 13,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                maxLines: null,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _send,
            child: AnimatedBuilder(
              animation: _glowAnim,
              builder: (_, _) => Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      DesignTokens.neonCyan.withValues(alpha: 0.85),
                      DesignTokens.neonCyan.withValues(alpha: 0.55),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: DesignTokens.neonCyan.withValues(
                        alpha: 0.35 * _glowAnim.value,
                      ),
                      blurRadius: 14,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.send_rounded,
                  color: Color(0xFF050A14),
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _formatPrice(int cents, String currency) {
    if (cents == 0) return 'FREE';
    final symbol = switch (currency.toUpperCase()) {
      'AUD' => 'A\$',
      'USD' => '\$',
      'NZD' => 'NZ\$',
      _ => '\$',
    };
    final dollars = cents / 100;
    return '$symbol${dollars.toStringAsFixed(dollars == dollars.truncate() ? 0 : 2)}';
  }
}

// ── Pulsing dot (typing indicator) ────────────────────────────────────────────

class _Dot extends StatefulWidget {
  final int delay;
  const _Dot({required this.delay});

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
    _anim = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, _) => Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: DesignTokens.neonCyan.withValues(alpha: _anim.value),
        ),
      ),
    );
  }
}
