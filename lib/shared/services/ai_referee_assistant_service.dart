import 'dart:async';
import 'package:flutter/foundation.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// DFC AI REFEREE ASSISTANT — #112
/// ═══════════════════════════════════════════════════════════════════════════
///
/// AI-powered real-time referee support for fighter safety. This system
/// provides alerts and analytics — referees ALWAYS make the final call.
///
/// Detection Systems:
///   • Foul detection (illegal strikes, groin shots, eye pokes, fence grabs)
///   • Knockdown detection & count tracking
///   • Submission lock detection
///   • Fighter distress signals (dazed, defenseless, unresponsive)
///   • Stamina collapse detection (late rounds)
///
/// Outputs:
///   • Real-time alerts to referee feed
///   • Post-fight analytics for review
///   • Safety intervention recommendations
///   • Foul replay & classification
///
/// ═══════════════════════════════════════════════════════════════════════════

enum FoulType {
  illegalStrike,
  groinShot,
  eyePoke,
  fenceGrab,
  backOfHead,
  headButt,
  soccerKick,
  twelveSixElbow,
  timberKick,
  other,
}

enum DistressLevel { none, mild, moderate, severe, critical }

enum AlertSeverity { info, warning, urgent, emergency }

class RefereeAlert {
  final String id;
  final String fightId;
  final AlertSeverity severity;
  final String message;
  final String category; // 'foul', 'distress', 'submission', 'knockdown'
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final bool acknowledged;

  const RefereeAlert({
    required this.id,
    required this.fightId,
    required this.severity,
    required this.message,
    required this.category,
    this.data = const {},
    required this.timestamp,
    this.acknowledged = false,
  });
}

class FighterDistressState {
  final String fighterId;
  DistressLevel level;
  int knockdownsThisRound;
  int totalKnockdownsFight;
  int unansweredStrikes;
  bool isDefenseless;
  double staminaLevel; // 0.0 – 1.0

  FighterDistressState({
    required this.fighterId,
    this.level = DistressLevel.none,
    this.knockdownsThisRound = 0,
    this.totalKnockdownsFight = 0,
    this.unansweredStrikes = 0,
    this.isDefenseless = false,
    this.staminaLevel = 1.0,
  });
}

class AiRefereeAssistantService extends ChangeNotifier {
  static final AiRefereeAssistantService _instance =
      AiRefereeAssistantService._internal();
  factory AiRefereeAssistantService() => _instance;
  AiRefereeAssistantService._internal();

  bool _initialized = false;
  Timer? _monitorTimer;

  final Map<String, List<RefereeAlert>> _alerts = {};
  final Map<String, Map<String, FighterDistressState>> _distressStates = {};
  int _totalAlertsIssued = 0;
  int _foulsDetected = 0;

  // ── Getters ──
  bool get initialized => _initialized;
  int get totalAlertsIssued => _totalAlertsIssued;
  int get foulsDetected => _foulsDetected;

  List<RefereeAlert> alertsForFight(String fightId) =>
      List.unmodifiable(_alerts[fightId] ?? []);

  FighterDistressState? distressFor(String fightId, String fighterId) =>
      _distressStates[fightId]?[fighterId];

  // ── Lifecycle ──

