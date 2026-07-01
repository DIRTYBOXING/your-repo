import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/design_tokens.dart';

/// YouTube Script Writer — structured script editor with sections,
/// estimated duration, and teleprompter mode.
class YoutubeScriptWriterScreen extends StatefulWidget {
  const YoutubeScriptWriterScreen({super.key});

  @override
  State<YoutubeScriptWriterScreen> createState() =>
      _YoutubeScriptWriterScreenState();
}

class _YoutubeScriptWriterScreenState extends State<YoutubeScriptWriterScreen> {
  final _sections = <_ScriptSection>[
    _ScriptSection(
      'Hook',
      Icons.flash_on,
      DesignTokens.neonRed,
      'Grab attention in the first 5 seconds',
    ),
    _ScriptSection(
      'Intro',
      Icons.play_circle_outline,
      DesignTokens.neonCyan,
      'Set up the topic and why viewers should care',
    ),
    _ScriptSection(
      'Main Points',
      Icons.format_list_numbered,
      DesignTokens.neonAmber,
      'Core content — breakdowns, analysis, takes',
    ),
    _ScriptSection(
      'Call to Action',
      Icons.touch_app,
      DesignTokens.neonGreen,
      'Like, subscribe, comment prompt',
    ),
    _ScriptSection(
      'Outro',
      Icons.stop_circle_outlined,
      DesignTokens.neonMagenta,
      'Wrap up + tease next video',
    ),
  ];

  bool _teleprompterMode = false;

  @override
  void dispose() {
    for (final s in _sections) {
      s.controller.dispose();
    }
    super.dispose();
  }

  int get _totalWords =>
      _sections.fold(0, (sum, s) => sum + _wordCount(s.controller.text));

  /// ~150 words per minute reading speed
  String get _estimatedDuration {
    final mins = (_totalWords / 150).ceil();
    if (mins < 1) return '< 1 min';
    return '$mins min';
  }

  int _wordCount(String text) =>
      text.trim().isEmpty ? 0 : text.trim().split(RegExp(r'\s+')).length;

  String get _fullScript {
    final buf = StringBuffer();
    for (final s in _sections) {
      if (s.controller.text.trim().isNotEmpty) {
        buf.writeln('[${s.title.toUpperCase()}]');
        buf.writeln(s.controller.text.trim());
        buf.writeln();
      }
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    if (_teleprompterMode) return _buildTeleprompter();

    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgSecondary,
        title: const Text(
          'Script Writer',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: DesignTokens.neonCyan),
        actions: [
          IconButton(
            icon: const Icon(Icons.slideshow, color: DesignTokens.neonAmber),
            tooltip: 'Teleprompter',
            onPressed: () => setState(() => _teleprompterMode = true),
          ),
          IconButton(
            icon: const Icon(Icons.copy, color: DesignTokens.neonCyan),
            tooltip: 'Copy Script',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: _fullScript));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Script copied!'),
                  backgroundColor: DesignTokens.neonGreen,
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Stats Bar ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: DesignTokens.bgSecondary.withValues(alpha: 0.5),
            child: Row(
              children: [
                _StatChip(
                  Icons.text_fields,
                  '$_totalWords words',
                  DesignTokens.neonCyan,
                ),
                const SizedBox(width: 16),
                _StatChip(
                  Icons.timer_outlined,
                  _estimatedDuration,
                  DesignTokens.neonAmber,
                ),
                const SizedBox(width: 16),
                _StatChip(
                  Icons.list,
                  '${_sections.length} sections',
                  DesignTokens.neonGreen,
                ),
              ],
            ),
          ),

          // ── Sections ──
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _sections.length,
              itemBuilder: (context, i) => _SectionCard(
                section: _sections[i],
                onChanged: () => setState(() {}),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Teleprompter Mode ──────────────────────────────────────────────────

  Widget _buildTeleprompter() {
    final script = _fullScript;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => setState(() => _teleprompterMode = false),
        ),
        title: const Text(
          'Teleprompter',
          style: TextStyle(color: DesignTokens.neonAmber),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Text(
          script.isEmpty ? 'Write your script first...' : script,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            height: 1.8,
            fontWeight: FontWeight.w300,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

// ── Section Card ─────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final _ScriptSection section;
  final VoidCallback onChanged;

  const _SectionCard({required this.section, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: section.color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: section.color.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(section.icon, size: 16, color: section.color),
                const SizedBox(width: 8),
                Text(
                  section.title,
                  style: TextStyle(
                    color: section.color,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                Text(
                  section.hint,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          // Editor
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: section.controller,
              maxLines: 4,
              minLines: 2,
              onChanged: (_) => onChanged(),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Write your ${section.title.toLowerCase()} here...',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.2),
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stat Chip ────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatChip(this.icon, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ── Model ────────────────────────────────────────────────────────────────────

class _ScriptSection {
  final String title;
  final IconData icon;
  final Color color;
  final String hint;
  final TextEditingController controller = TextEditingController();

  _ScriptSection(this.title, this.icon, this.color, this.hint);
}
