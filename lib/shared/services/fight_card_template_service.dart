import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/fight_card_template.dart';
import '../../core/utils/app_logger.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// FIGHT CARD TEMPLATE SERVICE
/// ═══════════════════════════════════════════════════════════════════════════
///
/// CRUD + share for fight card templates.
/// Coaches/promoters create templates, fill bouts, then print / download /
/// send to connected members.
///
/// ═══════════════════════════════════════════════════════════════════════════
class FightCardTemplateService extends ChangeNotifier {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  static const String _collection = 'fight_card_templates';

  List<FightCardTemplate> _myCards = [];
  List<FightCardTemplate> get myCards => _myCards;

  List<FightCardTemplate> _sharedWithMe = [];
  List<FightCardTemplate> get sharedWithMe => _sharedWithMe;

  bool _loading = false;
  bool get loading => _loading;

  // ─────────────────────────────────────────────────────────────────────────
  // LOAD
  // ─────────────────────────────────────────────────────────────────────────

  /// Cards created by current user
  Future<void> loadMyCards(String userId) async {
    _loading = true;
    notifyListeners();
    try {
      final snap = await _firestore
          .collection(_collection)
          .where('creatorId', isEqualTo: userId)
          .orderBy('updatedAt', descending: true)
          .get();
      _myCards = snap.docs
          .map(FightCardTemplate.fromFirestore)
          .toList();
    } catch (e) {
      AppLogger.error('loadMyCards failed', error: e, tag: 'FightCardSvc');
    }
    _loading = false;
    notifyListeners();
  }

  /// Cards that other users shared with me
  Future<void> loadSharedWithMe(String userId) async {
    try {
      final snap = await _firestore
          .collection(_collection)
          .where('sharedWith', arrayContains: userId)
          .orderBy('updatedAt', descending: true)
          .get();
      _sharedWithMe = snap.docs
          .map(FightCardTemplate.fromFirestore)
          .toList();
      notifyListeners();
    } catch (e) {
      AppLogger.error('loadSharedWithMe failed', error: e, tag: 'FightCardSvc');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CREATE / UPDATE
  // ─────────────────────────────────────────────────────────────────────────

  /// Create a new fight card template, returns the Firestore document ID
  Future<String?> createCard(FightCardTemplate card) async {
    try {
      final ref = await _firestore
          .collection(_collection)
          .add(card.toFirestore());
      AppLogger.info('Created fight card ${ref.id}', tag: 'FightCardSvc');
      return ref.id;
    } catch (e) {
      AppLogger.error('createCard failed', error: e, tag: 'FightCardSvc');
      return null;
    }
  }

  /// Overwrite an existing card
  Future<bool> updateCard(FightCardTemplate card) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(card.id)
          .set(card.toFirestore());
      // Refresh local list
      final idx = _myCards.indexWhere((c) => c.id == card.id);
      if (idx >= 0) {
        _myCards[idx] = card;
        notifyListeners();
      }
      return true;
    } catch (e) {
      AppLogger.error('updateCard failed', error: e, tag: 'FightCardSvc');
      return false;
    }
  }

