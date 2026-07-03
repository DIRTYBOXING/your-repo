import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../dfc_theme.dart';
import '../controllers/gym_directory_controller.dart';
import '../widgets/gym_directory_card.dart';

class GymDirectoryScreen extends StatefulWidget {
  const GymDirectoryScreen({super.key});

  @override
  State<GymDirectoryScreen> createState() => _GymDirectoryScreenState();
}

class _GymDirectoryScreenState extends State<GymDirectoryScreen> {
  final controller = GymDirectoryController();

  @override
  void initState() {
    super.initState();
    controller.loadGyms();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text(
          'GLOBAL GYM DIRECTORY',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: AppColors.textPrimary),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.map, color: AppColors.textPrimary),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // ─── FILTER STRIP ───────────────────────────────────────────────────
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildFilterPill('ALL GYMS', isActive: true),
                _buildFilterPill('MMA'),
                _buildFilterPill('BJJ / GRAPPLING'),
                _buildFilterPill('BOXING'),
                _buildFilterPill('MUAY THAI'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ─── GYM DIRECTORY GRID ────────────────────────────────────────────
          Expanded(
            child: ListenableBuilder(
              listenable: controller,
              builder: (context, _) {
                if (controller.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.accentCyan,
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: controller.gyms.length,
                  itemBuilder: (context, index) {
                    final gym = controller.gyms[index];
                    return GestureDetector(
                      onTap: () => context.push(
                        '/gym-team',
                      ), // Navigates to actual Gym Profile
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 24.0),
                        child: GymDirectoryCard(gym: gym),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPill(String title, {bool isActive = false}) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? AppColors.accentCyan : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive ? AppColors.accentCyan : AppColors.border,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: AppColors.accentCyan.withValues(alpha: 0.3),
                  blurRadius: 8,
                ),
              ]
            : [],
      ),
      child: Center(
        child: Text(
          title,
          style: TextStyle(
            color: isActive ? Colors.black : AppColors.textSecondary,
            fontWeight: FontWeight.bold,
            fontSize: 12,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}
