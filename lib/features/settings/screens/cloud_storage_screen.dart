import 'package:flutter/material.dart';
import 'package:datafightcentral/core/theme/design_tokens.dart';

/// Cloud Storage Screen — Smart tech for athletes who take their craft seriously.
/// Storage usage, media management, backup, cache — clean and organized.
/// Because disciplined athletes keep their digital life organized too.
class CloudStorageScreen extends StatefulWidget {
  const CloudStorageScreen({super.key});

  @override
  State<CloudStorageScreen> createState() => _CloudStorageScreenState();
}

class _CloudStorageScreenState extends State<CloudStorageScreen> {
  bool _autoBackup = true;
  bool _wifiOnly = true;

  // Demo storage data
  static const double _usedGB = 2.4;
  static const double _totalGB = 5.0;

  static const List<Map<String, dynamic>> _storageBreakdown = [
    {
      'label': 'Training Videos',
      'size': '1.2 GB',
      'count': 47,
      'icon': Icons.videocam,
      'color': 0xFF00F5FF,
      'percent': 0.50,
    },
    {
      'label': 'Fight Analysis',
      'size': '0.5 GB',
      'count': 23,
      'icon': Icons.analytics,
      'color': 0xFFFF00FF,
      'percent': 0.21,
    },
    {
      'label': 'Photos',
      'size': '0.4 GB',
      'count': 186,
      'icon': Icons.photo,
      'color': 0xFF00FF88,
      'percent': 0.17,
    },
    {
      'label': 'Health Data',
      'size': '0.2 GB',
      'count': 365,
      'icon': Icons.favorite,
      'color': 0xFFFF69B4,
      'percent': 0.08,
    },
    {
      'label': 'Documents',
      'size': '0.1 GB',
      'count': 12,
      'icon': Icons.description,
      'color': 0xFFFFB800,
      'percent': 0.04,
    },
  ];

