import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/glass_card.dart';

class PlatformLaunchpadScreen extends StatefulWidget {
  const PlatformLaunchpadScreen({Key? key}) : super(key: key);

  @override
  State<PlatformLaunchpadScreen> createState() => _PlatformLaunchpadScreenState();
}

class _PlatformLaunchpadScreenState extends State<PlatformLaunchpadScreen> {
  final List<String> _bootSequence = [];
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _runIgnitionSequence();
  }

  Future<void> _runIgnitionSequence() async {
    final steps = [
      'Establishing Secure Connection...',
      'Firebase Engine [ONLINE]',
      'Stripe Payment Gateway [SECURED]',
      'Mux Video Infrastructure [ONLINE]',
      'AstroHealth Telemetry [CALIBRATED]',
      'Shakura AI Guardian [AWAKE]',
      'Matchmaking Radar [ACTIVE]',
      'SYSTEM READY.',
    ];

    for (var step in steps) {
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) {
        setState(() {
          _bootSequence.add(step);
        });
      }
    }

    await Future.delayed(const Duration(milliseconds: 1000));
    if (mounted) {
      setState(() {
        _isReady = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo Placeholder / Reactor Core
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _isReady ? Colors.cyanAccent.withOpacity(0.6) : Colors.redAccent.withOpacity(0.6),
                      blurRadius: 50,
                      spreadRadius: 10,
                    )
                  ],
                  border: Border.all(
                    color: _isReady ? Colors.cyanAccent : Colors.redAccent,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Icon(
                    _isReady ? Icons.power : Icons.power_settings_new,
                    color: Colors.white,
                    size: 60,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                'DFC PLATFORM IGNITION',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4.0,
                ),
              ),
              const SizedBox(height: 40),
              GlassCard(
                child: Container(
                  width: double.infinity,
                  height: 300,
                  padding: const EdgeInsets.all(20),
                  child: ListView.builder(
                    itemCount: _bootSequence.length,
                    itemBuilder: (context, index) {
                      final isLast = index == _bootSequence.length - 1;
                      final isReadyText = _bootSequence[index] == 'SYSTEM READY.';
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Text(
                          '> ${_bootSequence[index]}',
                          style: TextStyle(
                            color: isReadyText 
                                ? Colors.greenAccent 
                                : (isLast ? Colors.cyanAccent : Colors.white54),
                            fontFamily: 'monospace',
                            fontSize: 14,
                            fontWeight: isReadyText ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 40),
              if (_isReady)
                AnimatedOpacity(
                  opacity: 1.0,
                  duration: const Duration(milliseconds: 500),
                  child: InkWell(
                    onTap: () => context.go('/cockpit'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.cyanAccent.withOpacity(0.1),
                        border: Border.all(color: Colors.cyanAccent),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Text(
                        'ENTER COCKPIT',
                        style: TextStyle(
                          color: Colors.cyanAccent,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                        ),
                      ),
                    ),
                  ),
                )
            ],
          ),
        ),
      ),
    );
  }
}
