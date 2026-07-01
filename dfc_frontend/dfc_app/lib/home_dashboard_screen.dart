import 'package:flutter/material.dart';
import '../../../dfc_theme.dart';
import '../controllers/dashboard_controller.dart';
import '../widgets/dashboard_live_strip.dart';
import '../widgets/dashboard_personal_row.dart';
import '../widgets/dashboard_discovery_grid.dart';
import '../widgets/dashboard_growth_engine.dart';

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  final controller = DashboardController();

  @override
  void initState() {
    super.initState();
    controller.loadDashboard();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final data = controller.data;

          if (data == null) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.accentCyan),
            );
          }

          return SafeArea(
            child: ListView(
              padding: EdgeInsets.zero,
              physics: const BouncingScrollPhysics(),
              children: [
                DashboardLiveStrip(items: data.liveItems),
                DashboardPersonalRow(items: data.personalItems),
                DashboardDiscoveryGrid(items: data.discoveryItems),
                DashboardGrowthEngine(items: data.growthItems),
              ],
            ),
          );
        },
      ),
    );
  }
}
