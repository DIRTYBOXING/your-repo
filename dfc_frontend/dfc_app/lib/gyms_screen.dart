import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/admin_gym_providers.dart';
import '../../../core/layout/dfc_layout.dart';
import '../../../core/layout/dfc_padding.dart';
import '../../../core/cards/dfc_card.dart';
import '../../../core/motion/dfc_motion.dart';
import 'gym_create_screen.dart';

class GymsScreen extends ConsumerWidget {
  const GymsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gymsAsync = ref.watch(adminGymListProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF05060A),
      body: DfcPadding(
        child: DfcLayout.constrain(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'GYM DIRECTORY',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.greenAccent,
                      foregroundColor: Colors.black,
                    ),
                    onPressed: () {
                      Navigator.of(
                        context,
                      ).push(DfcMotion.slide(const GymCreateScreen()));
                    },
                    child: const Text(
                      'ADD GYM',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: gymsAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: Colors.greenAccent),
                  ),
                  error: (err, stack) => Center(
                    child: Text(
                      'Error: $err',
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ),
                  data: (gyms) {
                    if (gyms.isEmpty) {
                      return const Center(
                        child: Text(
                          'No gyms found. Add one to begin.',
                          style: TextStyle(color: Colors.white54),
                        ),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: gyms.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final gym = gyms[index];
                        return DfcCard(
                          onTap: () {},
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                gym.name.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.greenAccent,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${gym.city}, ${gym.country}',
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
