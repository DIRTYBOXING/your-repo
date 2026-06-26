import 'dart:async';
import 'package:flutter/material.dart';
import '../genie_persona.dart';
import '../genie_api_service.dart';
import '../../../core/theme/design_tokens.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// BOT CHAT SCREEN — Dedicated chat page for a single AI bot persona.
///
/// Unlike the old GenieChatScreen (shared between all bots), this screen
/// is locked to ONE persona with a themed header, accent colours, and
/// no persona‑switcher.  Navigated to from the AI Bot Hub.
/// ═══════════════════════════════════════════════════════════════════════════
class BotChatScreen extends StatefulWidget {
  final GeniePersona persona;
  const BotChatScreen({super.key, required this.persona});

  @override
  State<BotChatScreen> createState() => _BotChatScreenState();
}

class _BotChatScreenState extends State<BotChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final List<_Msg> _messages = [];
  bool _isTyping = false;

  GeniePersona get bot => widget.persona;

  @override
  void initState() {
    super.initState();
    _messages.add(
      _Msg(
        text:
            'Hey, I\'m ${bot.displayName}. I can help with training, mindset, recovery, or app steps.\n\nWhat do you want to work on first?',
        isUser: false,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  // ── Send ──────────────────────────────────────────────────────────────────
  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(_Msg(text: text, isUser: true));
      _isTyping = true;
    });
    _controller.clear();
    _scrollDown();

    // Hide typing indicator after 0.8 seconds for instant feel
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted && _isTyping) {
        setState(() => _isTyping = false);
      }
    });

    try {
      final reply = await GenieApiService.askGenie(text, persona: bot).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Request took too long');
        },
      );
      if (!mounted) return;
      setState(() {
        _messages.add(_Msg(text: reply, isUser: false));
        _isTyping = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(
          _Msg(
            text: e.toString().contains('Timeout')
                ? 'Taking too long. Try again?'
                : 'Connection trouble — try again in a sec.',
            isUser: false,
            isError: true,
          ),
        );
        _isTyping = false;
      });
    }
    _scrollDown();
  }

  void _scrollDown() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final accent = bot.accentColor;
    return PopScope(
      child: Scaffold(
        backgroundColor: DesignTokens.bgPrimary,
        appBar: _buildAppBar(accent),
        body: Column(
          children: [
            Expanded(child: _buildMessages(accent)),
            if (_isTyping) _typingIndicator(accent),
            _inputBar(accent),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(Color accent) {
    return AppBar(
      backgroundColor: DesignTokens.bgSecondary,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Row(
        children: [
          _avatar(accent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bot.displayName,
                  style: TextStyle(
                    color: accent,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  bot.description.length > 40
                      ? '${bot.description.substring(0, 40)}...'
                      : bot.description,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.info_outline, color: accent.withValues(alpha: 0.6)),
          onPressed: _showBotInfo,
        ),
      ],
    );
  }

  // ── Messages List ─────────────────────────────────────────────────────────
  Widget _buildMessages(Color accent) {
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      itemCount: _messages.length,
      itemBuilder: (context, i) {
        final msg = _messages[i];
        return _bubble(msg, accent);
      },
    );
  }

  Widget _bubble(_Msg msg, Color accent) {
    final isUser = msg.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[_avatar(accent, size: 30), const SizedBox(width: 8)],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser
                    ? accent.withValues(alpha: 0.18)
                    : msg.isError
                    ? Colors.red.withValues(alpha: 0.12)
                    : Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                border: Border.all(
                  color: isUser
                      ? accent.withValues(alpha: 0.25)
                      : msg.isError
                      ? Colors.red.withValues(alpha: 0.25)
                      : Colors.white.withValues(alpha: 0.06),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isUser)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        bot.displayName,
                        style: TextStyle(
                          color: accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  Text(
                    msg.text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 15,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              child: const Icon(Icons.person, color: Colors.white54, size: 18),
            ),
          ],
        ],
      ),
    );
  }

  // ── Typing indicator ──────────────────────────────────────────────────────
  Widget _typingIndicator(Color accent) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 6),
      child: Row(
        children: [
          _avatar(accent, size: 24),
          const SizedBox(width: 8),
          _dot(accent, 0),
          _dot(accent, 150),
          _dot(accent, 300),
          const SizedBox(width: 6),
          Text(
            '${bot.displayName} is thinking...',
            style: TextStyle(
              color: accent.withValues(alpha: 0.5),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(Color c, int delayMs) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      builder: (_, v, _) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: c.withValues(alpha: v),
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  // ── Input bar ─────────────────────────────────────────────────────────────
  Widget _inputBar(Color accent) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        decoration: BoxDecoration(
          color: DesignTokens.bgSecondary,
          border: Border(
            top: BorderSide(color: accent.withValues(alpha: 0.12)),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                maxLines: null,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Message ${bot.displayName}...',
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                ),
                onSubmitted: (_) => _send(),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _send,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent,
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.4),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.send_rounded,
                  color: Colors.black,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Avatar helper ─────────────────────────────────────────────────────────
  Widget _avatar(Color accent, {double size = 36}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: accent.withValues(alpha: 0.15),
        border: Border.all(color: accent.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Center(
        child: bot.emoji.isNotEmpty
            ? Text(bot.emoji, style: TextStyle(fontSize: size * 0.5))
            : Icon(bot.icon, color: accent, size: size * 0.5),
      ),
    );
  }

  // ── Bot info sheet ────────────────────────────────────────────────────────
  void _showBotInfo() {
    final accent = bot.accentColor;
    showModalBottomSheet(
      context: context,
      backgroundColor: DesignTokens.bgSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _avatar(accent, size: 60),
            const SizedBox(height: 14),
            Text(
              bot.displayName,
              style: TextStyle(
                color: accent,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              bot.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: accent.withValues(alpha: 0.15)),
              ),
              child: Text(
                '"${bot.quote}"',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: accent.withValues(alpha: 0.8),
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Style: ${bot.style}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.35),
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ── Message Model ───────────────────────────────────────────────────────────
class _Msg {
  final String text;
  final bool isUser;
  final bool isError;
  _Msg({required this.text, required this.isUser, this.isError = false});
}
