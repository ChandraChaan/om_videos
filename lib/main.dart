import 'package:flutter/material.dart';
import 'screens/video_player_screen.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'package:dio/dio.dart';

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
        '/': (context) => LargeFileUploader(),
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

// NEW:
      if (respJson.containsKey('error') && respJson['error'] != null) {
        print("❌ Upload error: ${respJson['error']}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Upload error: ${respJson['error']}")),
        );
        break;
      }

// Continue uploading if server responded without errors
      start = respJson['uploadedBytes'] ?? start;
      print("✅ Uploaded bytes updated to: $start");
      setState(() {
        _progress = start / fileSize;
      });

      if (respJson['complete'] == true) {
        print("🎉 Upload complete! Watch URL: ${respJson['watchUrl']}");
        setState(() {
          _uploadComplete = true;
          _watchUrl = respJson['watchUrl'];
        });
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

class LargeFileUploader extends StatefulWidget {
  const LargeFileUploader({super.key});

  @override
  _LargeFileUploaderState createState() => _LargeFileUploaderState();
}

class _LargeFileUploaderState extends State<LargeFileUploader> {
  File? _file;
  double _progress = 0.0;
  String? _sessionId;

  final Dio dio = Dio();

  static const int chunkSize = 1024 * 1024; // 1 MB chunk

  // Replace with your PHP backend URL
  static const String baseUrl = 'https://omorals.com/php_server/';

  Future<void> pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null && result.files.single.path != null) {
      setState(() {
        _file = File(result.files.single.path!);
        _progress = 0;
        _sessionId = null;
      });
    }
  }

  Future<void> createUploadSession() async {
    print('Creating upload session...');
    final res = await dio.post('$baseUrl/upload_session.php');
    _sessionId = res.data['sessionId'];
    print('Upload session created: $_sessionId');
  }

  Future<void> uploadChunks() async {
    if (_file == null || _sessionId == null) {
      print('No file selected or session ID missing.');
      return;
    }

    final int totalSize = await _file!.length();
    final int totalChunks = (totalSize / chunkSize).ceil();

    print('Starting upload: totalSize=$totalSize bytes, totalChunks=$totalChunks');

    final raf = _file!.openSync();

    for (int i = 0; i < totalChunks; i++) {
      int start = i * chunkSize;
      int end = start + chunkSize;
      if (end > totalSize) end = totalSize;

      int chunkLength = end - start;

      raf.setPositionSync(start);
      Uint8List chunkData = raf.readSync(chunkLength);

      print('Uploading chunk $i: bytes $start to ${end - 1} (size $chunkLength)');

      FormData formData = FormData.fromMap({
        'sessionId': _sessionId,
        'chunkIndex': i.toString(),
        'chunk': MultipartFile.fromBytes(chunkData, filename: 'chunk_$i'),
      });

      // Print debug info before sending
      print('FormData for chunk $i:');
      print('  sessionId: $_sessionId');
      print('  chunkIndex: $i');
      print('  chunk filename: chunk_$i');
      print('  chunk size: ${chunkData.lengthInBytes} bytes');

      try {
        print('--- Uploading chunk $i ---');
        print('SessionId: $_sessionId');
        print('ChunkIndex: $i');
        print('Chunk filename: chunk_$i');
        print('Chunk size: ${chunkData.lengthInBytes} bytes');

        final response = await dio.post(
          '$baseUrl/upload_chunk.php',
          data: formData,
          options: Options(
            validateStatus: (_) => true, // Let us handle non-200 manually
          ),
        );

        print('HTTP ${response.statusCode} ${response.statusMessage}');
        print('Response data: ${response.data}');

        if (response.statusCode != 200) {
          print('❌ Server returned error status for chunk $i');
          throw Exception(
            'Chunk $i failed: HTTP ${response.statusCode} - ${response.data}',
          );
        } else {
          print('✅ Chunk $i uploaded successfully');
        }
      } on DioException catch (dioErr) {
        print('🚨 DioException while uploading chunk $i');
        print('Message: ${dioErr.message}');
        if (dioErr.response != null) {
          print('Status: ${dioErr.response?.statusCode}');
          print('Data: ${dioErr.response?.data}');
          print('Headers: ${dioErr.response?.headers}');
        }
        print('Request Options: ${dioErr.requestOptions}');
        rethrow; // Stop further uploads
      } catch (e, stack) {
        print('💥 Unexpected error uploading chunk $i: $e');
        print(stack);
        rethrow;
      }


      setState(() {
        _progress = (i + 1) / totalChunks;
      });
    }

    raf.closeSync();

    print('All chunks uploaded. Requesting server to complete upload.');

    try {
      print('📤 Sending complete_upload request...');
      print('  sessionId: $_sessionId');
      print('  fileName: ${_file!.path.split('/').last}');
      print('  totalChunks: $totalChunks');

      final res = await dio.post(
        '$baseUrl/complete_upload.php',
        data: {
          'sessionId': _sessionId,
          'fileName': _file!.path.split('/').last,
          'totalChunks': totalChunks,
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType, // Ensures PHP sees it as $_POST
          validateStatus: (status) => status != null && status < 500, // Allow 4xx so we can print
        ),
      );

      print('✅ Complete upload HTTP status: ${res.statusCode}');
      print('✅ Complete upload response: ${res.data}');
    } catch (e, stack) {
      print('❌ Error completing upload: $e');
      print('Stack trace: $stack');
      rethrow;
    }

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Large File Uploader')),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            ElevatedButton(onPressed: pickFile, child: Text('Pick File')),
            SizedBox(height: 20),
            if (_file != null) Text('File: ${_file!.path.split('/').last}'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: (_file == null)
                  ? null
                  : () async {
                try {
                  await createUploadSession();
                  await uploadChunks();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Upload Complete')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Upload failed: $e')),
                  );
                }
              },
              child: Text('Upload File'),
            ),
            SizedBox(height: 20),
            LinearProgressIndicator(value: _progress),
            SizedBox(height: 10),
            Text('${(_progress * 100).toStringAsFixed(1)} %'),
          ],
        ),
      ),
    );
  }
}