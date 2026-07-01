// ═══════════════════════════════════════════════════════════════════════════
// WAR ROOM APPROVALS SERVICE — Flutter client for Atlas approval endpoints
// Talks to Cloud Functions: approvalsList, approvalsDetail, approvalsDecision,
// approvalsEscalate, approvalsStats
// ═══════════════════════════════════════════════════════════════════════════

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

const String _functionsRegion = 'australia-southeast1';

class ApprovalTicket {
  final String ticketId;
  final String jobId;
  final String assetId;
  final String assetTitle;
  final String type;
  final String requester;
  final double estimatedSpendUsd;
  final int influencerCount;
  final double confidence;
  final String status;
  final String rationale;
  final Map<String, dynamic> provenance;
  final List<dynamic> outputs;
  final Map<String, dynamic> safetyFlags;
  final DateTime? createdAt;
  final String? reviewerId;
  final String? comments;

  ApprovalTicket({
    required this.ticketId,
    required this.jobId,
    required this.assetId,
    required this.assetTitle,
    required this.type,
    required this.requester,
    required this.estimatedSpendUsd,
    required this.influencerCount,
    required this.confidence,
    required this.status,
    required this.rationale,
    required this.provenance,
    required this.outputs,
    required this.safetyFlags,
    this.createdAt,
    this.reviewerId,
    this.comments,
  });

  factory ApprovalTicket.fromMap(Map<String, dynamic> m) {
    final prov = m['provenance'];
    return ApprovalTicket(
      ticketId: m['ticketId'] ?? '',
      jobId: m['jobId'] ?? '',
      assetId: m['assetId'] ?? '',
      assetTitle: m['assetTitle'] ?? 'Untitled',
      type: m['type'] ?? 'publish',
      requester: m['requester'] ?? '',
      estimatedSpendUsd: ((m['estimatedSpendUsd'] as num?) ?? 0).toDouble(),
      influencerCount: ((m['influencerCount'] as num?) ?? 0).toInt(),
      confidence: prov is Map ? ((prov['confidence'] as num?) ?? 0).toDouble() : 0.0,
      status: m['status'] ?? 'pending',
      rationale: m['rationale'] ?? '',
      provenance: prov is Map<String, dynamic> ? prov : {},
      outputs: m['outputs'] is List ? m['outputs'] : [],
      safetyFlags: m['safetyFlags'] is Map<String, dynamic>
          ? m['safetyFlags']
          : {},
      createdAt: m['createdAt'] != null
          ? DateTime.tryParse(m['createdAt'].toString())
          : null,
      reviewerId: m['reviewerId'],
      comments: m['comments'],
    );
  }

  bool get requiresLegal => safetyFlags['requiresLegal'] == true;
  bool get hasMedicalGate => safetyFlags['medicalGate'] == true;
  bool get hasAgeGating => safetyFlags['ageGating'] == true;
  bool get hasSafetyFlags => requiresLegal || hasMedicalGate || hasAgeGating;
}

class ApprovalStats {
  final int pending;
  final int approved;
  final int rejected;
  final int escalated;

  ApprovalStats({
    required this.pending,
    required this.approved,
    required this.rejected,
    required this.escalated,
  });

  int get total => pending + approved + rejected + escalated;
}

class WarRoomApprovalsService with ChangeNotifier {
  final _functions = FirebaseFunctions.instanceFor(region: _functionsRegion);
  final _firestore = FirebaseFirestore.instance;

  List<ApprovalTicket> _tickets = [];
  ApprovalStats _stats = ApprovalStats(
    pending: 0,
    approved: 0,
    rejected: 0,
    escalated: 0,
  );
  bool _loading = false;

  List<ApprovalTicket> get tickets => _tickets;
  List<ApprovalTicket> get pendingTickets =>
      _tickets.where((t) => t.status == 'pending').toList();
  ApprovalStats get stats => _stats;
  bool get loading => _loading;

