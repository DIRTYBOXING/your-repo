import 'package:flutter/material.dart';

/// Smart Devices Ready Panel (2026)
/// Lists global, Japan, and China tech for fight camp integration
class SmartDevicesPanel extends StatelessWidget {
  const SmartDevicesPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.blueGrey.shade900.withValues(alpha: 0.92),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 10,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.devices_other, color: Colors.cyanAccent, size: 32),
                SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Smart Devices Ready (2026)',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.cyanAccent,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Text(
              'Future Tech Devices:',
              style: TextStyle(
                fontSize: 16,
                color: Colors.amberAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '• Neural interfaces (Japan)\n• AI-powered sweat patch (China)\n• NASA biometrics\n• xAI mood sensors\n• Menstrual/fertility trackers\n• Smart recovery pods',
              style: TextStyle(fontSize: 14, color: Colors.white70),
            ),
            const SizedBox(height: 18),
            const Text(
              'All devices comply with 2026 global and Australian cyber security standards.',
              style: TextStyle(fontSize: 12, color: Colors.white38),
            ),
            const SizedBox(height: 16),
            _deviceCategory('Performance Tracking', [
              'WHOOP One / Peak 5.0 (USA/AUS)',
              'FightCamp Connect (USA)',
              'PunchLab Bluetooth Sensors (Europe/Global)',
              'Apple Watch Ultra 3 (USA)',
              'Garmin Forerunner 965 (USA)',
              'Oura Ring Gen 4 (Finland)',
              'Xiaomi Mi Band 9 (China)',
              'Amazfit Bip 6 (China)',
              'Huawei Band 10 (China)',
              'Sports Smartwatch 2026 (Japan)',
              'Amazfit Helio (China)',
              'Polar Vantage V3 / Grit X2 Pro (Global)',
              'Smart Gloves (Japan/China)',
            ]),
            const SizedBox(height: 12),
            _deviceCategory('Recovery & Health', [
              'Oura Ring Gen 4',
              'Amazfit Bip 6',
              'Sports Smartwatch 2026 (Japan)',
              'Polar Grit X2 Pro',
              'Apple Health / Sleep',
              'Garmin HRV/Body Battery',
              'BioTracker SpO2 (China)',
            ]),
            const SizedBox(height: 12),
            _deviceCategory('Smart Environment', [
              'Homey Pro Smart Hub 2026',
              'Withings Smart Scale',
              'Smart Lighting (Philips, Xiaomi, Japan brands)',
            ]),
            const SizedBox(height: 12),
            _deviceCategory('Interactive Training', [
              'FightCamp Interactive',
              'Music Boxing Machines (Japan/China)',
              'VR Boxing (Meta, Pico, Sony)',
            ]),
            const SizedBox(height: 18),
            const Text(
              'All devices comply with 2026 global and Australian cyber security standards.',
              style: TextStyle(fontSize: 12, color: Colors.greenAccent),
            ),
          ],
        ),
      ),
    );
  }

  Widget _deviceCategory(String title, List<String> devices) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.cyanAccent,
          ),
        ),
        const SizedBox(height: 4),
        ...devices.map(
          (d) => Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.greenAccent, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  d,
                  style: const TextStyle(fontSize: 13, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
