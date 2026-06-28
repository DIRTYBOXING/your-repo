import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/fighter_providers.dart';
import 'fighter_create_screen.dart';
import 'fighter_profile_screen.dart';
import '../../../core/motion/dfc_motion.dart';

class FightersScreen extends ConsumerWidget {
  const FightersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fightersAsync = ref.watch(fighterListProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF05060A),
      appBar: AppBar(
        title: const Text(
          'Fighter Roster',
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
          child: CircularProgressIndicator(color: Colors.blueAccent),
        ),
        error: (err, stack) => Center(
          child: Text(
            'Error: $err',
            style: const TextStyle(color: Colors.redAccent),
          ),
        ),
        data: (fighters) {
          if (fighters.isEmpty) {
            return const Center(
              child: Text(
                'No fighters found. Add one to begin.',
                style: TextStyle(color: Colors.white54),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: fighters.length,
            itemBuilder: (context, index) {
              final fighter = fighters[index];
              return Card(
                color: const Color(0xFF1A1C23),
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blueAccent.withValues(alpha: 0.2),
                    backgroundImage: fighter.profileImageUrl.isNotEmpty
                        ? NetworkImage(fighter.profileImageUrl)
                        : null,
                    child: fighter.profileImageUrl.isEmpty
                        ? const Icon(Icons.sports_mma, color: Colors.blueAccent)
                        : null,
                  ),
                  title: Text(
                    '${fighter.firstName} "${fighter.nickname}" ${fighter.lastName}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    '${fighter.weightClass} • Gym: ${fighter.gymId}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: Colors.white54,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      DfcMotion.slide(FighterProfileScreen(fighter: fighter)),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.blueAccent,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const FighterCreateScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Add Fighter',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
