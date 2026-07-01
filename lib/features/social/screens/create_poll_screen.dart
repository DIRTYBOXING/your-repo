import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../shared/services/auth_service.dart';
import '../../../shared/services/social_service.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// CREATE POLL SCREEN — Full-screen poll composer
///
/// • Question input with character counter
/// • 2–6 dynamic option fields
/// • Single/multi-select toggle
/// • Duration picker (1h, 6h, 24h, 3d, 7d)
/// • Posts via SocialService.createPoll()
/// ═══════════════════════════════════════════════════════════════════════════
class CreatePollScreen extends StatefulWidget {
  const CreatePollScreen({super.key});

  @override
  State<CreatePollScreen> createState() => _CreatePollScreenState();
}

class _CreatePollScreenState extends State<CreatePollScreen> {
  final _questionController = TextEditingController();
  final List<TextEditingController> _optionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];
  bool _allowMultiple = false;
  bool _posting = false;
  int _durationIndex = 2; // default 24h

  static const _maxOptions = 6;
  static const _maxOptionChars = 80;
  static const _durations = [
    ('1h', Duration(hours: 1)),
    ('6h', Duration(hours: 6)),
    ('24h', Duration(hours: 24)),
    ('3d', Duration(days: 3)),
    ('7d', Duration(days: 7)),
  ];

  @override
  void dispose() {
    _questionController.dispose();
    for (final c in _optionControllers) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _canPost {
    if (_posting) return false;
    if (_questionController.text.trim().isEmpty) return false;
    final filledOptions = _optionControllers
        .where((c) => c.text.trim().isNotEmpty)
        .length;
    return filledOptions >= 2;
  }

  void _addOption() {
    if (_optionControllers.length >= _maxOptions) return;
    setState(() => _optionControllers.add(TextEditingController()));
  }

  void _removeOption(int index) {
    if (_optionControllers.length <= 2) return;
    setState(() {
      _optionControllers[index].dispose();
      _optionControllers.removeAt(index);
    });
  }

  Future<void> _submit() async {
    if (!_canPost) return;
    setState(() => _posting = true);
    HapticFeedback.mediumImpact();

    final auth = context.read<AuthService>();
    final social = context.read<SocialService>();
    final user = auth.currentUser;
    final userModel = auth.userModel;
    final userId =
        user?.uid ?? (auth.isDemoUser ? AuthService.demoUserId : null);

    if (userId == null) {
      setState(() => _posting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please sign in to create a poll'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      final options = _optionControllers
          .map((c) => c.text.trim())
          .where((t) => t.isNotEmpty)
          .toList();

      await social.createPoll(
        authorId: userId,
        question: _questionController.text.trim(),
        options: options,
        displayName: userModel?.displayName ?? user?.displayName,
        role: userModel?.role.name,
        avatarUrl: userModel?.photoUrl ?? user?.photoURL,
        allowMultiple: _allowMultiple,
        duration: _durations[_durationIndex].$2,
      );

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _posting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $e'),
            backgroundColor: DesignTokens.neonRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgSecondary,
        title: const Text(
          'Create Poll',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white54),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: _canPost ? _submit : null,
              child: Text(
                _posting ? 'POSTING...' : 'POST POLL',
                style: TextStyle(
                  color: _canPost ? DesignTokens.neonCyan : Colors.white24,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Question ──
          _buildLabel('QUESTION'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _questionController,
            hint: 'Ask the community something...',
            maxLines: 3,
          ),
          const SizedBox(height: 20),

          // ── Options ──
          _buildLabel('OPTIONS'),
          const SizedBox(height: 8),
          ...List.generate(_optionControllers.length, (i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: DesignTokens.neonCyan.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: DesignTokens.neonCyan.withValues(alpha: 0.25),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(
                        color: DesignTokens.neonCyan,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTextField(
                      controller: _optionControllers[i],
                      hint: 'Option ${i + 1}',
                      maxLength: _maxOptionChars,
                    ),
                  ),
                  if (_optionControllers.length > 2)
                    IconButton(
                      icon: Icon(
                        Icons.remove_circle_outline,
                        color: DesignTokens.neonRed.withValues(alpha: 0.6),
                        size: 20,
                      ),
                      onPressed: () => _removeOption(i),
                    ),
                ],
              ),
            );
          }),
          if (_optionControllers.length < _maxOptions)
            GestureDetector(
              onTap: _addOption,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add, color: DesignTokens.neonCyan, size: 18),
                    SizedBox(width: 6),
                    Text(
                      'Add Option',
                      style: TextStyle(
                        color: DesignTokens.neonCyan,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 24),

          // ── Duration ──
          _buildLabel('DURATION'),
          const SizedBox(height: 8),
          Row(
            children: List.generate(_durations.length, (i) {
              final selected = _durationIndex == i;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _durationIndex = i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? DesignTokens.neonCyan.withValues(alpha: 0.15)
                          : Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected
                            ? DesignTokens.neonCyan.withValues(alpha: 0.4)
                            : Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Text(
                      _durations[i].$1,
                      style: TextStyle(
                        color: selected
                            ? DesignTokens.neonCyan
                            : Colors.white54,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 20),

          // ── Multi-select toggle ──
          GestureDetector(
            onTap: () => setState(() => _allowMultiple = !_allowMultiple),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
                border: Border.all(
                  color: _allowMultiple
                      ? DesignTokens.neonCyan.withValues(alpha: 0.3)
                      : Colors.white.withValues(alpha: 0.08),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _allowMultiple
                        ? Icons.check_box
                        : Icons.check_box_outline_blank,
                    color: _allowMultiple
                        ? DesignTokens.neonCyan
                        : Colors.white30,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Allow multiple selections',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.4),
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLength = 300,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLength: maxLength,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.25)),
        counterStyle: TextStyle(
          color: Colors.white.withValues(alpha: 0.2),
          fontSize: 10,
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.04),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
          borderSide: BorderSide(
            color: DesignTokens.neonCyan.withValues(alpha: 0.4),
          ),
        ),
      ),
    );
  }
}
