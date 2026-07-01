import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../shared/services/correspondence_service.dart';

/// Public Q&A Feed — Published fighter responses visible to everyone.
/// Every fighter response becomes content: profile highlights, feed posts,
/// fan engagement. Turns interaction into hype without risk.
class PublicQAFeedScreen extends StatefulWidget {
  final String? fighterId;
  const PublicQAFeedScreen({super.key, this.fighterId});

  @override
  State<PublicQAFeedScreen> createState() => _PublicQAFeedScreenState();
}

class _PublicQAFeedScreenState extends State<PublicQAFeedScreen> {
  final CorrespondenceService _service = CorrespondenceService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgSecondary,
        title: const Text(
          'FIGHTER Q&A',
          style: TextStyle(
            color: DesignTokens.neonCyan,
            fontWeight: FontWeight.w900,
            fontSize: 18,
            letterSpacing: 1.5,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              context.push('/correspondence/ask-fighter');
            },
            icon: const Icon(
              Icons.edit_outlined,
              color: DesignTokens.neonCyan,
              size: 16,
            ),
            label: const Text(
              'ASK',
              style: TextStyle(
                color: DesignTokens.neonCyan,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<FighterResponse>>(
        stream: _service.getPublicResponses(fighterId: widget.fighterId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: DesignTokens.neonCyan),
            );
          }

          final responses = snapshot.data ?? [];
          if (responses.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: responses.length + 1, // +1 for header
            itemBuilder: (context, index) {
              if (index == 0) return _buildHeader();
              return _buildQAPairCard(responses[index - 1]);
            },
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            DesignTokens.neonCyan.withValues(alpha: 0.12),
            DesignTokens.neonMagenta.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DesignTokens.neonCyan.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: DesignTokens.neonCyan.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.question_answer,
                  color: DesignTokens.neonCyan,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FIGHTER ANSWERS',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        letterSpacing: 1.0,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Real answers from real fighters. No trolling. No BS.',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStat('2', 'ANSWERS'),
              const SizedBox(width: 16),
              _buildStat('6', 'QUESTIONS'),
              const SizedBox(width: 16),
              _buildStat('4.3K', 'LIKES'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: DesignTokens.neonCyan,
            fontWeight: FontWeight.w900,
            fontSize: 20,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white38,
            fontWeight: FontWeight.w700,
            fontSize: 9,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }

  Widget _buildQAPairCard(FighterResponse response) {
    return FutureBuilder<FanMessage?>(
      future: _service.getMessageForResponse(response.messageId),
      builder: (context, msgSnapshot) {
        final question = msgSnapshot.data;
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: DesignTokens.bgCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: DesignTokens.neonCyan.withValues(alpha: 0.15),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Question (from fan)
              if (question != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.03),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(14),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: DesignTokens.neonAmber.withValues(
                          alpha: 0.2,
                        ),
                        child: Text(
                          question.fanName.isNotEmpty
                              ? question.fanName[0]
                              : '?',
                          style: const TextStyle(
                            color: DesignTokens.neonAmber,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  question.fanName,
                                  style: const TextStyle(
                                    color: Colors.white60,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  'asked',
                                  style: TextStyle(
                                    color: Colors.white30,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              question.content,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(
                                  Icons.arrow_upward,
                                  color: DesignTokens.neonAmber,
                                  size: 12,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${question.upvotes} fans voted for this question',
                                  style: const TextStyle(
                                    color: Colors.white30,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: Colors.white.withValues(alpha: 0.06)),
              ],

              // Fighter response
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: DesignTokens.neonCyan,
                          width: 2,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: DesignTokens.neonCyan.withValues(
                          alpha: 0.2,
                        ),
                        child: Text(
                          response.fighterName.isNotEmpty
                              ? response.fighterName[0]
                              : 'F',
                          style: const TextStyle(
                            color: DesignTokens.neonCyan,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                response.fighterName,
                                style: const TextStyle(
                                  color: DesignTokens.neonCyan,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: DesignTokens.neonCyan.withValues(
                                    alpha: 0.15,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'FIGHTER',
                                  style: TextStyle(
                                    color: DesignTokens.neonCyan,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 8,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            response.content,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _formatDate(response.createdAt),
                            style: const TextStyle(
                              color: Colors.white30,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Engagement bar
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    _engagementButton(
                      Icons.favorite_outline,
                      '${response.likes}',
                      DesignTokens.neonRed,
                    ),
                    const SizedBox(width: 20),
                    _engagementButton(
                      Icons.share_outlined,
                      '${response.shares}',
                      DesignTokens.neonCyan,
                    ),
                    const Spacer(),
                    _engagementButton(
                      Icons.bookmark_outline,
                      'Save',
                      Colors.white38,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _engagementButton(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.question_answer_outlined, size: 64, color: Colors.white24),
          SizedBox(height: 16),
          Text(
            'No Q&A answers yet',
            style: TextStyle(color: Colors.white38, fontSize: 16),
          ),
          SizedBox(height: 8),
          Text(
            'Be the first to ask a fighter a question!',
            style: TextStyle(color: Colors.white24, fontSize: 12),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
