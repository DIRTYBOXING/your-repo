import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/neon_card.dart';

class TaskerTab extends StatelessWidget {
  const TaskerTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShaderMask(
            shaderCallback: (b) => AppColors.neonGrad.createShader(b),
            child: const Text(
              'FightTasker',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const Text(
            'The gig economy for combat sports',
            style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _btn(Icons.search, 'Find Work', AppColors.neonBlue),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _btn(
                  Icons.add_circle_outline,
                  'Post a Job',
                  AppColors.neonGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _btn(Icons.outbox, 'Applications', AppColors.neonSky),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _btn(
                  Icons.list_alt,
                  'My Listings',
                  AppColors.neonOrange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          NeonCard(
            glow: AppColors.neonRed,
            child: Row(
              children: [
                const Icon(Icons.flash_on, size: 20, color: AppColors.neonRed),
                const SizedBox(width: 8),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Available Tonight',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Urgent staffing / fighter replacement',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.neonRed,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'GO',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Categories',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                [
                      'MC / Announcer',
                      'Referee / Judge',
                      'Cutman',
                      'Ring Girl',
                      'Security',
                      'Medical',
                      'Camera Crew',
                      'Photographer',
                      'Video Editor',
                      'DJ / Sound',
                      'Sparring Partner',
                      'Coach',
                      'Nutritionist',
                      'Physio',
                      'Stage Builder',
                      'Ticket Staff',
                    ]
                    .map(
                      (s) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.elevated,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          s,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    )
                    .toList(),
          ),
          const SizedBox(height: 20),
          const Text(
            'Recent Listings',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _job(
            context,
            'Cutman Needed',
            'Hex Fight Series 27',
            '\$350',
            'Mar 15',
            'Sydney',
            true,
          ),
          const SizedBox(height: 10),
          _job(
            context,
            'Ring Announcer',
            'Eternal MMA 83',
            '\$500',
            'Mar 28',
            'Melbourne',
            true,
          ),
          const SizedBox(height: 10),
          _job(
            context,
            'Sparring Partner 70kg',
            'Absolute MMA Melbourne',
            '\$80/session',
            'Ongoing',
            'Brisbane',
            false,
          ),
        ],
      ),
    );
  }

  Widget _btn(IconData ic, String l, Color c) => NeonCard(
    glow: c,
    child: Row(
      children: [
        Icon(ic, size: 20, color: c),
        const SizedBox(width: 10),
        Text(
          l,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    ),
  );

  Widget _job(
    BuildContext context,
    String t,
    String pr,
    String pay,
    String d,
    String loc,
    bool v,
  ) => NeonCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                t,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.neonGreen.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                pay,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.neonGreen,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            if (v)
              const Padding(
                padding: EdgeInsets.only(right: 4),
                child: Icon(
                  Icons.verified,
                  size: 14,
                  color: AppColors.neonBlue,
                ),
              ),
            Text(
              pr,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(
              Icons.calendar_today,
              size: 12,
              color: AppColors.textTertiary,
            ),
            const SizedBox(width: 4),
            Text(
              d,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(width: 12),
            const Icon(
              Icons.location_on,
              size: 12,
              color: AppColors.textTertiary,
            ),
            const SizedBox(width: 4),
            Text(
              loc,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Application noted — the task owner will be notified'),
                  duration: Duration(seconds: 3),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Apply Now',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    ),
  );
}
