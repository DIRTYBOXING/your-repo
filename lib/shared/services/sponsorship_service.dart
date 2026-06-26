import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/sponsorship_model.dart';

/// Sponsorship Marketplace Service
/// Connects fighters with brand sponsorship opportunities
class SponsorshipService {
  final FirebaseFirestore _firestore;

  SponsorshipService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Get all open sponsorship opportunities (marketplace browse)
  Future<List<Sponsorship>> getOpenSponsorships({
    int limit = 20,
    SponsorshipCategory? categoryFilter,
    double? minValue,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firestore
          .collection('sponsorships')
          .where('status', isEqualTo: 'open')
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (categoryFilter != null) {
        query = _firestore
            .collection('sponsorships')
            .where('status', isEqualTo: 'open')
            .where(
              'category',
              isEqualTo: categoryFilter.toString().split('.').last,
            )
            .orderBy('createdAt', descending: true)
            .limit(limit);
      }

      if (minValue != null) {
        query = _firestore
            .collection('sponsorships')
            .where('status', isEqualTo: 'open')
            .where('valueUSD', isGreaterThanOrEqualTo: minValue)
            .orderBy('valueUSD', descending: true)
            .orderBy('createdAt', descending: true)
            .limit(limit);
      }

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snap = await query.get();
      return snap.docs.map(Sponsorship.fromFirestore).toList();
    } catch (e) {
      debugPrint('Error fetching open sponsorships: $e');
      return [];
    }
  }

  /// Get sponsorships for a specific fighter (current deals + applications)
  Future<List<Sponsorship>> getFighterSponsorships({
    required String fighterId,
  }) async {
    try {
      final snap = await _firestore
          .collection('sponsorships')
          .where('fighterId', isEqualTo: fighterId)
          .orderBy('createdAt', descending: true)
          .get();

      return snap.docs.map(Sponsorship.fromFirestore).toList();
    } catch (e) {
      debugPrint('Error fetching fighter sponsorships: $e');
      return [];
    }
  }

  /// Get sponsorships fighter has applied to
  Future<List<Sponsorship>> getFighterApplications({
    required String fighterId,
  }) async {
    try {
      final snap = await _firestore
          .collection('sponsorships')
          .where('applicantIds', arrayContains: fighterId)
          .orderBy('createdAt', descending: true)
          .get();

      return snap.docs.map(Sponsorship.fromFirestore).toList();
    } catch (e) {
      debugPrint('Error fetching fighter applications: $e');
      return [];
    }
  }

  /// Get brand's sponsorship postings
  Future<List<Sponsorship>> getBrandSponsorships({
    required String brandId,
  }) async {
    try {
      final snap = await _firestore
          .collection('sponsorships')
          .where('brandId', isEqualTo: brandId)
          .orderBy('createdAt', descending: true)
          .get();

      return snap.docs.map(Sponsorship.fromFirestore).toList();
    } catch (e) {
      debugPrint('Error fetching brand sponsorships: $e');
      return [];
    }
  }

