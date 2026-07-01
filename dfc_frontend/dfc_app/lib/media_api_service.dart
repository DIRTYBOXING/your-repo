import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class MediaApiService {
  static const String baseUrl = "http://localhost:8000/api/upload";

  static Future<String> uploadFile(File file) async {
    final request = http.MultipartRequest("POST", Uri.parse(baseUrl));
    request.files.add(await http.MultipartFile.fromPath("file", file.path));

    final response = await request.send();
    final body = await response.stream.bytesToString();

    return jsonDecode(body)["url"];
  }
}
