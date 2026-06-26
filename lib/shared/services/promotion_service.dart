import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/promotion_model.dart';

/// Event Promotion Service — Young fighters + mentor guidance
class PromotionService {
  final FirebaseFirestore _firestore;

  PromotionService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Create promotion campaign (fighter side)
  Future<String?> createCampaign({
    required String fighterId,
    required String fighterName,
    required String title,
    required String description,
    required String eventId,
    required String eventTitle,
    List<PromotionChannel>? channels,
    int targetReach = 1000,
    bool requiresMentorApproval = true,
  }) async {
    try {
      final campaign = PromotionCampaign(
        id: '', // Will be set by Firestore
        fighterId: fighterId,
        fighterName: fighterName,
        title: title,
        description: description,
        eventId: eventId,
        eventTitle: eventTitle,
        createdAt: DateTime.now(),
        channels:
            channels ?? [PromotionChannel.social, PromotionChannel.messaging],
        targetReach: targetReach,
        requiresMentorApproval: requiresMentorApproval,
      );

      final docRef = await _firestore
          .collection('promotion_campaigns')
          .add(campaign.toFirestore());

      return docRef.id;
    } catch (e) {
      debugPrint('Error creating promotion campaign: $e');
      return null;
    }
  }

  /// Get campaigns for a fighter
  Future<List<PromotionCampaign>> getFighterCampaigns({
    required String fighterId,
  }) async {
    try {
      final snap = await _firestore
          .collection('promotion_campaigns')
          .where('fighterId', isEqualTo: fighterId)
          .orderBy('createdAt', descending: true)
          .get();

      return snap.docs.map(PromotionCampaign.fromFirestore).toList();
    } catch (e) {
      debugPrint('Error fetching fighter campaigns: $e');
      return [];
    }
  }

