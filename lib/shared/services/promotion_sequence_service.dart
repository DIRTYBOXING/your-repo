/// PromotionSequenceService — countdown automation, replay pushes, and campaign funnels
/// for DFC events, fighters, and PPV products.
class PromotionSequenceService {
  static final PromotionSequenceService _instance =
      PromotionSequenceService._internal();
  factory PromotionSequenceService() => _instance;
  PromotionSequenceService._internal();

  // ── Sequence generation ────────────────────────────────────────────────────

  /// Generates a countdown promotion sequence for an event.
  List<PromotionStep> buildEventCountdown({
    required String eventName,
    required DateTime fightDate,
    required String eventId,
  }) {
    final now = DateTime.now();
    final daysUntil = fightDate.difference(now).inDays;

    return [
      PromotionStep(
        id: 'announce',
        label: 'Announcement',
        description: 'Drop the official $eventName announcement card',
        scheduledAt: now,
        type: PromotionStepType.announcement,
        platform: ['instagram', 'facebook', 'youtube'],
        status: daysUntil > 21
            ? PromotionStepStatus.pending
            : PromotionStepStatus.sent,
      ),
      PromotionStep(
        id: 'countdown_21',
        label: '21 Days Out',
        description: 'Fighter spotlight: introduce the main event headliners',
        scheduledAt: fightDate.subtract(const Duration(days: 21)),
        type: PromotionStepType.spotlight,
        platform: ['instagram', 'tiktok'],
        status: daysUntil > 21
            ? PromotionStepStatus.pending
            : daysUntil > 14
            ? PromotionStepStatus.sent
            : PromotionStepStatus.sent,
      ),
      PromotionStep(
        id: 'countdown_14',
        label: '14 Days Out',
        description: 'Full fight card reveal + ticket/PPV push',
        scheduledAt: fightDate.subtract(const Duration(days: 14)),
        type: PromotionStepType.cardReveal,
        platform: ['instagram', 'facebook', 'youtube', 'twitter'],
        status: daysUntil > 14
            ? PromotionStepStatus.pending
            : PromotionStepStatus.sent,
      ),
      PromotionStep(
        id: 'countdown_7',
        label: '7 Days Out',
        description: 'Hype reel — training footage + fighter quotes',
        scheduledAt: fightDate.subtract(const Duration(days: 7)),
        type: PromotionStepType.hypeReel,
        platform: ['instagram', 'tiktok', 'youtube'],
        status: daysUntil > 7
            ? PromotionStepStatus.pending
            : PromotionStepStatus.sent,
      ),
      PromotionStep(
        id: 'countdown_1',
        label: 'Fight Eve',
        description: 'Final push — weigh-in results + last call for PPV',
        scheduledAt: fightDate.subtract(const Duration(days: 1)),
        type: PromotionStepType.finalPush,
        platform: ['instagram', 'facebook', 'youtube', 'twitter', 'whatsapp'],
        status: daysUntil > 1
            ? PromotionStepStatus.pending
            : PromotionStepStatus.sent,
      ),
      PromotionStep(
        id: 'fight_day',
        label: 'Fight Day',
        description: 'Live coverage alerts + PPV link in bio',
        scheduledAt: fightDate,
        type: PromotionStepType.liveAlert,
        platform: ['instagram', 'facebook', 'youtube', 'twitter', 'whatsapp'],
        status: daysUntil > 0
            ? PromotionStepStatus.pending
            : PromotionStepStatus.sent,
      ),
      PromotionStep(
        id: 'replay',
        label: 'Replay Push (48h)',
        description:
            'Post-event replay + highlight reel — capture missed viewers',
        scheduledAt: fightDate.add(const Duration(hours: 48)),
        type: PromotionStepType.replay,
        platform: ['instagram', 'youtube', 'facebook'],
        status: DateTime.now().isAfter(fightDate.add(const Duration(hours: 48)))
            ? PromotionStepStatus.sent
            : PromotionStepStatus.pending,
      ),
    ];
  }

  /// Generates a PPV sales funnel sequence.
  List<PromotionStep> buildPpvFunnel({
    required String productName,
    required DateTime launchDate,
  }) {
    return [
      PromotionStep(
        id: 'ppv_tease',
        label: 'Teaser',
        description: 'Drop 15-second teaser — no price, just hype',
        scheduledAt: launchDate.subtract(const Duration(days: 7)),
        type: PromotionStepType.announcement,
        platform: ['instagram', 'tiktok'],
        status: PromotionStepStatus.pending,
      ),
      PromotionStep(
        id: 'ppv_launch',
        label: 'Launch',
        description: 'Full $productName PPV launch with pricing + buy link',
        scheduledAt: launchDate,
        type: PromotionStepType.finalPush,
        platform: ['instagram', 'facebook', 'youtube', 'twitter'],
        status: PromotionStepStatus.pending,
      ),
      PromotionStep(
        id: 'ppv_urgency',
        label: 'Urgency Push',
        description: '24-hour countdown — last chance to buy',
        scheduledAt: launchDate.add(const Duration(days: 3)),
        type: PromotionStepType.finalPush,
        platform: ['instagram', 'whatsapp'],
        status: PromotionStepStatus.pending,
      ),
    ];
  }

  /// Returns all demo sequences for display.
  List<PromotionCampaign> getDemoCampaigns() {
    return [
      PromotionCampaign(
        id: 'camp_1',
        name: 'DFC Fight Night 12',
        type: 'Event Countdown',
        steps: buildEventCountdown(
          eventName: 'DFC Fight Night 12',
          fightDate: DateTime.now().add(const Duration(days: 18)),
          eventId: 'fn12',
        ),
      ),
      PromotionCampaign(
        id: 'camp_2',
        name: 'Logan vs Khan PPV',
        type: 'PPV Funnel',
        steps: buildPpvFunnel(
          productName: 'Logan vs Khan',
          launchDate: DateTime.now().add(const Duration(days: 5)),
        ),
      ),
    ];
  }
}

// ── Data classes ──────────────────────────────────────────────────────────────

enum PromotionStepType {
  announcement,
  spotlight,
  cardReveal,
  hypeReel,
  finalPush,
  liveAlert,
  replay,
}

enum PromotionStepStatus { pending, sent, failed }

class PromotionStep {
  final String id;
  final String label;
  final String description;
  final DateTime scheduledAt;
  final PromotionStepType type;
  final List<String> platform;
  final PromotionStepStatus status;

  const PromotionStep({
    required this.id,
    required this.label,
    required this.description,
    required this.scheduledAt,
    required this.type,
    required this.platform,
    required this.status,
  });
}

class PromotionCampaign {
  final String id;
  final String name;
  final String type;
  final List<PromotionStep> steps;

  const PromotionCampaign({
    required this.id,
    required this.name,
    required this.type,
    required this.steps,
  });

  int get sentCount =>
      steps.where((s) => s.status == PromotionStepStatus.sent).length;
  int get pendingCount =>
      steps.where((s) => s.status == PromotionStepStatus.pending).length;
}
