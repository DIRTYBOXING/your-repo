import 'package:equatable/equatable.dart';

class Badge extends Equatable {
  final String id;
  final String name;
  final String description;
  final String iconPath;
  final int pointsRequired;

  const Badge({
    required this.id,
    required this.name,
    required this.description,
    required this.iconPath,
    required this.pointsRequired,
  });

  @override
  List<Object?> get props => [id, name, description, iconPath, pointsRequired];
}
