import 'package:flutter/material.dart';
import '../../../dfc_theme.dart';
import '../models/ppv_event_model.dart';

class PpvBuyButton extends StatelessWidget {
  final PpvEventModel event;

  const PpvBuyButton({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.9),
        border: const Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(color: Colors.black, blurRadius: 30, spreadRadius: 20),
        ],
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'PAY PER VIEW',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '\$${event.price.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(width: 24),
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentRed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 10,
                shadowColor: AppColors.accentRed.withValues(alpha: 0.5),
              ),
              onPressed: () {
                // Trigger Checkout via Stripe Webhooks mapping
              },
              child: const Text(
                'PURCHASE TICKET',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
lib/
  modules/
    ppv_poster/
      screens/
        ppv_poster_screen.dart
      widgets/
        ppv_hero.dart
        ppv_fight_card.dart
        ppv_buy_button.dart
      models/
        ppv_event_model.dart
      services/
        ppv_service.dart
      controllers/
        void ppv_controller.dart
