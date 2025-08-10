// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import '../models/video_model.dart';
import '../services/api_service.dart';
import '../widgets/video_list_item.dart';
import 'video_player_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _api = ApiService();
  late Future<List<VideoModel>> _futureVideos;

  @override
  void initState() {
    super.initState();
    _futureVideos = _api.fetchVideos();
  }

  String _formatDuration(int? seconds) {
    if (seconds == null) return '';
    final d = Duration(seconds: seconds);
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final secs = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final hours = d.inHours;
    return hours > 0 ? '$hours:$minutes:$secs' : '$minutes:$secs';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OM Videos'),
        centerTitle: true,
      ),
      body: FutureBuilder<List<VideoModel>>(
        future: _futureVideos,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final videos = snapshot.data ?? [];
          if (videos.isEmpty) {
            return const Center(child: Text('No videos yet'));
          }
          return ListView.builder(
            itemCount: videos.length,
            itemBuilder: (context, index) {
              final v = videos[index];
              return VideoListItem(
                title: v.title,
                thumbnailUrl: v.thumbnailUrl,
                duration: _formatDuration(v.durationSeconds),
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    VideoPlayerScreen.routeName,
                    arguments: v,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}