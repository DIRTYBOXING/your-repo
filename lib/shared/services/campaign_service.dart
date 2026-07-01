import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/marketing_campaign_model.dart';
import 'beast_mode_service.dart';

/// CampaignService — Full Firestore CRUD + aggregate stats for marketing campaigns.
/// Collection: `marketing_campaigns`
/// 🔥 Integrates with Beast Mode for amplified campaign reach!
class CampaignService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final BeastModeService _beastMode = BeastModeService();
  static const String _collection = 'marketing_campaigns';

  CollectionReference<Map<String, dynamic>> get _ref =>
      _db.collection(_collection);

  // ── CREATE ───────────────────────────────────────────────────────

  Future<String> createCampaign(MarketingCampaignModel campaign) async {
    final doc = await _ref.add(campaign.toFirestore());
    return doc.id;
  }

  // ── READ ─────────────────────────────────────────────────────────

  Future<MarketingCampaignModel?> getCampaign(String id) async {
    final doc = await _ref.doc(id).get();
    if (!doc.exists) return null;
    return MarketingCampaignModel.fromFirestore(doc);
  }

  Stream<List<MarketingCampaignModel>> streamCampaigns({
    CampaignStatus? status,
    MarketingCampaignType? type,
    String? createdBy,
    int limit = 50,
  }) {
    Query<Map<String, dynamic>> q = _ref.orderBy('createdAt', descending: true);
    if (status != null) q = q.where('status', isEqualTo: status.name);
    if (type != null) q = q.where('type', isEqualTo: type.name);
    if (createdBy != null) q = q.where('createdBy', isEqualTo: createdBy);
    q = q.limit(limit);

    return q.snapshots().map(
      (snap) => snap.docs
          .map(MarketingCampaignModel.fromFirestore)
          .toList(),
    );
  }

  Future<List<MarketingCampaignModel>> getCampaigns({
    CampaignStatus? status,
    int limit = 50,
  }) async {
    Query<Map<String, dynamic>> q = _ref.orderBy('createdAt', descending: true);
    if (status != null) q = q.where('status', isEqualTo: status.name);
    q = q.limit(limit);

    final snap = await q.get();
    return snap.docs
        .map(MarketingCampaignModel.fromFirestore)
        .toList();
  }

  // ── UPDATE ───────────────────────────────────────────────────────

  Future<void> updateCampaign(String id, Map<String, dynamic> fields) async {
    fields['updatedAt'] = FieldValue.serverTimestamp();
    await _ref.doc(id).update(fields);
  }

  Future<void> updateStatus(String id, CampaignStatus status) =>
      updateCampaign(id, {'status': status.name});

  Future<void> incrementMetric(String id, String metric, int amount) async {
    await _ref.doc(id).update({
      metric: FieldValue.increment(amount),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── DELETE ───────────────────────────────────────────────────────

  Future<void> deleteCampaign(String id) => _ref.doc(id).delete();

  // ── VARIANTS / A-B TESTING ───────────────────────────────────────

  Stream<List<CampaignVariant>> streamVariants(String campaignId) {
    return _db
        .collection('campaign_variants')
        .where('campaignId', isEqualTo: campaignId)
        .orderBy('createdAt')
        .snapshots()
        .map((s) => s.docs.map(CampaignVariant.fromFirestore).toList());
  }

  Future<String> createVariant(CampaignVariant variant) async {
    final doc = await _db
        .collection('campaign_variants')
        .add(variant.toFirestore());
    return doc.id;
  }

  Future<void> markWinner(String campaignId, String variantId) async {
    final snap = await _db
        .collection('campaign_variants')
        .where('campaignId', isEqualTo: campaignId)
        .get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {
        'isWinner': doc.id == variantId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  // ── AGGREGATE STATS ──────────────────────────────────────────────

  /// Returns a summary map of marketing KPIs across all campaigns.
  /// 🔥 Beast Mode multiplies reach, impressions, and conversions!
  Future<Map<String, dynamic>> getMarketingStats() async {
    final snap = await _ref.get();
    final campaigns = snap.docs
        .map(MarketingCampaignModel.fromFirestore)
        .toList();

    int totalImpressions = 0;
    int totalClicks = 0;
    int totalConversions = 0;
    int totalShares = 0;
    double totalBudget = 0;
    double totalSpent = 0;
    double totalRevenue = 0;
    int activeCampaigns = 0;
    int swarmPowered = 0;

    for (final c in campaigns) {
      totalImpressions += c.impressions;
      totalClicks += c.clicks;
      totalConversions += c.conversions;
      totalShares += c.shares;
      totalBudget += c.budgetTotal;
      totalSpent += c.budgetSpent;
      totalRevenue += c.revenue;
      if (c.status == CampaignStatus.active) activeCampaigns++;
      if (c.swarmPowered) swarmPowered++;
    }

    // 🔥 APPLY BEAST MODE AMPLIFICATION
    final beastMultiplier = _beastMode.reachMultiplier;
    if (_beastMode.isActive) {
      totalImpressions = (totalImpressions * beastMultiplier).round();
      totalClicks = (totalClicks * beastMultiplier).round();
      totalConversions = (totalConversions * beastMultiplier).round();
      totalShares = (totalShares * beastMultiplier).round();

      // Track Beast Mode boost
      _beastMode.trackReachIncrease(
        (totalImpressions * (beastMultiplier - 1)).toDouble(),
      );
    }

    return {
      'totalCampaigns': campaigns.length,
      'activeCampaigns': activeCampaigns,
      'totalImpressions': totalImpressions,
      'totalClicks': totalClicks,
      'totalConversions': totalConversions,
      'totalShares': totalShares,
      'ctr': totalImpressions > 0
          ? (totalClicks / totalImpressions * 100)
          : 0.0,
      'totalBudget': totalBudget,
      'totalSpent': totalSpent,
      'totalRevenue': totalRevenue,
      'roi': totalSpent > 0
          ? ((totalRevenue - totalSpent) / totalSpent * 100)
          : 0.0,
      'swarmPowered': swarmPowered,
      'beastModeActive': _beastMode.isActive,
      'beastMultiplier': beastMultiplier,
    };
  }
}
