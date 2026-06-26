import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

// ═════════════════════════════════════════════════════════════════════════════
// DFC IMMUTABLE LEDGER SERVICE — Global Distribution Accounting Backbone
// ═════════════════════════════════════════════════════════════════════════════
//
// Every distribution run appended to an append-only ledger.
// No updates — amendments create new entries (event-sourced).
// Reconciled with Stripe payouts for automated settlement.
//
// Firestore Collections:
//   dfc_ledger/{entryId}                     — immutable ledger entries
//   dfc_ledger_summaries/{eventId}            — aggregated event totals
//   dfc_settlements/{settlementId}            — stripe payout reconciliation
//
// ═════════════════════════════════════════════════════════════════════════════

// ── Models ──────────────────────────────────────────────────────────────────

enum LedgerEntryStatus { pending, sent, failed, settled, amended, disputed }

enum RevenueParty { promoter, dfc, fighter, gym, affiliate, channel }

class LedgerRevenueShare {
  final RevenueParty party;
  final String partyId; // uid or org id
  final String partyName;
  final int amountCents;
  final double splitPct; // 0-100

  const LedgerRevenueShare({
    required this.party,
    required this.partyId,
    required this.partyName,
    required this.amountCents,
    required this.splitPct,
  });

  factory LedgerRevenueShare.fromMap(Map<String, dynamic> m) =>
      LedgerRevenueShare(
        party: RevenueParty.values.firstWhere(
          (p) => p.name == m['party'],
          orElse: () => RevenueParty.promoter,
        ),
        partyId: m['partyId'] ?? '',
        partyName: m['partyName'] ?? '',
        amountCents: m['amountCents'] ?? 0,
        splitPct: (m['splitPct'] as num?)?.toDouble() ?? 0.0,
      );

  Map<String, dynamic> toMap() => {
    'party': party.name,
    'partyId': partyId,
    'partyName': partyName,
    'amountCents': amountCents,
    'splitPct': splitPct,
  };
}

class LedgerEntry {
  final String id;
  final String eventId;
  final String promoterId;
  final String channel;
  final String region;
  final LedgerEntryStatus status;
  final int estimatedReachK;
  final int actualReachK;
  final int grossRevenueCents;
  final List<LedgerRevenueShare> shares;
  final DateTime createdAt;
  final DateTime? sentAt;
  final DateTime? settledAt;
  final String? stripePayoutId;
  final String?
  amendmentOf; // points to original entry id if this is an amendment
  final String? errorMessage;
  final String? runId; // link to distribution_runs document

  const LedgerEntry({
    required this.id,
    required this.eventId,
    required this.promoterId,
    required this.channel,
    required this.region,
    required this.status,
    this.estimatedReachK = 0,
    this.actualReachK = 0,
    this.grossRevenueCents = 0,
    this.shares = const [],
    required this.createdAt,
    this.sentAt,
    this.settledAt,
    this.stripePayoutId,
    this.amendmentOf,
    this.errorMessage,
    this.runId,
  });

  factory LedgerEntry.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return LedgerEntry(
      id: doc.id,
      eventId: d['eventId'] ?? '',
      promoterId: d['promoterId'] ?? '',
      channel: d['channel'] ?? '',
      region: d['region'] ?? '',
      status: LedgerEntryStatus.values.firstWhere(
        (s) => s.name == d['status'],
        orElse: () => LedgerEntryStatus.pending,
      ),
      estimatedReachK: d['estimatedReachK'] ?? 0,
      actualReachK: d['actualReachK'] ?? 0,
      grossRevenueCents: d['grossRevenueCents'] ?? 0,
      shares: (d['shares'] as List<dynamic>? ?? [])
          .map((s) => LedgerRevenueShare.fromMap(s as Map<String, dynamic>))
          .toList(),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      sentAt: (d['sentAt'] as Timestamp?)?.toDate(),
      settledAt: (d['settledAt'] as Timestamp?)?.toDate(),
      stripePayoutId: d['stripePayoutId'],
      amendmentOf: d['amendmentOf'],
      errorMessage: d['errorMessage'],
      runId: d['runId'],
    );
  }

  Map<String, dynamic> toFirestore() => {
    'eventId': eventId,
    'promoterId': promoterId,
    'channel': channel,
    'region': region,
    'status': status.name,
    'estimatedReachK': estimatedReachK,
    'actualReachK': actualReachK,
    'grossRevenueCents': grossRevenueCents,
    'shares': shares.map((s) => s.toMap()).toList(),
    'createdAt': Timestamp.fromDate(createdAt),
    if (sentAt != null) 'sentAt': Timestamp.fromDate(sentAt!),
    if (settledAt != null) 'settledAt': Timestamp.fromDate(settledAt!),
    if (stripePayoutId != null) 'stripePayoutId': stripePayoutId,
    if (amendmentOf != null) 'amendmentOf': amendmentOf,
    if (errorMessage != null) 'errorMessage': errorMessage,
    if (runId != null) 'runId': runId,
  };

  int get promoterCents => shares
      .where((s) => s.party == RevenueParty.promoter)
      .fold(0, (sum, s) => sum + s.amountCents);

  int get dfcCents => shares
      .where((s) => s.party == RevenueParty.dfc)
      .fold(0, (sum, s) => sum + s.amountCents);
}

