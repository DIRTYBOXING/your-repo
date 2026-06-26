import 'dart:async';
// This file is only used on web via conditional imports. Suppress the
// analyzer warnings about using `dart:html` and web libraries here.
// ignore: deprecated_member_use,avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Returns the base64 payload (without the data URI header) of the picked image,
/// or null if the user cancelled or an error occurred.
Future<String?> pickImageBase64Web() async {
  final upload = html.FileUploadInputElement()..accept = 'image/*';
  upload.click();

  final completer = Completer<String?>();

  upload.onChange.listen((_) async {
    final files = upload.files;
    if (files == null || files.isEmpty) {
      completer.complete(null);
      return;
    }
    final file = files[0];
    final reader = html.FileReader();
    reader.readAsDataUrl(file);
    await reader.onLoad.first;
    final result = reader.result as String;
    final base64Part = result.split(',').last;
    completer.complete(base64Part);
  });

  return completer.future;
}
