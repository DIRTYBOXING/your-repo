import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/router_config.dart' as rc;
import '../../../shared/services/creator_payout_engine.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// PROMOTER PAYOUT COMMAND — Live Revenue, Splits, Ledger, Instant Cashout
// 80/15/5 default · Stripe Connect · KYC · CSV Export · Weekly Settlements
// ═══════════════════════════════════════════════════════════════════════════════

const _cyan = Color(0xFF00F5FF);
const _magenta = Color(0xFFFF00FF);
const _green = Color(0xFF00FF88);
const _amber = Color(0xFFFFB800);
// _red reserved for future error states
const _gold = Color(0xFFFFD700);
const _bg = Color(0xFF050A14);
const _panel = Color(0xFF0D1B2A);
const _surface = Color(0xFF142236);
const _border = Color(0xFF1A2744);

class PromoterPayoutDashboardScreen extends StatefulWidget {
  const PromoterPayoutDashboardScreen({
    super.key,
    this.firestore,
    this.auth,
    this.payoutEngine,
    this.enableLiveDataLoad = true,
  });

  final FirebaseFirestore? firestore;
  final FirebaseAuth? auth;
  final CreatorPayoutEngine? payoutEngine;
  final bool enableLiveDataLoad;

  @override
  State<PromoterPayoutDashboardScreen> createState() =>
      _PromoterPayoutDashboardScreenState();
}

