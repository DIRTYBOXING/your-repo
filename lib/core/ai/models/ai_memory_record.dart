import 'package:equatable/equatable.dart';

/// Defines the scope and lifespan of the AI memory
enum AiMemoryType {
  /// Scope: Current app session (last few interactions). Store: In-memory/local cache.
  session,

  /// Scope: Fighter/gym/user history. Store: Firestore/DB per entity.
  profile,

  /// Scope: Specific "episodes" like a fight camp, event, or wellness cycle.
  episode,

  /// Scope: Module-specific (AstroHealth, Promoter, Gym, Feed).
  domain,
}

/// A unified memory structure used by all DFC AI Personas.
class AiMemoryRecord extends Equatable {
  final String personaId;
  final String ownerId;
  final String domain;
  final AiMemoryType type;
  final DateTime timestamp;
  final Map<String, dynamic> data;
  final List<String> tags;
  final int version;

  const AiMemoryRecord({
    required this.personaId,
    required this.ownerId,
    required this.domain,
    required this.type,
    required this.timestamp,
    required this.data,
    required this.tags,
    this.version = 1,
  });

  factory AiMemoryRecord.fromJson(Map<String, dynamic> json) {
    return AiMemoryRecord(
      personaId: json['persona_id'] as String? ?? '',
      ownerId: json['owner_id'] as String? ?? '',
      domain: json['domain'] as String? ?? '',
      type: AiMemoryType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => AiMemoryType.session,
      ),
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp'] as String) 
          : DateTime.now(),
      data: json['data'] as Map<String, dynamic>? ?? {},
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      version: json['version'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'persona_id': personaId,
      'owner_id': ownerId,
      'domain': domain,
      'type': type.name,
      'timestamp': timestamp.toIso8601String(),
      'data': data,
      'tags': tags,
      'version': version,
    };
  }

  @override
  List<Object?> get props => [
        personaId,
        ownerId,
        domain,
        type,
        timestamp,
        data,
        tags,
        version,
      ];
}
