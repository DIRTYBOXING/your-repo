import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/services/content_pipeline_service.dart';

/// Content Pipeline Dashboard — Visual pipeline flow with DRAG & DROP.
/// Kanban-style board: drag content between stages to advance/revert.
/// Shows Intake → Transform → Queue → Distribute → Track → Complete
/// with live Firestore counts and real-time streaming.
class ContentPipelineDashboardScreen extends StatefulWidget {
  const ContentPipelineDashboardScreen({super.key});

  @override
  State<ContentPipelineDashboardScreen> createState() =>
      _ContentPipelineDashboardScreenState();
}

class _ContentPipelineDashboardScreenState
    extends State<ContentPipelineDashboardScreen> {
  final ContentPipelineService _pipeline = ContentPipelineService();
  Map<String, int> _stageCounts = {};
  bool _loading = true;
  String _selectedStage = 'intake';
  String? _draggingOverStage; // Track which stage is being hovered

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    setState(() => _loading = true);
    try {
      final counts = await _pipeline.getStageCounts();
      if (mounted) {
        setState(() {
          _stageCounts = counts;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      appBar: AppBar(
        title: const Text('CONTENT PIPELINE'),
        backgroundColor: AppTheme.cardBackground,
        foregroundColor: AppTheme.neonCyan,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.neonCyan),
            onPressed: _loadCounts,
          ),
        ],
      ),
      body: Column(
        children: [
          // Pipeline flow visualization
          _buildPipelineFlow(),
          const Divider(color: AppTheme.cardBackground, height: 1),

          // Stage detail view
          Expanded(child: _buildStageDetail()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showTestPipelineDialog,
        backgroundColor: AppTheme.neonCyan,
        foregroundColor: AppTheme.primaryBackground,
        icon: const Icon(Icons.add),
        label: const Text('TEST PIPELINE'),
      ),
    );
  }

  // Stage definitions
  List<_PipelineStage> get _displayStages => [
    _PipelineStage('intake', 'INTAKE', Icons.input, AppTheme.neonCyan),
    _PipelineStage(
      'transform',
      'TRANSFORM',
      Icons.auto_fix_high,
      AppTheme.neonMagenta,
    ),
    _PipelineStage('queue', 'QUEUE', Icons.queue, AppTheme.neonOrange),
    _PipelineStage('distribute', 'DISTRIBUTE', Icons.send, AppTheme.neonGreen),
    _PipelineStage('track', 'TRACK', Icons.analytics, AppTheme.neonPurple),
    _PipelineStage(
      'complete',
      'DONE',
      Icons.check_circle,
      const Color(0xFFFFD700),
    ),
  ];

  Widget _buildPipelineFlow() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      color: AppTheme.cardBackground,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _displayStages.map((stage) {
            final count = _stageCounts[stage.key] ?? 0;
            final isSelected = _selectedStage == stage.key;
            final isDragOver = _draggingOverStage == stage.key;

            return Row(
              children: [
                DragTarget<Map<String, dynamic>>(
                  onWillAcceptWithDetails: (details) {
                    final fromStage = details.data['stage'] as String?;
                    // Allow drop if not the same stage
                    if (fromStage != stage.key) {
                      setState(() => _draggingOverStage = stage.key);
                      return true;
                    }
                    return false;
                  },
                  onLeave: (_) {
                    setState(() => _draggingOverStage = null);
                  },
                  onAcceptWithDetails: (details) async {
                    setState(() => _draggingOverStage = null);
                    final docId = details.data['id'] as String;
                    final fromStage = details.data['stage'] as String;

                    // Move item to new stage
                    await _pipeline.advanceStage(docId, stage.key);
                    _loadCounts();

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '✓ Moved from ${fromStage.toUpperCase()} → ${stage.key.toUpperCase()}',
                          ),
                          backgroundColor: stage.color,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  builder: (context, candidateData, rejectedData) {
                    return GestureDetector(
                      onTap: () => setState(() => _selectedStage = stage.key),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 80,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isDragOver
                              ? stage.color.withValues(alpha: 0.35)
                              : isSelected
                              ? stage.color.withValues(alpha: 0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: isDragOver
                              ? Border.all(color: stage.color, width: 3)
                              : isSelected
                              ? Border.all(color: stage.color, width: 1.5)
                              : null,
                          boxShadow: isDragOver
                              ? [
                                  BoxShadow(
                                    color: stage.color.withValues(alpha: 0.5),
                                    blurRadius: 12,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : null,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(stage.icon, color: stage.color, size: 24),
                            const SizedBox(height: 4),
                            Text(
                              _loading ? '...' : '$count',
                              style: TextStyle(
                                color: stage.color,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              stage.label,
                              style: const TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 9,
                                letterSpacing: 0.5,
                              ),
                            ),
                            if (isDragOver) ...[
                              const SizedBox(height: 4),
                              Text(
                                'DROP HERE',
                                style: TextStyle(
                                  color: stage.color,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
                if (stage.key != 'complete')
                  Icon(
                    Icons.arrow_forward_ios,
                    color: AppTheme.textMuted.withValues(alpha: 0.3),
                    size: 14,
                  ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildStageDetail() {
    final failedCount = _stageCounts['failed'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(
                '${_selectedStage.toUpperCase()} ITEMS',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              if (failedCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$failedCount FAILED',
                    style: const TextStyle(
                      color: AppTheme.error,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _pipeline.streamByStage(_selectedStage, limit: 30),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: AppTheme.neonCyan),
                );
              }

              final items = snapshot.data ?? [];
              if (items.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.inbox, color: AppTheme.textMuted, size: 48),
                      const SizedBox(height: 8),
                      Text(
                        'No items in ${_selectedStage.toUpperCase()}',
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return _buildPipelineItem(item);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPipelineItem(Map<String, dynamic> item) {
    final title = item['title'] ?? 'Untitled';
    final contentType = item['contentType'] ?? 'unknown';
    final stage = item['stage'] ?? 'intake';
    final error = item['error'];
    final color = _stageColor(stage);

    final itemContent = Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  contentType.toUpperCase(),
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              // Drag handle indicator
              Icon(
                Icons.drag_indicator,
                color: AppTheme.textMuted.withValues(alpha: 0.5),
                size: 18,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            title.toString(),
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (error != null) ...[
            const SizedBox(height: 4),
            Text(
              'Error: $error',
              style: const TextStyle(color: AppTheme.error, fontSize: 11),
            ),
          ],
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                'DRAG TO MOVE',
                style: TextStyle(
                  color: AppTheme.textMuted.withValues(alpha: 0.5),
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (stage == 'failed' || stage == 'intake')
                _buildStageActions(item),
            ],
          ),
        ],
      ),
    );

    // Wrap in Draggable
    return LongPressDraggable<Map<String, dynamic>>(
      data: item,
      delay: const Duration(milliseconds: 150),
      feedback: Material(
        color: Colors.transparent,
        elevation: 8,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.5),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.open_with, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                stage.toUpperCase(),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: itemContent),
      child: itemContent,
    );
  }

  Widget _buildStageActions(Map<String, dynamic> item) {
    final docId = item['id'] as String;
    final stage = item['stage'] as String;

    if (stage == 'failed') {
      return TextButton(
        onPressed: () async {
          await _pipeline.retry(docId);
          _loadCounts();
        },
        child: const Text(
          'RETRY',
          style: TextStyle(color: AppTheme.neonOrange, fontSize: 11),
        ),
      );
    }

    if (stage == 'intake') {
      return TextButton(
        onPressed: () async {
          await _pipeline.advanceStage(docId, 'transform');
          _loadCounts();
        },
        child: const Text(
          'ADVANCE',
          style: TextStyle(color: AppTheme.neonGreen, fontSize: 11),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Color _stageColor(String stage) {
    switch (stage) {
      case 'intake':
        return AppTheme.neonCyan;
      case 'transform':
        return AppTheme.neonMagenta;
      case 'queue':
        return AppTheme.neonOrange;
      case 'distribute':
        return AppTheme.neonGreen;
      case 'track':
        return AppTheme.neonPurple;
      case 'complete':
        return const Color(0xFFFFD700);
      case 'failed':
        return AppTheme.error;
      default:
        return AppTheme.textMuted;
    }
  }

  void _showTestPipelineDialog() {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: const Text(
          'Test Pipeline Intake',
          style: TextStyle(color: AppTheme.neonCyan),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Title',
                hintStyle: TextStyle(color: AppTheme.textMuted),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: bodyController,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Content body',
                hintStyle: TextStyle(color: AppTheme.textMuted),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppTheme.textMuted),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isNotEmpty) {
                await _pipeline.intake(
                  contentType: 'post',
                  title: titleController.text,
                  body: bodyController.text,
                  targetPlatforms: [
                    'instagram',
                    'facebook',
                    'twitter',
                    'tiktok',
                  ],
                );
                _loadCounts();
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Content ingested into pipeline'),
                      backgroundColor: AppTheme.neonGreen,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.neonCyan,
              foregroundColor: AppTheme.primaryBackground,
            ),
            child: const Text('INTAKE'),
          ),
        ],
      ),
    );
  }
}

class _PipelineStage {
  final String key;
  final String label;
  final IconData icon;
  final Color color;
  _PipelineStage(this.key, this.label, this.icon, this.color);
}