  /// Delete a card
  Future<bool> deleteCard(String cardId) async {
    try {
      await _firestore.collection(_collection).doc(cardId).delete();
      _myCards.removeWhere((c) => c.id == cardId);
      notifyListeners();
      return true;
    } catch (e) {
      AppLogger.error('deleteCard failed', error: e, tag: 'FightCardSvc');
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SHARE / SEND
  // ─────────────────────────────────────────────────────────────────────────

  /// Share a card with another user (by userId).
  /// Also creates a notification doc so the recipient sees it.
  Future<bool> shareCard(String cardId, String recipientUserId) async {
    try {
      await _firestore.collection(_collection).doc(cardId).update({
        'sharedWith': FieldValue.arrayUnion([recipientUserId]),
      });

      // Write a notification for the recipient
      await _firestore.collection('notifications').add({
        'userId': recipientUserId,
        'type': 'fight_card_shared',
        'cardId': cardId,
        'message': 'A fight card has been shared with you',
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update local model
      final idx = _myCards.indexWhere((c) => c.id == cardId);
      if (idx >= 0) {
        final current = _myCards[idx];
        _myCards[idx] = current.copyWith(
          sharedWith: [...current.sharedWith, recipientUserId],
        );
        notifyListeners();
      }

      AppLogger.info(
        'Shared card $cardId with $recipientUserId',
        tag: 'FightCardSvc',
      );
      return true;
    } catch (e) {
      AppLogger.error('shareCard failed', error: e, tag: 'FightCardSvc');
      return false;
    }
  }

  /// Unshare a card from a user
  Future<bool> unshareCard(String cardId, String recipientUserId) async {
    try {
      await _firestore.collection(_collection).doc(cardId).update({
        'sharedWith': FieldValue.arrayRemove([recipientUserId]),
      });
      return true;
    } catch (e) {
      AppLogger.error('unshareCard failed', error: e, tag: 'FightCardSvc');
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SEARCH USERS TO SEND TO
  // ─────────────────────────────────────────────────────────────────────────

  /// Search connected users by display name (for share dialog)
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    if (query.trim().length < 2) return [];
    try {
      final snap = await _firestore
          .collection('users')
          .where('displayName', isGreaterThanOrEqualTo: query)
          .where('displayName', isLessThanOrEqualTo: '$query\uf8ff')
          .limit(10)
          .get();
      return snap.docs.map((d) {
        final data = d.data();
        return {
          'id': d.id,
          'displayName': data['displayName'] ?? '',
          'role': data['role'] ?? '',
          'photoUrl': data['photoUrl'],
        };
      }).toList();
    } catch (e) {
      AppLogger.error('searchUsers failed', error: e, tag: 'FightCardSvc');
      return [];
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HTML FOR PRINT / DOWNLOAD
  // ─────────────────────────────────────────────────────────────────────────

  /// Generate printable HTML for a fight card
  String generatePrintHtml(FightCardTemplate card) {
    final sorted = card.sortedBouts;
    final buffer = StringBuffer();

    buffer.writeln('<!DOCTYPE html><html><head>');
    buffer.writeln('<meta charset="UTF-8">');
    buffer.writeln(
      '<meta name="viewport" content="width=device-width, initial-scale=1">',
    );
    buffer.writeln('<title>${_esc(card.eventName)} — Fight Card</title>');
    buffer.writeln('<style>');
    buffer.writeln(_printCss);
    buffer.writeln('</style></head><body>');

    // Header
    buffer.writeln('<div class="header">');
    if (card.promotionName.isNotEmpty) {
      buffer.writeln(
        '<div class="promotion">${_esc(card.promotionName)}</div>',
      );
    }
    buffer.writeln('<h1>${_esc(card.eventName)}</h1>');
    buffer.writeln('<div class="meta">');
    buffer.writeln(
      '${_fmtDate(card.eventDate)} &bull; ${_esc(card.venue)}, ${_esc(card.city)}, ${_esc(card.country)}',
    );
    buffer.writeln('</div>');
    if (card.sanctioningBody.isNotEmpty) {
      buffer.writeln(
        '<div class="sanction">Sanctioned by ${_esc(card.sanctioningBody)}</div>',
      );
    }
    buffer.writeln('</div>');

    // Bouts
    for (final bout in sorted) {
      final isTitle = bout.titleFight != null && bout.titleFight!.isNotEmpty;
      buffer.writeln(
        '<div class="bout ${bout.position == BoutPosition.mainEvent ? "main-event" : ""}">',
      );
      buffer.writeln(
        '<div class="position">${bout.position.label}${isTitle ? " — ${_esc(bout.titleFight!)}" : ""}</div>',
      );
      buffer.writeln('<div class="matchup">');
      buffer.writeln('<div class="corner red">');
      buffer.writeln(
        '<div class="name">${_esc(bout.redCornerName.isEmpty ? "TBA" : bout.redCornerName)}</div>',
      );
      if (bout.redCornerRecord.isNotEmpty) {
        buffer.writeln(
          '<div class="record">(${_esc(bout.redCornerRecord)})</div>',
        );
      }
      if (bout.redCornerGym.isNotEmpty) {
        buffer.writeln('<div class="gym">${_esc(bout.redCornerGym)}</div>');
      }
      buffer.writeln('</div>');
      buffer.writeln('<div class="vs">VS</div>');
      buffer.writeln('<div class="corner blue">');
      buffer.writeln(
        '<div class="name">${_esc(bout.blueCornerName.isEmpty ? "TBA" : bout.blueCornerName)}</div>',
      );
      if (bout.blueCornerRecord.isNotEmpty) {
        buffer.writeln(
          '<div class="record">(${_esc(bout.blueCornerRecord)})</div>',
        );
      }
      if (bout.blueCornerGym.isNotEmpty) {
        buffer.writeln('<div class="gym">${_esc(bout.blueCornerGym)}</div>');
      }
      buffer.writeln('</div></div>');
      buffer.writeln(
        '<div class="details">${_esc(bout.weightClass)} &bull; ${bout.rounds} × ${bout.roundMinutes} min &bull; ${_esc(bout.rules)} (${_esc(bout.sportType)})</div>',
      );
      buffer.writeln('</div>');
    }

    // Notes
    if (card.notes != null && card.notes!.isNotEmpty) {
      buffer.writeln(
        '<div class="notes"><strong>Notes:</strong> ${_esc(card.notes!)}</div>',
      );
    }

    buffer.writeln(
      '<div class="footer">Generated by DataFightCentral &bull; ${_fmtDate(DateTime.now())}</div>',
    );
    buffer.writeln('</body></html>');
    return buffer.toString();
  }

  String _esc(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  static const String _printCss = '''
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { font-family: 'Segoe UI', Arial, sans-serif; background: #0A0E1A; color: #fff; padding: 32px; }
    .header { text-align: center; margin-bottom: 32px; border-bottom: 2px solid #00FFF0; padding-bottom: 20px; }
    .promotion { font-size: 14px; color: #00FFF0; letter-spacing: 3px; text-transform: uppercase; }
    h1 { font-size: 28px; margin: 8px 0; }
    .meta { color: #B0B8C8; font-size: 14px; }
    .sanction { color: #FFD700; font-size: 12px; margin-top: 6px; }
    .bout { background: #121828; border-radius: 12px; padding: 20px; margin-bottom: 16px; border-left: 4px solid #00FFF0; }
    .bout.main-event { border-left-color: #FFD700; background: #1A1A2E; }
    .position { color: #00FFF0; font-size: 12px; font-weight: bold; letter-spacing: 2px; text-transform: uppercase; margin-bottom: 10px; }
    .bout.main-event .position { color: #FFD700; }
    .matchup { display: flex; align-items: center; justify-content: space-between; gap: 16px; }
    .corner { flex: 1; }
    .corner.red { text-align: right; }
    .corner.blue { text-align: left; }
    .corner .name { font-size: 18px; font-weight: bold; }
    .corner.red .name { color: #FF4757; }
    .corner.blue .name { color: #4A9EFF; }
    .corner .record { font-size: 12px; color: #B0B8C8; }
    .corner .gym { font-size: 11px; color: #6B7280; }
    .vs { font-size: 20px; font-weight: bold; color: #6B7280; min-width: 40px; text-align: center; }
    .details { margin-top: 10px; font-size: 12px; color: #B0B8C8; text-align: center; }
    .notes { background: #1A2235; border-radius: 8px; padding: 14px; margin-top: 8px; font-size: 13px; color: #B0B8C8; }
    .footer { text-align: center; margin-top: 32px; font-size: 11px; color: #6B7280; }
    @media print {
      body { background: #fff; color: #000; }
      .header { border-bottom-color: #000; }
      .promotion { color: #333; }
      .bout { background: #f5f5f5; border-left-color: #333; }
      .bout.main-event { background: #eee; border-left-color: #c48700; }
      .position { color: #333; }
      .bout.main-event .position { color: #c48700; }
      .corner.red .name { color: #c00; }
      .corner.blue .name { color: #0066cc; }
      .vs { color: #999; }
      .details, .meta, .corner .record, .corner .gym { color: #666; }
      .notes { background: #f0f0f0; color: #333; }
      .footer { color: #999; }
    }
  ''';
}