class _PromoterPayoutDashboardScreenState
    extends State<PromoterPayoutDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  bool _isLoadingLiveData = false;
  bool _isStripeConnected = true;

  // ── Split config ──
  double _promoterSplit = 80;
  double _fighterPoolSplit = 15;
  double _platformSplit = 5;

  // ── Demo ledger ──
  List<_LedgerEntry> _ledger = <_LedgerEntry>[
    _LedgerEntry(
      'EVT-2026-001',
      'Logan Main Event',
      10200.00,
      8160.00,
      1530.00,
      510.00,
      'paid',
      DateTime(2026, 3, 20),
    ),
    _LedgerEntry(
      'EVT-2026-002',
      'Brisbane Title Fight',
      18400.00,
      14720.00,
      2760.00,
      920.00,
      'paid',
      DateTime(2026, 3, 15),
    ),
    _LedgerEntry(
      'EVT-2026-003',
      'BKFC Underground',
      4800.00,
      3840.00,
      720.00,
      240.00,
      'pending',
      DateTime(2026, 3, 25),
    ),
    _LedgerEntry(
      'EVT-2026-004',
      'MMA Showcase',
      7600.00,
      6080.00,
      1140.00,
      380.00,
      'processing',
      DateTime(2026, 3, 24),
    ),
    _LedgerEntry(
      'EVT-2026-005',
      'Bare Knuckle Series',
      3200.00,
      2560.00,
      480.00,
      160.00,
      'paid',
      DateTime(2026, 3, 10),
    ),
    _LedgerEntry(
      'EVT-2026-006',
      'Regional Rumble',
      5100.00,
      4080.00,
      765.00,
      255.00,
      'scheduled',
      DateTime(2026, 3, 28),
    ),
  ];

  // ── Demo payouts ──
  List<_Payout> _payouts = <_Payout>[
    _Payout(
      'PAY-001',
      'Weekly Settlement',
      22880.00,
      'completed',
      DateTime(2026, 3, 21),
      'bank_transfer',
    ),
    _Payout(
      'PAY-002',
      'Instant Cashout',
      3840.00,
      'completed',
      DateTime(2026, 3, 25),
      'instant',
    ),
    _Payout(
      'PAY-003',
      'Weekly Settlement',
      6080.00,
      'processing',
      DateTime(2026, 3, 28),
      'bank_transfer',
    ),
  ];

  // ── Demo promoters ──
  List<_Promoter> _promoters = <_Promoter>[
    _Promoter(
      'PROMO-001',
      'Logan Fight Co',
      'Partner',
      true,
      42600.00,
      34080.00,
      12,
    ),
    _Promoter(
      'PROMO-002',
      'Brisbane Combat',
      'Partner',
      true,
      28100.00,
      22480.00,
      8,
    ),
    _Promoter(
      'PROMO-003',
      'Underground BKFC',
      'Standard',
      false,
      8400.00,
      5880.00,
      4,
    ),
    _Promoter(
      'PROMO-004',
      'Gold Coast MMA',
      'Partner',
      true,
      15200.00,
      12160.00,
      6,
    ),
    _Promoter(
      'PROMO-005',
      'Hunter Valley Boxing',
      'Standard',
      false,
      3100.00,
      2170.00,
      2,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    _loadLiveData();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  double get _totalGross => _ledger.fold(0.0, (s, e) => s + e.gross);
  double get _totalPromoterPaid => _ledger
      .where(
        (e) =>
            e.status == 'paid' ||
            e.status == 'completed' ||
            e.status == 'transferred',
      )
      .fold(0.0, (s, e) => s + e.promoterShare);
  double get _totalFighterPool =>
      _ledger.fold(0.0, (s, e) => s + e.fighterShare);
  double get _totalPlatform => _ledger.fold(0.0, (s, e) => s + e.platformShare);

  double _readDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? 0;
  }

  String? _readString(dynamic value) {
    final normalized = value?.toString().trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return normalized;
  }

  DateTime _readDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  double _readCurrencyAmount(
    Map<String, dynamic> data, {
    List<String> amountKeys = const ['amount'],
    List<String> centKeys = const ['amountCents'],
  }) {
    for (final key in amountKeys) {
      final value = _readDouble(data[key]);
      if (value > 0) return value;
    }

    for (final key in centKeys) {
      final value = _readDouble(data[key]);
      if (value > 0) return value / 100;
    }

    return 0;
  }

  String _normalizeStatus(dynamic value) {
    return value?.toString().trim().toLowerCase() ?? '';
  }

  Color _statusColorFor(String status) {
    switch (_normalizeStatus(status)) {
      case 'completed':
      case 'paid':
      case 'transferred':
        return _green;
      case 'processing':
        return _gold;
      case 'requested':
      case 'pending':
      case 'not_requested':
        return _cyan;
      case 'scheduled':
      case 'blocked':
        return _amber;
      case 'failed':
      case 'error':
      case 'rejected':
      case 'transfer_failed':
        return Colors.redAccent;
      default:
        return Colors.white38;
    }
  }

  String _statusLabelFor(String status) {
    switch (_normalizeStatus(status)) {
      case 'completed':
      case 'paid':
      case 'transferred':
        return 'PAID';
      case 'requested':
        return 'REQUESTED';
      case 'not_requested':
        return 'PENDING';
      default:
        final normalized = _normalizeStatus(status);
        return normalized.isEmpty ? 'UNKNOWN' : normalized.toUpperCase();
    }
  }

  Future<void> _loadLiveData() async {
    if (!widget.enableLiveDataLoad) {
      return;
    }

    final auth = widget.auth ?? FirebaseAuth.instance;
    final firestore = widget.firestore ?? FirebaseFirestore.instance;
    final user = auth.currentUser;
    if (user == null) return;

    setState(() {
      _isLoadingLiveData = true;
    });

    try {
      final results = await Future.wait([
        firestore.collection('users').doc(user.uid).get(),
        firestore.collection('connected_accounts_v2').doc(user.uid).get(),
        firestore.collection('creator_earnings').doc(user.uid).get(),
        firestore
            .collection('revenue_shares')
            .where('promoterId', isEqualTo: user.uid)
            .limit(50)
            .get(),
        firestore
            .collection('payout_history')
            .where('creatorId', isEqualTo: user.uid)
            .limit(50)
            .get(),
        firestore
            .collection('payout_history')
            .where('promoterId', isEqualTo: user.uid)
            .limit(50)
            .get(),
        firestore
            .collection('payout_requests')
            .where('creatorId', isEqualTo: user.uid)
            .limit(50)
            .get(),
        firestore
            .collection('payout_requests')
            .where('promoterId', isEqualTo: user.uid)
            .limit(50)
            .get(),
        firestore
            .collection('reconciliations')
            .where('promoterId', isEqualTo: user.uid)
            .limit(100)
            .get(),
        firestore
            .collection('ppv_events')
            .where('promoterId', isEqualTo: user.uid)
            .limit(50)
            .get(),
      ]);

      final userSnap = results[0] as DocumentSnapshot<Map<String, dynamic>>;
      final connectedSnap =
          results[1] as DocumentSnapshot<Map<String, dynamic>>;
      final earningsSnap = results[2] as DocumentSnapshot<Map<String, dynamic>>;
      final revenueSharesSnap =
          results[3] as QuerySnapshot<Map<String, dynamic>>;
      final payoutsHistoryCreatorSnap =
          results[4] as QuerySnapshot<Map<String, dynamic>>;
      final payoutsHistoryPromoterSnap =
          results[5] as QuerySnapshot<Map<String, dynamic>>;
      final payoutRequestsCreatorSnap =
          results[6] as QuerySnapshot<Map<String, dynamic>>;
      final payoutRequestsPromoterSnap =
          results[7] as QuerySnapshot<Map<String, dynamic>>;
      final reconciliationsSnap =
          results[8] as QuerySnapshot<Map<String, dynamic>>;
      final promoterEventsSnap =
          results[9] as QuerySnapshot<Map<String, dynamic>>;

      final eventNames = <String, String>{};
      final eventDates = <String, DateTime>{};
      final eventPrimaryIds = <String, String>{};
      for (final doc in promoterEventsSnap.docs) {
        final data = doc.data();
        final primaryEventId = doc.id;
        final aliasEventId = _readString(data['eventId']);
        final eventName = (data['title'] ?? data['name'] ?? primaryEventId)
            .toString();
        final eventDate = _readDate(
          data['eventDate'] ?? data['date'] ?? data['startTime'],
        );

        eventPrimaryIds[primaryEventId] = primaryEventId;
        eventNames[primaryEventId] = eventName;
        eventDates[primaryEventId] = eventDate;

        if (aliasEventId != null) {
          eventPrimaryIds[aliasEventId] = primaryEventId;
          eventNames[aliasEventId] = eventName;
          eventDates[aliasEventId] = eventDate;
        }
      }

      String resolvePrimaryEventId(String rawEventId) {
        return eventPrimaryIds[rawEventId] ?? rawEventId;
      }

      final latestReconciliationByEventId = <String, Map<String, dynamic>>{};
      final latestReconciliationAt = <String, DateTime>{};
      for (final doc in reconciliationsSnap.docs) {
        final data = doc.data();
        final rawEventId = _readString(data['eventId']) ?? doc.id;
        final primaryEventId = resolvePrimaryEventId(rawEventId);
        final reconciledAt = _readDate(
          data['reconciledAt'] ?? data['updatedAt'] ?? data['createdAt'],
        );
        final existingAt = latestReconciliationAt[primaryEventId];

        eventNames.putIfAbsent(
          primaryEventId,
          () => _readString(data['eventName']) ?? primaryEventId,
        );
        if (existingAt == null || reconciledAt.isAfter(existingAt)) {
          latestReconciliationByEventId[primaryEventId] = {
            ...data,
            '_docId': doc.id,
          };
          latestReconciliationAt[primaryEventId] = reconciledAt;
        }
      }

      final revenueShareByEventId =
          <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};
      for (final doc in revenueSharesSnap.docs) {
        final data = doc.data();
        final rawEventId = _readString(data['ppvEventId']) ?? doc.id;
        final primaryEventId = resolvePrimaryEventId(rawEventId);
        revenueShareByEventId[primaryEventId] = doc;
      }

      final allEventIds = <String>{
        ...promoterEventsSnap.docs.map((doc) => resolvePrimaryEventId(doc.id)),
        ...revenueShareByEventId.keys,
        ...latestReconciliationByEventId.keys,
      };

      final liveLedger =
          allEventIds
              .map((primaryEventId) {
                final revenueShareData =
                    revenueShareByEventId[primaryEventId]?.data() ??
                    const <String, dynamic>{};
                final reconciliationData =
                    latestReconciliationByEventId[primaryEventId] ??
                    const <String, dynamic>{};
                final hasReconciliation = reconciliationData.isNotEmpty;

                final gross = hasReconciliation
                    ? _readCurrencyAmount(
                        reconciliationData,
                        amountKeys: const [],
                        centKeys: const ['totalGrossCents'],
                      )
                    : _readDouble(revenueShareData['totalRevenue']);
                final promoterShare = hasReconciliation
                    ? _readCurrencyAmount(
                        reconciliationData,
                        amountKeys: const [],
                        centKeys: const ['totalPromoterCents'],
                      )
                    : _readDouble(revenueShareData['promoterAmount']);
                final platformShare = hasReconciliation
                    ? _readCurrencyAmount(
                        reconciliationData,
                        amountKeys: const [],
                        centKeys: const ['totalDfcCents'],
                      )
                    : _readDouble(revenueShareData['platformAmount']);
                final fighterShare = hasReconciliation
                    ? math
                          .max(0, gross - promoterShare - platformShare)
                          .toDouble()
                    : math
                          .max(
                            0,
                            _readDouble(revenueShareData['totalRevenue']) -
                                _readDouble(
                                  revenueShareData['promoterAmount'],
                                ) -
                                _readDouble(revenueShareData['platformAmount']),
                          )
                          .toDouble();
                final status = hasReconciliation
                    ? (_readString(reconciliationData['payoutState']) ??
                          _readString(reconciliationData['payoutStatus']) ??
                          'pending')
                    : (_readString(revenueShareData['payoutStatus']) ??
                          'pending');
                final date = hasReconciliation
                    ? _readDate(
                        reconciliationData['reconciledAt'] ??
                            reconciliationData['updatedAt'] ??
                            reconciliationData['createdAt'],
                      )
                    : _readDate(
                        revenueShareData['paidOutAt'] ??
                            revenueShareData['updatedAt'] ??
                            revenueShareData['createdAt'],
                      );

                return _LedgerEntry(
                  primaryEventId,
                  eventNames[primaryEventId] ?? primaryEventId,
                  gross,
                  promoterShare,
                  fighterShare,
                  platformShare,
                  status,
                  date,
                );
              })
              .where((entry) {
                return entry.gross > 0 ||
                    entry.promoterShare > 0 ||
                    _normalizeStatus(entry.status) != 'pending';
              })
              .toList()
            ..sort((left, right) => right.date.compareTo(left.date));

      final payoutDocs = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{
        for (final doc in payoutsHistoryCreatorSnap.docs) doc.id: doc,
        for (final doc in payoutsHistoryPromoterSnap.docs) doc.id: doc,
        for (final doc in payoutRequestsCreatorSnap.docs) doc.id: doc,
        for (final doc in payoutRequestsPromoterSnap.docs) doc.id: doc,
      };

      final latestPayoutsById = <String, _Payout>{};
      for (final doc in payoutDocs.values) {
        final data = doc.data();
        final payoutId =
            _readString(data['payoutId']) ?? doc.id.split('__attempt_').first;
        final rawEventId = _readString(data['eventId']);
        final primaryEventId = rawEventId == null
            ? null
            : resolvePrimaryEventId(rawEventId);
        final payoutDate = _readDate(
          data['payoutCompletedAt'] ??
              data['completedAt'] ??
              data['payoutFailedAt'] ??
              data['failedAt'] ??
              data['payoutRequestedAt'] ??
              data['requestedAt'] ??
              data['reconciledAt'] ??
              data['updatedAt'] ??
              data['createdAt'],
        );
        final payout = _Payout(
          payoutId,
          (_readString(data['description']) ??
                  _readString(data['label']) ??
                  (data['payoutType'] == 'reserve'
                      ? 'Reserve Release'
                      : 'Event Settlement'))
              .trim(),
          _readCurrencyAmount(
            data,
            centKeys: const ['amountCents', 'totalPayableCents'],
          ),
          _readString(data['payoutState']) ??
              _readString(data['status']) ??
              'pending',
          payoutDate,
          _readString(data['method']) ??
              _readString(data['payoutMethod']) ??
              'bank_transfer',
          eventId: primaryEventId,
          eventName: primaryEventId == null ? null : eventNames[primaryEventId],
          failureReason: _readString(
            data['payoutFailureReason'] ?? data['failureReason'],
          ),
        );

        final existing = latestPayoutsById[payoutId];
        if (existing == null || payout.date.isAfter(existing.date)) {
          latestPayoutsById[payoutId] = payout;
        }
      }

      for (final entry in latestReconciliationByEventId.entries) {
        final primaryEventId = entry.key;
        final data = entry.value;
        final payoutId =
            _readString(data['payoutId']) ??
            'event_settlement__$primaryEventId';
        if (latestPayoutsById.containsKey(payoutId)) {
          continue;
        }

        latestPayoutsById[payoutId] = _Payout(
          payoutId,
          'Event Settlement',
          _readCurrencyAmount(
            data,
            amountKeys: const [],
            centKeys: const ['totalPayableCents'],
          ),
          _readString(data['payoutState']) ??
              _readString(data['payoutStatus']) ??
              'pending',
          _readDate(
            data['reconciledAt'] ?? data['updatedAt'] ?? data['eventStartTime'],
          ),
          'bank_transfer',
          eventId: primaryEventId,
          eventName:
              eventNames[primaryEventId] ?? _readString(data['eventName']),
          failureReason: _readString(data['payoutFailureReason']),
        );
      }

      final livePayouts = latestPayoutsById.values.toList(growable: false)
        ..sort((left, right) => right.date.compareTo(left.date));

      final userData = userSnap.data() ?? const <String, dynamic>{};
      final connectedData = connectedSnap.data() ?? const <String, dynamic>{};
      final earningsData = earningsSnap.data() ?? const <String, dynamic>{};
      final liveGross = liveLedger.fold<double>(
        0,
        (total, entry) => total + entry.gross,
      );
      final livePaid = livePayouts
          .where((entry) => entry.status == 'completed')
          .fold<double>(0, (total, entry) => total + entry.amount);

      final hasLiveData =
          liveLedger.isNotEmpty ||
          livePayouts.isNotEmpty ||
          reconciliationsSnap.docs.isNotEmpty ||
          earningsSnap.exists ||
          promoterEventsSnap.docs.isNotEmpty;

      if (!mounted) return;

      setState(() {
        if (hasLiveData) {
          if (liveLedger.isNotEmpty) {
            _ledger = liveLedger;
          }
          if (livePayouts.isNotEmpty) {
            _payouts = livePayouts;
          }
          _promoters = [
            _Promoter(
              user.uid,
              (userData['organizationName'] ??
                      userData['displayName'] ??
                      user.email ??
                      'Current promoter')
                  .toString(),
              connectedData['onboardingComplete'] == true
                  ? 'Partner'
                  : 'Standard',
              connectedData['onboardingComplete'] == true,
              liveGross > 0
                  ? liveGross
                  : _readDouble(earningsData['lifetimeEarnings']),
              livePaid > 0
                  ? livePaid
                  : _readDouble(earningsData['lifetimePaidOut']),
              promoterEventsSnap.docs.length,
            ),
          ];
        }

        _isStripeConnected =
            connectedData['onboardingComplete'] == true ||
            connectedData['status'] == 'active';
        _isLoadingLiveData = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingLiveData = false;
      });
    }
  }

  Future<void> _exportLedgerCsv() async {
    final rows = <String>[
      'event_id,event_name,gross,promoter_share,fighter_share,platform_share,status,date',
      for (final entry in _ledger)
        [
          entry.eventId,
          '"${entry.eventName.replaceAll('"', '""')}"',
          entry.gross.toStringAsFixed(2),
          entry.promoterShare.toStringAsFixed(2),
          entry.fighterShare.toStringAsFixed(2),
          entry.platformShare.toStringAsFixed(2),
          entry.status,
          entry.date.toIso8601String(),
        ].join(','),
    ];

    await Clipboard.setData(ClipboardData(text: rows.join('\n')));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ledger CSV copied to clipboard'),
        backgroundColor: _green,
      ),
    );
  }

  Future<void> _requestPayout() async {
    final auth =
        widget.auth ??
        (widget.enableLiveDataLoad ? FirebaseAuth.instance : null);
    final user = auth?.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sign in to request a payout'),
          backgroundColor: _amber,
        ),
      );
      return;
    }

    try {
      final callable = FirebaseFunctions.instanceFor(
        region: 'australia-southeast1',
      ).httpsCallable('requestPromoterPayouts');
      final response = await callable.call({'promoterId': user.uid});
      final data = Map<String, dynamic>.from(
        response.data as Map<Object?, Object?>,
      );
      if (!mounted) return;

      final errorMessage = _readString(data['error']);
      if (errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      final requestedCount = (data['requestedCount'] as num?)?.toInt() ?? 0;
      final blockedCount = (data['blockedCount'] as num?)?.toInt() ?? 0;
      final skippedCount = (data['skippedCount'] as num?)?.toInt() ?? 0;
      final message = requestedCount > 0
          ? '$requestedCount event payout request${requestedCount == 1 ? '' : 's'} submitted'
          : blockedCount > 0
          ? '$blockedCount payout request${blockedCount == 1 ? '' : 's'} blocked until the Stripe account is ready'
          : skippedCount > 0
          ? 'No new payout requests created. Existing payout states are already authoritative.'
          : 'No payout-eligible events found.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: requestedCount > 0 ? _green : _amber,
        ),
      );

      await _loadLiveData();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payout request failed'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSummaryBar(),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _buildRevenueTab(),
                _buildLedgerTab(),
                _buildPayoutsTab(),
                _buildPromotersTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _panel,
      foregroundColor: _gold,
      elevation: 0,
      title: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 360;
          return Row(
            children: [
              const Icon(Icons.account_balance_wallet, color: _gold, size: 22),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'PAYOUT COMMAND',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Segoe UI',
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                    color: _gold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: _buildStripeStatusChip(compact: compact),
                  ),
                ),
              ),
              if (_isLoadingLiveData) ...[
                const SizedBox(width: 8),
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _cyan,
                  ),
                ),
              ],
            ],
          );
        },
      ),
      actions: [
        _appBarAction('EXPORT CSV', Icons.download, _cyan, _exportLedgerCsv),
        const SizedBox(width: 8),
        _appBarAction(
          'INSTANT CASHOUT',
          Icons.flash_on,
          _amber,
          _showInstantCashoutDialog,
        ),
        const SizedBox(width: 12),
      ],
      bottom: TabBar(
        controller: _tabCtrl,
        isScrollable: true,
        indicatorColor: _gold,
        labelColor: _gold,
        unselectedLabelColor: Colors.white54,
        labelStyle: const TextStyle(
          fontFamily: 'Segoe UI',
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        tabs: const [
          Tab(text: 'REVENUE'),
          Tab(text: 'LEDGER'),
          Tab(text: 'PAYOUTS'),
          Tab(text: 'PROMOTERS'),
        ],
      ),
    );
  }

  Widget _buildStripeStatusChip({bool compact = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: (_isStripeConnected ? _green : _amber).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: (_isStripeConnected ? _green : _amber).withValues(alpha: 0.4),
        ),
      ),
      child: Text(
        _isStripeConnected
            ? (compact ? 'CONNECTED' : 'STRIPE CONNECTED')
            : (compact ? 'PENDING' : 'STRIPE PENDING'),
        style: TextStyle(
          color: _isStripeConnected ? _green : _amber,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _appBarAction(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SUMMARY BAR
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildSummaryBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: _panel,
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _summaryChip(
              'GROSS REVENUE',
              '\$${_totalGross.toStringAsFixed(0)}',
              _gold,
            ),
            const SizedBox(width: 12),
            _summaryChip(
              'PROMOTER PAID',
              '\$${_totalPromoterPaid.toStringAsFixed(0)}',
              _green,
            ),
            const SizedBox(width: 12),
            _summaryChip(
              'FIGHTER POOL',
              '\$${_totalFighterPool.toStringAsFixed(0)}',
              _cyan,
            ),
            const SizedBox(width: 12),
            _summaryChip(
              'PLATFORM',
              '\$${_totalPlatform.toStringAsFixed(0)}',
              _magenta,
            ),
            const SizedBox(width: 12),
            _summaryChip('EVENTS', '${_ledger.length}', _amber),
            const SizedBox(width: 12),
            _summaryChip(
              'SPLIT',
              '${_promoterSplit.toInt()}/${_fighterPoolSplit.toInt()}/${_platformSplit.toInt()}',
              _gold,
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.7),
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              fontFamily: 'Segoe UI',
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 1 — Revenue Overview with split donut + bar chart
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildRevenueTab() {
    final isWide = MediaQuery.of(context).size.width > 900;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Split config
          _sectionHeader('REVENUE SPLIT CONFIG', _gold),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: _cardDecoration(),
            child: Column(
              children: [
                _splitSlider('Promoter', _promoterSplit, _green, (v) {
                  setState(() {
                    _promoterSplit = v;
                    _platformSplit = 100 - _promoterSplit - _fighterPoolSplit;
                  });
                }),
                _splitSlider('Fighter Pool', _fighterPoolSplit, _cyan, (v) {
                  setState(() {
                    _fighterPoolSplit = v;
                    _platformSplit = 100 - _promoterSplit - _fighterPoolSplit;
                  });
                }),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Platform: ',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    Text(
                      '${_platformSplit.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        color: _magenta,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Split donut (custom painted)
          if (isWide)
            Row(
              children: [
                Expanded(child: _splitDonut()),
                const SizedBox(width: 16),
                Expanded(child: _revenueByEvent()),
              ],
            )
          else ...[
            _splitDonut(),
            const SizedBox(height: 16),
            _revenueByEvent(),
          ],
          const SizedBox(height: 20),
          // KPI cards
          _sectionHeader('PAYOUT KPIs', _amber),
          const SizedBox(height: 12),
          Row(
            children: [
              _kpiCard('Avg Payout Speed', '3.2 days', _green, Icons.speed),
              const SizedBox(width: 8),
              _kpiCard(
                'Requested Payouts',
                '${_payouts.where((p) => _normalizeStatus(p.status) == 'requested' || _normalizeStatus(p.status) == 'processing').length}',
                _cyan,
                Icons.schedule,
              ),
              const SizedBox(width: 8),
              _kpiCard(
                'KYC Verified',
                '${_promoters.where((p) => p.kycVerified).length}/${_promoters.length}',
                _cyan,
                Icons.verified_user,
              ),
              const SizedBox(width: 8),
              _kpiCard('Dispute Rate', '0.2%', _green, Icons.gavel),
            ],
          ),
        ],
      ),
    );
  }

  Widget _splitSlider(
    String label,
    double value,
    Color color,
    ValueChanged<double> onChanged,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              activeTrackColor: color,
              thumbColor: color,
              inactiveTrackColor: color.withValues(alpha: 0.15),
              overlayColor: color.withValues(alpha: 0.1),
            ),
            child: Slider(
              value: value,
              max:
                  100 -
                  (label == 'Promoter' ? _fighterPoolSplit : _promoterSplit),
              onChanged: onChanged,
            ),
          ),
        ),
        SizedBox(
          width: 50,
          child: Text(
            '${value.toStringAsFixed(1)}%',
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _splitDonut() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          _sectionHeader('SPLIT VISUALIZATION', _gold),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: CustomPaint(
              size: const Size(180, 180),
              painter: _DonutPainter(
                promoter: _promoterSplit,
                fighter: _fighterPoolSplit,
                platform: _platformSplit,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendDot('Promoter ${_promoterSplit.toInt()}%', _green),
              const SizedBox(width: 16),
              _legendDot('Fighter ${_fighterPoolSplit.toInt()}%', _cyan),
              const SizedBox(width: 16),
              _legendDot('Platform ${_platformSplit.toInt()}%', _magenta),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendDot(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _revenueByEvent() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('REVENUE BY EVENT', _cyan),
          const SizedBox(height: 12),
          for (final e in _ledger)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e.eventName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          e.eventId,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.3),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '\$${e.gross.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: _gold,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Mini bar
                  SizedBox(
                    width: 80,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: e.gross / 20000,
                        backgroundColor: _surface,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _gold.withValues(alpha: 0.6),
                        ),
                        minHeight: 6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 2 — Ledger
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildLedgerTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('TRANSACTION LEDGER', _cyan),
          const SizedBox(height: 12),
          // Header row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'EVENT',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'GROSS',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
                Expanded(
                  child: Text(
                    'PROMOTER',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
                Expanded(
                  child: Text(
                    'FIGHTERS',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
                Expanded(
                  child: Text(
                    'PLATFORM',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: Text(
                    'STATUS',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: ListView.builder(
              itemCount: _ledger.length,
              itemBuilder: (ctx, i) => _ledgerRow(_ledger[i]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ledgerRow(_LedgerEntry e) {
    final statusColor = _statusColorFor(e.status);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey<String>('ledger-row-${e.eventId}'),
        borderRadius: BorderRadius.circular(8),
        onTap: () => context.pushNamed(
          rc.RouteConstants.promoterReconciliation,
          extra: e.eventId,
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: _panel,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _border),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e.eventName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${e.eventId} · ${e.date.day}/${e.date.month}/${e.date.year}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.35),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Text(
                  '\$${e.gross.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: _gold,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
              Expanded(
                child: Text(
                  '\$${e.promoterShare.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: _green,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
              Expanded(
                child: Text(
                  '\$${e.fighterShare.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: _cyan,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
              Expanded(
                child: Text(
                  '\$${e.platformShare.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: _magenta,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
              SizedBox(
                width: 80,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _statusLabelFor(e.status),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: Colors.white38, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 3 — Payouts
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildPayoutsTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _sectionHeader('PAYOUT HISTORY', _green),
              const Spacer(),
              _pillButton('REQUEST PAYOUT', _green, _requestPayout),
              const SizedBox(width: 8),
              _pillButton('INSTANT CASHOUT', _amber, _showInstantCashoutDialog),
            ],
          ),
          const SizedBox(height: 16),
          // Payout schedule info
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _green.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _green.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: _green, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                      children: const [
                        TextSpan(text: 'PPV settlements are '),
                        TextSpan(
                          text: 'reconciliation-backed',
                          style: TextStyle(
                            color: _green,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        TextSpan(
                          text: '. Main payouts are requested from the ',
                        ),
                        TextSpan(
                          text: 'event settlement ledger',
                          style: TextStyle(
                            color: _cyan,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        TextSpan(
                          text:
                              ', and reserve releases remain on the 28-day hold until the payout lane is clear.',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _payouts.length,
              itemBuilder: (ctx, i) => _payoutCard(_payouts[i]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _payoutCard(_Payout p) {
    final statusColor = _statusColorFor(p.status);
    final methodIcon = p.method == 'instant'
        ? Icons.flash_on
        : Icons.account_balance;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(methodIcon, color: statusColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.description,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (p.eventName != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    p.eventName!,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.64),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                Text(
                  '${p.id} · ${p.date.day}/${p.date.month}/${p.date.year} · ${p.method == 'instant' ? 'Instant' : 'Bank Transfer'}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 10,
                  ),
                ),
                if (p.failureReason != null && p.failureReason!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    p.failureReason!,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            '\$${p.amount.toStringAsFixed(2)}',
            style: const TextStyle(
              color: _gold,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              _statusLabelFor(p.status),
              style: TextStyle(
                color: statusColor,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 4 — Promoters
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildPromotersTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('PROMOTER ACCOUNTS', _cyan),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: _promoters.length,
              itemBuilder: (ctx, i) => _promoterCard(_promoters[i]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _promoterCard(_Promoter p) {
    final tierColor = p.tier == 'Partner' ? _gold : Colors.white54;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: tierColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                p.name.substring(0, 2).toUpperCase(),
                style: TextStyle(
                  color: tierColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
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
                      p.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: tierColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        p.tier,
                        style: TextStyle(
                          color: tierColor,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (p.kycVerified) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.verified, color: _green, size: 14),
                    ],
                  ],
                ),
                Text(
                  '${p.id} · ${p.events} events',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Gross: \$${p.grossRevenue.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: _gold,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Paid: \$${p.totalPaid.toStringAsFixed(0)}',
                style: const TextStyle(color: _green, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Instant Cashout Dialog
  // ═══════════════════════════════════════════════════════════════════════════
  void _showInstantCashoutDialog() {
    final pendingBalance = _ledger
        .where((e) => e.status == 'pending' || e.status == 'processing')
        .fold<double>(0, (s, e) => s + e.promoterShare);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _panel,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.flash_on, color: _amber, size: 22),
            SizedBox(width: 8),
            Text(
              'INSTANT CASHOUT',
              style: TextStyle(
                color: _amber,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Authority-Tracked Balance',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
            Text(
              '\$${pendingBalance.toStringAsFixed(2)}',
              style: const TextStyle(
                color: _gold,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _amber.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _amber.withValues(alpha: 0.2)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: _amber, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Instant cashout is retired for PPV settlements. Use REQUEST PAYOUT so the reconciliation ledger remains the only payout authority.',
                      style: TextStyle(color: _amber, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Current reconciliation-backed balance: \$${pendingBalance.toStringAsFixed(2)}',
              style: const TextStyle(
                color: _green,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CLOSE', style: TextStyle(color: Colors.white54)),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Shared helpers
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _sectionHeader(String text, Color color) {
    return Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: 14,
        fontWeight: FontWeight.w800,
        letterSpacing: 1,
      ),
    );
  }

  Widget _kpiCard(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: color.withValues(alpha: 0.6),
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _pillButton(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: _panel,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _border),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// DONUT PAINTER — Revenue split visualization
// ═══════════════════════════════════════════════════════════════════════════════
class _DonutPainter extends CustomPainter {
  final double promoter;
  final double fighter;
  final double platform;
  _DonutPainter({
    required this.promoter,
    required this.fighter,
    required this.platform,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 8;
    const strokeWidth = 28.0;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final total = promoter + fighter + platform;
    if (total <= 0) return;

    double startAngle = -math.pi / 2;

    void drawArc(double pct, Color color) {
      final sweep = (pct / total) * 2 * math.pi;
      canvas.drawArc(
        rect,
        startAngle,
        sweep,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.butt,
      );
      startAngle += sweep;
    }

    drawArc(promoter, const Color(0xFF00FF88));
    drawArc(fighter, const Color(0xFF00F5FF));
    drawArc(platform, const Color(0xFFFF00FF));
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.promoter != promoter ||
      old.fighter != fighter ||
      old.platform != platform;
}

// ═══════════════════════════════════════════════════════════════════════════════
// Data models
// ═══════════════════════════════════════════════════════════════════════════════
class _LedgerEntry {
  final String eventId, eventName, status;
  final double gross, promoterShare, fighterShare, platformShare;
  final DateTime date;
  _LedgerEntry(
    this.eventId,
    this.eventName,
    this.gross,
    this.promoterShare,
    this.fighterShare,
    this.platformShare,
    this.status,
    this.date,
  );
}

class _Payout {
  final String id, description, status, method;
  final double amount;
  final DateTime date;
  final String? eventId;
  final String? eventName;
  final String? failureReason;
  _Payout(
    this.id,
    this.description,
    this.amount,
    this.status,
    this.date,
    this.method, {
    this.eventId,
    this.eventName,
    this.failureReason,
  });
}

class _Promoter {
  final String id, name, tier;
  final bool kycVerified;
  final double grossRevenue, totalPaid;
  final int events;
  _Promoter(
    this.id,
    this.name,
    this.tier,
    this.kycVerified,
    this.grossRevenue,
    this.totalPaid,
    this.events,
  );
}
