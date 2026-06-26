import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';

class RadarScreen extends StatefulWidget {
  const RadarScreen({super.key});

  @override
  State<RadarScreen> createState() => _RadarScreenState();
}

class _RadarScreenState extends State<RadarScreen> {
  int activeFilter = 0;
  double zoom = 1.0;
  bool showDrawer = false;

  final filters = ["Fighters", "Gyms", "Events"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030508),
      body: Stack(
        children: [
          // Tactical Map Background
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(
                    "assets/dfc_backgrounds/dfc_and_back_ground.png",
                  ), // Using your existing asset
                  fit: BoxFit.cover,
                  opacity: 0.15,
                ),
              ),
            ),
          ),

          // Scalable Radar Area
          Positioned.fill(
            child: Transform.scale(
              scale: zoom,
              child: Stack(
                children: [
                  Positioned(
                    left: MediaQuery.of(context).size.width * 0.3,
                    top: MediaQuery.of(context).size.height * 0.4,
                    child: _buildBlip(
                      DesignTokens.neonRed,
                      () => setState(() => showDrawer = true),
                    ),
                  ),
                  Positioned(
                    left: MediaQuery.of(context).size.width * 0.7,
                    top: MediaQuery.of(context).size.height * 0.6,
                    child: _buildBlip(
                      DesignTokens.neonCyan,
                      () => setState(() => showDrawer = true),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Top Bar & Filters
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(filters.length, (i) {
                        final active = activeFilter == i;
                        return GestureDetector(
                          onTap: () => setState(() => activeFilter = i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: active
                                  ? DesignTokens.neonGreen
                                  : DesignTokens.bgCard.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: active
                                    ? DesignTokens.neonGreen
                                    : Colors.white10,
                              ),
                            ),
                            child: Text(
                              filters[i].toUpperCase(),
                              style: TextStyle(
                                color: active ? Colors.black : Colors.white70,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Alerts Feed
          Positioned(
            right: 16,
            top: 100,
            child: SizedBox(
              width: 200,
              child: Column(
                children: [
                  _buildAlertTile(
                    "Kai Storm training nearby",
                    DesignTokens.neonCyan,
                  ),
                  const SizedBox(height: 8),
                  _buildAlertTile(
                    "Event: DFC 42 in 3 days",
                    DesignTokens.neonRed,
                  ),
                ],
              ),
            ),
          ),

          // Zoom Controls
          Positioned(
            right: 16,
            bottom: showDrawer ? 120 : 32,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton(
                  heroTag: "zIn",
                  mini: true,
                  backgroundColor: DesignTokens.bgCard,
                  child: const Icon(Icons.add, color: Colors.white),
                  onPressed: () => setState(() => zoom += 0.2),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: "zOut",
                  mini: true,
                  backgroundColor: DesignTokens.bgCard,
                  child: const Icon(Icons.remove, color: Colors.white),
                  onPressed: () =>
                      setState(() => zoom = (zoom - 0.2).clamp(0.5, 3.0)),
                ),
              ],
            ),
          ),

          // Info Drawer
          if (showDrawer)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: DesignTokens.bgCard,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "KAI STORM",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white54),
                          onPressed: () => setState(() => showDrawer = false),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "12-2-0 • Featherweight • Brisbane, AU",
                      style: TextStyle(
                        color: DesignTokens.textMuted,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DesignTokens.neonCyan,
                          foregroundColor: Colors.black,
                        ),
                        child: const Text("VIEW PROFILE"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBlip(Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.6),
              blurRadius: 16,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Center(
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAlertTile(String text, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.radar, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