class LedgerSummary {
  final String eventId;
  final int totalEntries;
  final int totalSentEntries;
  final int totalSettledEntries;
  final int totalGrossRevenueCents;
  final int totalPromoterRevenueCents;
  final int totalDfcRevenueCents;
  final int totalActualReachK;
  final DateTime? lastUpdated;

  const LedgerSummary({
    required this.eventId,
    this.totalEntries = 0,
    this.totalSentEntries = 0,
    this.totalSettledEntries = 0,
    this.totalGrossRevenueCents = 0,
    this.totalPromoterRevenueCents = 0,
    this.totalDfcRevenueCents = 0,
    this.totalActualReachK = 0,
    this.lastUpdated,
  });

  factory LedgerSummary.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return LedgerSummary(
      eventId: doc.id,
      totalEntries: d['totalEntries'] ?? 0,
      totalSentEntries: d['totalSentEntries'] ?? 0,
      totalSettledEntries: d['totalSettledEntries'] ?? 0,
      totalGrossRevenueCents: d['totalGrossRevenueCents'] ?? 0,
      totalPromoterRevenueCents: d['totalPromoterRevenueCents'] ?? 0,
      totalDfcRevenueCents: d['totalDfcRevenueCents'] ?? 0,
      totalActualReachK: d['totalActualReachK'] ?? 0,
      lastUpdated: (d['lastUpdated'] as Timestamp?)?.toDate(),
    );
  }
}

// ── Service ──────────────────────────────────────────────────────────────────

class DfcLedgerService extends ChangeNotifier {
  DfcLedgerService._();
  static final DfcLedgerService instance = DfcLedgerService._();
  factory DfcLedgerService() => instance;

  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  CollectionReference get _ledger => _db.collection('dfc_ledger');
  CollectionReference get _summaries => _db.collection('dfc_ledger_summaries');
  CollectionReference get _settlements => _db.collection('dfc_settlements');

  // ── Append (append-only — NEVER update an existing entry) ────────────────

