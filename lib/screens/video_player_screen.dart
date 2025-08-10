// lib/screens/video_player_screen.dart
import 'package:flutter/material.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';
import '../models/video_model.dart';

class VideoPlayerScreen extends StatefulWidget {
  static const routeName = '/player';
  final VideoModel? video;

  const VideoPlayerScreen({super.key, this.video});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    // If video isn't passed in constructor (Navigator arguments used), try pulling from ModalRoute
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = widget.video ?? ModalRoute.of(context)?.settings.arguments as VideoModel?;
      if (args == null) {
        setState(() {
          error = 'No video provided';
          _isLoading = false;
        });
        return;
      }
      _initPlayer(args.videoUrl);
    });
  }

  Future<void> _initPlayer(String url) async {
    try {
      _videoController = VideoPlayerController.network(url);
      await _videoController!.initialize();
      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: true,
        looping: false,
        allowFullScreen: true,
        allowPlaybackSpeedChanging: true,
        /* other options */
      );
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = 'Failed to load video: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final passed = widget.video ?? ModalRoute.of(context)?.settings.arguments as VideoModel?;
    final title = passed?.title ?? 'Video Player';
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : (error != null
            ? Text(error!, style: const TextStyle(color: Colors.red))
            : _chewieController != null
            ? Chewie(controller: _chewieController!)
            : const SizedBox()),
      ),
    );
  }
}