import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/design_tokens.dart';

/// AI Quick Edit — Paste content, pick a transform, get refined output.
class AiQuickEditScreen extends StatefulWidget {
  const AiQuickEditScreen({super.key});

  @override
  State<AiQuickEditScreen> createState() => _AiQuickEditScreenState();
}

class _AiQuickEditScreenState extends State<AiQuickEditScreen> {
  final _inputCtrl = TextEditingController();
  String _output = '';
  String _selectedAction = 'Make Punchier';
  bool _processing = false;

  static const _actions = <_EditAction>[
    _EditAction(
      'Make Punchier',
      Icons.flash_on,
      DesignTokens.neonRed,
      'Add energy & impact — perfect for fight hype',
    ),
    _EditAction(
      'Shorten',
      Icons.compress,
      DesignTokens.neonAmber,
      'Trim to essentials, keep the punch',
    ),
    _EditAction(
      'Expand',
      Icons.open_in_full,
      DesignTokens.neonCyan,
      'Add detail, context, and flow',
    ),
    _EditAction(
      'Fix Grammar',
      Icons.spellcheck,
      DesignTokens.neonGreen,
      'Clean up spelling, grammar, and clarity',
    ),
    _EditAction(
      'Fight Hype',
      Icons.local_fire_department,
      DesignTokens.neonMagenta,
      'Turn any text into fight promotion copy',
    ),
    _EditAction(
      'Professional',
      Icons.business_center,
      DesignTokens.neonGold,
      'Press-release / sponsorship-ready tone',
    ),
  ];

  @override
  void dispose() {
    _inputCtrl.dispose();
    super.dispose();
  }

  Future<void> _runEdit() async {
    if (_inputCtrl.text.trim().isEmpty) return;
    setState(() {
      _processing = true;
      _output = '';
    });
    // Simulated AI transform — in production, call Vertex AI / Cloud Function
    await Future.delayed(const Duration(milliseconds: 800));
    setState(() {
      _processing = false;
      _output = _simulateTransform(_inputCtrl.text.trim(), _selectedAction);
    });
  }

  String _simulateTransform(String input, String action) {
    switch (action) {
      case 'Shorten':
        final words = input.split(' ');
        return words.length > 6
            ? '${words.take(words.length ~/ 2).join(' ')}.'
            : input;
      case 'Make Punchier':
        return '🔥 ${input.toUpperCase()} 🔥';
      case 'Fight Hype':
        return '⚡ BREAKING: $input — You do NOT want to miss this! #DFC #FightNight';
      case 'Professional':
        return 'We are pleased to announce: $input. For press inquiries, contact media@datafightcentral.com.';
      case 'Expand':
        return '$input\n\nThis represents a significant development in the combat sports landscape that fans and industry insiders have been watching closely.';
      case 'Fix Grammar':
        return input.replaceAll('  ', ' ').trim();
      default:
        return input;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgSecondary,
        title: const Text(
          'Quick Edit',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: DesignTokens.neonCyan),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Input ──
            TextField(
              controller: _inputCtrl,
              maxLines: 5,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Paste or type your content here...',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                ),
                filled: true,
                fillColor: DesignTokens.bgCard,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Action Chips ──
            Text(
              'TRANSFORM',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _actions
                  .map(
                    (a) => _ActionChip(
                      action: a,
                      selected: _selectedAction == a.label,
                      onTap: () => setState(() => _selectedAction = a.label),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),

            // ── Go Button ──
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: _processing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.auto_fix_high),
                label: Text(_processing ? 'Processing...' : 'Apply Edit'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: DesignTokens.neonCyan,
                  foregroundColor: DesignTokens.bgPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _processing ? null : _runEdit,
              ),
            ),
            const SizedBox(height: 20),

            // ── Output ──
            if (_output.isNotEmpty) ...[
              Row(
                children: [
                  Text(
                    'RESULT',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: _output));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Copied!'),
                          backgroundColor: DesignTokens.neonGreen,
                        ),
                      );
                    },
                    child: const Row(
                      children: [
                        Icon(
                          Icons.copy,
                          size: 14,
                          color: DesignTokens.neonCyan,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Copy',
                          style: TextStyle(
                            color: DesignTokens.neonCyan,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: DesignTokens.bgCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: DesignTokens.neonGreen.withValues(alpha: 0.3),
                  ),
                ),
                child: SelectableText(
                  _output,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Action Chip ──────────────────────────────────────────────────────────────

class _ActionChip extends StatelessWidget {
  final _EditAction action;
  final bool selected;
  final VoidCallback onTap;

  const _ActionChip({
    required this.action,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? action.color.withValues(alpha: 0.15)
              : DesignTokens.bgCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? action.color.withValues(alpha: 0.5)
                : Colors.white10,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              action.icon,
              size: 14,
              color: selected ? action.color : Colors.white38,
            ),
            const SizedBox(width: 6),
            Text(
              action.label,
              style: TextStyle(
                color: selected ? action.color : Colors.white60,
                fontSize: 12,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Model ────────────────────────────────────────────────────────────────────

class _EditAction {
  final String label;
  final IconData icon;
  final Color color;
  final String description;

  const _EditAction(this.label, this.icon, this.color, this.description);
}