  void initialize() {
    if (_initialized) return;
    _initialized = true;

    // Continuous monitoring every second during active fights.
    _monitorTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _monitorActiveFights();
    });

    debugPrint('[AIReferee] Online — safety monitor active');
    notifyListeners();
  }

  // ── Fight Session ──

  void startMonitoring(String fightId, String fighterAId, String fighterBId) {
    _alerts[fightId] = [];
    _distressStates[fightId] = {
      fighterAId: FighterDistressState(fighterId: fighterAId),
      fighterBId: FighterDistressState(fighterId: fighterBId),
    };
    debugPrint('[AIReferee] Monitoring started: $fightId');
    notifyListeners();
  }

  void stopMonitoring(String fightId) {
    debugPrint(
      '[AIReferee] Monitoring stopped: $fightId — '
      '${_alerts[fightId]?.length ?? 0} alerts issued',
    );
    notifyListeners();
  }

  // ── Detection Events ──

  void reportFoul(String fightId, String offenderId, FoulType foulType) {
    _foulsDetected++;

    final alert = RefereeAlert(
      id: 'alert_${DateTime.now().millisecondsSinceEpoch}',
      fightId: fightId,
      severity: _foulSeverity(foulType),
      message: 'Foul detected: ${foulType.name} by $offenderId',
      category: 'foul',
      data: {'offenderId': offenderId, 'foulType': foulType.name},
      timestamp: DateTime.now(),
    );

    _alerts.putIfAbsent(fightId, () => []).add(alert);
    _totalAlertsIssued++;
    debugPrint('[AIReferee] FOUL: ${foulType.name} — $offenderId');
    notifyListeners();
  }

  void reportKnockdown(String fightId, String knockedDownFighterId) {
    final state = _distressStates[fightId]?[knockedDownFighterId];
    if (state == null) return;

    state.knockdownsThisRound++;
    state.totalKnockdownsFight++;

    AlertSeverity severity = AlertSeverity.warning;
    if (state.knockdownsThisRound >= 3) {
      severity = AlertSeverity.emergency;
      state.level = DistressLevel.critical;
    } else if (state.knockdownsThisRound >= 2) {
      severity = AlertSeverity.urgent;
      state.level = DistressLevel.severe;
    }

    final alert = RefereeAlert(
      id: 'alert_${DateTime.now().millisecondsSinceEpoch}',
      fightId: fightId,
      severity: severity,
      message:
          'Knockdown #${state.knockdownsThisRound} this round '
          'for $knockedDownFighterId (${state.totalKnockdownsFight} total)',
      category: 'knockdown',
      data: {
        'fighterId': knockedDownFighterId,
        'roundKD': state.knockdownsThisRound,
        'totalKD': state.totalKnockdownsFight,
      },
      timestamp: DateTime.now(),
    );

    _alerts.putIfAbsent(fightId, () => []).add(alert);
    _totalAlertsIssued++;
    notifyListeners();
  }

  void reportSubmissionLock(
    String fightId,
    String attackerId,
    String defenderId,
    String submissionType,
  ) {
    final alert = RefereeAlert(
      id: 'alert_${DateTime.now().millisecondsSinceEpoch}',
      fightId: fightId,
      severity: AlertSeverity.urgent,
      message: 'Submission lock: $submissionType by $attackerId on $defenderId',
      category: 'submission',
      data: {
        'attackerId': attackerId,
        'defenderId': defenderId,
        'type': submissionType,
      },
      timestamp: DateTime.now(),
    );

    _alerts.putIfAbsent(fightId, () => []).add(alert);
    _totalAlertsIssued++;
    notifyListeners();
  }

  void reportUnansweredStrikes(String fightId, String fighterId, int count) {
    final state = _distressStates[fightId]?[fighterId];
    if (state == null) return;

    state.unansweredStrikes += count;

    if (state.unansweredStrikes >= 15) {
      state.level = DistressLevel.critical;
      state.isDefenseless = true;
      _issueAlert(
        fightId,
        AlertSeverity.emergency,
        'FIGHTER DISTRESS: $fighterId — ${state.unansweredStrikes} unanswered strikes',
        'distress',
        {'fighterId': fighterId},
      );
    } else if (state.unansweredStrikes >= 8) {
      state.level = DistressLevel.severe;
      _issueAlert(
        fightId,
        AlertSeverity.urgent,
        'Fighter taking heavy damage: $fighterId',
        'distress',
        {'fighterId': fighterId},
      );
    }

    notifyListeners();
  }

  void reportStaminaCollapse(String fightId, String fighterId, double level) {
    final state = _distressStates[fightId]?[fighterId];
    if (state == null) return;

    state.staminaLevel = level;

    if (level < 0.15) {
      state.level = DistressLevel.severe;
      _issueAlert(
        fightId,
        AlertSeverity.urgent,
        'Stamina collapse detected: $fighterId (${(level * 100).toStringAsFixed(0)}%)',
        'distress',
        {'fighterId': fighterId, 'stamina': level},
      );
    }
    notifyListeners();
  }

  /// Reset per-round state (knockdowns, unanswered strikes) between rounds.
  void resetRound(String fightId) {
    final states = _distressStates[fightId];
    if (states == null) return;
    for (final state in states.values) {
      state.knockdownsThisRound = 0;
      state.unansweredStrikes = 0;
      state.isDefenseless = false;
      if (state.level != DistressLevel.critical) {
        state.level = DistressLevel.none;
      }
    }
    notifyListeners();
  }

  // ── Post-Fight Analytics ──

  Map<String, dynamic> postFightAnalytics(String fightId) {
    final alerts = _alerts[fightId] ?? [];
    return {
      'totalAlerts': alerts.length,
      'fouls': alerts.where((a) => a.category == 'foul').length,
      'knockdowns': alerts.where((a) => a.category == 'knockdown').length,
      'submissionLocks': alerts.where((a) => a.category == 'submission').length,
      'distressAlerts': alerts.where((a) => a.category == 'distress').length,
      'emergencies': alerts
          .where((a) => a.severity == AlertSeverity.emergency)
          .length,
    };
  }

  @override
  void dispose() {
    _monitorTimer?.cancel();
    super.dispose();
  }

  // ── Internal ──

  AlertSeverity _foulSeverity(FoulType foul) {
    switch (foul) {
      case FoulType.eyePoke:
      case FoulType.backOfHead:
      case FoulType.headButt:
        return AlertSeverity.urgent;
      case FoulType.groinShot:
      case FoulType.soccerKick:
        return AlertSeverity.warning;
      default:
        return AlertSeverity.info;
    }
  }

  void _issueAlert(
    String fightId,
    AlertSeverity severity,
    String message,
    String category,
    Map<String, dynamic> data,
  ) {
    final alert = RefereeAlert(
      id: 'alert_${DateTime.now().millisecondsSinceEpoch}',
      fightId: fightId,
      severity: severity,
      message: message,
      category: category,
      data: data,
      timestamp: DateTime.now(),
    );
    _alerts.putIfAbsent(fightId, () => []).add(alert);
    _totalAlertsIssued++;
    debugPrint('[AIReferee] ALERT [$severity]: $message');
  }

  void _monitorActiveFights() {
    // Continuous monitoring loop — real implementation would ingest
    // live telemetry from scoring service / wearable devices.
  }
}
