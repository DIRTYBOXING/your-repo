class ContractModel {
  final String id;
  final String fighterName;
  final String offer;
  final String status;
  final int statusColorHex;

  ContractModel({
    required this.id,
    required this.fighterName,
    required this.offer,
    required this.status,
    required this.statusColorHex,
  });

  factory ContractModel.fromJson(Map<String, dynamic> json) => ContractModel(
        id: json['id'] ?? '',
        fighterName: json['fighterName'] ?? '',
        offer: json['offer'] ?? '',
        status: json['status'] ?? 'PENDING',
        statusColorHex: json['statusColorHex'] ?? 0xFFFFFFFF,
      );
}

class BudgetModel {
  final double total;
  final double committed;
  double get remaining => total - committed;
  BudgetModel({required this.total, required this.committed});
}