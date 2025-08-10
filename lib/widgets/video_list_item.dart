// lib/widgets/video_list_item.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class VideoListItem extends StatelessWidget {
  final String title;
  final String thumbnailUrl;
  final String duration;
  final VoidCallback onTap;

  const VideoListItem({
    super.key,
    required this.title,
    required this.thumbnailUrl,
    required this.duration,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Row(
          children: [
            ClipRRect(
              borderRadius:
              const BorderRadius.only(topLeft: Radius.circular(10), bottomLeft: Radius.circular(10)),
              child: CachedNetworkImage(
                imageUrl: thumbnailUrl,
                width: 140,
                height: 84,
                fit: BoxFit.cover,
                placeholder: (c, _) => Container(width: 140, height: 84, color: Colors.grey[300]),
                errorWidget: (c, e, s) => Container(width: 140, height: 84, color: Colors.grey[300], child: const Icon(Icons.broken_image)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Text(duration, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}