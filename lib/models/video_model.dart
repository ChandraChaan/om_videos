// lib/models/video_model.dart
class VideoModel {
  final String id;
  final String title;
  final String description;
  final String thumbnailUrl;
  final String videoUrl;
  final int? durationSeconds;

  const VideoModel({
    required this.id,
    required this.title,
    this.description = '',
    required this.thumbnailUrl,
    required this.videoUrl,
    this.durationSeconds,
  });

  factory VideoModel.fromJson(Map<String, dynamic> json) {
    return VideoModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      thumbnailUrl: json['thumbnailUrl'] ?? '',
      videoUrl: json['videoUrl'] ?? '',
      durationSeconds: json['durationSeconds'] != null
          ? int.tryParse(json['durationSeconds'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'thumbnailUrl': thumbnailUrl,
    'videoUrl': videoUrl,
    'durationSeconds': durationSeconds,
  };
}