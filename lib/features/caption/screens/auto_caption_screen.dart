import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/media_library_item.dart';
import '../../../shared/services/auto_caption_service.dart';

/// Auto Caption Engine Screen — generate hype captions and SEO descriptions
/// for DFC media items. Template mode works offline; AI mode requires GEMINI_API_KEY.
class AutoCaptionScreen extends StatefulWidget {
  const AutoCaptionScreen({super.key});

  @override
  State<AutoCaptionScreen> createState() => _AutoCaptionScreenState();
}

class _AutoCaptionScreenState extends State<AutoCaptionScreen> {
  final _svc = AutoCaptionService();

  // Demo media items — replace with live IngestionService.getRecentItems() when wired
  static final List<MediaLibraryItem> _demoItems = [
    MediaLibraryItem(
      id: 'demo-1',
      mediaUrl: 'assets/dfc_backgrounds/dfc_and_back_ground.png',
      thumbnailUrl: 'assets/dfc_backgrounds/dfc_and_back_ground.png',
      caption: '',
      postedAt: DateTime.now().subtract(const Duration(hours: 2)),
      engagement: 4820,
      platform: 'instagram',
      tags: const ['Christine Ferea', 'BKFC', 'bare knuckle'],
      type: 'highlight',
    ),
    MediaLibraryItem(
      id: 'demo-2',
      mediaUrl: 'assets/dfc_backgrounds/datafight_central_with_logo.png',
      thumbnailUrl: 'assets/dfc_backgrounds/datafight_central_with_logo.png',
      caption: '',
      postedAt: DateTime.now().subtract(const Duration(hours: 5)),
      engagement: 2310,
      platform: 'youtube',
      tags: const ['Stamp Fairtex', 'ONE Championship', 'Muay Thai'],
      type: 'training',
    ),
    MediaLibraryItem(
      id: 'demo-3',
      mediaUrl: 'assets/dfc_backgrounds/new_dfc_image_1.png',
      thumbnailUrl: 'assets/dfc_backgrounds/new_dfc_image_1.png',
      caption: '',
      postedAt: DateTime.now().subtract(const Duration(hours: 8)),
      engagement: 6700,
      platform: 'facebook',
      tags: const ['IBC IV', 'Gold Coast', 'MMA'],
      type: 'promo',
    ),
    MediaLibraryItem(
      id: 'demo-4',
      mediaUrl: 'assets/dfc_backgrounds/dfc2_image_.png',
      thumbnailUrl: 'assets/dfc_backgrounds/dfc2_image_.png',
      caption: '',
      postedAt: DateTime.now().subtract(const Duration(hours: 12)),
      engagement: 1890,
      platform: 'tiktok',
      tags: const ['knockdown', 'Brawling', 'highlight'],
      type: 'highlight',
    ),
    MediaLibraryItem(
      id: 'demo-5',
      mediaUrl: 'assets/dfc_backgrounds/dfc2_image.png',
      thumbnailUrl: 'assets/dfc_backgrounds/dfc2_image.png',
      caption: '',
      postedAt: DateTime.now().subtract(const Duration(hours: 24)),
      engagement: 3400,
      platform: 'instagram',
      tags: const ['Logan DFC', 'champion', 'Dragon'],
      type: 'interview',
    ),
  ];

  final Map<String, CaptionResult> _results = {};
  final Set<String> _loading = {};

  static const _platformColors = {
    'instagram': Color(0xFFE1306C),
    'facebook': Color(0xFF1877F2),
    'youtube': Color(0xFFFF0000),
    'tiktok': Color(0xFF00F2EA),
  };

  static const _typeIcons = {
    'highlight': Icons.bolt,
    'training': Icons.fitness_center,
    'promo': Icons.campaign,
    'interview': Icons.mic,
    'event': Icons.sports_mma,
  };

  Future<void> _generate(MediaLibraryItem item) async {
    setState(() => _loading.add(item.id));
    try {
      final result = await _svc.generateAll(item);
      setState(() => _results[item.id] = result);
    } finally {
      setState(() => _loading.remove(item.id));
    }
  }

