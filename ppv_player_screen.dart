import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class PpvPlayerScreen extends StatefulWidget {
  final String playbackId;

  const PpvPlayerScreen({super.key, required this.playbackId});

  @override
  State<PpvPlayerScreen> createState() => _PpvPlayerScreenState();
}

class _PpvPlayerScreenState extends State<PpvPlayerScreen> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    final videoUrl = 'https://stream.mux.com/${widget.playbackId}.m3u8';
    _controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));

    try {
      await _controller.initialize();
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        _controller.play();
      }
    } catch (e) {
      debugPrint('Error initializing video player: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'LIVE PPV',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      extendBodyBehindAppBar: true,
      body: Center(
        child: _hasError
            ? const Text(
                'Error loading stream. Please try again.',
                style: TextStyle(color: Colors.redAccent),
              )
            : _isInitialized
            ? AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              )
            : const CircularProgressIndicator(color: Colors.pinkAccent),
      ),
      floatingActionButton: _isInitialized
          ? FloatingActionButton(
              backgroundColor: Colors.pinkAccent,
              onPressed: () {
                setState(() {
                  _controller.value.isPlaying
                      ? _controller.pause()
                      : _controller.play();
                });
              },
              child: Icon(
                _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
              ),
            )
          : null,
    );
  }
}
