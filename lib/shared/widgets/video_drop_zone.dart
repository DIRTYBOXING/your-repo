import 'package:flutter/material.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:cross_file/cross_file.dart';
import 'package:file_picker/file_picker.dart';

class VideoDropZone extends StatefulWidget {
  final Function(XFile) onFileDropped;

  const VideoDropZone({super.key, required this.onFileDropped});

  @override
  State<VideoDropZone> createState() => _VideoDropZoneState();
}

class _VideoDropZoneState extends State<VideoDropZone> {
  bool _dragging = false;

  @override
  Widget build(BuildContext context) {
    return DropTarget(
      onDragDone: (detail) {
        if (detail.files.isNotEmpty) {
          widget.onFileDropped(detail.files.first);
        }
      },
      onDragEntered: (detail) {
        setState(() {
          _dragging = true;
        });
      },
      onDragExited: (detail) {
        setState(() {
          _dragging = false;
        });
      },
      child: GestureDetector(
        onTap: _pickVideo,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: _dragging
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.white.withValues(alpha: 0.05),
            border: Border.all(
              color: _dragging ? Colors.blue : Colors.white24,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.cloud_upload_outlined,
                size: 64,
                color: _dragging ? Colors.blue : Colors.white54,
              ),
              const SizedBox(height: 16),
              Text(
                'Drag and drop video here',
                style: TextStyle(
                  color: _dragging ? Colors.blue : Colors.white54,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'or click to browse',
                style: TextStyle(color: Colors.white38, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickVideo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      if (file.path != null) {
        widget.onFileDropped(XFile(file.path!));
      }
    }
  }
}
