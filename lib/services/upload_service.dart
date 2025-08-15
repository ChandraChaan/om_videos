import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;

class ResumableUploader {
  final Dio _dio;
  final String baseUrl;
  final int chunkSize;

  ResumableUploader({
    required this.baseUrl,
    this.chunkSize = 1 * 1024 * 1024, // 1 MB
  }) : _dio = Dio(
         BaseOptions(
           connectTimeout: const Duration(seconds: 10),
           receiveTimeout: const Duration(seconds: 30),
         ),
       );

  /// Create or reuse an upload session
  Future<String> createUploadSession(String fileName, int fileSize) async {
    final url = '$baseUrl/upload_session.php';
    final totalChunks = (fileSize / chunkSize).ceil();
    print("[Uploader] createUploadSession(): Preparing request...");
    print("[Uploader] URL: $url");
    print("[Uploader] fileName: $fileName");
    print("[Uploader] fileSize: $fileSize bytes");

    try {
      final response = await _dio.post(
        url,
        data: {
          'fileName': fileName,
          'fileSize': fileSize,
          'totalChunks': totalChunks,
        },
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      print("[Uploader] Response status: ${response.statusCode}");
      print("[Uploader] Response data: ${response.data}");

      if (response.statusCode == 200) {
        final data = response.data is String
            ? jsonDecode(response.data)
            : response.data;

        if (data['status'] == 'ok' && data['sessionId'] != null) {
          print(
            "[Uploader] Session created successfully. ID: ${data['sessionId']}",
          );
          return data['sessionId'];
        } else {
          throw Exception(
            'Server returned error: ${data['message'] ?? 'Unknown error'}',
          );
        }
      } else {
        throw Exception('HTTP error: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print("[Uploader] Dio error type: ${e.type}");
      print("[Uploader] Dio error message: ${e.message}");
      if (e.response != null) {
        print("[Uploader] Dio error response code: ${e.response?.statusCode}");
        print("[Uploader] Dio error response data: ${e.response?.data}");
      }
      rethrow;
    } catch (e, stack) {
      print("[Uploader] Unexpected error: $e");
      print(stack);
      rethrow;
    }
  }

  /// Get already uploaded chunk indices
  Future<List<int>> getUploadedChunks(String sessionId) async {
    print('[Uploader] getUploadedChunks(): Checking...');
    final response = await _dio.get(
      '$baseUrl/get_uploaded_chunks.php',
      queryParameters: {'sessionId': sessionId},
    );
    print('[Uploader]   Response: ${response.data}');
    if (response.statusCode == 200) {
      return List<int>.from(response.data['uploadedChunks'] ?? []);
    }
    throw Exception('Failed to fetch uploaded chunks');
  }

  /// Upload one chunk
  Future<void> uploadChunk({
    required String sessionId,
    required File file,
    required int chunkIndex,
    required String fileName,
    required int totalChunks,
  }) async {
    final raf = file.openSync(mode: FileMode.read);
    raf.setPositionSync(chunkIndex * chunkSize);
    final bytes = raf.readSync(chunkSize);
    raf.closeSync();

    print('[Uploader] uploadChunk($chunkIndex) size: ${bytes.length} bytes');

    final formData = FormData.fromMap({
      'sessionId': sessionId,
      'chunkIndex': chunkIndex,
      'fileName': fileName,
      'totalChunks': totalChunks,
      'chunk': MultipartFile.fromBytes(bytes, filename: 'chunk_$chunkIndex'),
    });

    final response = await _dio.post(
      '$baseUrl/upload_chunk.php',
      data: formData,
    );

    print('[Uploader]   Response: ${response.data}');

    if (response.statusCode != 200 || response.data['status'] != 'ok') {
      throw Exception('Chunk $chunkIndex failed to upload');
    }
  }

  /// Complete the upload
  Future<void> completeUpload(
    String sessionId,
    String fileName,
    int totalChunks,
  ) async {
    print('[Uploader] completeUpload(): Finalizing...');
    final response = await _dio.post(
      '$baseUrl/complete_upload.php',
      data: FormData.fromMap({
        'sessionId': sessionId,
        'fileName': fileName,
        'totalChunks': totalChunks,
      }),
    );

    print('[Uploader]   Response: ${response.data}');

    if (response.statusCode != 200 || response.data['status'] != 'ok') {
      throw Exception('Failed to complete upload');
    }
  }

  /// Main method to handle the whole flow
  Future<void> uploadFile(File file) async {
    final fileName = p.basename(file.path);
    final fileSize = await file.length();
    final totalChunks = (fileSize / chunkSize).ceil();

    // 1) Create session
    final sessionId = await createUploadSession(fileName, fileSize);

    // 2) Check uploaded chunks
    final uploadedChunks = await getUploadedChunks(sessionId);

    // 3) Upload missing chunks
    for (var i = 0; i < totalChunks; i++) {
      if (!uploadedChunks.contains(i)) {
        await uploadChunk(
          sessionId: sessionId,
          file: file,
          chunkIndex: i,
          fileName: fileName,
          totalChunks: totalChunks,
        );
      } else {
        print('[Uploader] Skipping chunk $i (already uploaded)');
      }
    }

    // 4) Complete upload
    await completeUpload(sessionId, fileName, totalChunks);
    print('[Uploader] Upload complete!');
  }
}
