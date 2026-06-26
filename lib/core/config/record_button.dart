import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/design_tokens.dart';

class RecordButton extends StatefulWidget {
  final VoidCallback onRecordStart;
  final VoidCallback onRecordStop;

  const RecordButton({
    super.key,
    required this.onRecordStart,
    required this.onRecordStop,
  });

  @override
  State<RecordButton> createState() => _RecordButtonState();
}

class _RecordButtonState extends State<RecordButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startRecording(LongPressStartDetails details) {
    HapticFeedback.heavyImpact();
    Future.delayed(
      const Duration(milliseconds: 120),
      () => HapticFeedback.lightImpact(),
    );
    setState(() => _isRecording = true);
    _controller.repeat(reverse: true);
    widget.onRecordStart();
  }

  void _stopRecording() {
    if (!_isRecording) return;
    HapticFeedback.selectionClick();
    setState(() => _isRecording = false);
    _controller.stop();
    _controller.reset();
    widget.onRecordStop();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: _startRecording,
      onLongPressEnd: (details) => _stopRecording(),
      onLongPressCancel: _stopRecording,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final scale = _isRecording ? 1.1 + (_controller.value * 0.15) : 1.0;
          final glowOpacity = _isRecording
              ? 0.4 + (_controller.value * 0.6)
              : 0.0;

          return Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: _isRecording
                  ? [
                      BoxShadow(
                        color: Colors.greenAccent.withValues(
                          alpha: glowOpacity,
                        ),
                        blurRadius: 16,
                        spreadRadius: 4,
                      ),
                    ]
                  : [],
            ),
            child: Transform.scale(
              scale: scale,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isRecording ? Colors.redAccent : DesignTokens.bgCard,
                  border: Border.all(
                    color: _isRecording
                        ? Colors.greenAccent.withValues(alpha: 0.8)
                        : DesignTokens.neonMagenta.withValues(alpha: 0.5),
                    width: _isRecording ? 3 : 1,
                  ),
                ),
                child: Icon(
                  Icons.mic,
                  color: _isRecording ? Colors.white : DesignTokens.neonMagenta,
                  size: 20,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
