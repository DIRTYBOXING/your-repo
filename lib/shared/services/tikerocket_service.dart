import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// TIKEROCKET SERVICE
// Digital ticketing + FightCoin wallet for DFC events.
// Handles: ticket purchase, transfer, resale, FightCoin balance, QR generation.
// ═══════════════════════════════════════════════════════════════════════════════

enum TicketStatus { active, used, transferred, cancelled, resale }

enum TicketType { general, vip, ringside, digital, ppv, gym }

class FightCoinLedger {
  final String id;
  final String userId;
  final double balance;
  final List<FightCoinTx> recentTxs;
  const FightCoinLedger({
    required this.id,
    required this.userId,
    required this.balance,
    this.recentTxs = const [],
  });
}

class FightCoinTx {
  final String id;
  final String fromUserId;
  final String? toUserId;
  final double amount;
  final String type; // 'purchase' | 'transfer' | 'resale' | 'refund' | 'reward'
  final String? eventId;
  final String? ticketId;
  final String description;
  final DateTime createdAt;
  const FightCoinTx({
    required this.id,
    required this.fromUserId,
    this.toUserId,
    required this.amount,
    required this.type,
    this.eventId,
    this.ticketId,
    required this.description,
    required this.createdAt,
  });
  factory FightCoinTx.fromMap(String id, Map<String, dynamic> m) => FightCoinTx(
    id: id,
    fromUserId: m['fromUserId'] ?? '',
    toUserId: m['toUserId'],
    amount: (m['amount'] ?? 0).toDouble(),
    type: m['type'] ?? 'purchase',
    eventId: m['eventId'],
    ticketId: m['ticketId'],
    description: m['description'] ?? '',
    createdAt: (m['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
  );
}

class DfcTicket {
  final String id;
  final String eventId;
  final String eventTitle;
  final String holderId;
  final String holderName;
  final TicketType type;
  final TicketStatus status;
  final double pricePaid; // in AUD
  final double fightCoinsSpent;
  final String qrCode; // unique QR payload
  final DateTime eventDate;
  final String? seat;
  final DateTime issuedAt;
  final bool isResale;
  final double? resalePrice;

  const DfcTicket({
    required this.id,
    required this.eventId,
    required this.eventTitle,
    required this.holderId,
    required this.holderName,
    required this.type,
    required this.status,
    required this.pricePaid,
    this.fightCoinsSpent = 0,
    required this.qrCode,
    required this.eventDate,
    this.seat,
    required this.issuedAt,
    this.isResale = false,
    this.resalePrice,
  });

  factory DfcTicket.fromMap(String id, Map<String, dynamic> m) => DfcTicket(
    id: id,
    eventId: m['eventId'] ?? '',
    eventTitle: m['eventTitle'] ?? 'DFC Event',
    holderId: m['holderId'] ?? '',
    holderName: m['holderName'] ?? 'Fighter Fan',
    type: TicketType.values.firstWhere(
      (t) => t.name == (m['type'] ?? 'general'),
      orElse: () => TicketType.general,
    ),
    status: TicketStatus.values.firstWhere(
      (s) => s.name == (m['status'] ?? 'active'),
      orElse: () => TicketStatus.active,
    ),
    pricePaid: (m['pricePaid'] ?? 0).toDouble(),
    fightCoinsSpent: (m['fightCoinsSpent'] ?? 0).toDouble(),
    qrCode: m['qrCode'] ?? id,
    eventDate: (m['eventDate'] as dynamic)?.toDate() ?? DateTime.now(),
    seat: m['seat'],
    issuedAt: (m['issuedAt'] as dynamic)?.toDate() ?? DateTime.now(),
    isResale: m['isResale'] == true,
    resalePrice: m['resalePrice']?.toDouble(),
  );
}

class TikeRocketService extends ChangeNotifier {
  static final TikeRocketService _i = TikeRocketService._();
  factory TikeRocketService() => _i;
  TikeRocketService._();

  final _fs = FirebaseFirestore.instance;
  final _fns = FirebaseFunctions.instanceFor(region: 'australia-southeast1');

  // ── FightCoin Wallet ────────────────────────────────────────────────────────

  Stream<FightCoinLedger> watchWallet(String userId) => _fs
      .collection('fightcoin_wallets')
      .doc(userId)
      .snapshots()
      .asyncMap((doc) async {
        final data = doc.data() ?? {};
        final txSnap = await _fs
            .collection('fightcoin_transactions')
            .where('fromUserId', isEqualTo: userId)
            .orderBy('createdAt', descending: true)
            .limit(20)
            .get();
        return FightCoinLedger(
          id: doc.id,
          userId: userId,
          balance: (data['balance'] ?? 0).toDouble(),
          recentTxs: txSnap.docs
              .map((d) => FightCoinTx.fromMap(d.id, d.data()))
              .toList(),
        );
      });

  Future<double> getBalance(String userId) async {
    final doc = await _fs.collection('fightcoin_wallets').doc(userId).get();
    return (doc.data()?['balance'] ?? 0).toDouble();
  }

  Future<bool> transferFightCoins({
    required String fromUserId,
    required String toUserId,
    required double amount,
    String? eventId,
    String description = 'FightCoin transfer',
  }) async {
    try {
      final callable = _fns.httpsCallable('transferFightCoins');
      final res = await callable.call({
        'fromUserId': fromUserId,
        'toUserId': toUserId,
        'amount': amount,
        'eventId': eventId,
        'description': description,
      });
      notifyListeners();
      return res.data['success'] == true;
    } catch (e) {
      debugPrint('TikeRocket.transferFightCoins: $e');
      return false;
    }
  }

  // ── Ticket Purchase ─────────────────────────────────────────────────────────

  Future<DfcTicket?> purchaseTicket({
    required String userId,
    required String userName,
    required String eventId,
    required String eventTitle,
    required DateTime eventDate,
    required TicketType type,
    required double priceAud,
    double fightCoinsToSpend = 0,
    String? preferredSeat,
    String paymentMethod = 'stripe', // 'stripe' | 'fightcoin' | 'hybrid'
  }) async {
    try {
      final callable = _fns.httpsCallable('purchaseTicket');
      final res = await callable.call({
        'userId': userId,
        'userName': userName,
        'eventId': eventId,
        'eventTitle': eventTitle,
        'eventDate': eventDate.toIso8601String(),
        'ticketType': type.name,
        'priceAud': priceAud,
        'fightCoinsToSpend': fightCoinsToSpend,
        'preferredSeat': preferredSeat,
        'paymentMethod': paymentMethod,
      });
      if (res.data['ticketId'] != null) {
        final ticketDoc = await _fs
            .collection('tickets')
            .doc(res.data['ticketId'] as String)
            .get();
        if (ticketDoc.exists) {
          notifyListeners();
          return DfcTicket.fromMap(ticketDoc.id, ticketDoc.data()!);
        }
      }
      return null;
    } catch (e) {
      debugPrint('TikeRocket.purchaseTicket: $e');
      return null;
    }
  }

  // ── Ticket Transfer (P2P) ───────────────────────────────────────────────────

  Future<bool> transferTicket({
    required String ticketId,
    required String fromUserId,
    required String toUserId,
    required String toUserName,
  }) async {
    try {
      await _fs.collection('tickets').doc(ticketId).update({
        'holderId': toUserId,
        'holderName': toUserName,
        'status': 'active',
        'transferredAt': FieldValue.serverTimestamp(),
        'previousHolder': fromUserId,
      });
      // Log FightCoin ledger entry for tracking
      await _fs.collection('fightcoin_transactions').add({
        'fromUserId': fromUserId,
        'toUserId': toUserId,
        'amount': 0,
        'type': 'transfer',
        'ticketId': ticketId,
        'description': 'Ticket transferred',
        'createdAt': FieldValue.serverTimestamp(),
      });
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('TikeRocket.transferTicket: $e');
      return false;
    }
  }

  // ── Ticket Resale ───────────────────────────────────────────────────────────

  Future<bool> listForResale({
    required String ticketId,
    required String userId,
    required double resalePrice,
  }) async {
    try {
      await _fs.collection('tickets').doc(ticketId).update({
        'status': 'resale',
        'resalePrice': resalePrice,
        'resaleListedAt': FieldValue.serverTimestamp(),
        'resaleListedBy': userId,
      });
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('TikeRocket.listForResale: $e');
      return false;
    }
  }

  Future<bool> buyResaleTicket({
    required String ticketId,
    required String buyerId,
    required String buyerName,
  }) async {
    try {
      final callable = _fns.httpsCallable('buyResaleTicket');
      final res = await callable.call({
        'ticketId': ticketId,
        'buyerId': buyerId,
        'buyerName': buyerName,
      });
      notifyListeners();
      return res.data['success'] == true;
    } catch (e) {
      debugPrint('TikeRocket.buyResaleTicket: $e');
      return false;
    }
  }

  // ── My Tickets ──────────────────────────────────────────────────────────────

  Stream<List<DfcTicket>> watchMyTickets(String userId) => _fs
      .collection('tickets')
      .where('holderId', isEqualTo: userId)
      .orderBy('eventDate', descending: false)
      .snapshots()
      .map(
        (snap) =>
            snap.docs.map((d) => DfcTicket.fromMap(d.id, d.data())).toList(),
      );

  Future<List<DfcTicket>> getMyTickets(String userId) async {
    final snap = await _fs
        .collection('tickets')
        .where('holderId', isEqualTo: userId)
        .orderBy('eventDate', descending: false)
        .get();
    return snap.docs.map((d) => DfcTicket.fromMap(d.id, d.data())).toList();
  }

  // ── Resale Marketplace ──────────────────────────────────────────────────────

  Stream<List<DfcTicket>> watchResaleMarket({String? eventId}) {
    var query =
        _fs.collection('tickets').where('status', isEqualTo: 'resale')
            as Query<Map<String, dynamic>>;
    if (eventId != null) {
      query = query.where('eventId', isEqualTo: eventId);
    }
    return query
        .orderBy('resalePrice')
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => DfcTicket.fromMap(d.id, d.data())).toList(),
        );
  }

  // ── Validate QR (gate scan) ─────────────────────────────────────────────────

  Future<Map<String, dynamic>> validateTicketQr(String qrPayload) async {
    try {
      final snap = await _fs
          .collection('tickets')
          .where('qrCode', isEqualTo: qrPayload)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) {
        return {'valid': false, 'reason': 'Ticket not found'};
      }
      final ticket = DfcTicket.fromMap(
        snap.docs.first.id,
        snap.docs.first.data(),
      );
      if (ticket.status == TicketStatus.used) {
        return {'valid': false, 'reason': 'Already scanned', 'ticket': ticket};
      }
      if (ticket.status == TicketStatus.cancelled) {
        return {'valid': false, 'reason': 'Ticket cancelled', 'ticket': ticket};
      }
      // Mark as used
      await snap.docs.first.reference.update({
        'status': 'used',
        'scannedAt': FieldValue.serverTimestamp(),
      });
      return {'valid': true, 'ticket': ticket};
    } catch (e) {
      return {'valid': false, 'reason': 'Scan error: $e'};
    }
  }
}
