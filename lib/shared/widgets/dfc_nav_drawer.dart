import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';

class DFCNavDrawer extends StatelessWidget {
  const DFCNavDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            color: AppColors.bg.withValues(alpha: 0.8),
            child: SafeArea(
              child: Column(
                children: [
                  // Drawer Header
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.neonCyan.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.neonCyan.withValues(alpha: 0.5)),
                          ),
                          child: const Icon(Icons.hub, color: AppColors.neonCyan),
                        ),
                        const SizedBox(width: 16),
                        const Text(
                          'DFC OS',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
                  
                  // Scrollable Route List
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      physics: const BouncingScrollPhysics(),
                      children: [
                        _buildSectionHeader('FIGHTER & COACH'),
                        _buildRouteTile(context, 'Neural Coach', '/neural-coach', Icons.psychology, AppColors.neonCyan),
                        _buildRouteTile(context, 'Corner Coach (Round)', '/corner-coach', Icons.timer, AppColors.neonMagenta),
                        _buildRouteTile(context, 'Training Session', '/training-session', Icons.fitness_center, AppColors.neonRed),
                        _buildRouteTile(context, 'Performance Lab', '/performance-lab', Icons.science, AppColors.neonGreen),
                        _buildRouteTile(context, 'Device Hub', '/devices', Icons.sensors, AppColors.neonBlue),
                        
                        _buildSectionHeader('IDENTITY & GYM'),
                        _buildRouteTile(context, 'Public Profile', '/public-profile', Icons.person_search, AppColors.neonAmber),
                        _buildRouteTile(context, 'Gym & Team Hub', '/gym-hub', Icons.shield, AppColors.neonBlue),
                        _buildRouteTile(context, 'Coach Hub', '/coach-hub', Icons.assignment_ind, AppColors.neonCyan),
                        
                        _buildSectionHeader('BROADCAST & PPV'),
                        _buildRouteTile(context, 'Event Center', '/event-center', Icons.event, AppColors.neonOrange),
                        _buildRouteTile(context, 'Streaming Center', '/streaming', Icons.live_tv, AppColors.neonRed),
                        _buildRouteTile(context, 'Replay Center', '/replay', Icons.slow_motion_video, AppColors.neonBlue),
                        _buildRouteTile(context, 'PPV & Tickets', '/ppv', Icons.confirmation_number, AppColors.neonGreen),
                        
                        _buildSectionHeader('OPERATIONS & ADMIN'),
                        _buildRouteTile(context, 'Promoter Dashboard', '/promoter', Icons.dashboard, AppColors.neonMagenta),
                        _buildRouteTile(context, 'Venue Operations', '/venue-ops', Icons.stadium, AppColors.neonCyan),
                        _buildRouteTile(context, 'Officials Tablet', '/officials', Icons.gavel, AppColors.neonAmber),
                        _buildRouteTile(context, 'Medical & Safety', '/medical', Icons.health_and_safety, AppColors.neonRed),
                        _buildRouteTile(context, 'Payouts & Finance', '/finance', Icons.attach_money, AppColors.neonGreen),
                        _buildRouteTile(context, 'Google Power Hub', '/google-hub', Icons.cloud, AppColors.neonBlue),
                        _buildRouteTile(context, 'AstroHealth Monitor', '/astrohealth', Icons.rocket_launch, AppColors.neonPurple),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.4),
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
        ),
      );
    );
  }

  Widget _buildRouteTile(BuildContext context, String title, String route, IconData icon, Color color) {
    return ListTile(
      leading: Icon(icon, color: color, size: 20),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
      ),
      onTap: () {
        Navigator.pop(context); // Close the drawer
        context.push(route);    // Navigate to the screen
      },
    );
  }
}