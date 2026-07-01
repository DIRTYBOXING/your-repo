import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/design_tokens.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// RICH TEXT CONTENT — Makes #hashtags and @mentions tappable
///
/// • Parses post content for #hashtag and @mention patterns
/// • Hashtags navigate to /hashtag/:tag filtered feed
/// • Mentions navigate to user search with pre-filled query
/// • Regular text renders normally
/// ═══════════════════════════════════════════════════════════════════════════
class RichTextContent extends StatelessWidget {
  final String text;
  final int? maxLength;
  final bool expanded;
  final VoidCallback? onToggleExpand;

  const RichTextContent({
    super.key,
    required this.text,
    this.maxLength,
    this.expanded = true,
    this.onToggleExpand,
  });

  static final _pattern = RegExp(r'(#[\w\d_]+|@[\w\d_.]+)');

  @override
  Widget build(BuildContext context) {
    final displayText =
        (maxLength != null && !expanded && text.length > maxLength!)
        ? '${text.substring(0, maxLength)}...'
        : text;

    final spans = _buildSpans(context, displayText);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(text: TextSpan(children: spans)),
        if (maxLength != null && text.length > maxLength!)
          GestureDetector(
            onTap: onToggleExpand,
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                expanded ? 'Show less' : 'Read more',
                style: TextStyle(
                  color: DesignTokens.neonCyan.withValues(alpha: 0.7),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }

  List<InlineSpan> _buildSpans(BuildContext context, String input) {
    final spans = <InlineSpan>[];
    int lastEnd = 0;

    for (final match in _pattern.allMatches(input)) {
      // Plain text before match
      if (match.start > lastEnd) {
        spans.add(
          TextSpan(
            text: input.substring(lastEnd, match.start),
            style: const TextStyle(
              color: DesignTokens.textPrimary,
              fontSize: 14,
              height: 1.45,
            ),
          ),
        );
      }

      final token = match.group(0)!;
      final isHashtag = token.startsWith('#');

      spans.add(
        TextSpan(
          text: token,
          style: TextStyle(
            color: isHashtag ? DesignTokens.neonCyan : DesignTokens.neonGreen,
            fontSize: 14,
            height: 1.45,
            fontWeight: FontWeight.w600,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () {
              if (isHashtag) {
                final tag = token.substring(1); // strip #
                context.push('/hashtag/$tag');
              } else {
                final username = token.substring(1); // strip @
                context.push('/user-search?q=$username');
              }
            },
        ),
      );

      lastEnd = match.end;
    }

    // Remaining plain text
    if (lastEnd < input.length) {
      spans.add(
        TextSpan(
          text: input.substring(lastEnd),
          style: const TextStyle(
            color: DesignTokens.textPrimary,
            fontSize: 14,
            height: 1.45,
          ),
        ),
      );
    }

    if (spans.isEmpty) {
      spans.add(
        TextSpan(
          text: input,
          style: const TextStyle(
            color: DesignTokens.textPrimary,
            fontSize: 14,
            height: 1.45,
          ),
        ),
      );
    }

    return spans;
  }
}
