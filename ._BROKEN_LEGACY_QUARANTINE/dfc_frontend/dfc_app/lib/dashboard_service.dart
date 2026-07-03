import 'package:flutter/material.dart';
import '../models/dashboard_item_model.dart';

class DashboardService {
  Future<DashboardData> fetchDashboard() async {
    // Simulated network delay for V12 authentic loading feel
    await Future.delayed(const Duration(milliseconds: 600));

    return DashboardData(
      liveItems: [
        DashboardItemModel(
          title: "LIVE NOW: EWART VS JOHNSON",
          imageUrl: "",
          icon: Icons.emergency,
        ),
        DashboardItemModel(
          title: "COUNTDOWN: 02:14:55",
          imageUrl: "",
          icon: Icons.timer,
        ),
      ],
      personalItems: [
        DashboardItemModel(
          title: "Your Fighters",
          imageUrl: "",
          icon: Icons.people_outline,
        ),
        DashboardItemModel(
          title: "Your Gyms",
          imageUrl: "",
          icon: Icons.fitness_center,
        ),
        DashboardItemModel(
          title: "Your Vault",
          imageUrl: "",
          icon: Icons.lock_outline,
        ),
      ],
      discoveryItems: [
        DashboardItemModel(
          title: "Trending Fighter",
          imageUrl:
              "https://images.unsplash.com/photo-1599552375245-298069501538?auto=format&fit=crop&q=80&w=600",
          icon: Icons.trending_up,
        ),
        DashboardItemModel(
          title: "New Gym",
          imageUrl:
              "https://images.unsplash.com/photo-1534438327276-14e5300c3a48?auto=format&fit=crop&q=80&w=600",
          icon: Icons.location_on,
        ),
        DashboardItemModel(
          title: "Knockout of the Week",
          imageUrl:
              "https://images.unsplash.com/photo-1549719386-74dfcbf7dbed?auto=format&fit=crop&q=80&w=600",
          icon: Icons.play_circle_fill,
        ),
        DashboardItemModel(
          title: "PPV Saturday",
          imageUrl:
              "https://images.unsplash.com/photo-1517438476312-10d79c077509?auto=format&fit=crop&q=80&w=600",
          icon: Icons.event,
        ),
      ],
      growthItems: [
        DashboardItemModel(
          title: "Watch 3 Training Clips",
          imageUrl: "",
          icon: Icons.play_arrow,
        ),
        DashboardItemModel(
          title: "Predict the Main Event",
          imageUrl: "",
          icon: Icons.online_prediction,
        ),
      ],
    );
  }
}
