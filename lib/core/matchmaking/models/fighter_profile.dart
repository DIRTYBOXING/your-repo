import 'package:equatable/equatable.dart';

class FighterProfile extends Equatable {
  final String id;
  final String name;
  final double weight;
  final String region;
  final bool medicallyCleared;
  final int ranking;

  const FighterProfile({
    required this.id,
    required this.name,
    required this.weight,
    required this.region,
    required this.medicallyCleared,
    required this.ranking,
  });

  @override
  List<Object?> get props => [id, name, weight, region, medicallyCleared, ranking];
}
