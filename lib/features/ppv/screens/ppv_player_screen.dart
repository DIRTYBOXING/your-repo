import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class PpvPlayerScreen extends StatefulWidget {
  final String playbackId;
  const PpvPlayerScreen({super.key, required this.playbackId});

  @override
  State<PpvPlayerScreen> createState() => _PpvPlayerScreenState();
}

class _PpvPlayerScreenState extends State<PpvPlayerScreen> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    initPlayer();
  }

  Future<void> initPlayer() async {
    final url = "https://stream.mux.com/${widget.playbackId}.m3u8";

    _videoController = VideoPlayerController.networkUrl(Uri.parse(url));
    await _videoController!.initialize();

    if (!mounted) return;

    _chewieController = ChewieController(
      videoPlayerController: _videoController!,
      autoPlay: true,
      looping: false,
      allowFullScreen: true,
      allowMuting: true,
      aspectRatio: _videoController!.value.aspectRatio,
      materialProgressColors: ChewieProgressColors(
        playedColor: Colors.pinkAccent,
        handleColor: Colors.cyanAccent,
        backgroundColor: Colors.white12,
        bufferedColor: Colors.white38,
      ),
      cupertinoProgressColors: ChewieProgressColors(
        playedColor: Colors.pinkAccent,
        handleColor: Colors.cyanAccent,
        backgroundColor: Colors.white12,
        bufferedColor: Colors.white38,
      ),
      errorBuilder: (context, errorMessage) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.pinkAccent,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(errorMessage, style: const TextStyle(color: Colors.white70)),
            ],
          ),
        );
      },
    );

    setState(() {});
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_chewieController == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.pinkAccent),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Theme(
          data: ThemeData.dark().copyWith(
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          child: Chewie(controller: _chewieController!),
        ),
      ),
    );
  }
}
