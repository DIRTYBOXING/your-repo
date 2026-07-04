import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/event_providers.dart';
import 'event_create_screen.dart';
import 'fight_card_builder_screen.dart';
import '../../../core/layout/dfc_layout.dart';
import '../../../core/layout/dfc_padding.dart';
import '../../../core/cards/dfc_card.dart';
import '../../../core/motion/dfc_motion.dart';

class EventsScreen extends ConsumerWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(eventListProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF05060A),
      body: DfcPadding(
        child: DfcLayout.constrain(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              const Text(
                'EVENTS & PPV',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.of(
                        context,
                      ).push(DfcMotion.slide(const EventCreateScreen()));
                    },
                    child: const Text(
                      'CREATE EVENT',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: eventsAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: Colors.redAccent),
                  ),
                  error: (err, stack) => Center(
                    child: Text(
                      'Error: $err',
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ),
                  data: (events) {
                    if (events.isEmpty) {
                      return const Center(
                        child: Text(
                          'No events found. Create one to begin.',
                          style: TextStyle(color: Colors.white54),
                        ),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: events.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final event = events[index];
                        final formattedDate = DateFormat(
                          'MMM d, yyyy • h:mm a',
                        ).format(event.startTime);

                        return DfcCard(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    FightCardBuilderScreen(eventId: event.id),
                              ),
                            );
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                event.name.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                formattedDate,
                                style: const TextStyle(color: Colors.white70),
                              ),
                              Text(
                                '${event.venue}, ${event.city} • PPV: \$${(event.ppvPriceCents / 100).toStringAsFixed(2)}',
                                style: const TextStyle(color: Colors.white38),
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
