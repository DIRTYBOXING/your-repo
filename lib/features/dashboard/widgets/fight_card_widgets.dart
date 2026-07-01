import 'package:flutter/material.dart';

class FightCardEntry {
  final String redCorner;
  final String blueCorner;
  final String redGym;
  final String blueGym;
  final String weightClass;
  final String title;
  const FightCardEntry({
    this.redCorner = '',
    this.blueCorner = '',
    this.redGym = '',
    this.blueGym = '',
    this.weightClass = '',
    this.title = '',
  });
  FightCardEntry copyWith({
    String? redCorner,
    String? blueCorner,
    String? redGym,
    String? blueGym,
    String? weightClass,
    String? title,
  }) {
    return FightCardEntry(
      redCorner: redCorner ?? this.redCorner,
      blueCorner: blueCorner ?? this.blueCorner,
      redGym: redGym ?? this.redGym,
      blueGym: blueGym ?? this.blueGym,
      weightClass: weightClass ?? this.weightClass,
      title: title ?? this.title,
    );
  }
}

class CornerFighterField extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final ValueChanged<String> onChanged;
  const CornerFighterField({
    required this.label,
    required this.value,
    required this.color,
    required this.onChanged,
    super.key,
  });
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: color.withValues(alpha: 0.7)),
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      style: TextStyle(color: color),
      onChanged: onChanged,
    );
  }
}

class FightCardEntryEditor extends StatelessWidget {
  final FightCardEntry entry;
  final ValueChanged<FightCardEntry> onChanged;
  final int fightNum;
  const FightCardEntryEditor({
    required this.entry,
    required this.onChanged,
    required this.fightNum,
    super.key,
  });
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fight $fightNum',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Row(
          children: [
            Expanded(
              child: CornerFighterField(
                label: 'Red Corner',
                value: entry.redCorner,
                color: Colors.redAccent,
                onChanged: (v) => onChanged(entry.copyWith(redCorner: v)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: CornerFighterField(
                label: 'Blue Corner',
                value: entry.blueCorner,
                color: Colors.blueAccent,
                onChanged: (v) => onChanged(entry.copyWith(blueCorner: v)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: entry.redGym,
                decoration: const InputDecoration(
                  labelText: 'Red Gym/Trainer',
                  labelStyle: TextStyle(color: Colors.redAccent),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                style: const TextStyle(color: Colors.redAccent),
                onChanged: (v) => onChanged(entry.copyWith(redGym: v)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                initialValue: entry.blueGym,
                decoration: const InputDecoration(
                  labelText: 'Blue Gym/Trainer',
                  labelStyle: TextStyle(color: Colors.blueAccent),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                style: const TextStyle(color: Colors.blueAccent),
                onChanged: (v) => onChanged(entry.copyWith(blueGym: v)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: entry.weightClass,
                decoration: const InputDecoration(
                  labelText: 'Weight Class',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (v) => onChanged(entry.copyWith(weightClass: v)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                initialValue: entry.title,
                decoration: const InputDecoration(
                  labelText: 'Title (optional)',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (v) => onChanged(entry.copyWith(title: v)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class FightCardPrintPreview extends StatelessWidget {
  final List<FightCardEntry> fightCard;
  final String roundFormat;
  final String rules;
  final String? customRounds;
  final String? customTime;
  final String? customRules;
  const FightCardPrintPreview({
    required this.fightCard,
    required this.roundFormat,
    required this.rules,
    this.customRounds,
    this.customTime,
    this.customRules,
    super.key,
  });
  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 24)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.sports_mma, color: Colors.black87),
                const SizedBox(width: 10),
                const Text(
                  'Fight Card',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Rules: ${customRules?.isNotEmpty == true ? customRules : rules}',
              style: const TextStyle(color: Colors.black87),
            ),
            Text(
              'Rounds: ${roundFormat == 'Custom' ? ((customRounds?.isNotEmpty == true && customTime?.isNotEmpty == true) ? '$customRounds x $customTime min' : 'Custom') : roundFormat}',
              style: const TextStyle(color: Colors.black87),
            ),
            const Divider(height: 24),
            ...fightCard.asMap().entries.map((e) {
              final i = e.key + 1;
              final f = e.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Fight $i',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Red: ${f.redCorner}',
                            style: const TextStyle(color: Colors.redAccent),
                          ),
                        ),
                        if (f.redGym.isNotEmpty) ...[
                          const SizedBox(width: 4),
                          Text(
                            '(${f.redGym})',
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 11,
                            ),
                          ),
                        ],
                        Expanded(
                          child: Text(
                            'Blue: ${f.blueCorner}',
                            style: const TextStyle(color: Colors.blueAccent),
                          ),
                        ),
                        if (f.blueGym.isNotEmpty) ...[
                          const SizedBox(width: 4),
                          Text(
                            '(${f.blueGym})',
                            style: const TextStyle(
                              color: Colors.blueAccent,
                              fontSize: 11,
                            ),
                          ),
                        ],
                        const SizedBox(width: 12),
                        Text(
                          f.weightClass,
                          style: const TextStyle(color: Colors.black54),
                        ),
                        if (f.title.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              f.title,
                              style: const TextStyle(
                                color: Colors.amber,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 18),
            Row(
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.print),
                  label: const Text('Print'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.send),
                  label: const Text('Send'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
