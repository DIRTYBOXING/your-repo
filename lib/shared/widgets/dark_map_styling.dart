import 'package:flutter/material.dart';
import 'dart:ui' as ui;

/// Dark combat map styling - The underworld aesthetic
/// Google Maps requires a JSON style, but we also need Flutter overlays
/// for the neon diamond markers that make the discovery magical.

class DarkMapTheme {
  /// Google Maps Dark Style JSON
  /// Stripped of all distraction, pure combat underworld
  static const String darkStyleJson = '''
  [
    {
      "elementType": "geometry",
      "stylers": [{ "color": "#0A0A0A" }]
    },
    {
      "elementType": "labels.text.fill",
      "stylers": [{ "color": "#9CA3AF" }]
    },
    {
      "elementType": "labels.text.stroke",
      "stylers": [{ "color": "#000000" }]
    },
    {
      "featureType": "administrative",
      "elementType": "geometry.stroke",
      "stylers": [{ "color": "#1F2937" }]
    },
    {
      "featureType": "administrative.land_parcel",
      "elementType": "labels",
      "stylers": [{ "visibility": "off" }]
    },
    {
      "featureType": "administrative.land_parcel",
      "elementType": "geometry.stroke",
      "stylers": [{ "color": "#1F2937" }]
    },
    {
      "featureType": "landscape",
      "elementType": "geometry",
      "stylers": [{ "color": "#0D0D0D" }]
    },
    {
      "featureType": "poi",
      "elementType": "geometry",
      "stylers": [{ "color": "#111111" }]
    },
    {
      "featureType": "poi",
      "elementType": "labels",
      "stylers": [{ "visibility": "off" }]
    },
    {
      "featureType": "poi.park",
      "elementType": "geometry",
      "stylers": [{ "color": "#0A1A0A" }]
    },
    {
      "featureType": "road",
      "elementType": "geometry",
      "stylers": [{ "color": "#1A1A1A" }]
    },
    {
      "featureType": "road",
      "elementType": "geometry.stroke",
      "stylers": [{ "color": "#222222" }]
    },
    {
      "featureType": "road.highway",
      "elementType": "geometry",
      "stylers": [{ "color": "#252525" }]
    },
    {
      "featureType": "road.highway",
      "elementType": "geometry.stroke",
      "stylers": [{ "color": "#2D2D2D" }]
    },
    {
      "featureType": "transit",
      "elementType": "geometry",
      "stylers": [{ "color": "#151515" }]
    },
    {
      "featureType": "water",
      "elementType": "geometry",
      "stylers": [{ "color": "#050510" }]
    },
    {
      "featureType": "water",
      "elementType": "labels.text.fill",
      "stylers": [{ "color": "#4B5563" }]
    }
  ]
  ''';

  /// Neon colour palette for map elements
  static const Color cyanNeon = Color(0xFF00F5FF);
  static const Color magentaNeon = Color(0xFFFF00FF);
  static const Color greenNeon = Color(0xFF00FF87);
  static const Color orangeNeon = Color(0xFFFF6B00);
  static const Color goldNeon = Color(0xFFFFD700);
  static const Color purpleNeon = Color(0xFF9D00FF);

  /// Diamond colours by mentor status
  static Color diamondColorForStatus(MentorStatus status) {
    switch (status) {
      case MentorStatus.legendary:
        return goldNeon;
      case MentorStatus.verified:
        return cyanNeon;
      case MentorStatus.emerging:
        return greenNeon;
      case MentorStatus.community:
        return purpleNeon;
      case MentorStatus.hidden:
        return magentaNeon;
    }
  }
}

/// Mentor status for diamond presentation
enum MentorStatus {
  legendary, // Gold diamond - hall of fame level
  verified, // Cyan diamond - verified and active
  emerging, // Green diamond - rising coaches
  community, // Purple diamond - grassroots legends
  hidden, // Magenta diamond - subscriber-only unlock
}

/// Gym/Mentor marker data for the map
class MentorDiamondData {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final MentorStatus status;
  final List<String> disciplines;
  final String? headCoach;
  final bool requiresSubscription;
  final double? rating;

  const MentorDiamondData({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.status,
    this.disciplines = const [],
    this.headCoach,
    this.requiresSubscription = false,
    this.rating,
  });
}

/// Mentor Diamond Marker Widget - Neon glow diamond
class MentorDiamondMarker extends StatefulWidget {
  final MentorDiamondData data;
  final VoidCallback? onTap;
  final bool isUnlocked;

  const MentorDiamondMarker({
    super.key,
    required this.data,
    this.onTap,
    this.isUnlocked = true,
  });

