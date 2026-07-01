import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/design_tokens.dart';

/// Twitter / X Thread Composer — multi-tweet editor with character counts,
/// drag-to-reorder, and thread numbering.
class TwitterThreadComposerScreen extends StatefulWidget {
  const TwitterThreadComposerScreen({super.key});

  @override
  State<TwitterThreadComposerScreen> createState() =>
      _TwitterThreadComposerScreenState();
}

class _TwitterThreadComposerScreenState
    extends State<TwitterThreadComposerScreen> {
  static const _maxChars = 280;
  final List<TextEditingController> _tweets = [TextEditingController()];
  bool _showPreview = false;

  @override
  void dispose() {
    for (final c in _tweets) {
      c.dispose();
    }
    super.dispose();
  }

  void _addTweet() {
    setState(() => _tweets.add(TextEditingController()));
  }

  void _removeTweet(int index) {
    if (_tweets.length <= 1) return;
    setState(() {
      _tweets[index].dispose();
      _tweets.removeAt(index);
    });
  }

  void _reorderItem(int oldIndex, int newIndex) {
    setState(() {
      final item = _tweets.removeAt(oldIndex);
      _tweets.insert(newIndex, item);
    });
  }

  String _buildThread() {
    final buf = StringBuffer();
    for (var i = 0; i < _tweets.length; i++) {
      buf.writeln('${i + 1}/${_tweets.length}');
      buf.writeln(_tweets[i].text);
      if (i < _tweets.length - 1) buf.writeln();
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgSecondary,
        title: const Text(
          'Thread Composer',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: DesignTokens.neonCyan),
        actions: [
          IconButton(
            icon: Icon(
              _showPreview ? Icons.edit : Icons.preview,
              color: DesignTokens.neonCyan,
            ),
            tooltip: _showPreview ? 'Edit' : 'Preview',
            onPressed: () => setState(() => _showPreview = !_showPreview),
          ),
          IconButton(
            icon: const Icon(Icons.copy, color: DesignTokens.neonAmber),
            tooltip: 'Copy Thread',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: _buildThread()));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Thread copied!'),
                  backgroundColor: DesignTokens.neonGreen,
                ),
              );
            },
          ),
        ],
      ),
      body: _showPreview ? _buildPreviewView() : _buildEditorView(),
      floatingActionButton: _showPreview
          ? null
          : FloatingActionButton(
              backgroundColor: DesignTokens.neonCyan,
              onPressed: _addTweet,
              child: const Icon(Icons.add, color: DesignTokens.bgPrimary),
            ),
    );
  }

  // ── Editor ─────────────────────────────────────────────────────────────

  Widget _buildEditorView() {
    return ReorderableListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _tweets.length,
      onReorder: _reorderItem,
      proxyDecorator: (child, _, _) =>
          Material(color: Colors.transparent, elevation: 4, child: child),
      itemBuilder: (context, i) => _TweetEditor(
        key: ValueKey(_tweets[i]),
        controller: _tweets[i],
        index: i,
        total: _tweets.length,
        maxChars: _maxChars,
        onRemove: () => _removeTweet(i),
      ),
    );
  }

  // ── Preview ────────────────────────────────────────────────────────────

  Widget _buildPreviewView() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _tweets.length,
      itemBuilder: (context, i) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: DesignTokens.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 16,
                  backgroundColor: DesignTokens.neonCyan,
                  child: Icon(
                    Icons.person,
                    size: 16,
                    color: DesignTokens.bgPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'DFC Fighter',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '@dfcfighter',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: DesignTokens.neonCyan.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${i + 1}/${_tweets.length}',
                    style: const TextStyle(
                      color: DesignTokens.neonCyan,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              _tweets[i].text.isEmpty ? '(empty tweet)' : _tweets[i].text,
              style: TextStyle(
                color: _tweets[i].text.isEmpty
                    ? Colors.white24
                    : Colors.white.withValues(alpha: 0.9),
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tweet Editor Card ────────────────────────────────────────────────────────

class _TweetEditor extends StatefulWidget {
  final TextEditingController controller;
  final int index;
  final int total;
  final int maxChars;
  final VoidCallback onRemove;

  const _TweetEditor({
    super.key,
    required this.controller,
    required this.index,
    required this.total,
    required this.maxChars,
    required this.onRemove,
  });

  @override
  State<_TweetEditor> createState() => _TweetEditorState();
}

class _TweetEditorState extends State<_TweetEditor> {
  int _charCount = 0;

  @override
  void initState() {
    super.initState();
    _charCount = widget.controller.text.length;
    widget.controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    setState(() => _charCount = widget.controller.text.length);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final overLimit = _charCount > widget.maxChars;
    final remaining = widget.maxChars - _charCount;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: overLimit
              ? DesignTokens.neonRed.withValues(alpha: 0.5)
              : Colors.white10,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.drag_handle, size: 18, color: Colors.white24),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: DesignTokens.neonCyan.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${widget.index + 1}/${widget.total}',
                  style: const TextStyle(
                    color: DesignTokens.neonCyan,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '$remaining',
                style: TextStyle(
                  color: overLimit ? DesignTokens.neonRed : Colors.white38,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (widget.total > 1) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: widget.onRemove,
                  child: const Icon(
                    Icons.close,
                    size: 16,
                    color: Colors.white24,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: widget.controller,
            maxLines: 4,
            minLines: 2,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: widget.index == 0
                  ? 'Start your thread...'
                  : 'Continue the thread...',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2)),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          // Character progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: (_charCount / widget.maxChars).clamp(0.0, 1.0),
              minHeight: 2,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation(
                overLimit ? DesignTokens.neonRed : DesignTokens.neonCyan,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
