import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

/// Client for DFC DRM license exchange.
///
/// Validates playback tokens server-side and proxies to your DRM provider
/// (Widevine or FairPlay). Never exposes DRM keys to the client.
class DfcDrmClient {
  static const _base = String.fromEnvironment(
    'DFC_API_BASE',
    defaultValue: 'http://localhost:8080',
  );

  final http.Client _client;
  final String? Function() _tokenProvider;

  DfcDrmClient({http.Client? client, required String? Function() tokenProvider})
    : _client = client ?? http.Client(),
      _tokenProvider = tokenProvider;

  Future<Map<String, String>> _headers() async {
    final h = <String, String>{'Content-Type': 'application/json'};
    final token = _tokenProvider();
    if (token != null) h['Authorization'] = 'Bearer $token';
    return h;
  }

  /// Request a Widevine license.
  /// [licenseRequestBase64] is the Widevine challenge encoded as base64.
  Future<Uint8List> requestWidevineLicense(
    String playbackToken,
    String licenseRequestBase64,
  ) async {
    final url = Uri.parse('$_base/drm/license');
    final res = await _client.post(
      url,
      headers: await _headers(),
      body: jsonEncode({
        'playbackToken': playbackToken,
        'drmType': 'widevine',
        'licenseRequestBase64': licenseRequestBase64,
      }),
    );
    if (res.statusCode != 200) {
      throw Exception('Widevine license request failed: ${res.statusCode}');
    }
    // Server may return raw bytes or base64-encoded JSON
    try {
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      return base64Decode(json['licenseBase64'] as String);
    } catch (_) {
      return res.bodyBytes;
    }
  }

  /// Request a FairPlay CKC (Content Key Context).
  /// [spcBase64] is the SPC (Server Playback Context) encoded as base64.
  Future<Uint8List> requestFairplayCkc(
    String playbackToken,
    String spcBase64,
  ) async {
    final url = Uri.parse('$_base/drm/license');
    final res = await _client.post(
      url,
      headers: await _headers(),
      body: jsonEncode({
        'playbackToken': playbackToken,
        'drmType': 'fairplay',
        'spc': spcBase64,
      }),
    );
    if (res.statusCode != 200) {
      throw Exception('FairPlay CKC request failed: ${res.statusCode}');
    }
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    return base64Decode(json['ckcBase64'] as String);
  }

  void dispose() => _client.close();
}
