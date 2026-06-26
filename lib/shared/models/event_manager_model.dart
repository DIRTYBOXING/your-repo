/// Fight Card Event Model
/// Represents a single fight in the event lineup (e.g., Fight 1, Semifinal, Main Event)
library;

class FightCardEvent {
  final int order; // 1, 2, 3, ...
  final String label; // e.g., 'Fight 1', 'Semifinal', 'Main Event'
  final String fighterA;
  final String fighterB;
  final String type; // e.g., 'Prelim', 'Semi', 'Main Event'

  FightCardEvent({
    required this.order,
    required this.label,
    required this.fighterA,
    required this.fighterB,
    required this.type,
  });
}

/// Example usage:
/// FightCardEvent(order: 1, label: 'Fight 1', fighterA: 'John Doe', fighterB: 'Max Power', type: 'Prelim')