  static const List<Map<String, dynamic>> _recentUploads = [
    {
      'name': 'boxing_footwork_drill.mp4',
      'size': '84 MB',
      'date': 'Today',
      'type': 'video',
    },
    {
      'name': 'sparring_analysis_feb.mp4',
      'size': '142 MB',
      'date': 'Yesterday',
      'type': 'video',
    },
    {
      'name': 'nutrition_plan_march.pdf',
      'size': '2.1 MB',
      'date': 'Mar 3',
      'type': 'doc',
    },
    {
      'name': 'gym_progress_photo.jpg',
      'size': '4.8 MB',
      'date': 'Mar 2',
      'type': 'photo',
    },
    {
      'name': 'heart_rate_export.csv',
      'size': '156 KB',
      'date': 'Mar 1',
      'type': 'data',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgPrimary,
        elevation: 0,
        title: const Text(
          'Cloud Storage',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: () {},
            icon: Icon(
              Icons.settings_outlined,
              color: Colors.white.withValues(alpha: 0.5),
              size: 22,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _buildStorageRing(),
          const SizedBox(height: 20),
          _sectionLabel('Storage Breakdown'),
          const SizedBox(height: 10),
          ..._storageBreakdown.map(_buildStorageItem),
          const SizedBox(height: 20),
          _sectionLabel('Backup Settings'),
          const SizedBox(height: 10),
          _buildBackupSettings(),
          const SizedBox(height: 20),
          _sectionLabel('Recent Uploads'),
          const SizedBox(height: 10),
          ..._recentUploads.map(_buildRecentItem),
          const SizedBox(height: 20),
          _buildCacheCard(),
          const SizedBox(height: 20),
          _buildUpgradeCard(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildStorageRing() {
    final percent = _usedGB / _totalGB;
    final color = percent > 0.9
        ? DesignTokens.neonRed
        : percent > 0.7
        ? DesignTokens.neonAmber
        : DesignTokens.neonCyan;

    return _glassCard(
      child: Column(
        children: [
          SizedBox(
            height: 140,
            width: 140,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 140,
                  width: 140,
                  child: CircularProgressIndicator(
                    value: percent,
                    strokeWidth: 10,
                    backgroundColor: Colors.white.withValues(alpha: 0.06),
                    valueColor: AlwaysStoppedAnimation(color),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${_usedGB.toStringAsFixed(1)} GB',
                      style: TextStyle(
                        color: color,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'of ${_totalGB.toStringAsFixed(0)} GB used',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
            ),
            child: Text(
              '${(_totalGB - _usedGB).toStringAsFixed(1)} GB available — track your training journey',
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStorageItem(Map<String, dynamic> item) {
    final color = Color(item['color'] as int);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: _glassCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(item['icon'] as IconData, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['label'] as String,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${item['count']} items • ${item['size']}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 60,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: item['percent'] as double,
                  backgroundColor: Colors.white.withValues(alpha: 0.06),
                  valueColor: AlwaysStoppedAnimation(color),
                  minHeight: 6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackupSettings() {
    return _glassCard(
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.cloud_upload_outlined,
                color: DesignTokens.neonGreen,
                size: 20,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Auto Backup',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Automatically sync training data to cloud',
                      style: TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: _autoBackup,
                onChanged: (v) => setState(() => _autoBackup = v),
                activeThumbColor: DesignTokens.neonGreen,
                activeTrackColor: DesignTokens.neonGreen.withValues(alpha: 0.3),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Divider(color: Colors.white.withValues(alpha: 0.06), height: 1),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.wifi, color: DesignTokens.neonCyan, size: 20),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Wi-Fi Only',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Save mobile data for when you\'re at the gym',
                      style: TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: _wifiOnly,
                onChanged: (v) => setState(() => _wifiOnly = v),
                activeThumbColor: DesignTokens.neonCyan,
                activeTrackColor: DesignTokens.neonCyan.withValues(alpha: 0.3),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text(
                      'Backup started — your training data is being secured',
                    ),
                    backgroundColor: DesignTokens.neonGreen.withValues(
                      alpha: 0.9,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.backup, size: 18),
              label: const Text(
                'Backup Now',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: DesignTokens.neonGreen,
                side: BorderSide(
                  color: DesignTokens.neonGreen.withValues(alpha: 0.3),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentItem(Map<String, dynamic> item) {
    IconData icon;
    Color color;
    switch (item['type']) {
      case 'video':
        icon = Icons.play_circle_outline;
        color = DesignTokens.neonCyan;
        break;
      case 'doc':
        icon = Icons.description_outlined;
        color = DesignTokens.neonAmber;
        break;
      case 'photo':
        icon = Icons.image_outlined;
        color = DesignTokens.neonGreen;
        break;
      case 'data':
        icon = Icons.bar_chart;
        color = DesignTokens.neonMagenta;
        break;
      default:
        icon = Icons.insert_drive_file;
        color = Colors.white54;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['name'] as String,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${item['size']} • ${item['date']}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.more_horiz,
              color: Colors.white.withValues(alpha: 0.3),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCacheCard() {
    return _glassCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: DesignTokens.neonRed.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.cleaning_services,
              color: DesignTokens.neonRed,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Clear Cache',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Free up 312 MB of cached data',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cache cleared — 312 MB freed')),
              );
            },
            child: const Text(
              'Clear',
              style: TextStyle(
                color: DesignTokens.neonRed,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpgradeCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            DesignTokens.neonGold.withValues(alpha: 0.08),
            DesignTokens.neonAmber.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        border: Border.all(color: DesignTokens.neonGold.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          const Text('🏆', style: TextStyle(fontSize: 28)),
          const SizedBox(height: 8),
          const Text(
            'Upgrade to DFC Pro',
            style: TextStyle(
              color: DesignTokens.neonGold,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Get 50 GB storage, unlimited video analysis, and priority backup. '
            'Invest in your athletic development.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: DesignTokens.neonGold.withValues(alpha: 0.2),
                foregroundColor: DesignTokens.neonGold,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
                  side: BorderSide(
                    color: DesignTokens.neonGold.withValues(alpha: 0.3),
                  ),
                ),
              ),
              child: const Text(
                'View Pro Plans',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.35),
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _glassCard({required Widget child, EdgeInsets? padding}) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard.withValues(
          alpha: DesignTokens.glassOpacity + 0.04,
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        border: Border.all(
          color: Colors.white.withValues(
            alpha: DesignTokens.glassBorderOpacity,
          ),
        ),
      ),
      child: child,
    );
  }
}
