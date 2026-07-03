import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class MuxVideoPlayer extends StatefulWidget {
  final String playbackId;
  final bool autoPlay;
  final bool looping;

  const MuxVideoPlayer({
    Key? key,
    required this.playbackId,
    this.autoPlay = false,
    this.looping = false,
  }) : super(key: key);

  @override
  State<MuxVideoPlayer> createState() => _MuxVideoPlayerState();
}

class _MuxVideoPlayerState extends State<MuxVideoPlayer> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    // Construct the Mux HLS URL
    final muxUrl = 'https://stream.mux.com/${widget.playbackId}.m3u8';
    
    _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(muxUrl));
    
    await _videoPlayerController.initialize();

    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController,
      autoPlay: widget.autoPlay,
      looping: widget.looping,
      aspectRatio: _videoPlayerController.value.aspectRatio,
      materialProgressColors: ChewieProgressColors(
        playedColor: Colors.cyanAccent,
        handleColor: Colors.purpleAccent,
        backgroundColor: Colors.grey,
        bufferedColor: Colors.white24,
      ),
      autoInitialize: true,
      errorBuilder: (context, errorMessage) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 42),
              const SizedBox(height: 10),
              Text(
                'Stream unavailable: $errorMessage',
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        );
      },
    );

    setState(() {});
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_chewieController != null &&
        _chewieController!.videoPlayerController.value.isInitialized) {
      return Chewie(controller: _chewieController!);
    } else {
      return const Center(
        child: CircularProgressIndicator(
          color: Colors.cyanAccent,
        ),
      );
    }
  }
}