  /// Fetch pending approval tickets
  Future<void> fetchPendingApprovals() async {
    _loading = true;
    notifyListeners();

    try {
      final result = await _functions.httpsCallable('approvalsList').call({
        'status': 'pending',
      });
      final data = result.data as Map<String, dynamic>;
      final ticketList = data['tickets'] as List<dynamic>? ?? [];
      _tickets = ticketList
          .map((t) => ApprovalTicket.fromMap(Map<String, dynamic>.from(t)))
          .toList();
    } catch (e) {
      debugPrint('fetchPendingApprovals error: $e');
      // Fallback: read directly from Firestore
      await _fetchFromFirestore();
    }

    _loading = false;
    notifyListeners();
  }

  /// Fallback Firestore read
  Future<void> _fetchFromFirestore() async {
    try {
      final snap = await _firestore
          .collection('atlas_approvals')
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      _tickets = snap.docs.map((doc) {
        final m = doc.data();
        m['ticketId'] = doc.id;
        if (m['createdAt'] is Timestamp) {
          m['createdAt'] = (m['createdAt'] as Timestamp)
              .toDate()
              .toIso8601String();
        }
        return ApprovalTicket.fromMap(m);
      }).toList();
    } catch (e) {
      debugPrint('Firestore fallback error: $e');
    }
  }

  /// Stream pending approvals in real-time
  Stream<List<ApprovalTicket>> streamPendingApprovals() {
    return _firestore
        .collection('atlas_approvals')
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snap) => snap.docs.map((doc) {
            final m = doc.data();
            m['ticketId'] = doc.id;
            if (m['createdAt'] is Timestamp) {
              m['createdAt'] = (m['createdAt'] as Timestamp)
                  .toDate()
                  .toIso8601String();
            }
            return ApprovalTicket.fromMap(m);
          }).toList(),
        );
  }

  /// Approve a ticket
  Future<bool> approveTicket({
    required String ticketId,
    required String reviewerId,
    String? comments,
    double? budgetOverrideUsd,
  }) async {
    try {
      final payload = <String, dynamic>{
        'ticketId': ticketId,
        'decision': 'approve',
        'reviewerId': reviewerId,
        'comments': comments ?? '',
      };
      if (budgetOverrideUsd != null) {
        payload['budgetOverrideUsd'] = budgetOverrideUsd;
      }
      await _functions.httpsCallable('approvalsDecision').call(payload);
      _tickets.removeWhere((t) => t.ticketId == ticketId);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('approveTicket error: $e');
      return false;
    }
  }

  /// Reject a ticket (reason required)
  Future<bool> rejectTicket({
    required String ticketId,
    required String reviewerId,
    required String reason,
  }) async {
    try {
      await _functions.httpsCallable('approvalsDecision').call({
        'ticketId': ticketId,
        'decision': 'reject',
        'reviewerId': reviewerId,
        'comments': reason,
      });
      _tickets.removeWhere((t) => t.ticketId == ticketId);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('rejectTicket error: $e');
      return false;
    }
  }

  /// Escalate a ticket
  Future<bool> escalateTicket({
    required String ticketId,
    required String to,
    required String reason,
    String? escalatedBy,
  }) async {
    try {
      await _functions.httpsCallable('approvalsEscalate').call({
        'ticketId': ticketId,
        'to': to,
        'reason': reason,
        'escalatedBy': escalatedBy ?? 'war_room_operator',
      });
      _tickets.removeWhere((t) => t.ticketId == ticketId);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('escalateTicket error: $e');
      return false;
    }
  }

  /// Fetch stats
  Future<void> fetchStats() async {
    try {
      final result = await _functions.httpsCallable('approvalsStats').call({});
      final data = result.data as Map<String, dynamic>;
      _stats = ApprovalStats(
        pending: ((data['pending'] as num?) ?? 0).toInt(),
        approved: ((data['approved'] as num?) ?? 0).toInt(),
        rejected: ((data['rejected'] as num?) ?? 0).toInt(),
        escalated: ((data['escalated'] as num?) ?? 0).toInt(),
      );
      notifyListeners();
    } catch (e) {
      debugPrint('fetchStats error: $e');
    }
  }
}
