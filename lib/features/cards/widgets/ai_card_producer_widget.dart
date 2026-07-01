import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:datafightcentral/shared/services/gemini_image_service.dart';
import '../../../shared/widgets/dfc_network_image.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  AI CARD PRODUCER & POSTER BOY WIDGET
//  Generates fight cards, poster art, and promotional images using AI.
//  Neon-themed dark UI consistent with the DFC design system.
// ─────────────────────────────────────────────────────────────────────────────

class AiCardProducerWidget extends StatefulWidget {
  final String apiKey;
  final String defaultPrompt;
  const AiCardProducerWidget({
    required this.apiKey,
    this.defaultPrompt =
        'A futuristic fight poster boy, neon cyan and purple lighting, combat sports, dramatic pose',
    super.key,
  });

  @override
  State<AiCardProducerWidget> createState() => _AiCardProducerWidgetState();
}

class _AiCardProducerWidgetState extends State<AiCardProducerWidget> {
  // ── Theme colours ─────────────────────────────────────────────────────────
  static const _bg = Color(0xFF0A0E1A);
  static const _card = Color(0xFF111827);
  static const _cyan = Color(0xFF00E5FF);
  static const _green = Color(0xFF00E676);
  static const _amber = Color(0xFFFFAB00);
  static const _red = Color(0xFFFF1744);
  static const _purple = Color(0xFF9D00FF);

  String? _imageUrl;
  Uint8List? _imageBytes;
  String? _errorMessage;
  bool _loading = false;
  String _selectedSize = '512x512';
  String _selectedStyle = 'Poster Boy';
  final TextEditingController _promptController = TextEditingController();

  final _sizes = ['256x256', '512x512', '1024x1024'];
  final _styles = [
    'Poster Boy',
    'Fight Card',
    'Event Flyer',
    'Champion Belt',
    'Training Montage',
    'Custom',
  ];

  final _stylePrompts = {
    'Poster Boy':
        'dramatic fighter poster, neon lighting, combat sports hero, cinematic',
    'Fight Card':
        'professional fight card layout, versus screen, two fighters facing off, neon accents',
    'Event Flyer':
        'combat sports event flyer, bold typography, arena lights, crowd silhouette',
    'Champion Belt':
        'championship belt close-up, gold and neon glow, victory celebration',
    'Training Montage':
        'fighter training montage, gym atmosphere, sweat and determination, dramatic lighting',
    'Custom': '',
  };

  @override
  void initState() {
    super.initState();
    _promptController.text = widget.defaultPrompt;
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _generateImage() async {
    if (_promptController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Please enter a prompt.');
      return;
    }
    setState(() {
      _loading = true;
      _errorMessage = null;
      _imageUrl = null;
      _imageBytes = null;
    });
    try {
      final gemini = GeminiImageService();
      if (gemini.isConfigured) {
        // Use Gemini for image generation
        final result = await gemini.generateFromText(
          prompt: _promptController.text.trim(),
        );
        if (result.success && result.hasImage) {
          setState(() {
            _imageBytes = result.imageBytes;
            _loading = false;
          });
          return;
        }
        setState(() {
          _errorMessage = result.error ?? 'Generation returned no image';
          _loading = false;
        });
      } else {
        setState(() {
          _errorMessage =
              'Add GEMINI_API_KEY via --dart-define to enable AI generation.';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Generation failed: $e';
        _loading = false;
      });
    }
  }

  void _applyStyle(String style) {
    setState(() {
      _selectedStyle = style;
      final base = _stylePrompts[style] ?? '';
      if (base.isNotEmpty) {
        _promptController.text = base;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cyan.withAlpha(40)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_cyan.withAlpha(20), _purple.withAlpha(15)],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, color: _cyan, size: 18),
                const SizedBox(width: 8),
                const Text(
                  'AI CARD PRODUCER',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _green.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _green.withAlpha(60)),
                  ),
                  child: const Text(
                    'POWERED BY AI',
                    style: TextStyle(
                      color: _green,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Style Selector ─────────────────────────────────────────
                const Text(
                  'STYLE',
                  style: TextStyle(
                    color: _cyan,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _styles.map(_styleChip).toList(),
                ),
                const SizedBox(height: 14),

                // ── Prompt Input ───────────────────────────────────────────
                const Text(
                  'PROMPT',
                  style: TextStyle(
                    color: _cyan,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _promptController,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  decoration: InputDecoration(
                    hintText: 'Describe your fight card or poster...',
                    hintStyle: TextStyle(
                      color: Colors.white.withAlpha(60),
                      fontSize: 11,
                    ),
                    filled: true,
                    fillColor: _bg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: _cyan.withAlpha(40)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: _cyan.withAlpha(30)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: _cyan, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // ── Size Selector ──────────────────────────────────────────
                Row(
                  children: [
                    const Text(
                      'SIZE',
                      style: TextStyle(
                        color: _cyan,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(width: 12),
                    ..._sizes.map(
                      (s) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(
                            s,
                            style: TextStyle(
                              color: _selectedSize == s ? _bg : Colors.white54,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          selected: _selectedSize == s,
                          selectedColor: _cyan,
                          backgroundColor: _bg,
                          side: BorderSide(color: _cyan.withAlpha(40)),
                          onSelected: (_) => setState(() => _selectedSize = s),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // ── Generate Button ────────────────────────────────────────
                SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _generateImage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _cyan,
                      foregroundColor: _bg,
                      disabledBackgroundColor: _cyan.withAlpha(60),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: _bg,
                            ),
                          )
                        : const Text(
                            'GENERATE IMAGE',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),
                  ),
                ),

                // ── Error Message ──────────────────────────────────────────
                if (_errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: _red,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                const SizedBox(height: 14),

                // ── Generated Image Preview ────────────────────────────────
                if (_imageBytes != null || _imageUrl != null) ...[
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _cyan.withAlpha(50)),
                      boxShadow: [
                        BoxShadow(color: _cyan.withAlpha(20), blurRadius: 20),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _imageBytes != null
                          ? Image.memory(
                              _imageBytes!,
                              height: 300,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => const SizedBox(
                                height: 300,
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.broken_image,
                                        color: _red,
                                        size: 40,
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Failed to decode image',
                                        style: TextStyle(
                                          color: _red,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          : DfcNetworkImage(
                              url: _imageUrl!,
                              height: 300,
                              width: double.infinity,
                            ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _actionBtn(Icons.download, 'Save', _green),
                      const SizedBox(width: 12),
                      _actionBtn(Icons.share, 'Share', _cyan),
                      const SizedBox(width: 12),
                      _actionBtn(Icons.refresh, 'Regenerate', _amber),
                    ],
                  ),
                ] else ...[
                  // Placeholder
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: _bg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withAlpha(15)),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.image_outlined,
                            color: Colors.white.withAlpha(40),
                            size: 48,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your AI-generated image will appear here',
                            style: TextStyle(
                              color: Colors.white.withAlpha(60),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _styleChip(String style) {
    final selected = _selectedStyle == style;
    return GestureDetector(
      onTap: () => _applyStyle(style),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? _cyan.withAlpha(30) : _bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? _cyan : Colors.white.withAlpha(20),
          ),
        ),
        child: Text(
          style,
          style: TextStyle(
            color: selected ? _cyan : Colors.white54,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _actionBtn(IconData icon, String label, Color col) {
    return Column(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: col.withAlpha(20),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: col.withAlpha(50)),
          ),
          child: Icon(icon, color: col, size: 18),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: col,
            fontSize: 8,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
