import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'media_upload_service.dart';

class DfcImageUploadWidget extends StatefulWidget {
  final String label;
  final String folderPath;
  final Function(String) onUploadComplete;

  const DfcImageUploadWidget({
    super.key,
    required this.label,
    required this.folderPath,
    required this.onUploadComplete,
  });

  @override
  State<DfcImageUploadWidget> createState() => _DfcImageUploadWidgetState();
}

class _DfcImageUploadWidgetState extends State<DfcImageUploadWidget> {
  bool _isUploading = false;
  String? _uploadedUrl;

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (image == null) return;

    setState(() => _isUploading = true);

    try {
      final Uint8List bytes = await image.readAsBytes();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${image.name}';

      final url = await MediaUploadService.uploadBytes(
        folderPath: widget.folderPath,
        fileName: fileName,
        bytes: bytes,
      );

      if (url != null) {
        setState(() => _uploadedUrl = url);
        widget.onUploadComplete(url);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _isUploading ? null : _pickAndUploadImage,
      child: Container(
        height: 120,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1C23),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _uploadedUrl != null
                ? Colors.greenAccent
                : Colors.cyanAccent.withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
        child: _isUploading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.cyanAccent),
              )
            : _uploadedUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(_uploadedUrl!, fit: BoxFit.cover),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.cloud_upload_outlined,
                    color: Colors.cyanAccent,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.label,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