  /// Fighter applies for a sponsorship
  Future<bool> applyForSponsorship({
    required String sponsorshipId,
    required String fighterId,
    required String fighterName,
    required String fighterPhoto,
  }) async {
    try {
      final sponsorshipRef = _firestore
          .collection('sponsorships')
          .doc(sponsorshipId);
      final sponsorship = await sponsorshipRef.get();

      if (!sponsorship.exists) return false;

      final current = Sponsorship.fromFirestore(sponsorship);
      final applicants = current.applicantIds ?? [];

      // Check if already applied
      if (applicants.contains(fighterId)) {
        debugPrint('Already applied for this sponsorship');
        return false;
      }

      // Add fighter to applicants
      applicants.add(fighterId);

      await sponsorshipRef.update({
        'applicantIds': applicants,
        'applicantCount': applicants.length,
      });

      // Create application record
      await _firestore.collection('sponsorship_applications').add({
        'sponsorshipId': sponsorshipId,
        'fighterId': fighterId,
        'fighterName': fighterName,
        'fighterPhoto': fighterPhoto,
        'appliedAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      return true;
    } catch (e) {
      debugPrint('Error applying for sponsorship: $e');
      return false;
    }
  }

  /// Create new sponsorship (brand side)
  Future<String?> createSponsorship({
    required String brandId,
    required String brandName,
    required String brandLogo,
    required String title,
    required String description,
    required double valueUSD,
    required int durationMonths,
    required SponsorshipCategory category,
    List<String>? requirements,
    List<String>? deliverables,
    bool isVerified = false,
    double rating = 3.0,
  }) async {
    try {
      final sponsorship = Sponsorship(
        id: '', // Will be set by Firestore
        brandId: brandId,
        brandName: brandName,
        brandLogo: brandLogo,
        status: SponsorshipStatus.open,
        category: category,
        title: title,
        description: description,
        valueUSD: valueUSD,
        durationMonths: durationMonths,
        createdAt: DateTime.now(),
        requirements: requirements ?? [],
        deliverables: deliverables ?? [],
        isVerified: isVerified,
        rating: rating,
      );

      final docRef = await _firestore
          .collection('sponsorships')
          .add(sponsorship.toFirestore());

      return docRef.id;
    } catch (e) {
      debugPrint('Error creating sponsorship: $e');
      return null;
    }
  }

  /// Accept fighter for sponsorship (brand side)
  Future<bool> acceptApplicant({
    required String sponsorshipId,
    required String fighterId,
    required String fighterName,
    required String fighterPhoto,
  }) async {
    try {
      final sponsorshipRef = _firestore
          .collection('sponsorships')
          .doc(sponsorshipId);

      await sponsorshipRef.update({
        'fighterId': fighterId,
        'fighterName': fighterName,
        'fighterPhoto': fighterPhoto,
        'status': 'active',
        'startsAt': FieldValue.serverTimestamp(),
      });

      // Mark application as accepted
      final appSnap = await _firestore
          .collection('sponsorship_applications')
          .where('sponsorshipId', isEqualTo: sponsorshipId)
          .where('fighterId', isEqualTo: fighterId)
          .get();

      if (appSnap.docs.isNotEmpty) {
        await appSnap.docs.first.reference.update({'status': 'accepted'});
      }

      return true;
    } catch (e) {
      debugPrint('Error accepting applicant: $e');
      return false;
    }
  }

  /// Reject fighter application
  Future<bool> rejectApplicant({
    required String sponsorshipId,
    required String fighterId,
  }) async {
    try {
      final sponsorshipRef = _firestore
          .collection('sponsorships')
          .doc(sponsorshipId);
      final sponsorship = await sponsorshipRef.get();

      if (!sponsorship.exists) return false;

      final current = Sponsorship.fromFirestore(sponsorship);
      final applicants = current.applicantIds ?? [];
      applicants.removeWhere((id) => id == fighterId);

      await sponsorshipRef.update({
        'applicantIds': applicants,
        'applicantCount': applicants.length,
      });

      // Mark application as rejected
      final appSnap = await _firestore
          .collection('sponsorship_applications')
          .where('sponsorshipId', isEqualTo: sponsorshipId)
          .where('fighterId', isEqualTo: fighterId)
          .get();

      if (appSnap.docs.isNotEmpty) {
        await appSnap.docs.first.reference.update({'status': 'rejected'});
      }

      return true;
    } catch (e) {
      debugPrint('Error rejecting applicant: $e');
      return false;
    }
  }

  /// Search sponsorships by title/category
  Future<List<Sponsorship>> searchSponsorships({
    required String query,
    SponsorshipCategory? category,
  }) async {
    try {
      var searchQuery = _firestore
          .collection('sponsorships')
          .where('status', isEqualTo: 'open');

      if (category != null) {
        searchQuery = searchQuery.where(
          'category',
          isEqualTo: category.toString().split('.').last,
        );
      }

      final snap = await searchQuery.get();
      final results = snap.docs.map(Sponsorship.fromFirestore).toList();

      // Client-side filter by title/description
      final q = query.toLowerCase();
      return results
          .where(
            (s) =>
                s.title.toLowerCase().contains(q) ||
                s.description.toLowerCase().contains(q) ||
                s.brandName.toLowerCase().contains(q),
          )
          .toList();
    } catch (e) {
      debugPrint('Error searching sponsorships: $e');
      return [];
    }
  }

  /// Stream top sponsorship opportunities (real-time market)
  Stream<List<Sponsorship>> streamTopSponsorships({int limit = 10}) {
    return _firestore
        .collection('sponsorships')
        .where('status', isEqualTo: 'open')
        .where('isVerified', isEqualTo: true)
        .orderBy('rating', descending: true)
        .orderBy('valueUSD', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(Sponsorship.fromFirestore).toList());
  }

  /// Get sponsorship by ID
  Future<Sponsorship?> getSponsorship(String id) async {
    try {
      final doc = await _firestore.collection('sponsorships').doc(id).get();
      if (!doc.exists) return null;
      return Sponsorship.fromFirestore(doc);
    } catch (e) {
      debugPrint('Error fetching sponsorship: $e');
      return null;
    }
  }
}
