import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Ingestion Pipeline Monitor Screen — 7-stage pipeline status, source health, ingestion rates.
class IngestionPipelineScreen extends StatelessWidget {
  const IngestionPipelineScreen({super.key});

  static const _stages = [
    _PipelineStage(
      step: 1,
      name: 'Intake',
      icon: Icons.input,
      description:
          'Receive raw content from Meta API, YouTube, and partner sources.',
      status: _StageStatus.active,
      itemsProcessed: 1284,
      color: AppTheme.neonCyan,
    ),
    _PipelineStage(
      step: 2,
      name: 'Normalize',
      icon: Icons.tune,
      description: 'Standardize metadata, thumbnails, captions, and durations.',
      status: _StageStatus.active,
      itemsProcessed: 1201,
      color: AppTheme.neonGreen,
    ),
    _PipelineStage(
      step: 3,
      name: 'Tag',
      icon: Icons.label_outline,
      description: 'AI auto-tag fighters, gyms, events, locations, and styles.',
      status: _StageStatus.active,
      itemsProcessed: 1156,
      color: AppTheme.neonCyan,
    ),
    _PipelineStage(
      step: 4,
      name: 'Caption',
      icon: Icons.text_fields,
      description: 'Generate hype captions and SEO descriptions via AI.',
      status: _StageStatus.active,
      itemsProcessed: 1089,
      color: AppTheme.neonMagenta,
    ),
    _PipelineStage(
      step: 5,
      name: 'Distribute',
      icon: Icons.public,
      description:
          'Push to Instagram, Facebook, YouTube, TikTok per region rules.',
      status: _StageStatus.active,
      itemsProcessed: 978,
      color: AppTheme.neonGreen,
    ),
    _PipelineStage(
      step: 6,
      name: 'Track',
      icon: Icons.bar_chart,
      description: 'Record engagement, reach, and analytics per media item.',
      status: _StageStatus.idle,
      itemsProcessed: 812,
      color: AppTheme.neonCyan,
    ),
    _PipelineStage(
      step: 7,
      name: 'Promote',
      icon: Icons.campaign,
      description:
          'Trigger promotion sequences — countdowns, replays, campaigns.',
      status: _StageStatus.idle,
      itemsProcessed: 394,
      color: AppTheme.neonMagenta,
    ),
  ];

  static const _sources = [
    _SourceHealth(name: 'Meta Graph API', health: 98, icon: Icons.facebook),
    _SourceHealth(
      name: 'YouTube Data API',
      health: 100,
      icon: Icons.play_circle_outline,
    ),
    _SourceHealth(name: 'DFC Partner Feeds', health: 94, icon: Icons.rss_feed),
    _SourceHealth(
      name: 'Firestore Uploads',
      health: 100,
      icon: Icons.cloud_upload,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryBackground,
        title: const Text(
          'Ingestion Pipeline Monitor',
          style: TextStyle(
            color: AppTheme.neonCyan,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: AppTheme.neonCyan),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('Pipeline Stages', Icons.account_tree),
          const SizedBox(height: 12),
          ..._stages.map(_buildStageCard),
          const SizedBox(height: 24),
          _buildSectionHeader('Source Health', Icons.monitor_heart),
          const SizedBox(height: 12),
          ..._sources.map(_buildSourceCard),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.neonCyan, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: AppTheme.neonCyan,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildStageCard(_PipelineStage stage) {
    final statusColor = switch (stage.status) {
      _StageStatus.active => AppTheme.neonGreen,
      _StageStatus.idle => Colors.grey,
      _StageStatus.error => AppTheme.neonMagenta,
    };
    final statusLabel = switch (stage.status) {
      _StageStatus.active => 'ACTIVE',
      _StageStatus.idle => 'IDLE',
      _StageStatus.error => 'ERROR',
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: stage.color.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Step badge
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: stage.color, width: 1.5),
              ),
              alignment: Alignment.center,
              child: Text(
                '${stage.step}',
                style: TextStyle(
                  color: stage.color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(stage.icon, color: stage.color, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        stage.name,
                        style: TextStyle(
                          color: stage.color,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: statusColor.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    stage.description,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${stage.itemsProcessed.toString()} items processed',
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceCard(_SourceHealth source) {
    final healthColor = source.health >= 98
        ? AppTheme.neonGreen
        : source.health >= 90
        ? Colors.orange
        : AppTheme.neonMagenta;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B2A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Icon(source.icon, color: Colors.white54, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              source.name,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
          Text(
            '${source.health}%',
            style: TextStyle(
              color: healthColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: healthColor,
              boxShadow: [
                BoxShadow(
                  color: healthColor.withValues(alpha: 0.6),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Data classes ──────────────────────────────────────────────────────────────

enum _StageStatus { active, idle, error }

class _PipelineStage {
  final int step;
  final String name;
  final IconData icon;
  final String description;
  final _StageStatus status;
  final int itemsProcessed;
  final Color color;

  const _PipelineStage({
    required this.step,
    required this.name,
    required this.icon,
    required this.description,
    required this.status,
    required this.itemsProcessed,
    required this.color,
  });
}

class _SourceHealth {
  final String name;
  final int health;
  final IconData icon;

  const _SourceHealth({
    required this.name,
    required this.health,
    required this.icon,
  });
}
