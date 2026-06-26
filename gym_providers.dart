import 'package:flutter_riverpod/flutter_riverpod.dart';

class Gym {
  final String id;
  final String name;
  Gym({required this.id, required this.name});
}

class Fighter {
  final String id;
  final String name;
  Fighter({required this.id, required this.name});
}

final gymProvider = Provider<Gym>((ref) {
  return Gym(id: 'g_001', name: 'Data Fight Central Gym');
});

final gymFightersProvider = Provider<List<Fighter>>((ref) {
  return [
    Fighter(id: 'F123', name: 'John Doe'),
    Fighter(id: 'F124', name: 'Jane Smith'),
  ];
});
