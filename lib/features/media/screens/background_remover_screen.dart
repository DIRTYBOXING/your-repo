import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../shared/services/background_removal_service.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// BACKGROUND REMOVER SCREEN — Upload image → get transparent cutout
///
/// Powers: fighter cutouts for posters, collectible cards, promo graphics.
/// Calls the U²-Net bg-removal-worker Cloud Run service.
/// ═══════════════════════════════════════════════════════════════════════════

class BackgroundRemoverScreen extends StatefulWidget {
  const BackgroundRemoverScreen({super.key});

  @override
  State<BackgroundRemoverScreen> createState() =>
      _BackgroundRemoverScreenState();
}

class _BackgroundRemoverScreenState extends State<BackgroundRemoverScreen> {
  final _service = BackgroundRemovalService();
  final _picker = ImagePicker();

  Uint8List? _originalBytes;
  Uint8List? _resultBytes;
  String _filename = '';
  bool _processing = false;
  String? _error;

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 2048,
      maxHeight: 2048,
    );
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    setState(() {
      _originalBytes = bytes;
      _resultBytes = null;
      _filename = picked.name;
      _error = null;
    });
  }

  Future<void> _removeBackground() async {
    if (_originalBytes == null) return;
    setState(() {
      _processing = true;
      _error = null;
    });

    final result = await _service.removeBackground(
      imageBytes: _originalBytes!,
      filename: _filename,
    );

    if (!mounted) return;
    setState(() {
      _processing = false;
      _resultBytes = result;
      if (result == null) _error = 'Background removal failed. Check service.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgSecondary,
        title: const Text(
          'Background Remover',
          style: TextStyle(
            color: DesignTokens.neonCyan,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_library, color: DesignTokens.neonCyan),
            onPressed: _pickImage,
            tooltip: 'Pick Image',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Upload area
            if (_originalBytes == null) _buildUploadArea(),

            // Preview
            if (_originalBytes != null) ...[
              _buildPreviewRow(),
              const SizedBox(height: 16),

              // Process button
              SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _processing ? null : _removeBackground,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DesignTokens.neonCyan,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: _processing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : const Icon(Icons.auto_fix_high),
                  label: Text(
                    _processing ? 'Processing...' : 'Remove Background',
                  ),
                ),
              ),

              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: const TextStyle(
                    color: DesignTokens.neonRed,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],

              const SizedBox(height: 16),

              // Clear button
              TextButton.icon(
                onPressed: () => setState(() {
                  _originalBytes = null;
                  _resultBytes = null;
                  _error = null;
                }),
                icon: const Icon(Icons.clear, color: Colors.white54, size: 16),
                label: const Text(
                  'Clear',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
            ],

            // Usage hints
            const SizedBox(height: 32),
            _buildUsageHints(),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadArea() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 240,
        decoration: BoxDecoration(
          color: DesignTokens.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: DesignTokens.neonCyan.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_upload_outlined,
              size: 56,
              color: DesignTokens.neonCyan,
            ),
            SizedBox(height: 12),
            Text(
              'Tap to upload image',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            SizedBox(height: 4),
            Text(
              'JPEG, PNG, WebP · Up to 10 MB',
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewRow() {
    return Row(
      children: [
        Expanded(child: _buildPreviewCard('Original', _originalBytes!)),
        const SizedBox(width: 12),
        Expanded(
          child: _resultBytes != null
              ? _buildPreviewCard('Result', _resultBytes!)
              : Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: DesignTokens.bgCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: const Center(
                    child: Text(
                      'Result will\nappear here',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white24),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildPreviewCard(String label, Uint8List bytes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 200,
            decoration: const BoxDecoration(
              // Checkerboard pattern for transparency
              color: DesignTokens.bgCard,
            ),
            child: Image.memory(
              bytes,
              fit: BoxFit.contain,
              width: double.infinity,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUsageHints() {
    const hints = [
      ('🥊', 'Fighter Cutouts', 'Create clean fighter cutouts for posters'),
      ('🃏', 'Trading Cards', 'Remove backgrounds for collectible card art'),
      ('📰', 'Fight Posters', 'Isolate fighters for event poster composition'),
      ('🎬', 'Promo Graphics', 'Clean subject isolation for social media'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'USE CASES',
          style: TextStyle(
            color: Colors.white38,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        ...hints.map(
          (h) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Text(h.$1, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        h.$2,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        h.$3,
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
