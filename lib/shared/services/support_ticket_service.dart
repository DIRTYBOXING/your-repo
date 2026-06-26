import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// SUPPORT TICKET SERVICE — Professional Help & Contact System
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Facebook-style support infrastructure:
///  - Users submit support tickets (stored in Firestore)
///  - Admin sees all tickets in Owner Command Center
///  - Ticket states: open → in_progress → resolved → closed
///  - Priority levels: low, normal, high, urgent
///  - Categories: account, billing, safety, bug, feature, content, other
///  - Admin can reply (creates audit trail)
///  - Email notifications via Cloud Functions (future)
///
/// Firestore collection: `support_tickets`
/// ═══════════════════════════════════════════════════════════════════════════

enum TicketStatus { open, inProgress, resolved, closed }

enum TicketPriority { low, normal, high, urgent }

enum TicketCategory {
  account,
  billing,
  safety,
  bug,
  featureRequest,
  content,
  technical,
  other,
}

class SupportTicket {
  final String id;
  final String userId;
  final String userEmail;
  final String userName;
  final String subject;
  final String description;
  final TicketCategory category;
  final TicketPriority priority;
  final TicketStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? resolvedAt;
  final String? assignedTo; // admin uid
  final List<TicketReply> replies;
  final Map<String, dynamic> metadata;

  const SupportTicket({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.userName,
    required this.subject,
    required this.description,
    this.category = TicketCategory.other,
    this.priority = TicketPriority.normal,
    this.status = TicketStatus.open,
    required this.createdAt,
    this.updatedAt,
    this.resolvedAt,
    this.assignedTo,
    this.replies = const [],
    this.metadata = const {},
  });

  String get statusLabel {
    switch (status) {
      case TicketStatus.open:
        return 'Open';
      case TicketStatus.inProgress:
        return 'In Progress';
      case TicketStatus.resolved:
        return 'Resolved';
      case TicketStatus.closed:
        return 'Closed';
    }
  }

  String get categoryLabel {
    switch (category) {
      case TicketCategory.account:
        return 'Account & Login';
      case TicketCategory.billing:
        return 'Billing & Subscription';
      case TicketCategory.safety:
        return 'Safety & Moderation';
      case TicketCategory.bug:
        return 'Bug Report';
      case TicketCategory.featureRequest:
        return 'Feature Request';
      case TicketCategory.content:
        return 'Content Issue';
      case TicketCategory.technical:
        return 'Technical Support';
      case TicketCategory.other:
        return 'Other';
    }
  }

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'userEmail': userEmail,
    'userName': userName,
    'subject': subject,
    'description': description,
    'category': category.name,
    'priority': priority.name,
    'status': status.name,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
    'assignedTo': assignedTo,
    'replies': replies.map((r) => r.toMap()).toList(),
    'metadata': metadata,
  };

  factory SupportTicket.fromMap(String id, Map<String, dynamic> map) {
    final repliesRaw = map['replies'] as List<dynamic>? ?? [];
    return SupportTicket(
      id: id,
      userId: map['userId'] as String? ?? '',
      userEmail: map['userEmail'] as String? ?? '',
      userName: map['userName'] as String? ?? '',
      subject: map['subject'] as String? ?? '',
      description: map['description'] as String? ?? '',
      category: TicketCategory.values.firstWhere(
        (c) => c.name == (map['category'] as String? ?? 'other'),
        orElse: () => TicketCategory.other,
      ),
      priority: TicketPriority.values.firstWhere(
        (p) => p.name == (map['priority'] as String? ?? 'normal'),
        orElse: () => TicketPriority.normal,
      ),
      status: TicketStatus.values.firstWhere(
        (s) => s.name == (map['status'] as String? ?? 'open'),
        orElse: () => TicketStatus.open,
      ),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
      resolvedAt: (map['resolvedAt'] as Timestamp?)?.toDate(),
      assignedTo: map['assignedTo'] as String?,
      replies: repliesRaw
          .map((r) => TicketReply.fromMap(r as Map<String, dynamic>))
          .toList(),
    );
  }
}

class TicketReply {
  final String authorId;
  final String authorName;
  final String message;
  final DateTime timestamp;
  final bool isAdmin;

  const TicketReply({
    required this.authorId,
    required this.authorName,
    required this.message,
    required this.timestamp,
    this.isAdmin = false,
  });

  Map<String, dynamic> toMap() => {
    'authorId': authorId,
    'authorName': authorName,
    'message': message,
    'timestamp': Timestamp.fromDate(timestamp),
    'isAdmin': isAdmin,
  };