  /// Get campaigns awaiting mentor approval
  Future<List<PromotionCampaign>> getPendingApprovalCampaigns({
    required String mentorId,
  }) async {
    try {
      final snap = await _firestore
          .collection('promotion_campaigns')
          .where('mentorId', isEqualTo: mentorId)
          .where('requiresMentorApproval', isEqualTo: true)
          .where('isApproved', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .get();

      return snap.docs.map(PromotionCampaign.fromFirestore).toList();
    } catch (e) {
      debugPrint('Error fetching pending campaigns: $e');
      return [];
    }
  }

  /// Mentor assigns themselves to help with a campaign
  Future<bool> assignMentor({
    required String campaignId,
    required String mentorId,
    required String mentorName,
  }) async {
    try {
      await _firestore.collection('promotion_campaigns').doc(campaignId).update(
        {'mentorId': mentorId, 'mentorName': mentorName},
      );

      return true;
    } catch (e) {
      debugPrint('Error assigning mentor: $e');
      return false;
    }
  }

  /// Mentor approves campaign for promotion
  Future<bool> approveCampaign({
    required String campaignId,
    required String mentorId,
  }) async {
    try {
      final campaign = await _firestore
          .collection('promotion_campaigns')
          .doc(campaignId)
          .get();

      if (!campaign.exists) return false;

      final current = PromotionCampaign.fromFirestore(campaign);
      final chain = [
        ...current.approvalChain,
        '$mentorId:${DateTime.now().toIso8601String()}',
      ];

      await _firestore.collection('promotion_campaigns').doc(campaignId).update(
        {'isApproved': true, 'approvalChain': chain, 'status': 'active'},
      );

      return true;
    } catch (e) {
      debugPrint('Error approving campaign: $e');
      return false;
    }
  }

  /// Mentor rejects campaign with feedback message
  Future<bool> rejectCampaign({
    required String campaignId,
    required String mentorId,
    required String feedback,
  }) async {
    try {
      await _firestore.collection('promotion_campaigns').doc(campaignId).update(
        {
          'status': 'draft',
          'metadata': {
            'lastRejectionBy': mentorId,
            'lastRejectionReason': feedback,
            'lastRejectionAt': DateTime.now().toIso8601String(),
          },
        },
      );

      return true;
    } catch (e) {
      debugPrint('Error rejecting campaign: $e');
      return false;
    }
  }

  /// Update promotion message for a channel
  Future<bool> updateMessage({
    required String campaignId,
    required PromotionChannel channel,
    required String message,
  }) async {
    try {
      final campaign = await _firestore
          .collection('promotion_campaigns')
          .doc(campaignId)
          .get();

      if (!campaign.exists) return false;

      final current = PromotionCampaign.fromFirestore(campaign);
      final messages = Map<String, String>.from(current.messages);
      messages[channel.toString().split('.').last] = message;

      await _firestore.collection('promotion_campaigns').doc(campaignId).update(
        {'messages': messages},
      );

      return true;
    } catch (e) {
      debugPrint('Error updating message: $e');
      return false;
    }
  }

  /// Record engagement (click, share, message from promotion)
  Future<bool> recordEngagement({
    required String campaignId,
    required String engagementType, // 'click', 'share', 'message', 'view'
  }) async {
    try {
      await _firestore.collection('promotion_campaigns').doc(campaignId).update(
        {'engagements': FieldValue.increment(1)},
      );

      return true;
    } catch (e) {
      debugPrint('Error recording engagement: $e');
      return false;
    }
  }

  /// Get promotion templates for fighters to choose from
  Future<List<Map<String, dynamic>>> getPromotionTemplates() async {
    try {
      final snap = await _firestore
          .collection('promotion_templates')
          .where('isPublic', isEqualTo: true)
          .get();

      return snap.docs.map((d) => d.data()).toList();
    } catch (e) {
      debugPrint('Error fetching templates: $e');
      return [];
    }
  }

  /// Get promotion guidelines/best practices for young fighters
  Future<List<Map<String, dynamic>>> getPromotionGuidelines() async {
    try {
      final snap = await _firestore
          .collection('promotion_guidelines')
          .orderBy('priority', descending: true)
          .get();

      return snap.docs.map((d) => d.data()).toList();
    } catch (e) {
      debugPrint('Error fetching guidelines: $e');
      return [];
    }
  }

  /// Stream active campaigns for analytics dashboard
  Stream<List<PromotionCampaign>> streamActiveCampaigns({
    required String fighterId,
  }) {
    return _firestore
        .collection('promotion_campaigns')
        .where('fighterId', isEqualTo: fighterId)
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snap) {
          final campaigns =
              snap.docs.map(PromotionCampaign.fromFirestore).toList();
          if (campaigns.isEmpty) return _demoCampaigns(fighterId);
          return campaigns;
        })
        .handleError((_) {
          return _demoCampaigns(fighterId);
        });
  }

  /// Demo campaigns for showcase when Firestore has no data
  static List<PromotionCampaign> _demoCampaigns(String fighterId) {
    final now = DateTime.now();
    return [
      PromotionCampaign(
        id: 'demo_campaign_1',
        fighterId: fighterId,
        fighterName: 'Jordan Roesler',
        title: 'Ultimate Legends — April 24 Fight Night',
        description:
            'Promoting my main card bout at the April 24 Ultimate Legends event. Ticket sales, hype content, and fight week coverage.',
        mentorId: 'coach_ray',
        mentorName: 'Coach Ray Mitchell',
        eventId: 'demo_event_ul_apr24',
        eventTitle: 'Ultimate Legends — April 24',
        status: PromotionStatus.active,
        isApproved: true,
        channels: const [
          PromotionChannel.social,
          PromotionChannel.messaging,
          PromotionChannel.video,
        ],
        targetReach: 5000,
        currentReach: 3420,
        engagements: 287,
        createdAt: now.subtract(const Duration(days: 12)),
        expiresAt: now.add(const Duration(days: 8)),
      ),
      PromotionCampaign(
        id: 'demo_campaign_2',
        fighterId: fighterId,
        fighterName: 'Jordan Roesler',
        title: 'Fight Camp Diaries — Behind the Scenes',
        description:
            'Weekly training content series building up to fight night. Sparring clips, weight cuts, and camp life.',
        mentorId: 'coach_ray',
        mentorName: 'Coach Ray Mitchell',
        eventId: 'demo_event_ul_apr24',
        eventTitle: 'Ultimate Legends — April 24',
        status: PromotionStatus.active,
        isApproved: true,
        channels: const [PromotionChannel.social, PromotionChannel.video],
        targetReach: 2000,
        currentReach: 1180,
        engagements: 94,
        createdAt: now.subtract(const Duration(days: 7)),
        expiresAt: now.add(const Duration(days: 14)),
      ),
    ];
  }

  /// Get single campaign
  Future<PromotionCampaign?> getCampaign(String id) async {
    try {
      final doc = await _firestore
          .collection('promotion_campaigns')
          .doc(id)
          .get();
      if (!doc.exists) return null;
      return PromotionCampaign.fromFirestore(doc);
    } catch (e) {
      debugPrint('Error fetching campaign: $e');
      return null;
    }
  }
}
