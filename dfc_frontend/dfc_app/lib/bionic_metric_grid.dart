import 'package:flutter/material.dart';
import '../../../../dfc_theme.dart';
import '../models/telemetry_data_model.dart';

class BionicMetricGrid extends StatelessWidget {
  final TelemetryDataModel data;

  const BionicMetricGrid({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildMetricCard(
          'PUNCH VELOCITY',
          '${data.punchVelocity} MPH',
          AppColors.accentCyan,
          Icons.speed,
        ),
        _buildMetricCard(
          'HEAD EVASIONS',
          '${data.headMovementCount}',
          AppColors.championGold,
          Icons.compare_arrows,
        ),
        _buildMetricCard(
          'HIT / MISS RATIO',
          data.hitMissRatio,
          AppColors.accentPurple,
          Icons.shield,
        ),
        _buildMetricCard(
          'REACTION TIME',
          '${data.reactionTime.toInt()} MS',
          AppColors.accentGreen,
          Icons.flash_on,
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    Color accentColor,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(color: accentColor.withValues(alpha: 0.05), blurRadius: 15),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: accentColor, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