  factory TicketReply.fromMap(Map<String, dynamic> map) {
    return TicketReply(
      authorId: map['authorId'] as String? ?? '',
      authorName: map['authorName'] as String? ?? '',
      message: map['message'] as String? ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isAdmin: map['isAdmin'] as bool? ?? false,
    );
  }
}

/// ─── Service ────────────────────────────────────────────────────────────

class SupportTicketService extends ChangeNotifier {
  SupportTicketService._();
  static final SupportTicketService _instance = SupportTicketService._();
  factory SupportTicketService() => _instance;

  final _firestore = FirebaseFirestore.instance;
  static const _collection = 'support_tickets';

  /// Platform contact info (visible to all users)
  static const String supportEmail = 'support@datafightcentral.com';
  static const String adminEmail = 'admin@datafightcentral.com';
  static const String websiteUrl = 'https://datafightcentral.web.app';
  static const String helpUrl = 'https://datafightcentral.web.app/help';

  // ── User Actions ──────────────────────────────────────────────────────

  /// Submit a new support ticket
  Future<String?> submitTicket({
    required String userId,
    required String userEmail,
    required String userName,
    required String subject,
    required String description,
    TicketCategory category = TicketCategory.other,
    TicketPriority priority = TicketPriority.normal,
  }) async {
    try {
      final doc = _firestore.collection(_collection).doc();
      final ticket = SupportTicket(
        id: doc.id,
        userId: userId,
        userEmail: userEmail,
        userName: userName,
        subject: subject,
        description: description,
        category: category,
        priority: priority,
        createdAt: DateTime.now(),
      );
      await doc.set(ticket.toMap());
      debugPrint('[Support] Ticket submitted: ${doc.id}');
      notifyListeners();
      return doc.id;
    } catch (e) {
      debugPrint('[Support] Submit error: $e');
      return null;
    }
  }

  /// Get user's own tickets
  Stream<List<SupportTicket>> myTickets(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => SupportTicket.fromMap(d.id, d.data()))
              .toList(),
        );
  }

  /// Add a reply to a ticket (user or admin)
  Future<bool> addReply({
    required String ticketId,
    required String authorId,
    required String authorName,
    required String message,
    bool isAdmin = false,
  }) async {
    try {
      final reply = TicketReply(
        authorId: authorId,
        authorName: authorName,
        message: message,
        timestamp: DateTime.now(),
        isAdmin: isAdmin,
      );
      await _firestore.collection(_collection).doc(ticketId).update({
        'replies': FieldValue.arrayUnion([reply.toMap()]),
        'updatedAt': FieldValue.serverTimestamp(),
        if (isAdmin) 'status': TicketStatus.inProgress.name,
      });
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[Support] Reply error: $e');
      return false;
    }
  }

  // ── Admin Actions ─────────────────────────────────────────────────────

  /// Get ALL tickets (admin view)
  Stream<List<SupportTicket>> allTickets({TicketStatus? filterStatus}) {
    Query<Map<String, dynamic>> query = _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true);

    if (filterStatus != null) {
      query = query.where('status', isEqualTo: filterStatus.name);
    }

    return query.snapshots().map(
      (snap) =>
          snap.docs.map((d) => SupportTicket.fromMap(d.id, d.data())).toList(),
    );
  }

  /// Update ticket status (admin)
  Future<bool> updateStatus({
    required String ticketId,
    required TicketStatus newStatus,
    String? adminId,
  }) async {
    try {
      final updates = <String, dynamic>{
        'status': newStatus.name,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (adminId != null) updates['assignedTo'] = adminId;
      if (newStatus == TicketStatus.resolved) {
        updates['resolvedAt'] = FieldValue.serverTimestamp();
      }
      await _firestore.collection(_collection).doc(ticketId).update(updates);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[Support] Status update error: $e');
      return false;
    }
  }

  /// Get ticket stats for admin dashboard
  Future<Map<String, int>> getTicketStats() async {
    try {
      final snap = await _firestore.collection(_collection).get();
      final tickets = snap.docs
          .map((d) => SupportTicket.fromMap(d.id, d.data()))
          .toList();
      return {
        'total': tickets.length,
        'open': tickets.where((t) => t.status == TicketStatus.open).length,
        'inProgress': tickets
            .where((t) => t.status == TicketStatus.inProgress)
            .length,
        'resolved': tickets
            .where((t) => t.status == TicketStatus.resolved)
            .length,
        'closed': tickets.where((t) => t.status == TicketStatus.closed).length,
      };
    } catch (e) {
      return {
        'total': 0,
        'open': 0,
        'inProgress': 0,
        'resolved': 0,
        'closed': 0,
      };
    }
  }
}
