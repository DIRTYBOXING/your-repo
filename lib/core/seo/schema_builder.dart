import 'dart:convert';

/// ═══════════════════════════════════════════════════════════════════════════
/// SCHEMA BUILDER (Rich Snippets / JSON-LD)
/// Generates structured data for Google Search so entities appear as rich cards
/// ═══════════════════════════════════════════════════════════════════════════
class SchemaBuilder {
  /// Builds JSON-LD Schema for a Fighter Profile
  static String buildFighterSchema({
    required String name,
    required String gymAffiliation,
    required String record,
    String? imageUrl,
  }) {
    final schema = {
      "@context": "https://schema.org",
      "@type": "Person",
      "name": name,
      "jobTitle": "Professional Fighter",
      "affiliation": {
        "@type": "SportsOrganization",
        "name": gymAffiliation,
      },
      "description": "Professional Combat Athlete with a record of $record.",
      ...?((imageUrl != null) ? {"image": imageUrl} : null),
    };
    return jsonEncode(schema);
  }

  /// Builds JSON-LD Schema for a PPV Event
  static String buildEventSchema({
    required String eventName,
    required String startDate,
    required String locationName,
    String? posterUrl,
    List<Map<String, String>>? fightCard,
  }) {
    final schema = {
      "@context": "https://schema.org",
      "@type": "SportsEvent",
      "name": eventName,
      "startDate": startDate,
      "location": {
        "@type": "Place",
        "name": locationName,
      },
      ...?((posterUrl != null) ? {"image": posterUrl} : null),
      ...?((fightCard != null) ? {"subEvent": fightCard.map((fight) => {
          "@type": "SportsEvent",
          "name": "${fight['fighterA']} vs ${fight['fighterB']}"
        }).toList()} : null),
    };
    return jsonEncode(schema);
  }

  /// Builds JSON-LD Schema for a Gym/Camp
  static String buildGymSchema({
    required String gymName,
    required String address,
    required String specialties,
  }) {
    final schema = {
      "@context": "https://schema.org",
      "@type": "HealthAndBeautyBusiness",
      "name": gymName,
      "address": address,
      "description": "Premium combat sports facility specializing in $specialties",
    };
    return jsonEncode(schema);
  }
}
