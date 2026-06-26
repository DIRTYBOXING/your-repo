import 'package:flutter/material.dart';

/// Listing types surfaced in the marketplace.
enum ListingType { promoter, clinic, brand, wellness }

extension ListingTypeDetails on ListingType {
  String get label {
    switch (this) {
      case ListingType.promoter:
        return 'Promoter Offer';
      case ListingType.clinic:
        return 'Recovery Clinic';
      case ListingType.brand:
        return 'Brand Collaboration';
      case ListingType.wellness:
        return 'Wellness Lab';
    }
  }

  Color get accentColor {
    switch (this) {
      case ListingType.promoter:
        return const Color(0xFFFF6B6B);
      case ListingType.clinic:
        return const Color(0xFF4ECDC4);
      case ListingType.brand:
        return const Color(0xFF9D4EDD);
      case ListingType.wellness:
        return const Color(0xFF48BFE3);
    }
  }
}

class MarketplaceListing {
  const MarketplaceListing({
    required this.id,
    required this.title,
    required this.organization,
    required this.description,
    required this.compensation,
    required this.location,
    required this.tags,
    required this.type,
    required this.closingDate,
  });

  final String id;
  final String title;
  final String organization;
  final String description;
  final String compensation;
  final String location;
  final List<String> tags;
  final ListingType type;
  final DateTime closingDate;
}

class MarketplaceApplication {
  const MarketplaceApplication({
    required this.listing,
    required this.status,
    required this.submittedAt,
  });

  final MarketplaceListing listing;
  final String status;
  final DateTime submittedAt;
}

class MarketplaceBooking {
  const MarketplaceBooking({
    required this.listing,
    required this.windowStart,
    required this.windowEnd,
  });

  final MarketplaceListing listing;
  final DateTime windowStart;
  final DateTime windowEnd;
}
