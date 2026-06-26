import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/smartcoach_provider.dart';
import '../../../core/theme/design_tokens.dart';
import '../../smartcoach/widgets/record_button.dart';

class SmartCoachScreen extends ConsumerStatefulWidget {
  const SmartCoachScreen({super.key});

  @override
  ConsumerState<SmartCoachScreen> createState() => _SmartCoachScreenState();
}

class _SmartCoachScreenState extends ConsumerState<SmartCoachScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, String>> _messages = [
    {
      "role": "coach",
      "text":
          "Neural Coach initialized. Upload your sparring footage, describe your upcoming opponent, or ask for a weight cut protocol. What are we working on today?",
    },
  ];
  bool _isTyping = false;
  bool _isRecording = false;

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({"role": "user", "text": text});
      _isTyping = true;
    });

    _controller.clear();
    _scrollToBottom();

    final reply = await ref.read(smartCoachProvider(text).future);

    if (!mounted) return;

    setState(() {
      _isTyping = false;
      _messages.add({"role": "coach", "text": reply});
    });
    _scrollToBottom();
  }

  Future<void> _sendAudio() async {
    setState(() {
      _messages.add({"role": "user", "text": "🎤 Processing voice note..."});
      _isTyping = true;
    });
    _scrollToBottom();

    // Simulate processing delay
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _messages.last = {"role": "user", "text": "🎤 Voice note (0:04)"};
    });

    final reply = await ref.read(
      smartCoachProvider("Audio transcript: How do I cut 5 lbs safely?").future,
    );

    if (!mounted) return;
    setState(() {
      _isTyping = false;
      _messages.add({"role": "coach", "text": reply});
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgPrimary,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: DesignTokens.neonMagenta.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: DesignTokens.neonMagenta.withValues(alpha: 0.5),
                ),
              ),
              child: const Icon(
                Icons.psychology,
                color: DesignTokens.neonMagenta,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "SMART COACH",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                Text(
                  "AI Combat Analytics",
                  style: TextStyle(
                    color: DesignTokens.neonMagenta,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (_, i) {
                if (i == _messages.length && _isTyping) {
                  return _buildTypingIndicator();
                }
                final msg = _messages[i];
                final isUser = msg["role"] == "user";

                return Align(
                  alignment: isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.all(16),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    decoration: BoxDecoration(
                      color: isUser
                          ? DesignTokens.neonCyan.withValues(alpha: 0.1)
                          : DesignTokens.bgCard,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isUser ? 16 : 4),
                        bottomRight: Radius.circular(isUser ? 4 : 16),
                      ),
                      border: Border.all(
                        color: isUser
                            ? DesignTokens.neonCyan.withValues(alpha: 0.3)
                            : DesignTokens.neonMagenta.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      msg["text"]!,
                      style: TextStyle(
                        color: isUser
                            ? Colors.white
                            : DesignTokens.textSecondary,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Input Bar
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: MediaQuery.of(context).padding.bottom + 12,
            ),
            decoration: const BoxDecoration(
              color: DesignTokens.bgCard,
              border: Border(top: BorderSide(color: Colors.white10)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _isRecording
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.mic, color: Colors.redAccent),
                            const SizedBox(width: 8),
                            Text(
                              "Recording...",
                              style: TextStyle(
                                color: Colors.redAccent.withValues(alpha: 0.8),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const _AudioWaveform(),
                          ],
                        )
                      : TextField(
                          controller: _controller,
                          onChanged: (val) => setState(() {}),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          decoration: InputDecoration(
                            hintText: "Ask your AI coach...",
                            hintStyle: const TextStyle(
                              color: DesignTokens.textMuted,
                            ),
                            filled: true,
                            fillColor: DesignTokens.bgPrimary,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onSubmitted: (_) => _send(),
                        ),
                ),
                const SizedBox(width: 8),
                _controller.text.isNotEmpty
                    ? GestureDetector(
                        onTap: _send,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: DesignTokens.neonMagenta,
                          ),
                          child: const Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      )
                    : RecordButton(
                        onRecordStart: () =>
                            setState(() => _isRecording = true),
                        onRecordStop: () {
                          setState(() => _isRecording = false);
                          _sendAudio();
                        },
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: DesignTokens.bgCard,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
          ),
          border: Border.all(
            color: DesignTokens.neonMagenta.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: DesignTokens.neonMagenta,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              "Coach is analyzing...",
              style: TextStyle(
                color: DesignTokens.textMuted,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AudioWaveform extends StatefulWidget {
  const _AudioWaveform();

  @override
  State<_AudioWaveform> createState() => _AudioWaveformState();
}

class _AudioWaveformState extends State<_AudioWaveform>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            // Stagger the animation timing for each bar
            final t = (_controller.value + (index * 0.2)) % 1.0;
            final height = 8.0 + 12.0 * math.sin(t * math.pi);

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 3,
              height: height,
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.redAccent.withValues(alpha: 0.5),
                    blurRadius: 4,
                  ),
                ],
              ),
            );
          },
        );
      }),
    );
  }
}
