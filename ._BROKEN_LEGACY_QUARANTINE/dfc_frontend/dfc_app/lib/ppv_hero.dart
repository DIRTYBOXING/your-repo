import 'package:flutter/material.dart';
import '../../../dfc_theme.dart';
import '../models/ppv_event_model.dart';

class PpvHero extends StatelessWidget {
  final PpvEventModel event;

  const PpvHero({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: MediaQuery.of(context).size.height * 0.65,
      backgroundColor: AppColors.background,
      pinned: true,
      stretch: true,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // POSTER IMAGE
            Image.network(
              event.posterUrl,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
            
            // CINEMATIC GRADIENT
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.background.withValues(alpha: 0.0),
                    AppColors.background.withValues(alpha: 0.4),
                    AppColors.background.withValues(alpha: 1.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.4, 0.7, 1.0],
                ),
              ),
            ),

            // EVENT METADATA OVERLAY
            Positioned(
              bottom: 24,
              left: 24,
              right: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.accentRed.withValues(alpha: 0.2),
                      border: Border.all(color: AppColors.accentRed),
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [BoxShadow(color: AppColors.accentRed.withValues(alpha: 0.5), blurRadius: 10)],
                    ),
                    child: const Text(
                      'LIVE PPV EVENT',
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    event.title.toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                      shadows: [Shadow(color: AppColors.accentRed, blurRadius: 20)],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${event.date} • ${event.location}',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}