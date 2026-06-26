import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/services/global_pricing_service.dart';

/// Global Pricing Screen — region-aware PPV pricing table with detected-region hero.
class GlobalPricingScreen extends StatefulWidget {
  const GlobalPricingScreen({super.key});

  @override
  State<GlobalPricingScreen> createState() => _GlobalPricingScreenState();
}

class _GlobalPricingScreenState extends State<GlobalPricingScreen> {
  final _svc = GlobalPricingService();
  // Demo: treat AU as the detected region (replace with real locale detection in production).
  static const _detectedCode = 'AU';
  RegionPricingEntry? _liveEntry;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadLive();
  }

  Future<void> _loadLive() async {
    final entry = await _svc.getLivePricing(_detectedCode);
    if (mounted) {
      setState(() {
        _liveEntry = entry;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final entries = _svc.allEntries;
    final detected = _liveEntry ?? _svc.getEntry(_detectedCode);

    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryBackground,
        title: const Text(
          'Global Pricing Intelligence',
          style: TextStyle(
            color: AppTheme.neonCyan,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: AppTheme.neonCyan),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.neonCyan),
            onPressed: () {
              setState(() => _loading = true);
              _loadLive();
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeroCard(detected),
          const SizedBox(height: 20),
          _buildSectionHeader('All Regions — PPV Pricing', Icons.public),
          const SizedBox(height: 12),
          ...entries.map((e) => _buildPricingRow(e, e.code == _detectedCode)),
          const SizedBox(height: 24),
          _buildInfoCard(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHeroCard(RegionPricingEntry? entry) {
    if (entry == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.neonCyan.withValues(alpha: 0.15),
            AppTheme.neonMagenta.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.neonCyan.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.neonCyan.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.neonCyan.withValues(alpha: 0.4),
                  ),
                ),
                child: const Text(
                  'YOUR REGION',
                  style: TextStyle(
                    color: AppTheme.neonCyan,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const Spacer(),
              if (_loading)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.neonCyan,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text(entry.flag, style: const TextStyle(fontSize: 40)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${entry.currency} · ${entry.code}',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    entry.displayPrice,
                    style: const TextStyle(
                      color: AppTheme.neonCyan,
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                    ),
                  ),
                  const Text(
                    'per PPV event',
                    style: TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.neonCyan, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: AppTheme.neonCyan,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
        ),
      ],
    );
  }

  Widget _buildPricingRow(RegionPricingEntry e, bool isDetected) {
    final accent = isDetected ? AppTheme.neonCyan : Colors.white24;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDetected
            ? AppTheme.neonCyan.withValues(alpha: 0.07)
            : const Color(0xFF0D1B2A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Text(e.flag, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              e.name,
              style: TextStyle(
                color: isDetected ? AppTheme.neonCyan : Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              e.currency,
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            e.displayPrice,
            style: TextStyle(
              color: isDetected ? AppTheme.neonCyan : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.neonGreen.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.neonGreen.withValues(alpha: 0.25)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: AppTheme.neonGreen, size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Prices are set per region. Overrides can be applied in Firestore under global_pricing/{code}.',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
