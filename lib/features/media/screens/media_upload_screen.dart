import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/media_provider.dart';

class MediaUploadScreen extends ConsumerStatefulWidget {
  const MediaUploadScreen({super.key});

  @override
  ConsumerState<MediaUploadScreen> createState() => _MediaUploadScreenState();
}

class _MediaUploadScreenState extends ConsumerState<MediaUploadScreen> {
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

    final result = await ref.read(mediaUploadProvider(selectedFile!).future);
    setState(() => uploadedUrl = result);
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
