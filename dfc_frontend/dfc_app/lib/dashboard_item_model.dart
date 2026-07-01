import 'package:flutter/material.dart';

class DashboardItemModel {
  final String title;
  final String imageUrl;
  final IconData icon;

  DashboardItemModel({
    required this.title,
    required this.imageUrl,
    required this.icon,
  });
}

class DashboardData {
  final List<DashboardItemModel> liveItems;
  final List<DashboardItemModel> personalItems;
  final List<DashboardItemModel> discoveryItems;
  final List<DashboardItemModel> growthItems;

  DashboardData({
    required this.liveItems, required this.personalItems,
    required this.discoveryItems, required this.growthItems,
  });
}