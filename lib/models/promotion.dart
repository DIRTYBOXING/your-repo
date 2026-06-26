class Promotion {
  final String id;
  final String title;
  final String description;
  final bool enabled;
  final Map<String, dynamic> ui;

  Promotion({
    required this.id,
    required this.title,
    required this.description,
    required this.enabled,
    required this.ui,
  });

  factory Promotion.fromMap(Map<String, dynamic> m) => Promotion(
    id: m['id'] as String,
    title: m['title'] as String,
    description: m['description'] as String,
    enabled: m['enabled'] as bool? ?? false,
    ui: Map<String, dynamic>.from(m['ui'] ?? {}),
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'description': description,
    'enabled': enabled,
    'ui': ui,
  };
}
