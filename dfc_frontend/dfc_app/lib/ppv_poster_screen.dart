import 'package:flutter/material.dart';
import '../../../dfc_theme.dart';
import '../controllers/ppv_controller.dart';
import '../widgets/ppv_hero.dart';
import '../widgets/ppv_fight_card.dart';
import '../widgets/ppv_buy_button.dart';

class PpvPosterScreen extends StatefulWidget {
  final String eventId;

  const PpvPosterScreen({super.key, required this.eventId});

  @override
  State<PpvPosterScreen> createState() => _PpvPosterScreenState();
}

class _PpvPosterScreenState extends State<PpvPosterScreen> {
  final controller = PpvController();

  @override
  void initState() {
    super.initState();
    controller.loadEvent(widget.eventId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final event = controller.event;

          if (controller.isLoading || event == null) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.accentRed),
            );
          }

          return Stack(
            children: [
              CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // CINEMATIC PARALLAX POSTER
                  PpvHero(event: event),
                  
                  // THE FIGHT CARD
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 32, 24, 120), // Padding for Buy Button
                      child: PpvFightCard(fights: event.fights),
                    ),
                  ),
                ],
              ),
              
              // BACK BUTTON OVERLAY
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                left: 16,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                    child: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                ),
              ),

              // STICKY BUY BUTTON
              Positioned(bottom: 0, left: 0, right: 0, child: PpvBuyButton(event: event)),
            ],
          );
        },
      ),
    );
  }
}