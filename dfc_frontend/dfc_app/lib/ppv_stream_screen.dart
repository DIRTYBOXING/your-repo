import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/ppv_entitlement_service.dart';
import 'ppv_analytics_service.dart';

class PpvStreamScreen extends StatefulWidget {
  final String eventId;

  const PpvStreamScreen({super.key, required this.eventId});

  @override
  State<PpvStreamScreen> createState() => _PpvStreamScreenState();
}

class _PpvStreamScreenState extends State<PpvStreamScreen> {
  final PpvEntitlementService _entitlementService = PpvEntitlementService();

  bool _watchStarted = false;

  @override
  void initState() {
    super.initState();
    // gate_view
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      Analytics.ppvEvent(
        funnelStep: 'gate_view',
        eventId: widget.eventId,
        userId: uid,
      );

      // gate_check_access (emitted once, right when we subscribe)
      Analytics.ppvEvent(
        funnelStep: 'gate_check_access',
        eventId: widget.eventId,
        userId: uid,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: _entitlementService.watchEntitlement(widget.eventId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF05060A),
            body: Center(
              child: CircularProgressIndicator(color: Colors.cyanAccent),
            ),
          );
        }

        final hasAccess = snapshot.data ?? false;

        // gate_access_granted / denied (based on entitlement snapshot)
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null) {
          if (hasAccess) {
            Analytics.ppvEvent(
              funnelStep: 'gate_access_granted',
              eventId: widget.eventId,
              userId: uid,
            );

            // watch_start (first time only)
            if (!_watchStarted) {
              _watchStarted = true;
              Analytics.ppvEvent(
                funnelStep: 'watch_start',
                eventId: widget.eventId,
                userId: uid,
              );
            }
          } else {
            Analytics.ppvEvent(
              funnelStep: 'gate_access_denied',
              eventId: widget.eventId,
              userId: uid,
            );

            if (_watchStarted) {
              _watchStarted = false;
              Analytics.ppvEvent(
                funnelStep: 'watch_complete',
                eventId: widget.eventId,
                userId: uid,
              );
            }
          }
        }

        if (!hasAccess) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(
              context,
            ).pushReplacementNamed('/access-pass', arguments: widget.eventId);
          });
          return const Scaffold(backgroundColor: Color(0xFF05060A));
        }

        return Scaffold(
          backgroundColor: const Color(0xFF05060A),
          appBar: AppBar(
            backgroundColor: Colors.black,
            title: const Text(
              'LIVE EVENT',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            centerTitle: true,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Column(
            children: [
              // 1. Video Player Placeholder
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  color: Colors.black87,
                  child: const Center(
                    child: Icon(
                      Icons.play_circle_fill,
                      color: Colors.white54,
                      size: 64,
                    ),
                  ),
                ),
              ),

              // 2. Multi-Cam Options
              Container(
                height: 60,
                color: Colors.grey[900],
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 12,
                  ),
                  children: [
                    _buildCamPill('MAIN CAM', true),
                    _buildCamPill('BLUE CORNER', false),
                    _buildCamPill('RED CORNER', false),
                    _buildCamPill('REFEREE CAM', false),
                  ],
                ),
              ),

              // 3. Biometrics, Stats, and Chat Tabs
              Expanded(
                child: DefaultTabController(
                  length: 3,
                  child: Column(
                    children: [
                      const TabBar(
                        indicatorColor: Colors.cyanAccent,
                        labelColor: Colors.cyanAccent,
                        unselectedLabelColor: Colors.white54,
                        tabs: [
                          Tab(text: 'BIOMETRICS'),
                          Tab(text: 'STATS'),
                          Tab(text: 'CHAT'),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _buildPlaceholder('Biometrics Overlay Data'),
                            _buildPlaceholder('Live Fight Stats'),
                            _buildPlaceholder('DFC Chat Room'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCamPill(String label, bool isSelected) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isSelected
            ? Colors.cyanAccent.withValues(alpha: 0.2)
            : Colors.transparent,
        border: Border.all(
          color: isSelected ? Colors.cyanAccent : Colors.white24,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.cyanAccent : Colors.white70,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPlaceholder(String text) {
    return Center(
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white54,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}
