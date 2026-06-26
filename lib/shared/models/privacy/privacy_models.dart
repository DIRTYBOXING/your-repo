class Consent {
  final String userId;
  final bool locationConsent;
  final bool healthConsent;
  final bool analyticsConsent;
  final bool adsConsent;
  final bool marketingConsent;
  final bool communityConsent;

  Consent({
    required this.userId,
    required this.locationConsent,
    required this.healthConsent,
    required this.analyticsConsent,
    required this.adsConsent,
    required this.marketingConsent,
    required this.communityConsent,
  });
}

class Verification {
  final String userId;
  final bool isVerified;
  final DateTime verificationDate;

  Verification({
    required this.userId,
    required this.isVerified,
    required this.verificationDate,
  });
}

class AuditLog {
  final String id;
  final String userId;
  final String action;
  final DateTime timestamp;

  AuditLog({
    required this.id,
    required this.userId,
    required this.action,
    required this.timestamp,
  });
}
