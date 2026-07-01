import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../services/octane_service.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// CREATIVE HUB
/// DFC Octane Promo Video Editor & Image Selection.
/// ═══════════════════════════════════════════════════════════════════════════
class CreativeHubScreen extends StatefulWidget {
  const CreativeHubScreen({super.key});

  @override
  State<CreativeHubScreen> createState() => _CreativeHubScreenState();
}

class _CreativeHubScreenState extends State<CreativeHubScreen> {
  final OctaneService _octaneService = OctaneService();
  final ImagePicker _picker = ImagePicker();

  final List<File> _selectedImages = [];
  String _selectedTheme = 'Neon Underground';
  bool _isRendering = false;
  String? _finalVideoUrl;

  final List<String> _themes = [
    'Neon Underground',
    'Samurai Spirit',
    'Inferno',
    'Blizzard',
    'Warzone',
  ];

  Future<void> _pickImage() async {
    if (_selectedImages.length >= 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 6 images allowed.')),
      );
      return;
    }

    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _selectedImages.add(File(image.path)));
    }
  }

  Future<void> _triggerRender() async {
    if (_selectedImages.isEmpty) return;

    setState(() => _isRendering = true);

    final url = await _octaneService.generatePromoVideo(
      eventId:
          'evt_${DateTime.now().millisecondsSinceEpoch}', // Mock Event ID for demo
      images: _selectedImages,
      theme: _selectedTheme.toLowerCase().replaceAll(' ', '_'),
    );

    if (mounted) {
      setState(() {
        _isRendering = false;
        _finalVideoUrl = url;
      });

      if (url != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Render job successfully queued via Octane Engine!'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.panel,
        title: const Text(
          'DFC CREATIVE HUB',
          style: TextStyle(
            color: AppColors.neonCyan,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'OCTANE PROMO BUILDER',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Upload up to 6 raw images. The DFC Octane Engine will stitch them into a cinematic 15-second promo.',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 24),

          // ── IMAGE SELECTOR GRID ──
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: 6,
            itemBuilder: (context, index) {
              if (index < _selectedImages.length) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(_selectedImages[index], fit: BoxFit.cover),
                );
              } else if (index == _selectedImages.length) {
                return GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.neonCyan.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.neonCyan.withValues(alpha: 0.4),
                      ),
                    ),
                    child: const Icon(
                      Icons.add_a_photo,
                      color: AppColors.neonCyan,
                    ),
                  ),
                );
              } else {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                );
              }
            },
          ),
          const SizedBox(height: 32),

          // ── THEME SELECTOR ──
          const Text(
            'SELECT CINEMATIC THEME',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _themes
                .map(
                  (theme) => ChoiceChip(
                    label: Text(
                      theme,
                      style: TextStyle(
                        color: _selectedTheme == theme
                            ? Colors.black
                            : Colors.white,
                      ),
                    ),
                    selected: _selectedTheme == theme,
                    selectedColor: AppColors.neonCyan,
                    backgroundColor: AppColors.panel,
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedTheme = theme);
                    },
                  ),
                )
                .toList(),
          ),

          const SizedBox(height: 48),
          SizedBox(
            height: 56,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.neonMagenta,
                foregroundColor: Colors.white,
              ),
              onPressed: _isRendering || _selectedImages.isEmpty
                  ? null
                  : _triggerRender,
              icon: _isRendering
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Icon(Icons.movie_creation),
              label: const Text(
                'RENDER PROMO (OCTANE)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
