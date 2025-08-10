import 'dart:io';
import 'package:http/http.dart' as http;

class UploadService {
  final String serverUrl = "https://omorals.com/app/"; // Change to your server

  Future<int> getUploadedSize(String fileName) async {
    final res = await http.post(
      Uri.parse("$serverUrl/check_progress.php"),
      body: {"fileName": fileName},
    );
    if (res.statusCode == 200) {
      return int.tryParse(res.body) ?? 0;
    }
    return 0;
  }

  Future<void> uploadFileWithResume(File file) async {
    final fileName = file.uri.pathSegments.last;
    final totalSize = await file.length();

    int uploadedSize = await getUploadedSize(fileName);
    print("Already uploaded: $uploadedSize bytes");

    final chunkSize = 1024 * 512; // 512 KB per chunk
    final raf = file.openSync(mode: FileMode.read);
    raf.setPositionSync(uploadedSize);

    int currentPosition = uploadedSize;
    while (currentPosition < totalSize) {
      final remaining = totalSize - currentPosition;
      final bytesToRead = remaining > chunkSize ? chunkSize : remaining;
      final chunk = raf.readSync(bytesToRead);

      var request = http.MultipartRequest(
        "POST",
        Uri.parse("$serverUrl/upload.php"),
      );
      request.fields['fileName'] = fileName;
      request.fields['totalSize'] = totalSize.toString();
      request.fields['chunkStart'] = currentPosition.toString();
      request.files.add(http.MultipartFile.fromBytes(
        'fileChunk',
        chunk,
        filename: fileName,
      ));

      final res = await request.send();
      if (res.statusCode == 200) {
        currentPosition += bytesToRead;
        print("Uploaded $currentPosition / $totalSize bytes");
      } else {
        print("Error uploading chunk at $currentPosition bytes");
        break;
      }
    }
    raf.closeSync();
  }
}