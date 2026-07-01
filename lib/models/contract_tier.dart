class ContractTier {
  final String id;
  final String name;
  final Map<String, dynamic> criteria;
  final String rateKey;

  ContractTier({
    required this.id,
    required this.name,
    required this.criteria,
    required this.rateKey,
  });

  factory ContractTier.fromMap(Map<String, dynamic> m) => ContractTier(
    id: m['id'] as String,
    name: m['name'] as String,
    criteria: Map<String, dynamic>.from(m['criteria'] ?? {}),
    rateKey: m['rate_key'] as String,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'criteria': criteria,
    'rate_key': rateKey,
  };
}
