import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Payment event types tracked from Stripe webhooks.
enum PaymentEventType {
  paymentIntentSucceeded,
  chargeSucceeded,
  chargeRefunded,
  chargeDisputeCreated,
  chargeDisputeUpdated,
  payoutPaid,
  payoutFailed,
  transferCreated,
  transferFailed,
  accountUpdated,
  checkoutSessionCompleted,
}

/// Immutable payment event audit record.
///
/// Stored in Firestore `payment_events/{eventId}`.
/// Retains full Stripe webhook payloads for 90+ days for
/// provenance, fee verification, and dispute resolution.
class PaymentEventModel extends Equatable {
  /// Firestore document ID
  final String id;

  /// Links to paid_promotions/{promotionId} if applicable
  final String? promotionId;

  /// Stripe event ID (evt_...) — idempotency key
  final String stripeEventId;

  /// Event type from Stripe webhook
  final PaymentEventType eventType;

  /// Full or partial Stripe webhook payload (stored for audit)
  final Map<String, dynamic> payload;

  /// Stripe Connect account ID involved (acct_...)
  final String? connectedAccountId;

  /// When the webhook was received by DFC
  final DateTime receivedTs;

  const PaymentEventModel({
    required this.id,
    this.promotionId,
    required this.stripeEventId,
    required this.eventType,
    required this.payload,
    this.connectedAccountId,
    required this.receivedTs,
  });

  factory PaymentEventModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    return PaymentEventModel(
      id: doc.id,
      promotionId: d['promotionId'],
      stripeEventId: d['stripeEventId'] ?? '',
      eventType: PaymentEventType.values.firstWhere(
        (e) => e.name == d['eventType'],
        orElse: () => PaymentEventType.paymentIntentSucceeded,
      ),
      payload: Map<String, dynamic>.from(d['payload'] ?? {}),
      connectedAccountId: d['connectedAccountId'],
      receivedTs: (d['receivedTs'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    if (promotionId != null) 'promotionId': promotionId,
    'stripeEventId': stripeEventId,
    'eventType': eventType.name,
    'payload': payload,
    if (connectedAccountId != null) 'connectedAccountId': connectedAccountId,
    'receivedTs': Timestamp.fromDate(receivedTs),
  };

  @override
  List<Object?> get props => [id, stripeEventId, eventType];
}

/// Prediction audit record for neural-signal-ranked promotions.
///
/// Stored in Firestore `prediction_audit/{predictionId}`.
/// Tags every TRIBE/PSYCHE prediction used for ranking or promotion
/// with model version, confidence, and consent linkage.
class PredictionAuditModel extends Equatable {
  final String id;
  final String userId;
  final String modelVersion;

  /// Hash of the input features (for reproducibility without storing raw data)
  final String inputFeaturesHash;

  /// Human-readable prediction label
  final String predictionLabel;

  /// Model confidence score (0.0-1.0)
  final double confidence;

  /// Whether this prediction was used to rank feed content
  final bool usedForRanking;

  /// Confidence of the ranking decision that used this prediction
  final double? rankingConfidence;

  /// Consent token that authorized this prediction use
  final String? consentToken;

  final DateTime timestamp;

  const PredictionAuditModel({
    required this.id,
    required this.userId,
    required this.modelVersion,
    required this.inputFeaturesHash,
    required this.predictionLabel,
    required this.confidence,
    this.usedForRanking = false,
    this.rankingConfidence,
    this.consentToken,
    required this.timestamp,
  });

  factory PredictionAuditModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    return PredictionAuditModel(
      id: doc.id,
      userId: d['userId'] ?? '',
      modelVersion: d['modelVersion'] ?? '',
      inputFeaturesHash: d['inputFeaturesHash'] ?? '',
      predictionLabel: d['predictionLabel'] ?? '',
      confidence: (d['confidence'] as num?)?.toDouble() ?? 0,
      usedForRanking: d['usedForRanking'] ?? false,
      rankingConfidence: (d['rankingConfidence'] as num?)?.toDouble(),
      consentToken: d['consentToken'],
      timestamp: (d['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'userId': userId,
    'modelVersion': modelVersion,
    'inputFeaturesHash': inputFeaturesHash,
    'predictionLabel': predictionLabel,
    'confidence': confidence,
    'usedForRanking': usedForRanking,
    if (rankingConfidence != null) 'rankingConfidence': rankingConfidence,
    if (consentToken != null) 'consentToken': consentToken,
    'timestamp': Timestamp.fromDate(timestamp),
  };

  @override
  List<Object?> get props => [id, userId, modelVersion, inputFeaturesHash];
}
