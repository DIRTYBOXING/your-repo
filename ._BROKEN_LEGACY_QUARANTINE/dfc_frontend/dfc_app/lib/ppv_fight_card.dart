import 'package:flutter/material.dart';
import '../../../dfc_theme.dart';
import '../models/ppv_event_model.dart';

class PpvFightCard extends StatelessWidget {
  final List<PpvFightModel> fights;

  const PpvFightCard({super.key, required this.fights});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'OFFICIAL FIGHT CARD',
          style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.5),
        ),
        const SizedBox(height: 24),
        ...fights.map((fight) => _buildFightRow(fight)),
      ],
    );
  }

  Widget _buildFightRow(PpvFightModel fight) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: fight.isMainEvent ? AppColors.championGold.withValues(alpha: 0.5) : AppColors.border),
        boxShadow: fight.isMainEvent ? [BoxShadow(color: AppColors.championGold.withValues(alpha: 0.1), blurRadius: 20)] : [],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(fight.weightClass.toUpperCase(), style: const TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
              if (fight.isMainEvent)
                const Text('MAIN EVENT', style: TextStyle(color: AppColors.championGold, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  fight.redCorner.toUpperCase(),
                  textAlign: TextAlign.end,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w900),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'VS',
                  style: TextStyle(color: AppColors.accentRed, fontSize: 14, fontStyle: FontStyle.italic, fontWeight: FontWeight.w900),
                ),
              ),
              Expanded(
                child: Text(
                  fight.blueCorner.toUpperCase(),
                  textAlign: TextAlign.start,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}