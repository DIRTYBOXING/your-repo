import 'package:cloud_firestore/cloud_firestore.dart';

/// A single evaluated condition within a campaign DSL rule.
class RuleCondition {
  final String field;
  final String op;
  final dynamic value;

  const RuleCondition({
    required this.field,
    required this.op,
    required this.value,
  });

  factory RuleCondition.fromMap(Map<String, dynamic> m) {
    return RuleCondition(
      field: m['field'] as String? ?? '',
      op: m['op'] as String? ?? '==',
      value: m['value'],
    );
  }

  Map<String, dynamic> toMap() => {'field': field, 'op': op, 'value': value};
}

/// A compiled campaign promotion rule with conditions and effect payload.
/// Maps to Firestore `rules/{ruleId}`.
///
/// Allowed condition fields: market, event_days_until, fighter,
/// engagement_last_24h, min_followers, region, audience_tag.
/// Allowed operators: ==, !=, >, <, >=, <=, IN, NOT IN.
/// Effect schema: discount must include discount_pct, boost must include boost_score.
class RuleModel {
  final String id;
  final String campaignId;
  final String type;
  final List<RuleCondition> conditions;
  final Map<String, dynamic> effect;
  final bool stackable;
  final int priority;
  final DateTime? createdAt;

  const RuleModel({
    required this.id,
    required this.campaignId,
    required this.type,
    required this.conditions,
    required this.effect,
    this.stackable = false,
    this.priority = 100,
    this.createdAt,
  });

  factory RuleModel.fromFirestore(DocumentSnapshot doc) {
    final m = doc.data() as Map<String, dynamic>? ?? {};
    final condList = (m['conditions'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(RuleCondition.fromMap)
        .toList();
    return RuleModel(
      id: doc.id,
      campaignId: m['campaign_id'] as String? ?? '',
      type: m['type'] as String? ?? 'discount',
      conditions: condList,
      effect: m['effect'] as Map<String, dynamic>? ?? {},
      stackable: m['stackable'] as bool? ?? false,
      priority: (m['priority'] as num?)?.toInt() ?? 100,
      createdAt: (m['created_at'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'campaign_id': campaignId,
    'type': type,
    'conditions': conditions.map((c) => c.toMap()).toList(),
    'effect': effect,
    'stackable': stackable,
    'priority': priority,
    if (createdAt != null) 'created_at': Timestamp.fromDate(createdAt!),
  };
}
