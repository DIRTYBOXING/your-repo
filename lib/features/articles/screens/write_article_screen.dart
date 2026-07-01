import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../shared/services/auth_service.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// WRITE ARTICLE — Publish directly to feed_content
///
/// You write it. It goes live. No pipeline, no approval queue.
/// Shows up in the feed immediately.
/// ═══════════════════════════════════════════════════════════════════════════
class WriteArticleScreen extends StatefulWidget {
  const WriteArticleScreen({super.key});

  @override
  State<WriteArticleScreen> createState() => _WriteArticleScreenState();
}

class _WriteArticleScreenState extends State<WriteArticleScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _tagsController = TextEditingController();

  String _category = 'mma';
  bool _isBreaking = false;
  bool _isFeatured = false;
  bool _publishing = false;

  static const _categories = [
    'mma',
    'boxing',
    'muay_thai',
    'kickboxing',
    'brawling',
    'bkfc',
    'wrestling',
    'local',
    'general',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _imageUrlController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  bool get _canPublish =>
      _titleController.text.trim().isNotEmpty &&
      _bodyController.text.trim().isNotEmpty &&
      !_publishing;

  Future<void> _publish() async {
    if (!_canPublish) return;
    setState(() => _publishing = true);
    HapticFeedback.mediumImpact();

    final auth = context.read<AuthService>();
    final user = auth.currentUser;
    final userModel = auth.userModel;

    if (user == null) {
      if (mounted) {
        setState(() => _publishing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sign in to publish articles'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      final title = _titleController.text.trim();
      final body = _bodyController.text.trim();
      final imageUrl = _imageUrlController.text.trim();
      final rawTags = _tagsController.text.trim();
      final tags = rawTags.isNotEmpty
          ? rawTags
                .split(',')
                .map((t) => t.trim().toLowerCase())
                .where((t) => t.isNotEmpty)
                .toList()
          : <String>[];

      // Build a summary from the first ~300 chars of the body
      final summary = body.length > 300 ? '${body.substring(0, 297)}...' : body;

      final authorName =
          userModel?.displayName ?? user.displayName ?? 'DFC Editorial';

      await FirebaseFirestore.instance.collection('feed_content').add({
        'title': title,
        'summary': summary,
        'body': body,
        'source': 'Data Fight Central',
        'category': _category,
        'region': 'au',
        'url': '', // Original article lives on DFC
        'imageUrl': imageUrl.isNotEmpty ? imageUrl : null,
        'tags': tags,
        'isBreaking': _isBreaking,
        'isFeatured': _isFeatured,
        'trustScore': 1.0, // Our own content
        'authorName': authorName,
        'authorId': user.uid,
        'attribution': 'Data Fight Central — $authorName',
        'status': 'published',
        'publishedAt': FieldValue.serverTimestamp(),
        'promotedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Article published. It\'s live in the feed now.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _publishing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppTheme.cardDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'WRITE ARTICLE',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: _canPublish ? _publish : null,
              style: TextButton.styleFrom(
                backgroundColor: _canPublish
                    ? DesignTokens.neonCyan
                    : Colors.white.withValues(alpha: 0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
              ),
              child: _publishing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'PUBLISH',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            TextField(
              controller: _titleController,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
              maxLines: null,
              decoration: const InputDecoration(
                hintText: 'Headline',
                hintStyle: TextStyle(color: Colors.white30, fontSize: 22),
                border: InputBorder.none,
              ),
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: 8),

            // Category + flags row
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // Category dropdown
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _category,
                      dropdownColor: AppTheme.cardDark,
                      style: const TextStyle(
                        color: DesignTokens.neonCyan,
                        fontSize: 13,
                      ),
                      items: _categories
                          .map(
                            (c) => DropdownMenuItem(
                              value: c,
                              child: Text(c.toUpperCase().replaceAll('_', ' ')),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _category = v);
                      },
                    ),
                  ),
                ),
                // Breaking toggle
                _flagChip(
                  'BREAKING',
                  _isBreaking,
                  Colors.red,
                  () => setState(() => _isBreaking = !_isBreaking),
                ),
                // Featured toggle
                _flagChip(
                  'FEATURED',
                  _isFeatured,
                  DesignTokens.neonAmber,
                  () => setState(() => _isFeatured = !_isFeatured),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Body
            TextField(
              controller: _bodyController,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
                height: 1.6,
              ),
              maxLines: null,
              minLines: 12,
              decoration: const InputDecoration(
                hintText: 'Write your article here...',
                hintStyle: TextStyle(color: Colors.white24, fontSize: 16),
                border: InputBorder.none,
              ),
              onChanged: (_) => setState(() {}),
            ),

            const Divider(color: Colors.white12, height: 32),

            // Image URL
            _fieldLabel('COVER IMAGE URL (optional)'),
            const SizedBox(height: 6),
            TextField(
              controller: _imageUrlController,
              style: const TextStyle(color: Colors.white60, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'https://...',
                hintStyle: const TextStyle(color: Colors.white24),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.04),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.white12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.white12),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Tags
            _fieldLabel('TAGS (comma-separated)'),
            const SizedBox(height: 6),
            TextField(
              controller: _tagsController,
              style: const TextStyle(color: Colors.white60, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'ufc, perth, whittaker, mma',
                hintStyle: const TextStyle(color: Colors.white24),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.04),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.white12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.white12),
                ),
              ),
            ),

            const SizedBox(height: 40),

            // Word count
            Text(
              '${_bodyController.text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length} words',
              style: const TextStyle(color: Colors.white24, fontSize: 12),
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _flagChip(String label, bool active, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? color.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active ? color.withValues(alpha: 0.6) : Colors.white12,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? color : Colors.white38,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white38,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1,
      ),
    );
  }
}
