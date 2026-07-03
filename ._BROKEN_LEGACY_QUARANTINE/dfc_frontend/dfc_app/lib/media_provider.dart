import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/media_api_service.dart';

final mediaUploadProvider = FutureProvider.family<String, File>((
  ref,
  file,
) async {
  return MediaApiService.uploadFile(file);
});
