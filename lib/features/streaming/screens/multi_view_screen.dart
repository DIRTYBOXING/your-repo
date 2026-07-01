import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';

/// MULTI-VIEW / SPLITVIEW — Watch multiple fights simultaneously.
/// Camera angle selector · Picture-in-picture · Side-by-side · Quad view
/// Beats Kayo/UFC with combat-specific camera controls and fight sync.
class MultiViewScreen extends StatefulWidget {
  const MultiViewScreen({super.key});

  @override
  State<MultiViewScreen> createState() => _MultiViewScreenState();
}

class _MultiViewScreenState extends State<MultiViewScreen> {
  int _layout = 0; // 0=single, 1=side-by-side, 2=quad, 3=pip
  int _selectedStream = 0;

  static const _layouts = [
    ('SINGLE', Icons.crop_square),
    ('SPLIT', Icons.view_column),
    ('QUAD', Icons.grid_view),
    ('PiP', Icons.picture_in_picture),
  ];

  static const _streams = [
    _StreamSource(
      label: 'MAIN CARD',
      event: 'BKFC Fight Night Australia',
      fight: 'Hepi vs Wisniewski',
      quality: '1080p',
      viewers: 12400,
      isLive: true,
    ),
    _StreamSource(
      label: 'CORNER CAM',
      event: 'BKFC Fight Night Australia',
      fight: 'Hepi Corner',
      quality: '720p',
      viewers: 3200,
      isLive: true,
    ),
    _StreamSource(
      label: 'UNDERCARD',
      event: 'BKFC Fight Night Australia',
      fight: 'BK Bau vs TBA',
      quality: '1080p',
      viewers: 5600,
      isLive: true,
    ),
    _StreamSource(
      label: 'CROWD CAM',
      event: 'BKFC Fight Night Australia',
      fight: 'Townsville Crowd',
      quality: '720p',
      viewers: 1800,
      isLive: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width > 800;
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgSecondary,
        title: const Row(
          children: [
            Icon(Icons.view_comfy_alt, color: DesignTokens.neonCyan, size: 22),
            SizedBox(width: 8),
            Text(
              'MULTI-VIEW',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 18,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.fullscreen, color: Colors.white54),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white54),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Layout selector
          _buildLayoutSelector(),
          // Video area
          Expanded(child: _buildVideoArea(wide)),
          // Stream selector strip
          _buildStreamSelector(),
          // Controls bar
          _buildControlsBar(),
        ],
      ),
    );
  }

  Widget _buildLayoutSelector() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: List.generate(_layouts.length, (i) {
          final (label, icon) = _layouts[i];
          final selected = i == _layout;
          return GestureDetector(
            onTap: () => setState(() => _layout = i),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: selected
                    ? DesignTokens.neonCyan.withValues(alpha: 0.12)
                    : Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(8),
                border: selected
                    ? Border.all(
                        color: DesignTokens.neonCyan.withValues(alpha: 0.3),
                      )
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    color: selected ? DesignTokens.neonCyan : Colors.white30,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      color: selected ? DesignTokens.neonCyan : Colors.white30,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildVideoArea(bool wide) {
    switch (_layout) {
      case 1: // Side-by-side
        return Row(
          children: [
            Expanded(child: _videoPanel(_streams[0], true)),
            const SizedBox(width: 2),
            Expanded(child: _videoPanel(_streams[2], false)),
          ],
        );
      case 2: // Quad
        return Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _videoPanel(_streams[0], true)),
                  const SizedBox(width: 2),
                  Expanded(child: _videoPanel(_streams[1], false)),
                ],
              ),
            ),
            const SizedBox(height: 2),
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _videoPanel(_streams[2], false)),
                  const SizedBox(width: 2),
                  Expanded(child: _videoPanel(_streams[3], false)),
                ],
              ),
            ),
          ],
        );
      case 3: // PiP
        return Stack(
          children: [
            _videoPanel(_streams[_selectedStream], true),
            Positioned(
              right: 16,
              bottom: 16,
              width: wide ? 280 : 160,
              height: wide ? 160 : 90,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _videoPanel(
                  _streams[(_selectedStream + 1) % _streams.length],
                  false,
                ),
              ),
            ),
          ],
        );
      default: // Single
        return _videoPanel(_streams[_selectedStream], true);
    }
  }

  Widget _videoPanel(_StreamSource stream, bool primary) {
    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: primary
              ? DesignTokens.neonCyan.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Stack(
        children: [
          // Placeholder for video
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.videocam,
                  color: DesignTokens.neonCyan.withValues(alpha: 0.2),
                  size: 48,
                ),
                const SizedBox(height: 8),
                Text(
                  stream.fight,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                Text(
                  stream.label,
                  style: const TextStyle(color: Colors.white24, fontSize: 10),
                ),
              ],
            ),
          ),
          // Live badge
          if (stream.isLive)
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: DesignTokens.neonRed.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: DesignTokens.neonRed,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'LIVE',
                      style: TextStyle(
                        color: DesignTokens.neonRed,
                        fontWeight: FontWeight.w900,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // Quality + viewers
          Positioned(
            top: 8,
            right: 8,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    stream.quality,
                    style: const TextStyle(color: Colors.white54, fontSize: 9),
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.visibility,
                        color: Colors.white38,
                        size: 10,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${stream.viewers}',
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreamSelector() {
    return SizedBox(
      height: 64,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _streams.length,
        itemBuilder: (context, index) {
          final s = _streams[index];
          final selected = index == _selectedStream;
          return GestureDetector(
            onTap: () => setState(() => _selectedStream = index),
            child: Container(
              width: 140,
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: selected
                    ? DesignTokens.neonCyan.withValues(alpha: 0.1)
                    : DesignTokens.bgCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: selected
                      ? DesignTokens.neonCyan.withValues(alpha: 0.3)
                      : Colors.white.withValues(alpha: 0.06),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    s.label,
                    style: TextStyle(
                      color: selected ? DesignTokens.neonCyan : Colors.white54,
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    s.fight,
                    style: const TextStyle(color: Colors.white30, fontSize: 9),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildControlsBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _controlBtn(Icons.volume_up, 'AUDIO'),
          _controlBtn(Icons.speed, 'LATENCY'),
          _controlBtn(Icons.chat_bubble_outline, 'CHAT'),
          _controlBtn(Icons.analytics_outlined, 'STATS'),
          _controlBtn(Icons.cast, 'CAST'),
          _controlBtn(Icons.share, 'SHARE'),
        ],
      ),
    );
  }

  Widget _controlBtn(IconData icon, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white38, size: 18),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white24,
            fontWeight: FontWeight.w700,
            fontSize: 8,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _StreamSource {
  final String label;
  final String event;
  final String fight;
  final String quality;
  final int viewers;
  final bool isLive;

  const _StreamSource({
    required this.label,
    required this.event,
    required this.fight,
    required this.quality,
    required this.viewers,
    required this.isLive,
  });
}