  @override
  State<MentorDiamondMarker> createState() => _MentorDiamondMarkerState();
}

class _MentorDiamondMarkerState extends State<MentorDiamondMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = DarkMapTheme.diamondColorForStatus(widget.data.status);
    final isLocked = widget.data.requiresSubscription && !widget.isUnlocked;

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Outer glow ring
              Container(
                width: 48 * _pulseAnimation.value,
                height: 48 * _pulseAnimation.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(
                        alpha: 0.3 * _pulseAnimation.value,
                      ),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
              ),
              // Diamond shape
              CustomPaint(
                size: const Size(32, 40),
                painter: DiamondPainter(
                  color: isLocked ? Colors.grey : color,
                  glowIntensity: _pulseAnimation.value,
                ),
              ),
              // Lock overlay if subscription required
              if (isLocked)
                const Icon(Icons.lock, color: Colors.white70, size: 12),
            ],
          );
        },
      ),
    );
  }
}

/// Diamond shape painter with neon glow
class DiamondPainter extends CustomPainter {
  final Color color;
  final double glowIntensity;

  DiamondPainter({required this.color, this.glowIntensity = 1.0});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();

    // Diamond shape points
    path.moveTo(size.width / 2, 0); // Top
    path.lineTo(size.width, size.height * 0.35); // Right
    path.lineTo(size.width / 2, size.height); // Bottom
    path.lineTo(0, size.height * 0.35); // Left
    path.close();

    // Outer glow
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.5 * glowIntensity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, glowPaint);

    // Fill gradient
    final gradient = ui.Gradient.linear(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      [color, color.withValues(alpha: 0.7)],
    );

    final fillPaint = Paint()
      ..shader = gradient
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // Inner highlight
    final highlightPath = Path();
    highlightPath.moveTo(size.width / 2, 4);
    highlightPath.lineTo(size.width * 0.75, size.height * 0.35);
    highlightPath.lineTo(size.width / 2, size.height * 0.5);
    highlightPath.lineTo(size.width * 0.35, size.height * 0.35);
    highlightPath.close();

    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    canvas.drawPath(highlightPath, highlightPaint);

    // Border
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(DiamondPainter oldDelegate) {
    return oldDelegate.glowIntensity != glowIntensity ||
        oldDelegate.color != color;
  }
}

/// Mentor popup card - appears when diamond tapped
class MentorInfoCard extends StatelessWidget {
  final MentorDiamondData data;
  final VoidCallback? onViewProfile;
  final VoidCallback? onGetDirections;

  const MentorInfoCard({
    super.key,
    required this.data,
    this.onViewProfile,
    this.onGetDirections,
  });

  @override
  Widget build(BuildContext context) {
    final color = DarkMapTheme.diamondColorForStatus(data.status);

    return Container(
      width: 280,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F0F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with status badge
          Row(
            children: [
              Expanded(
                child: Text(
                  data.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withValues(alpha: 0.5)),
                ),
                child: Text(
                  _statusLabel(data.status),
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Head coach
          if (data.headCoach != null) ...[
            Text(
              'Head Coach: ${data.headCoach}',
              style: TextStyle(color: Colors.grey[400], fontSize: 13),
            ),
            const SizedBox(height: 8),
          ],

          // Disciplines
          if (data.disciplines.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: data.disciplines
                  .map(
                    (d) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        d,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),

          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  label: 'View Profile',
                  icon: Icons.person,
                  color: color,
                  onTap: onViewProfile,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionButton(
                  label: 'Directions',
                  icon: Icons.directions,
                  color: Colors.white70,
                  onTap: onGetDirections,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _statusLabel(MentorStatus status) {
    switch (status) {
      case MentorStatus.legendary:
        return 'LEGENDARY';
      case MentorStatus.verified:
        return 'VERIFIED';
      case MentorStatus.emerging:
        return 'RISING';
      case MentorStatus.community:
        return 'COMMUNITY';
      case MentorStatus.hidden:
        return 'EXCLUSIVE';
    }
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Seed data - DFC HQ Gym and mentors
class MentorMapSeeds {
  static const greyMercyStreetGym = MentorDiamondData(
    id: 'dfc_hq_gym',
    name: 'DFC HQ',
    latitude: -37.8136, // Melbourne
    longitude: 144.9631,
    status: MentorStatus.legendary,
    disciplines: ['Boxing', 'Kickboxing', 'MMA'],
    headCoach: 'DFC Coaching Staff',
    rating: 5.0,
  );

  static const List<MentorDiamondData> australianGyms = [
    greyMercyStreetGym,
    // More to be added from real gym data
  ];
}