  void _copy(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryBackground,
        title: const Text(
          'AI Caption Engine',
          style: TextStyle(
            color: AppTheme.neonCyan,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: AppTheme.neonCyan),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _buildAiToggle(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          ..._demoItems.map(_buildItemCard),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildAiToggle() {
    return GestureDetector(
      onTap: () {
        if (!_svc.useAi) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Set useAi=true and provide GEMINI_API_KEY via dart-define to enable AI mode.',
              ),
              duration: Duration(seconds: 3),
            ),
          );
        }
        setState(() => _svc.useAi = !_svc.useAi);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: _svc.useAi
              ? AppTheme.neonGreen.withValues(alpha: 0.15)
              : Colors.white10,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _svc.useAi
                ? AppTheme.neonGreen.withValues(alpha: 0.5)
                : Colors.white24,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _svc.useAi ? Icons.auto_awesome : Icons.auto_awesome_outlined,
              size: 14,
              color: _svc.useAi ? AppTheme.neonGreen : Colors.white38,
            ),
            const SizedBox(width: 5),
            Text(
              _svc.useAi ? 'AI ON' : 'AI OFF',
              style: TextStyle(
                color: _svc.useAi ? AppTheme.neonGreen : Colors.white38,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.neonCyan.withValues(alpha: 0.10),
            AppTheme.neonMagenta.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.neonCyan.withValues(alpha: 0.3)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome,
                color: AppTheme.neonCyan,
                size: 28,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'DFC AI CAPTION ENGINE',
                  style: TextStyle(
                    color: AppTheme.neonCyan,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    letterSpacing: 1.4,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Generate hype captions and SEO descriptions for any DFC media item. '
            'Template mode runs offline. Toggle AI ON to use Gemini Flash (requires GEMINI_API_KEY).',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(MediaLibraryItem item) {
    final result = _results[item.id];
    final isLoading = _loading.contains(item.id);
    final platformColor = _platformColors[item.platform] ?? AppTheme.neonCyan;
    final typeIcon = _typeIcons[item.type] ?? Icons.video_library;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: result != null
              ? AppTheme.neonGreen.withValues(alpha: 0.4)
              : Colors.white10,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: platformColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(typeIcon, color: platformColor, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.tags.join(', '),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          _chip(item.platform, platformColor),
                          const SizedBox(width: 6),
                          _chip(item.type, Colors.white38),
                          const SizedBox(width: 6),
                          _chip('${item.engagement} eng', AppTheme.neonGreen),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 34,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : () => _generate(item),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.neonCyan.withValues(
                        alpha: 0.15,
                      ),
                      foregroundColor: AppTheme.neonCyan,
                      side: BorderSide(
                        color: AppTheme.neonCyan.withValues(alpha: 0.5),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.neonCyan,
                            ),
                          )
                        : Text(
                            result != null ? 'Regen' : 'Generate',
                            style: const TextStyle(fontSize: 12),
                          ),
                  ),
                ),
              ],
            ),
          ),
          // Results
          if (result != null) _buildResultBlock(result),
        ],
      ),
    );
  }

  Widget _buildResultBlock(CaptionResult result) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      decoration: BoxDecoration(
        color: AppTheme.neonGreen.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.neonGreen.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          _resultRow(
            icon: Icons.bolt,
            label: 'HYPE CAPTION',
            text: result.hypeCaption,
            color: AppTheme.neonMagenta,
          ),
          const Divider(height: 1, color: Colors.white10),
          _resultRow(
            icon: Icons.search,
            label: 'SEO DESCRIPTION',
            text: result.seoDescription,
            color: AppTheme.neonCyan,
          ),
        ],
      ),
    );
  }

  Widget _resultRow({
    required IconData icon,
    required String label,
    required String text,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 13),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => _copy(text, label),
                child: const Icon(Icons.copy, size: 14, color: Colors.white38),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            text,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
