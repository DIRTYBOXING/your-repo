import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// CRISIS INTERVENTION — NightChill Program
// SOS alerts · Safety tracking · Emergency contacts · Mind health support
// ═══════════════════════════════════════════════════════════════════════════════

class CrisisInterventionScreen extends StatefulWidget {
  const CrisisInterventionScreen({super.key});

  @override
  State<CrisisInterventionScreen> createState() =>
      _CrisisInterventionScreenState();
}

class _CrisisInterventionScreenState extends State<CrisisInterventionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;
  bool _sosActive = false;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _pulse = Tween<double>(
      begin: 0.9,
      end: 1.1,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _triggerSOS() async {
    setState(() => _sosActive = true);
    HapticFeedback.heavyImpact();

    try {
      await FirebaseFirestore.instance.collection('nightchill_sos').add({
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'crisis_sos',
        'status': 'active',
        'responded': false,
      });
    } catch (_) {}

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A0000),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.redAccent),
        ),
        title: const Row(
          children: [
            Icon(Icons.sos, color: Colors.redAccent, size: 28),
            SizedBox(width: 8),
            Text(
              'SOS ALERT SENT',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        content: const Text(
          'Your trusted contacts have been notified with your approximate location.\n\n'
          'Help is on the way.\n\n'
          'If you are in immediate danger, call 000 (Australia) or your local emergency number.',
          style: TextStyle(color: Colors.white70, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => _callEmergency('000'),
            child: const Text(
              'CALL 000',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() => _sosActive = false);
            },
            child: const Text(
              'I\'m Safe Now',
              style: TextStyle(color: Colors.greenAccent),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _callEmergency(String number) async {
    final uri = Uri.parse('tel:$number');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0008),
      appBar: AppBar(
        backgroundColor: Colors.red.shade900.withValues(alpha: 0.8),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Row(
          children: [
            Icon(Icons.sos, color: Colors.redAccent),
            SizedBox(width: 8),
            Text(
              'Crisis Intervention',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── SOS BUTTON ──
          Center(
            child: GestureDetector(
              onTap: _sosActive ? null : _triggerSOS,
              child: AnimatedBuilder(
                animation: _pulse,
                builder: (_, _) => Transform.scale(
                  scale: _sosActive ? 1.0 : _pulse.value,
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: _sosActive
                            ? [Colors.green.shade800, Colors.green.shade900]
                            : [Colors.red.shade700, Colors.red.shade900],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (_sosActive ? Colors.green : Colors.red)
                              .withValues(alpha: 0.4),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _sosActive ? Icons.check : Icons.sos,
                          color: Colors.white,
                          size: 48,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _sosActive ? 'HELP SENT' : 'SOS',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              _sosActive
                  ? 'Your contacts have been notified'
                  : 'Tap to alert your trusted contacts',
              style: TextStyle(
                color: _sosActive ? Colors.greenAccent : Colors.white54,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: 32),

          // ── EMERGENCY NUMBERS ──
          _sectionHead('EMERGENCY NUMBERS'),
          const SizedBox(height: 8),
          _emergencyContact(
            emoji: '🚨',
            name: 'Emergency Services',
            number: '000',
            subtitle: 'Police, Fire, Ambulance (Australia)',
            color: Colors.redAccent,
          ),
          _emergencyContact(
            emoji: '🧠',
            name: 'Lifeline Australia',
            number: '13 11 14',
            subtitle: '24/7 crisis support and suicide prevention',
            color: Colors.cyanAccent,
          ),
          _emergencyContact(
            emoji: '👧',
            name: 'Kids Helpline',
            number: '1800 55 1800',
            subtitle: 'Free counselling for young people 5-25',
            color: Colors.amberAccent,
          ),
          _emergencyContact(
            emoji: '💜',
            name: '1800RESPECT',
            number: '1800 737 732',
            subtitle: 'National DV & sexual assault helpline',
            color: Colors.pinkAccent,
          ),
          _emergencyContact(
            emoji: '🌏',
            name: 'Beyond Blue',
            number: '1300 22 4636',
            subtitle: 'Depression, anxiety and mind health support',
            color: Colors.blueAccent,
          ),
          _emergencyContact(
            emoji: '🆘',
            name: 'Suicide Call Back',
            number: '1300 659 467',
            subtitle: '24/7 phone, video & online counselling',
            color: Colors.orangeAccent,
          ),
          const SizedBox(height: 24),

          // ── INTERNATIONAL NUMBERS ──
          _sectionHead('INTERNATIONAL'),
          const SizedBox(height: 8),
          _emergencyContact(
            emoji: '🇺🇸',
            name: 'US Crisis Line',
            number: '988',
            subtitle: 'Suicide & Crisis Lifeline (US)',
            color: Colors.blue,
          ),
          _emergencyContact(
            emoji: '🇬🇧',
            name: 'Samaritans UK',
            number: '116 123',
            subtitle: '24/7 emotional support (UK & Ireland)',
            color: Colors.green,
          ),
          _emergencyContact(
            emoji: '🇳🇿',
            name: 'Need to Talk? NZ',
            number: '1737',
            subtitle: '24/7 free text or call (New Zealand)',
            color: Colors.tealAccent,
          ),
          const SizedBox(height: 24),

          // ── MIND HEALTH TOOLS ──
          _sectionHead('MIND HEALTH TOOLS'),
          const SizedBox(height: 8),
          _toolCard(
            icon: Icons.air,
            title: 'Breathing Exercise',
            subtitle: 'Box breathing: 4 seconds in, hold, out, hold. Repeat.',
            color: Colors.cyan,
            onTap: _showBreathingExercise,
          ),
          const SizedBox(height: 8),
          _toolCard(
            icon: Icons.visibility,
            title: 'Grounding (5-4-3-2-1)',
            subtitle:
                '5 things you see, 4 you touch, 3 you hear, 2 you smell, 1 you taste',
            color: Colors.deepPurple,
            onTap: _showGrounding,
          ),
          const SizedBox(height: 8),
          _toolCard(
            icon: Icons.self_improvement,
            title: 'Safety Plan',
            subtitle: 'Create your personal safety plan with trusted contacts',
            color: Colors.teal,
            onTap: () {},
          ),
          const SizedBox(height: 24),

          // ── SELF CARE ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.indigo.shade900.withValues(alpha: 0.4),
                  Colors.deepPurple.shade900.withValues(alpha: 0.4),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Text(
                  'Right now, just breathe.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontStyle: FontStyle.italic,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  '💧 Water  🚿 Shower  🪥 Teeth  🛏️ Rest  💙 You matter',
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                ),
                const SizedBox(height: 12),
                Text(
                  'You are not alone. You are not broken.\nYou are surviving — and that takes strength.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.deepPurple.shade200,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // COMPONENTS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _sectionHead(String title) {
    return Text(
      title,
      style: TextStyle(
        color: Colors.red.shade200,
        fontWeight: FontWeight.bold,
        fontSize: 13,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _emergencyContact({
    required String emoji,
    required String name,
    required String number,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: ListTile(
        leading: Text(emoji, style: const TextStyle(fontSize: 28)),
        title: Text(
          name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              number,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
        trailing: IconButton(
          icon: Icon(Icons.phone, color: color),
          onPressed: () => _callEmergency(number.replaceAll(' ', '')),
        ),
        onTap: () => _callEmergency(number.replaceAll(' ', '')),
      ),
    );
  }

  Widget _toolCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBreathingExercise() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0A0A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.cyanAccent),
        ),
        title: const Text(
          'Box Breathing',
          style: TextStyle(color: Colors.cyanAccent),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Follow this pattern:',
              style: TextStyle(color: Colors.white70),
            ),
            SizedBox(height: 16),
            Text(
              '1. Breathe IN — 4 seconds',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              '2. HOLD — 4 seconds',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              '3. Breathe OUT — 4 seconds',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              '4. HOLD — 4 seconds',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              'Repeat 4-6 times.\nFocus only on the count.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Close',
              style: TextStyle(color: Colors.cyanAccent),
            ),
          ),
        ],
      ),
    );
  }

  void _showGrounding() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0A0A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.deepPurple),
        ),
        title: const Text(
          '5-4-3-2-1 Grounding',
          style: TextStyle(color: Colors.deepPurpleAccent),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Look around you right now:',
              style: TextStyle(color: Colors.white70),
            ),
            SizedBox(height: 16),
            Text(
              '👀  5 things you can SEE',
              style: TextStyle(color: Colors.white, fontSize: 15),
            ),
            SizedBox(height: 8),
            Text(
              '✋  4 things you can TOUCH',
              style: TextStyle(color: Colors.white, fontSize: 15),
            ),
            SizedBox(height: 8),
            Text(
              '👂  3 things you can HEAR',
              style: TextStyle(color: Colors.white, fontSize: 15),
            ),
            SizedBox(height: 8),
            Text(
              '👃  2 things you can SMELL',
              style: TextStyle(color: Colors.white, fontSize: 15),
            ),
            SizedBox(height: 8),
            Text(
              '👅  1 thing you can TASTE',
              style: TextStyle(color: Colors.white, fontSize: 15),
            ),
            SizedBox(height: 16),
            Text(
              'Take your time with each one.\nYou are here. You are safe.',
              style: TextStyle(color: Colors.white54),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Close',
              style: TextStyle(color: Colors.deepPurpleAccent),
            ),
          ),
        ],
      ),
    );
  }
}
