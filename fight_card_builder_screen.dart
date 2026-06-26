import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'fight_model.dart';
import 'fight_card_providers.dart';
import 'fighter_providers.dart';
import 'fighter_model.dart';

class FightCardBuilderScreen extends ConsumerStatefulWidget {
  final String eventId;

  const FightCardBuilderScreen({super.key, required this.eventId});

  @override
  ConsumerState<FightCardBuilderScreen> createState() =>
      _FightCardBuilderScreenState();
}

class _FightCardBuilderScreenState
    extends ConsumerState<FightCardBuilderScreen> {
  void _showAddFightDialog(List<FighterModel> roster, int nextOrder) {
    String? selectedRedCorner;
    String? selectedBlueCorner;
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1C23),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'MATCH NEW FIGHT',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Red Corner Dropdown
                  _buildFighterDropdown(
                    'Red Corner',
                    roster,
                    selectedRedCorner,
                    Colors.redAccent,
                    (val) {
                      setModalState(() => selectedRedCorner = val);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Blue Corner Dropdown
                  _buildFighterDropdown(
                    'Blue Corner',
                    roster,
                    selectedBlueCorner,
                    Colors.blueAccent,
                    (val) {
                      setModalState(() => selectedBlueCorner = val);
                    },
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purpleAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed:
                          (selectedRedCorner == null ||
                              selectedBlueCorner == null ||
                              isSubmitting)
                          ? null
                          : () async {
                              if (selectedRedCorner == selectedBlueCorner) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Cannot fight themselves!'),
                                  ),
                                );
                                return;
                              }

                              setModalState(() => isSubmitting = true);

                              final newFight = FightModel(
                                id: 'fight_${DateTime.now().millisecondsSinceEpoch}',
                                fighterAId: selectedRedCorner!,
                                fighterBId: selectedBlueCorner!,
                                fightOrder: nextOrder,
                              );

                              try {
                                await ref
                                    .read(fightCardApiServiceProvider)
                                    .addFight(widget.eventId, newFight);
                                ref.invalidate(
                                  fightListProvider(widget.eventId),
                                );
                                if (context.mounted) Navigator.pop(context);
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error: $e')),
                                  );
                                }
                              } finally {
                                setModalState(() => isSubmitting = false);
                              }
                            },
                      child: isSubmitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'CONFIRM BOUT',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFighterDropdown(
    String label,
    List<FighterModel> roster,
    String? value,
    Color accentColor,
    Function(String?) onChanged,
  ) {
    return DropdownButtonFormField<String>(
      value: value,
      dropdownColor: const Color(0xFF0A0E17),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: accentColor),
        filled: true,
        fillColor: const Color(0xFF0A0E17),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accentColor.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accentColor),
        ),
      ),
      items: roster
          .map(
            (f) => DropdownMenuItem(
              value: f.id,
              child: Text(
                '${f.firstName} "${f.nickname}" ${f.lastName} (${f.weightClass})',
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    final fightsAsync = ref.watch(fightListProvider(widget.eventId));
    final fightersAsync = ref.watch(fighterListProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF05060A),
      appBar: AppBar(
        title: const Text(
          'Fight Card Builder',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        backgroundColor: const Color(0xFF0A0E17),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: fightersAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Colors.purpleAccent),
        ),
        error: (err, stack) => Center(
          child: Text(
            'Error loading roster: $err',
            style: const TextStyle(color: Colors.redAccent),
          ),
        ),
        data: (roster) {
          return fightsAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: Colors.purpleAccent),
            ),
            error: (err, stack) => Center(
              child: Text(
                'Error loading fights: $err',
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
            data: (fights) {
              if (fights.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.sports_martial_arts,
                        size: 64,
                        color: Colors.white24,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Card is empty. Add the main event to start.',
                        style: TextStyle(color: Colors.white54),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => _showAddFightDialog(roster, 1),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Bout'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purpleAccent,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ReorderableListView.builder(
                onReorder: (oldIndex, newIndex) async {
                  if (oldIndex < newIndex) newIndex -= 1;

                  HapticFeedback.heavyImpact(); // Premium tactile feel

                  try {
                    await ref
                        .read(fightListProvider(widget.eventId).notifier)
                        .reorderFights(oldIndex, newIndex);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(e.toString()),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                    }
                  }
                },
                padding: const EdgeInsets.all(16),
                itemCount: fights.length,
                itemBuilder: (context, index) {
                  final fight = fights[index];
                  final fighterA = roster.firstWhere(
                    (f) => f.id == fight.fighterAId,
                    orElse: () => FighterModel(
                      id: '',
                      firstName: 'Unknown',
                      lastName: '',
                      nickname: '',
                      weightClass: '',
                      gymId: '',
                      promotionId: '',
                      profileImageUrl: '',
                    ),
                  );
                  final fighterB = roster.firstWhere(
                    (f) => f.id == fight.fighterBId,
                    orElse: () => FighterModel(
                      id: '',
                      firstName: 'Unknown',
                      lastName: '',
                      nickname: '',
                      weightClass: '',
                      gymId: '',
                      promotionId: '',
                      profileImageUrl: '',
                    ),
                  );

                  return Card(
                    key: ValueKey(fight.id),
                    color: const Color(0xFF1A1C23),
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(
                            'BOUT ${fight.fightOrder}',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Red Corner
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      fighterA.firstName.toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      fighterA.lastName.toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      height: 3,
                                      width: 40,
                                      color: Colors.redAccent,
                                    ),
                                  ],
                                ),
                              ),
                              const Text(
                                'VS',
                                style: TextStyle(
                                  color: Colors.white24,
                                  fontSize: 24,
                                  fontStyle: FontStyle.italic,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              // Blue Corner
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      fighterB.firstName.toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      fighterB.lastName.toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      height: 3,
                                      width: 40,
                                      color: Colors.blueAccent,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: fightsAsync.value?.isNotEmpty == true
          ? FloatingActionButton.extended(
              backgroundColor: Colors.purpleAccent,
              onPressed: () => _showAddFightDialog(
                fightersAsync.value ?? [],
                fightsAsync.value!.length + 1,
              ),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Add Bout',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
    );
  }
}
