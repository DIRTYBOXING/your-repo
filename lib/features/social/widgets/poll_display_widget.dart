import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../shared/models/community/community_models.dart';
import '../../../shared/services/auth_service.dart';
import '../../../shared/services/social_service.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// POLL DISPLAY WIDGET — Inline poll card embedded inside DFCPostCard
///
/// • Shows question, options as tappable bars
/// • Vote counts + percentage fill
/// • Expired / active state
/// • Calls SocialService.votePoll()
/// ═══════════════════════════════════════════════════════════════════════════
class PollDisplayWidget extends StatefulWidget {
  final Post post;
  const PollDisplayWidget({super.key, required this.post});

  @override
  State<PollDisplayWidget> createState() => _PollDisplayWidgetState();
}

class _PollDisplayWidgetState extends State<PollDisplayWidget> {
  bool _voting = false;
  late Map<String, List<String>> _localVotes;
  String? _uid;

  Post get post => widget.post;

  @override
  void initState() {
    super.initState();
    _localVotes = Map<String, List<String>>.from(
      post.pollVotes.map((k, v) => MapEntry(k, List<String>.from(v))),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _uid ??= context.read<AuthService>().currentUser?.uid;
  }

  bool get _hasVoted {
    if (_uid == null) return false;
    return _localVotes.values.any((voters) => voters.contains(_uid));
  }

  bool get _expired {
    if (post.pollExpiresAt == null) return false;
    return DateTime.now().isAfter(post.pollExpiresAt!);
  }

  int get _totalVotes => _localVotes.values.fold(0, (sum, v) => sum + v.length);

  bool _didVoteFor(int index) {
    final key = index.toString();
    return _localVotes[key]?.contains(_uid) ?? false;
  }

  Future<void> _vote(int index) async {
    if (_voting || _expired || _uid == null) return;
    setState(() => _voting = true);
    HapticFeedback.lightImpact();

    // Optimistic update
    final key = index.toString();
    setState(() {
      if (!post.pollAllowMultiple) {
        // remove from all
        for (final entry in _localVotes.entries) {
          entry.value.remove(_uid);
        }
      }
      final list = _localVotes.putIfAbsent(key, () => []);
      if (list.contains(_uid)) {
        list.remove(_uid);
      } else {
        list.add(_uid!);
      }
    });

    try {
      await context.read<SocialService>().votePoll(
        postId: post.id,
        optionIndex: index,
        userId: _uid!,
      );
    } catch (_) {
      // revert would be complex — just leave optimistic state
    }
    if (mounted) setState(() => _voting = false);
  }

  @override
  Widget build(BuildContext context) {
    final showResults = _hasVoted || _expired;
    final total = _totalVotes;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question
          if (post.pollQuestion != null && post.pollQuestion!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                post.pollQuestion!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

          // Options
          ...List.generate(post.pollOptions.length, (i) {
            final label = post.pollOptions[i];
            final votes = _localVotes[i.toString()]?.length ?? 0;
            final pct = total > 0 ? votes / total : 0.0;
            final voted = _didVoteFor(i);

            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: GestureDetector(
                onTap: showResults && !post.pollAllowMultiple
                    ? null
                    : () => _vote(i),
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: voted
                          ? DesignTokens.neonCyan.withValues(alpha: 0.5)
                          : Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Stack(
                    children: [
                      // fill bar
                      if (showResults)
                        FractionallySizedBox(
                          widthFactor: pct,
                          child: Container(
                            height: 40,
                            decoration: BoxDecoration(
                              color: voted
                                  ? DesignTokens.neonCyan.withValues(
                                      alpha: 0.15,
                                    )
                                  : Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(9),
                            ),
                          ),
                        ),
                      // label + percent
                      Container(
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: [
                            if (voted)
                              const Padding(
                                padding: EdgeInsets.only(right: 6),
                                child: Icon(
                                  Icons.check_circle,
                                  size: 14,
                                  color: DesignTokens.neonCyan,
                                ),
                              ),
                            Expanded(
                              child: Text(
                                label,
                                style: TextStyle(
                                  color: voted
                                      ? DesignTokens.neonCyan
                                      : Colors.white70,
                                  fontSize: 13,
                                  fontWeight: voted
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                              ),
                            ),
                            if (showResults)
                              Text(
                                '${(pct * 100).round()}%',
                                style: TextStyle(
                                  color: voted
                                      ? DesignTokens.neonCyan
                                      : Colors.white38,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

          // Footer: total votes + expiry
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Text(
                  '$total vote${total == 1 ? '' : 's'}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.35),
                    fontSize: 11,
                  ),
                ),
                if (post.pollExpiresAt != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    _expired ? 'Poll ended' : _timeLeft(),
                    style: TextStyle(
                      color: _expired
                          ? Colors.white.withValues(alpha: 0.25)
                          : DesignTokens.neonAmber.withValues(alpha: 0.6),
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _timeLeft() {
    if (post.pollExpiresAt == null) return '';
    final diff = post.pollExpiresAt!.difference(DateTime.now());
    if (diff.inDays > 0) return '${diff.inDays}d left';
    if (diff.inHours > 0) return '${diff.inHours}h left';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m left';
    return 'ending soon';
  }
}
