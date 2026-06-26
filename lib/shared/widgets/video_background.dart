import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// A looping video background widget for splash/landing screens.
class VideoBackground extends StatefulWidget {
  final String assetPath;
  final Widget? overlay;
  final double opacity;
  final bool enableAudio;

  const VideoBackground({
    super.key,
    required this.assetPath,
    this.overlay,
    this.opacity = 0.3,
    this.enableAudio = false,
  });

  @override
  State<VideoBackground> createState() => _VideoBackgroundState();
}

class _VideoBackgroundState extends State<VideoBackground> {
  late VideoPlayerController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset(widget.assetPath)
      ..initialize()
          .then((_) {
            setState(() => _initialized = true);
            _controller.setLooping(true);
            _controller.setVolume(widget.enableAudio ? 1.0 : 0.0);
            _controller.play();
          })
          .catchError((e) {
            debugPrint('VideoBackground error: $e');
          });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (_initialized)
          SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller.value.size.width,
                height: _controller.value.size.height,
                child: VideoPlayer(_controller),
              ),
            ),
          ),
        Container(color: Colors.black.withValues(alpha: 1.0 - widget.opacity)),
        if (widget.overlay != null) widget.overlay!,
      ],
    );
  }
}
