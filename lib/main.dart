// import 'package:flutter/material.dart';
// import 'package:om_videos/services/upload_service.dart';
// import 'screens/video_player_screen.dart';
// import 'dart:io';
// import 'package:file_picker/file_picker.dart';
//
// void main() {
//   runApp(const OmVideosApp());
// }
//
// class OmVideosApp extends StatelessWidget {
//   const OmVideosApp({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'OM Videos',
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(
//         primarySwatch: Colors.deepOrange,
//       ),
//       initialRoute: '/',
//       routes: {
//         '/': (context) => LargeFileUploader(),
//         VideoPlayerScreen.routeName: (context) => const VideoPlayerScreen(),
//       },
//     );
//   }
// }
//
// class LargeFileUploader extends StatefulWidget {
//   const LargeFileUploader({super.key});
//
//   @override
//   _LargeFileUploaderState createState() => _LargeFileUploaderState();
// }
//
// class _LargeFileUploaderState extends State<LargeFileUploader> {
//
//   File? _file;
//   double _progress = 0.0;
//
//   final uploader = ResumableUploader(
//     baseUrl: 'https://omorals.com/php_server',
//   );
//
//   Future<void> startUpload() async {
//     await uploader.uploadFile(_file!);
//   }
//
//
//   Future<void> pickFile() async {
//     FilePickerResult? result = await FilePicker.platform.pickFiles();
//
//     if (result != null && result.files.single.path != null) {
//       setState(() {
//         _file = File(result.files.single.path!);
//         _progress = 0;
//       });
//     }
//   }
//
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Large File Uploader')),
//       body: Padding(
//         padding: EdgeInsets.all(20),
//         child: Column(
//           children: [
//             ElevatedButton(onPressed: pickFile, child: Text('Pick File')),
//             SizedBox(height: 20),
//             if (_file != null) Text('File: ${_file!.path.split('/').last}'),
//             SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: (_file == null)
//                   ? null
//                   : () async {
//                 try {
//                   await startUpload();
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(content: Text('Upload Complete')),
//                   );
//                 } catch (e) {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(content: Text('Upload failed: $e')),
//                   );
//                 }
//               },
//               child: Text('Upload File'),
//             ),
//             SizedBox(height: 20),
//             LinearProgressIndicator(value: _progress),
//             SizedBox(height: 10),
//             Text('${(_progress * 100).toStringAsFixed(1)} %'),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:om_videos/screens/login_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginScreen(),
    );
  }
}