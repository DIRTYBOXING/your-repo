import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../shared/services/media_upload_service.dart';

class MediaUploadScreen extends StatefulWidget {
  const MediaUploadScreen({super.key});

  @override
  State<MediaUploadScreen> createState() => _MediaUploadScreenState();
}

class _MediaUploadScreenState extends State<MediaUploadScreen> {
  final MediaUploadService _mediaService = MediaUploadService();
  File? selectedFile;
  String? uploadedUrl;

  Future<void> pickFile() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() => selectedFile = File(picked.path));
    }
  }

  Future<void> upload() async {
    if (selectedFile == null) return;

    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
    final result = await _mediaService.uploadImageFile(
      file: selectedFile!,
      userId: userId,
      type: MediaUploadType.post,
    );
    if (!mounted) return;
    setState(() => uploadedUrl = result.success ? result.url : null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Media Upload")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (selectedFile != null) Image.file(selectedFile!, height: 200),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: pickFile,
              child: const Text("Select File"),
            ),

            const SizedBox(height: 20),

            ElevatedButton(onPressed: upload, child: const Text("Upload")),

            if (uploadedUrl != null) ...[
              const SizedBox(height: 20),
              Text("Uploaded URL: $uploadedUrl"),
            ],
          ],
        ),
      ),
    );
  }
}
