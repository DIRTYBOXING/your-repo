import 'package:flutter/material.dart';
import '../../core/theme/design_tokens.dart';
import 'dfc_shimmer.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// DFC SKELETONS — Feed-shaped shimmer placeholders (Instagram/TikTok feel)
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Real apps don't show spinners. They show content-shaped gray boxes that
/// pulse, so the user's brain already knows where things will land.
///
/// Usage:
///   if (_loading) return DFCFeedSkeleton();
///   if (_loading) return DFCEventCardSkeleton();
///   if (_loading) return DFCProfileSkeleton();
/// ═══════════════════════════════════════════════════════════════════════════

/// Feed post skeleton — avatar + name + body + image + actions
class DFCFeedSkeleton extends StatelessWidget {
  final int itemCount;

  const DFCFeedSkeleton({super.key, this.itemCount = 4});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: const EdgeInsets.all(16),
      itemCount: itemCount,
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (_, _) => _PostSkeleton(),
    );
  }
}

class _PostSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        border: Border.all(
          color: DesignTokens.neonCyan.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: avatar + name + time
          Row(
            children: [
              DFCShimmer.circle(),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DFCShimmer.line(width: 100),
                  SizedBox(height: 6),
                  DFCShimmer.line(width: 60, height: 10),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Body text lines
          const DFCShimmer.line(width: double.infinity),
          const SizedBox(height: 8),
          const DFCShimmer.line(width: 220),
          const SizedBox(height: 14),

          // Image placeholder
          DFCShimmer.card(height: 180),
          const SizedBox(height: 14),

          // Action bar: like + comment + share
          const Row(
            children: [
              DFCShimmer.line(width: 50, height: 10),
              SizedBox(width: 24),
              DFCShimmer.line(width: 50, height: 10),
              SizedBox(width: 24),
              DFCShimmer.line(width: 50, height: 10),
            ],
          ),
        ],
      ),
    );
  }
}

/// Event card skeleton — image banner + title + date + venue
class DFCEventCardSkeleton extends StatelessWidget {
  final int itemCount;

  const DFCEventCardSkeleton({super.key, this.itemCount = 3});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: const EdgeInsets.all(16),
      itemCount: itemCount,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (_, _) => Container(
        decoration: BoxDecoration(
          color: DesignTokens.bgCard,
          borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
          border: Border.all(
            color: DesignTokens.neonCyan.withValues(alpha: 0.06),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner image
            DFCShimmer.card(height: 140),
            const Padding(
              padding: EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DFCShimmer.line(width: 200, height: 14),
                  SizedBox(height: 8),
                  DFCShimmer.line(width: 140, height: 11),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      DFCShimmer.line(width: 80, height: 10),
                      SizedBox(width: 16),
                      DFCShimmer.line(width: 100, height: 10),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Profile header skeleton — banner + avatar + name + stats
class DFCProfileSkeleton extends StatelessWidget {
  const DFCProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Banner
        DFCShimmer.card(height: 160),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              // Avatar + name
              Row(
                children: [
                  DFCShimmer.circle(size: 64),
                  const SizedBox(width: 16),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DFCShimmer.line(width: 140, height: 16),
                      SizedBox(height: 8),
                      DFCShimmer.line(width: 100),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Stats row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  3,
                  (_) => const Column(
                    children: [
                      DFCShimmer.line(width: 30, height: 18),
                      SizedBox(height: 4),
                      DFCShimmer.line(width: 50, height: 10),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Chat / message list skeleton
class DFCChatSkeleton extends StatelessWidget {
  final int itemCount;

  const DFCChatSkeleton({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: const EdgeInsets.all(16),
      itemCount: itemCount,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final isMe = i % 3 == 0;
        return Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isMe) ...[
                DFCShimmer.circle(size: 32),
                const SizedBox(width: 8),
              ],
              DFCShimmer(
                width: 120 + (i % 3) * 40,
                height: 36,
                borderRadius: 16,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Notification list skeleton
class DFCNotificationSkeleton extends StatelessWidget {
  final int itemCount;

  const DFCNotificationSkeleton({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: const EdgeInsets.all(16),
      itemCount: itemCount,
      separatorBuilder: (_, _) => Divider(
        color: DesignTokens.neonCyan.withValues(alpha: 0.06),
        height: 1,
      ),
      itemBuilder: (_, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            DFCShimmer.circle(size: 44),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DFCShimmer.line(width: double.infinity),
                  SizedBox(height: 6),
                  DFCShimmer.line(width: 160, height: 10),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const DFCShimmer.line(width: 30, height: 10),
          ],
        ),
      ),
    );
  }
}
