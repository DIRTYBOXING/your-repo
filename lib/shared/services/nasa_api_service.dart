import 'dart:convert';
import 'package:http/http.dart' as http;

class NasaApiService {
  static const String _baseUrl = 'https://api.nasa.gov';
  static const String _apiKey = 'DEMO_KEY'; // Replace with your NASA API key

  /// Fetch Astronomy Picture of the Day
  Future<Map<String, dynamic>?> fetchApod() async {
    final url = Uri.parse('$_baseUrl/planetary/apod?api_key=$_apiKey');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    return null;
  }

  /// Fetch Mars Rover Photos (latest)
  Future<List<dynamic>?> fetchMarsRoverPhotos() async {
    final url = Uri.parse(
      '$_baseUrl/mars-photos/api/v1/rovers/curiosity/latest_photos?api_key=$_apiKey',
    );
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['latest_photos'];
    }
    return null;
  }
}
