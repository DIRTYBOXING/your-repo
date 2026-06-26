import 'package:flutter/material.dart';
import '../models/event_manager_model.dart';
import '../../core/constants/app_logos.dart';

/// EventManagerCard
/// Displays the DFC logo and a lineup of fights (print/share ready)
class EventManagerCard extends StatelessWidget {
  final List<FightCardEvent> lineup;
  final String? eventTitle;
  final String? eventDate;
  final ImageProvider? eventLogo;

  /// [eventLogo] can be a FileImage, NetworkImage, or AssetImage. If null, defaults to DFC logo asset.
  const EventManagerCard({
    super.key,
    required this.lineup,
    this.eventTitle,
    this.eventDate,
    this.eventLogo,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: Colors.black,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Event Logo (user-uploaded or DFC default)
            SizedBox(
              height: 64,
              child: Image(
                image: eventLogo ?? const AssetImage(AppLogos.icon),
                fit: BoxFit.contain,
              ),
            ),
            if (eventTitle != null) ...[
              const SizedBox(height: 12),
              Text(
                eventTitle!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
            if (eventDate != null) ...[
              const SizedBox(height: 4),
              Text(
                eventDate!,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
            const SizedBox(height: 20),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: lineup.length,
              separatorBuilder: (_, _) => const Divider(color: Colors.white24),
              itemBuilder: (context, i) {
                final fight = lineup[i];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          fight.label,
                          style: const TextStyle(
                            color: Colors.cyanAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.cyan.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            fight.type,
                            style: const TextStyle(
                              color: Colors.cyanAccent,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.redAccent.withValues(alpha: 0.7),
                              ),
                            ),
                            child: Text(
                              'RED: ${fight.fighterA}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            'VS',
                            style: TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.lightBlueAccent.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                            ),
                            child: Text(
                              'BLUE: ${fight.fighterB}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                color: Colors.lightBlueAccent,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
