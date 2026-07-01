import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/collectible_model.dart';

class HolographicCard extends StatefulWidget {
  final Collectible collectible;

  const HolographicCard({super.key, required this.collectible});

  @override
  State<HolographicCard> createState() => _HolographicCardState();
}

class _HolographicCardState extends State<HolographicCard>
    with SingleTickerProviderStateMixin {
  double _xRotation = 0.0;
  double _yRotation = 0.0;
  late AnimationController _resetController;

  @override
  void initState() {
    super.initState();
    _resetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _resetController.addListener(() {
      setState(() {
        _xRotation = _xRotation * (1 - _resetController.value);
        _yRotation = _yRotation * (1 - _resetController.value);
      });
    });
  }

  @override
  void dispose() {
    _resetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rarityColor = widget.collectible.rarity.color;

    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          _yRotation += details.delta.dx * 0.01;
          _xRotation -= details.delta.dy * 0.01;
          // Clamp rotation to prevent flipping
          _yRotation = _yRotation.clamp(-0.4, 0.4);
          _xRotation = _xRotation.clamp(-0.4, 0.4);
        });
      },
      onPanEnd: (_) {
        HapticFeedback.lightImpact();
        _resetController.forward(from: 0.0);
      },
      child: Transform(
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001) // perspective
          ..rotateX(_xRotation)
          ..rotateY(_yRotation),
        alignment: Alignment.center,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: rarityColor.withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: -5,
                offset: Offset(
                  _yRotation * -30,
                  _xRotation * -30,
                ), // dynamic shadow
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Card Background Image
                Image.asset(widget.collectible.imageUrl, fit: BoxFit.cover),
                // Holographic Overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.2),
                        Colors.transparent,
                        rarityColor.withValues(alpha: 0.2),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
                // Borders and Meta Data
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: rarityColor.withValues(alpha: 0.8),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: rarityColor),
                    ),
                    child: Text(
                      '#${widget.collectible.mintNumber} / ${widget.collectible.totalMinted}',
                      style: TextStyle(
                        color: rarityColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.9),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.collectible.rarity.name.toUpperCase(),
                          style: TextStyle(
                            color: rarityColor,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                        Text(
                          widget.collectible.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.collectible.subtitle,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
