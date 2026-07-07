import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/design_tokens.dart';

class WomensHavenScreen extends StatefulWidget {
  const WomensHavenScreen({super.key});

  @override
  State<WomensHavenScreen> createState() => _WomensHavenScreenState();
}

class _WomensHavenScreenState extends State<WomensHavenScreen> {
  bool _isLocked = true;
  String _pin = '';

  void _enterPin(String digit) {
    HapticFeedback.selectionClick();
    if (_pin.length < 4) {
      setState(() => _pin += digit);
      if (_pin.length == 4) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (_pin == '1234') {
            // Mock PIN to unlock
            HapticFeedback.heavyImpact();
            setState(() => _isLocked = false);
          } else {
            HapticFeedback.vibrate();
            setState(() => _pin = '');
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLocked) {
      return _buildPrivacyLock();
    }

    return Scaffold(
      backgroundColor: const Color(0xFF07090C), // Softer deep black
      appBar: AppBar(
        backgroundColor: const Color(0xFF07090C),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white70),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          "SANCTUARY",
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            letterSpacing: 4,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.lock_outline, color: Colors.tealAccent),
            onPressed: () {
              HapticFeedback.mediumImpact();
              setState(() {
                _pin = '';
                _isLocked = true;
              });
            },
          ),
        ],
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          _buildSafetyActionBar(),
          const SizedBox(height: 24),
          _buildCycleTrackerV2(),
          const SizedBox(height: 24),
          _buildWellbeingDashboard(),
          const SizedBox(height: 24),
          _buildCalmSpace(),
          const SizedBox(height: 24),
          _buildPrivateNotes(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ═══ 1. PRIVACY LOCK ═══
  Widget _buildPrivacyLock() {
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.shield_moon_outlined,
              size: 64,
              color: Colors.tealAccent,
            ),
            const SizedBox(height: 24),
            const Text(
              "PRIVATE HAVEN",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Enter your 4-digit security PIN",
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index < _pin.length
                        ? Colors.tealAccent
                        : Colors.white10,
                    boxShadow: index < _pin.length
                        ? [
                            BoxShadow(
                              color: Colors.tealAccent.withValues(alpha: 0.5),
                              blurRadius: 8,
                            ),
                          ]
                        : [],
                  ),
                );
              }),
            ),
            const SizedBox(height: 60),
            _buildPinPad(),
            const SizedBox(height: 40),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                "Exit",
                style: TextStyle(color: Colors.white54),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPinPad() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 1.2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: 12,
        itemBuilder: (context, index) {
          if (index == 9) return const SizedBox(); // Bottom left empty
          if (index == 11) {
            return IconButton(
              icon: const Icon(Icons.backspace_outlined, color: Colors.white54),
              onPressed: () {
                HapticFeedback.lightImpact();
                if (_pin.isNotEmpty) {
                  setState(() => _pin = _pin.substring(0, _pin.length - 1));
                }
              },
            );
          }
          final digit = index == 10 ? '0' : '${index + 1}';
          return InkWell(
            onTap: () => _enterPin(digit),
            borderRadius: BorderRadius.circular(32),
            child: Center(
              child: Text(
                digit,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ═══ 2. SAFETY ACTION BAR ═══
  Widget _buildSafetyActionBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.health_and_safety_outlined,
                color: Colors.redAccent,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                "SAFETY PROTOCOLS",
                style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  "ACTIVE",
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildSafetyButton(
                Icons.phone_in_talk,
                "Call\nTrusted",
                Colors.redAccent,
              ),
              const SizedBox(width: 12),
              _buildSafetyButton(
                Icons.location_on,
                "Share\nLocation",
                Colors.amber,
              ),
              const SizedBox(width: 12),
              _buildSafetyButton(
                Icons.check_circle,
                "Quick\nCheck-In",
                Colors.greenAccent,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyButton(IconData icon, String label, Color color) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.heavyImpact();
          Future.delayed(
            const Duration(milliseconds: 120),
            HapticFeedback.lightImpact,
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══ 3. CYCLE TRACKER V2 ═══
  Widget _buildCycleTrackerV2() {
    return _buildPanel(
      "BODY & CYCLE",
      Icons.water_drop_outlined,
      Colors.tealAccent,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Phase: Follicular (Day 11)",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Energy is typically high. Focus on strength training and power output today.",
            style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.5),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildSmallTag("High Energy", Colors.tealAccent),
              const SizedBox(width: 8),
              _buildSmallTag("Stable Mood", Colors.greenAccent),
              const SizedBox(width: 8),
              _buildSmallTag("No Symptoms", Colors.white54),
            ],
          ),
        ],
      ),
    );
  }

  // ═══ 4. WELLBEING DASHBOARD ═══
  Widget _buildWellbeingDashboard() {
    return _buildPanel(
      "DAILY WELLBEING",
      Icons.spa_outlined,
      Colors.purpleAccent,
      Row(
        children: [
          _buildWellbeingStat("Sleep", "7.5h", Icons.bedtime),
          Container(width: 1, height: 40, color: Colors.white10),
          _buildWellbeingStat("Stress", "Low", Icons.psychology),
          Container(width: 1, height: 40, color: Colors.white10),
          _buildWellbeingStat("Readiness", "92%", Icons.battery_charging_full),
        ],
      ),
    );
  }

  Widget _buildWellbeingStat(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.white54, size: 18),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 10),
          ),
        ],
      ),
    );
  }

  // ═══ 5. CALM SPACE ═══
  Widget _buildCalmSpace() {
    return _buildPanel(
      "CALM SPACE",
      Icons.air,
      Colors.blueAccent,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Take a moment to center yourself before training.",
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.self_improvement, size: 18),
            label: const Text("Start 2-Min Box Breathing"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent.withValues(alpha: 0.2),
              foregroundColor: Colors.blueAccent,
              elevation: 0,
              minimumSize: const Size(double.infinity, 44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  // ═══ 6. PRIVATE NOTES ═══
  Widget _buildPrivateNotes() {
    return _buildPanel(
      "PRIVATE JOURNAL",
      Icons.lock_outline,
      Colors.white54,
      TextField(
        maxLines: 4,
        style: const TextStyle(color: Colors.white, fontSize: 13),
        decoration: InputDecoration(
          hintText:
              "Write your thoughts, boundaries, or training notes here. This data never leaves your device.",
          hintStyle: const TextStyle(color: Colors.white38),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.05),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  // ═══ UTILS ═══
  Widget _buildPanel(String title, IconData icon, Color color, Widget child) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF111418), // Slightly lighter than background
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildSmallTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
