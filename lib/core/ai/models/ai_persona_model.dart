import 'package:equatable/equatable.dart';

class AIPersonaModel extends Equatable {
  final String id;
  final String name;
  final String role;
  final List<String> domain;
  final Map<String, bool> logic;
  final Map<String, bool> memory;
  final List<String> boundaries;

  const AIPersonaModel({
    required this.id,
    required this.name,
    required this.role,
    required this.domain,
    required this.logic,
    required this.memory,
    required this.boundaries,
  });

  factory AIPersonaModel.fromJson(Map<String, dynamic> json) {
    return AIPersonaModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      role: json['role'] as String? ?? '',
      domain: (json['domain'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      logic: (json['logic'] as Map<String, dynamic>?)?.map((k, v) => MapEntry(k, v as bool)) ?? {},
      memory: (json['memory'] as Map<String, dynamic>?)?.map((k, v) => MapEntry(k, v as bool)) ?? {},
      boundaries: (json['boundaries'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'role': role,
      'domain': domain,
      'logic': logic,
      'memory': memory,
      'boundaries': boundaries,
    };
  }

  @override
  List<Object?> get props => [id, name, role, domain, logic, memory, boundaries];
}
