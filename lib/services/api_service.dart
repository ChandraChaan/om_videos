// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/video_model.dart';

class ApiService {
  // TODO: set to your real server later
  static const String baseUrl = 'https://example.com/api';

  Future<List<VideoModel>> fetchVideos() async {
    // For now return sample data (no real HTTP). Replace this with an HTTP GET.
    await Future.delayed(const Duration(milliseconds: 300)); // fake latency
    final List<VideoModel> samples = [
      VideoModel(
        id: '1',
        title: 'Big Buck Bunny',
        description: 'Sample video (Big Buck Bunny)',
        thumbnailUrl: 'https://peach.blender.org/wp-content/uploads/title_anouncement.jpg?x11217',
        videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
        durationSeconds: 596,
      ),
      VideoModel(
        id: '2',
        title: 'Sintel (sample)',
        description: 'Sample video (Sintel)',
        thumbnailUrl: 'https://upload.wikimedia.org/wikipedia/commons/7/75/Sintel_poster.jpg',
        videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4',
        durationSeconds: 888,
      ),
    ];
    return samples;
  }

// Example real fetch (commented)
/*
  Future<List<VideoModel>> fetchVideosFromServer() async {
    final response = await http.get(Uri.parse('$baseUrl/videos'));
    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List;
      return list.map((e) => VideoModel.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load videos');
    }
  }
  */
}