import 'package:flutter/material.dart';
import 'screens/video_player_screen.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'dart:convert';
import 'package:http/http.dart' as http;

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
        '/': (context) => FilePickerScreen(),
        VideoPlayerScreen.routeName: (context) => const VideoPlayerScreen(),
      },
    );
  }
}

class FilePickerScreen extends StatefulWidget {
  const FilePickerScreen({Key? key}) : super(key: key);

  @override
  State<FilePickerScreen> createState() => _FilePickerScreenState();
}

class _FilePickerScreenState extends State<FilePickerScreen> {
  File? _selectedFile;

  double _progress = 0;
  bool _isUploading = false;
  bool _uploadComplete = false;
  String? _watchUrl;

  // Configure your server base URL here
  final String serverUrl = "https://omorals.com/php_server";

  Future<void> pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      File file = File(result.files.single.path!);
      setState(() {
        _selectedFile = file;
        _progress = 0;
        _uploadComplete = false;
        _watchUrl = null;
      });
    }
  }

  Future<void> startUpload() async {
    print("=== startUpload() CALLED ===");

    if (_selectedFile == null) {
      print("❌ ERROR: _selectedFile is NULL");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please select a file first")),
      );
      return;
    }
    print("✅ File selected: ${_selectedFile!.path}");

    setState(() {
      _isUploading = true;
    });

    String fileName = path.basename(_selectedFile!.path);
    int fileSize = await _selectedFile!.length();
    print("📄 fileName: $fileName");
    print("📦 fileSize: $fileSize bytes");
    print("🌐 Server URL: $serverUrl");

    // STEP 1: Request upload ID from server
    print("📤 Sending start_upload.php request...");
    var idRes = await http.post(
      Uri.parse("$serverUrl/start_upload.php"),
      body: {
        "fileName": fileName,
        "totalSize": fileSize.toString(), // server expects totalSize, not fileSize
      },
    );
    print("📥 Response from start_upload.php: ${idRes.statusCode} ${idRes.body}");

    var idJson;
    try {
      idJson = jsonDecode(idRes.body);
    } catch (e) {
      print("❌ JSON decode error: $e");
      return;
    }

    print("📦 Parsed idJson: $idJson");

    if (idJson['uploadId'] == null) {
      print("❌ uploadId is NULL. Full server response: $idJson");
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to init upload: ${idJson['error'] ?? 'Unknown error'}")),
      );
      return;
    }
    String _uploadId = idJson['uploadId'];
    print("✅ Got uploadId: $_uploadId");

    // STEP 2: Check how many bytes already uploaded
    print("📤 Sending check.php request...");
    var checkRes = await http.post(
      Uri.parse("$serverUrl/check.php"),
      body: {
        "uploadId": _uploadId,
      },
    );
    print("📥 Response from check.php: ${checkRes.statusCode} ${checkRes.body}");

    var checkJson;
    try {
      checkJson = jsonDecode(checkRes.body);
    } catch (e) {
      print("❌ JSON decode error in check.php: $e");
      return;
    }

    int uploadedBytes = checkJson['uploadedBytes'] ?? 0;
    print("📊 Uploaded bytes from server: $uploadedBytes");

    // STEP 3: Upload in chunks
    const int chunkSize = 512 * 1024; // 512 KB
    RandomAccessFile raf = await _selectedFile!.open();
    int start = uploadedBytes;

    print("🚀 Starting chunk upload loop...");
    while (start < fileSize) {
      int end = (start + chunkSize > fileSize) ? fileSize : start + chunkSize;
      int currentChunkSize = end - start;
      print("➡️ Sending chunk from $start to $end ($currentChunkSize bytes)");

      raf.setPositionSync(start);
      List<int> chunkData = raf.readSync(currentChunkSize);

      var request = http.MultipartRequest(
        "POST",
        Uri.parse("$serverUrl/upload.php"),
      );
      request.fields['uploadId'] = _uploadId;
      request.fields['startByte'] = start.toString();
      request.fields['totalSize'] = fileSize.toString();
      request.files.add(http.MultipartFile.fromBytes(
        'chunk',
        chunkData,
        filename: fileName,
      ));

      var response = await request.send();
      var respStr = await response.stream.bytesToString();
      print("📥 Response from upload.php: $respStr");

      var respJson;
      try {
        respJson = jsonDecode(respStr);
      } catch (e) {
        print("❌ JSON decode error in upload.php: $e");
        break;
      }

      if (respJson['success'] == true) {
        start = respJson['uploadedBytes'] ?? start;
        print("✅ Uploaded bytes updated to: $start");
        setState(() {
          _progress = start / fileSize;
        });
      } else {
        print("❌ Upload error: ${respJson['message']}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Upload error: ${respJson['message']}")),
        );
        break;
      }

      if (respJson['complete'] == true) {
        print("🎉 Upload complete! Watch URL: ${respJson['watchUrl']}");
        setState(() {
          _uploadComplete = true;
          _watchUrl = respJson['watchUrl'];
        });
        break;
      }
    }

    await raf.close();
    setState(() {
      _isUploading = false;
    });
    print("=== startUpload() FINISHED ===");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Resumable File Upload"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: pickFile,
              child: const Text("Pick File"),
            ),
            if (_selectedFile != null) ...[
              const SizedBox(height: 10),
              Text("File: ${path.basename(_selectedFile!.path)}"),
              Text("Size: ${(_selectedFile!.lengthSync() / 1024).toStringAsFixed(2)} KB"),
              const SizedBox(height: 20),
              LinearProgressIndicator(value: _progress),
              const SizedBox(height: 10),
              if (_isUploading)
                const Text("Uploading..."),
              if (!_isUploading && !_uploadComplete)
                ElevatedButton(
                  onPressed: startUpload,
                  child: const Text("Start Upload"),
                ),
              if (_uploadComplete && _watchUrl != null)
                Column(
                  children: [
                    const Text("Upload Complete!"),
                    SelectableText("Watch URL: $_watchUrl"),
                  ],
                ),
            ]
          ],
        ),
      ),
    );
  }
}