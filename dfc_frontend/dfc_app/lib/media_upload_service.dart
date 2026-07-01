import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class MediaUploadService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  static Future<String?> uploadBytes({
    required String folderPath,
    required String fileName,
    required Uint8List bytes,
    String contentType = 'image/jpeg',
  }) async {
    try {
      final ref = _storage.ref().child(folderPath).child(fileName);
      final uploadTask = await ref.putData(
        bytes,
        SettableMetadata(contentType: contentType),
      );

      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint('Firebase Storage Upload Error: $e');
      throw Exception('Failed to upload media: $e');
    }
  }
}
