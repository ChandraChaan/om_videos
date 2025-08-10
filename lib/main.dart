// lib/main.dart
import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/video_player_screen.dart';

void main() {
  runApp(const OmVideosApp());
}

class OmVideosApp extends StatelessWidget {
  const OmVideosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OM Videos',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepOrange,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        VideoPlayerScreen.routeName: (context) => const VideoPlayerScreen(),
      },
    );
  }
}