  /// Appends a new immutable ledger entry for a distribution run.
  /// [grossRevenueCents] is split 85/15 (promoter/DFC) by default.
  Future<String> appendEntry({
    required String eventId,
    required String channel,
    required String region,
    required int estimatedReachK,
    int grossRevenueCents = 0,
    String? runId,
    List<LedgerRevenueShare>? customShares,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('Must be signed in to write ledger');
    if (eventId.trim().isEmpty) throw ArgumentError('eventId is required');
    if (channel.trim().isEmpty) throw ArgumentError('channel is required');

    final shares = customShares ?? _defaultShares(uid, grossRevenueCents);

    final entry = LedgerEntry(
      id: '',
      eventId: eventId.trim(),
      promoterId: uid,
      channel: channel.trim().toLowerCase(),
      region: region.trim().toLowerCase(),
      status: LedgerEntryStatus.pending,
      estimatedReachK: estimatedReachK.clamp(0, 100000),
      grossRevenueCents: grossRevenueCents.clamp(0, 1000000000),
      shares: shares,
      createdAt: DateTime.now(),
      runId: runId,
    );

    final ref = await _ledger.add(entry.toFirestore());
    await _updateSummary(eventId, entry);
    return ref.id;
  }

  /// Marks an entry as sent. Does NOT mutate the original — use markAmendment for corrections.
  Future<void> markSent(
    String entryId, {
    required int actualReachK,
    required int grossRevenueCents,
  }) async {
    if (entryId.trim().isEmpty) throw ArgumentError('entryId is required');
    if (actualReachK < 0) throw RangeError('actualReachK must be >= 0');
    if (grossRevenueCents < 0) {
      throw RangeError('grossRevenueCents must be >= 0');
    }
    final snap = await _ledger.doc(entryId).get();
    if (!snap.exists) throw StateError('Ledger entry $entryId not found');

    // Append an amendment entry with updated reach/revenue; mark original as amended
    final original = LedgerEntry.fromFirestore(snap);
    await _ledger.doc(entryId).update({
      'status': LedgerEntryStatus.amended.name,
    });

    final uid = _auth.currentUser?.uid ?? original.promoterId;
    final amendment = original.toFirestore()
      ..['status'] = LedgerEntryStatus.sent.name
      ..['sentAt'] = Timestamp.fromDate(DateTime.now())
      ..['actualReachK'] = actualReachK.clamp(0, 100000)
      ..['grossRevenueCents'] = grossRevenueCents.clamp(0, 1000000000)
      ..['shares'] = _defaultShares(
        uid,
        grossRevenueCents,
      ).map((s) => s.toMap()).toList()
      ..['amendmentOf'] = entryId;

    await _ledger.add(amendment);
    await _updateSummary(original.eventId, LedgerEntry.fromFirestore(snap));
  }

  Future<void> markFailed(
    String entryId, {
    required String errorMessage,
  }) async {
    if (entryId.trim().isEmpty) throw ArgumentError('entryId is required');
    // Read-then-write to produce amendment
    final snap = await _ledger.doc(entryId).get();
    if (!snap.exists) throw StateError('Ledger entry $entryId not found');
    await _ledger.doc(entryId).update({
      'status': LedgerEntryStatus.amended.name,
    });
    final original = LedgerEntry.fromFirestore(snap);
    final amendment = original.toFirestore()
      ..['status'] = LedgerEntryStatus.failed.name
      ..['errorMessage'] = errorMessage.trim()
      ..['amendmentOf'] = entryId;
    await _ledger.add(amendment);
  }

  /// Reconciles a ledger entry against a Stripe payout.
  Future<void> reconcileSettlement(
    String entryId, {
    required String stripePayoutId,
  }) async {
    if (entryId.trim().isEmpty) throw ArgumentError('entryId is required');
    if (stripePayoutId.trim().isEmpty) {
      throw ArgumentError('stripePayoutId is required');
    }
    final snap = await _ledger.doc(entryId).get();
    if (!snap.exists) throw StateError('Ledger entry $entryId not found');
    await _ledger.doc(entryId).update({
      'status': LedgerEntryStatus.settled.name,
      'settledAt': Timestamp.fromDate(DateTime.now()),
      'stripePayoutId': stripePayoutId.trim(),
    });

    // Log to settlements collection for auditing
    await _settlements.add({
      'entryId': entryId,
      'stripePayoutId': stripePayoutId.trim(),
      'reconciledAt': Timestamp.fromDate(DateTime.now()),
      'reconciledBy': _auth.currentUser?.uid ?? '',
    });
  }

  // ── Streams ──────────────────────────────────────────────────────────────

  Stream<List<LedgerEntry>> streamEntries(String eventId) {
    if (eventId.trim().isEmpty) return Stream.value([]);
    return _ledger
        .where('eventId', isEqualTo: eventId.trim())
        .orderBy('createdAt', descending: true)
        .limit(200)
        .snapshots()
        .map(
          (snap) => snap.docs.map(LedgerEntry.fromFirestore).toList(),
        )
        .handleError((e) {
          debugPrint('[DfcLedger] streamEntries error: $e');
          return <LedgerEntry>[];
        });
  }

  Stream<LedgerSummary?> streamSummary(String eventId) {
    if (eventId.trim().isEmpty) return Stream.value(null);
    return _summaries
        .doc(eventId.trim())
        .snapshots()
        .map((snap) => snap.exists ? LedgerSummary.fromFirestore(snap) : null)
        .handleError((e) {
          debugPrint('[DfcLedger] streamSummary error: $e');
          return null;
        });
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  List<LedgerRevenueShare> _defaultShares(String promoterId, int grossCents) {
    final promoterCents = (grossCents * 0.85).round();
    final dfcCents = grossCents - promoterCents;
    return [
      LedgerRevenueShare(
        party: RevenueParty.promoter,
        partyId: promoterId,
        partyName: 'Promoter',
        amountCents: promoterCents,
        splitPct: 85.0,
      ),
      LedgerRevenueShare(
        party: RevenueParty.dfc,
        partyId: 'dfc',
        partyName: 'DataFightCentral',
        amountCents: dfcCents,
        splitPct: 15.0,
      ),
    ];
  }

  Future<void> _updateSummary(String eventId, LedgerEntry entry) async {
    await _summaries.doc(eventId).set({
      'totalEntries': FieldValue.increment(1),
      'lastUpdated': Timestamp.fromDate(DateTime.now()),
    }, SetOptions(merge: true));
  }

  // ── Demo Data ────────────────────────────────────────────────────────────

  List<LedgerEntry> get demoEntries => [
    LedgerEntry(
      id: 'demo_l1',
      eventId: 'demo_event',
      promoterId: 'demo_promoter',
      channel: 'dfc',
      region: 'au',
      status: LedgerEntryStatus.settled,
      estimatedReachK: 12,
      actualReachK: 15,
      grossRevenueCents: 250000,
      shares: _defaultShares('demo_promoter', 250000),
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
      sentAt: DateTime.now().subtract(const Duration(days: 7)),
      settledAt: DateTime.now().subtract(const Duration(days: 3)),
      stripePayoutId: 'po_demo_xyz',
    ),
    LedgerEntry(
      id: 'demo_l2',
      eventId: 'demo_event',
      promoterId: 'demo_promoter',
      channel: 'youtube',
      region: 'global',
      status: LedgerEntryStatus.sent,
      estimatedReachK: 50,
      actualReachK: 62,
      grossRevenueCents: 180000,
      shares: _defaultShares('demo_promoter', 180000),
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      sentAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    LedgerEntry(
      id: 'demo_l3',
      eventId: 'demo_event',
      promoterId: 'demo_promoter',
      channel: 'instagram',
      region: 'au',
      status: LedgerEntryStatus.pending,
      estimatedReachK: 20,
      shares: [],
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
  ];
}
