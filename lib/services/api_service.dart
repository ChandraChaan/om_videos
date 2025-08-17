// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/video_model.dart';
import '../utils/constants.dart';

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

  static Uri _u(String path) => Uri.parse('${AppConstants.apiBaseUrl}/$path');

  static Future<Map<String, dynamic>> post(
      String path,
      Map<String, dynamic> body, {
        String? token,
      }) async {
    final res = await http.post(
      _u(path),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );
    return _decode(res);
  }

  static Future<Map<String, dynamic>> get(
      String path, {
        String? token,
        Map<String, String>? query,
      }) async {
    final uri = _u(path).replace(queryParameters: query);
    final res = await http.get(
      uri,
      headers: {
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
    return _decode(res);
  }

  static Map<String, dynamic> _decode(http.Response res) {
    final map = jsonDecode(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300) return map;
    throw ApiException(res.statusCode, map is Map<String, dynamic> ? (map['error'] ?? map) : map);
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

class ApiException implements Exception {
  final int statusCode;
  final dynamic body;
  ApiException(this.statusCode, this.body);
  @override
  String toString() => 'ApiException($statusCode, $body)';
}
