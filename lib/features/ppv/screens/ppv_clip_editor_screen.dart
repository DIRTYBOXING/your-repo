import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../shared/models/ppv_model.dart';
import '../services/ppv_clip_export_service.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// PPV CLIP EDITOR SCREEN — TRIM & EXPORT
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Interactive UI for selecting clip range:
///   1. Video preview with timeline slider
///   2. Start/End time selection with mm:ss display
///   3. Moment description dropdown (KNOCKOUT, TAKEDOWN, etc.)
///   4. Live watermark preview
///   5. Export button with size estimate
///
/// ═══════════════════════════════════════════════════════════════════════════

class PPVClipEditorScreen extends StatefulWidget {
  /// PPV event context
  final PPVEvent event;

  /// Video URL for preview
  final String videoUrl;

  /// Fighter 1 name
  final String fighter1Name;

  /// Fighter 2 name
  final String fighter2Name;

  /// Current round (for context)
  final int currentRound;

  /// Callback when clip is exported
  final Function(PPVClipExportService.ExportedClip)? onClipExported;

  const PPVClipEditorScreen({
    super.key,
    required this.event,
    required this.videoUrl,
    required this.fighter1Name,
    required this.fighter2Name,
    required this.currentRound,
    this.onClipExported,
  });

  @override
  State<PPVClipEditorScreen> createState() => _PPVClipEditorScreenState();
}

class _PPVClipEditorScreenState extends State<PPVClipEditorScreen> {
  late VideoPlayerController _videoController;
  late PPVClipExportService _exportService;

  // ── Clip Selection State ──
  int _startMs = 0;
  int _endMs = PPVClipExportService.defaultClipDurationSeconds * 1000;
  String? _selectedMoment;
  bool _isExporting = false;

  // ── Moment Types ──
  static const List<String> momentTypes = [
    'KNOCKOUT',
    'TAKEDOWN',
    'SUBMISSION',
    'STRIKING COMBO',
    'REVERSAL',
    'NEAR SUBMISSION',
    'HIGHLIGHT',
  ];

  @override
  void initState() {
    super.initState();
    _exportService = PPVClipExportService();
    _initVideoController();
  }

  void _initVideoController() {
    _videoController =
        VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
          ..initialize().then((_) {
            if (mounted) {
              setState(() {
                // Default to 15 second clip from current position
                _endMs = (_videoController.value.duration.inMilliseconds);
                if (_endMs - _startMs >
                    PPVClipExportService.maxClipDurationSeconds * 1000) {
                  _endMs =
                      _startMs +
                      PPVClipExportService.defaultClipDurationSeconds * 1000;
                }
              });
            }
          });
    _videoController.addListener(_onVideoPositionChanged);
  }

  void _onVideoPositionChanged() {
    setState(() {});
  }

  void _setStartTime(int ms) {
    setState(() {
      _startMs = ms;
      if (_endMs - _startMs >
          PPVClipExportService.maxClipDurationSeconds * 1000) {
        _endMs =
            _startMs + PPVClipExportService.defaultClipDurationSeconds * 1000;
      }
    });
  }

  void _setEndTime(int ms) {
    setState(() {
      _endMs = ms;
      if (_endMs - _startMs >
          PPVClipExportService.maxClipDurationSeconds * 1000) {
        _startMs =
            _endMs - PPVClipExportService.defaultClipDurationSeconds * 1000;
      }
    });
  }

