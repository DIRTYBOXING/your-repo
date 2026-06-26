import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// ═══════════════════════════════════════════════════════════════════════
/// Identity Verification Service
///
/// Users submit ID (driver's licence / passport / govt ID) for review.
/// Verified users earn a Gold badge and trusted-account status.
/// This eliminates fake/spam accounts — only real people get badged.
/// ═══════════════════════════════════════════════════════════════════════

enum VerificationStatus {
  none,
  pending,
  verified,
  rejected,
  expired;

  String get label {
    switch (this) {
      case VerificationStatus.none:
        return 'Not Verified';
      case VerificationStatus.pending:
        return 'Under Review';
      case VerificationStatus.verified:
        return 'Verified';
      case VerificationStatus.rejected:
        return 'Rejected';
      case VerificationStatus.expired:
        return 'Expired';
    }
  }
}

enum IdDocumentType {
  driversLicence,
  passport,
  nationalId,
  governmentId;

  String get label {
    switch (this) {
      case IdDocumentType.driversLicence:
        return "Driver's Licence";
      case IdDocumentType.passport:
        return 'Passport';
      case IdDocumentType.nationalId:
        return 'National ID Card';
      case IdDocumentType.governmentId:
        return 'Government-Issued ID';
    }
  }
}

class IdentityVerification {
  final String id;
  final String userId;
  final IdDocumentType documentType;
  final String fullName;
  final String country;
  final VerificationStatus status;
  final DateTime submittedAt;
  final DateTime? reviewedAt;
  final String? reviewerNote;

  const IdentityVerification({
    required this.id,
    required this.userId,
    required this.documentType,
    required this.fullName,
    required this.country,
    required this.status,
    required this.submittedAt,
    this.reviewedAt,
    this.reviewerNote,
  });

  factory IdentityVerification.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return IdentityVerification(
      id: doc.id,
      userId: d['userId'] ?? '',
      documentType: IdDocumentType.values.firstWhere(
        (t) => t.name == d['documentType'],
        orElse: () => IdDocumentType.governmentId,
      ),
      fullName: d['fullName'] ?? '',
      country: d['country'] ?? '',
      status: VerificationStatus.values.firstWhere(
        (s) => s.name == d['status'],
        orElse: () => VerificationStatus.none,
      ),
      submittedAt: (d['submittedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reviewedAt: (d['reviewedAt'] as Timestamp?)?.toDate(),
      reviewerNote: d['reviewerNote'],
    );
  }

  Map<String, dynamic> toFirestore() => {
    'userId': userId,
    'documentType': documentType.name,
    'fullName': fullName,
    'country': country,
    'status': status.name,
    'submittedAt': Timestamp.fromDate(submittedAt),
    'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
    'reviewerNote': reviewerNote,
  };
}

class IdentityVerificationService extends ChangeNotifier {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  FirebaseAuth get _auth => FirebaseAuth.instance;

  static const String _collection = 'identity_verifications';

  VerificationStatus _status = VerificationStatus.none;
  IdentityVerification? _currentVerification;

  VerificationStatus get status => _status;
  IdentityVerification? get currentVerification => _currentVerification;
  bool get isVerified => _status == VerificationStatus.verified;

  /// Load verification status for current user.
  Future<void> loadStatus() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final snap = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: user.uid)
          .orderBy('submittedAt', descending: true)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) {
        _status = VerificationStatus.none;
        _currentVerification = null;
      } else {
        _currentVerification = IdentityVerification.fromFirestore(
          snap.docs.first,
        );
        _status = _currentVerification!.status;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('IdentityVerificationService: $e');
    }
  }

  /// Submit an ID verification request.
  Future<bool> submitVerification({
    required IdDocumentType documentType,
    required String fullName,
    required String country,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    // Prevent duplicate pending submissions
    if (_status == VerificationStatus.pending) return false;

    try {
      final verification = IdentityVerification(
        id: '',
        userId: user.uid,
        documentType: documentType,
        fullName: fullName,
        country: country,
        status: VerificationStatus.pending,
        submittedAt: DateTime.now(),
      );

      final docRef = await _firestore
          .collection(_collection)
          .add(verification.toFirestore());

      _currentVerification = IdentityVerification(
        id: docRef.id,
        userId: user.uid,
        documentType: documentType,
        fullName: fullName,
        country: country,
        status: VerificationStatus.pending,
        submittedAt: DateTime.now(),
      );
      _status = VerificationStatus.pending;

      // Mark user profile as pending verification
      await _firestore.collection('users').doc(user.uid).update({
        'verificationStatus': 'pending',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('IdentityVerificationService.submit: $e');
      return false;
    }
  }

  /// Check if the current user was approved and set isVerified on user doc.
  /// Called by admin functions / Cloud Function webhook.
  Future<void> approveVerification(String verificationId) async {
    await _firestore.collection(_collection).doc(verificationId).update({
      'status': VerificationStatus.verified.name,
      'reviewedAt': FieldValue.serverTimestamp(),
    });

    final doc = await _firestore
        .collection(_collection)
        .doc(verificationId)
        .get();
    final userId = doc.data()?['userId'];

    if (userId != null) {
      await _firestore.collection('users').doc(userId).update({
        'isVerified': true,
        'verificationStatus': 'verified',
        'verifiedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }
}