  Future<void> _exportClip() async {
    final clipSelection = PPVClipExportService.ClipSelection(
      startMs: _startMs,
      endMs: _endMs,
      event: widget.event,
      fighter1Name: widget.fighter1Name,
      fighter2Name: widget.fighter2Name,
      round: widget.currentRound,
      momentDescription: _selectedMoment,
    );

    if (!clipSelection.isValidLength) {
      _showError('Clip must be 1–60 seconds');
      return;
    }

    setState(() => _isExporting = true);

    try {
      final exported = await _exportService.exportClip(
        clipSelection,
        videoController: _videoController,
      );

      if (exported != null && mounted) {
        await _exportService.logClipExport(exported, 'current_user_id');
        widget.onClipExported?.call(exported);
        _showSuccess('Clip exported: ${exported.selection.filename}');

        // Pop back to watch screen
        if (mounted) {
          Navigator.pop(context, exported);
        }
      }
    } catch (e) {
      _showError('Failed to export clip: $e');
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: DesignTokens.neonRed),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: DesignTokens.neonGreen),
    );
  }

  @override
  void dispose() {
    _videoController.removeListener(_onVideoPositionChanged);
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_videoController.value.isInitialized) {
      return Scaffold(
        backgroundColor: const Color(0xFF030810),
        appBar: AppBar(
          backgroundColor: const Color(0xFF030810),
          title: const Text('CLIP EDITOR'),
          centerTitle: true,
        ),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(DesignTokens.neonCyan),
          ),
        ),
      );
    }

    final durationSec = (_endMs - _startMs) ~/ 1000;
    final isValid =
        durationSec > 0 &&
        durationSec <= PPVClipExportService.maxClipDurationSeconds;

    return Scaffold(
      backgroundColor: const Color(0xFF030810),
      appBar: AppBar(
        backgroundColor: const Color(0xFF030810),
        title: const Text('CLIP EDITOR'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─ Video Preview ─
              Container(
                width: double.infinity,
                height: 250,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: DesignTokens.neonCyan.withValues(alpha: 0.2),
                  ),
                ),
                child: Stack(
                  children: [
                    VideoPlayer(_videoController),
                    // ─ Clip range overlay ─
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: DesignTokens.neonGreen.withValues(
                                alpha: 0.4,
                              ),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ─ Timeline Slider ─
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CLIP RANGE',
                    style: TextStyle(
                      color: DesignTokens.neonCyan,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Start slider
                  Row(
                    children: [
                      Text(
                        'START:',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Slider(
                          value: _startMs.toDouble(),
                          min: 0,
                          max: (_endMs - 1000)
                              .toDouble(), // At least 1s before end
                          activeColor: DesignTokens.neonGreen,
                          inactiveColor: Colors.white24,
                          onChanged: (v) => _setStartTime(v.toInt()),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 50,
                        child: Text(
                          _formatMs(_startMs),
                          style: TextStyle(
                            color: DesignTokens.neonGreen,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // End slider
                  Row(
                    children: [
                      Text(
                        'END:',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Slider(
                          value: _endMs.toDouble(),
                          min: (_startMs + 1000).toDouble(),
                          max: _videoController.value.duration.inMilliseconds
                              .toDouble(),
                          activeColor: DesignTokens.neonAmber,
                          inactiveColor: Colors.white24,
                          onChanged: (v) => _setEndTime(v.toInt()),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 50,
                        child: Text(
                          _formatMs(_endMs),
                          style: TextStyle(
                            color: DesignTokens.neonAmber,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ─ Duration Display ─
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isValid
                      ? DesignTokens.neonGreen.withValues(alpha: 0.12)
                      : DesignTokens.neonRed.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isValid
                        ? DesignTokens.neonGreen.withValues(alpha: 0.3)
                        : DesignTokens.neonRed.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'DURATION',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      '$durationSec s',
                      style: TextStyle(
                        color: isValid
                            ? DesignTokens.neonGreen
                            : DesignTokens.neonRed,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ─ Moment Type Dropdown ─
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MOMENT TYPE (OPTIONAL)',
                    style: TextStyle(
                      color: DesignTokens.neonCyan,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: _selectedMoment,
                    items: [
                      const DropdownMenuItem(value: null, child: Text('None')),
                      ...momentTypes.map(
                        (m) => DropdownMenuItem(value: m, child: Text(m)),
                      ),
                    ],
                    onChanged: (v) => setState(() => _selectedMoment = v),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: DesignTokens.neonCyan.withValues(alpha: 0.3),
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05),
                    ),
                    style: const TextStyle(color: Colors.white),
                    dropdownColor: const Color(0xFF030810),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ─ Watermark Preview ─
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'WATERMARK PREVIEW',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      PPVClipExportService.watermarkText,
                      style: TextStyle(
                        color: DesignTokens.neonCyan,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (widget.fighter1Name.isNotEmpty &&
                        widget.fighter2Name.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${widget.fighter1Name} vs ${widget.fighter2Name}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      'Round ${widget.currentRound} • $durationSec s',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ─ Export Button ─
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isExporting || !isValid ? null : _exportClip,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isValid
                        ? DesignTokens.neonGreen
                        : Colors.grey,
                    foregroundColor: const Color(0xFF030810),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isExporting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          'EXPORT & SHARE',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 12),

              // ─ Cancel Button ─
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('CANCEL'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatMs(int ms) {
    final seconds = ms ~/ 1000;
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}
