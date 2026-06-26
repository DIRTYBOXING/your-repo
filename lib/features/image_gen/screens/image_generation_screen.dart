// lib/features/image_gen/screens/image_generation_screen.dart
//
// AI Image Studio — Text-to-Image & Image-to-Image generation
// Powered by OpenAI DALL-E + Google Gemini

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../../shared/widgets/dfc_network_image.dart';
// import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../shared/widgets/dfc_background.dart';
import '../../../shared/services/gemini_image_service.dart';
import '../services/image_generation_service.dart';

enum _AiEngine { openai, gemini }

class ImageGenerationScreen extends StatefulWidget {
  const ImageGenerationScreen({super.key});

  @override
  State<ImageGenerationScreen> createState() => _ImageGenerationScreenState();
}

class _ImageGenerationScreenState extends State<ImageGenerationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ImageGenerationService _service;
  final GeminiImageService _gemini = GeminiImageService();

  // ── Engine selector ───────────────────────────────────────────────────
  _AiEngine _engine = _AiEngine.gemini;
  GeminiImageModel _geminiModel = GeminiImageModel.flash;

  // ── Shared state ──────────────────────────────────────────────────────
  final _promptController = TextEditingController();
  ImageSize _selectedSize = ImageSize.square;
  ImageGenResult? _result;
  Uint8List? _geminiResultBytes; // Gemini returns raw bytes
  String? _geminiResultError;
  bool _isLoading = false;

  // ── Text-to-Image options ─────────────────────────────────────────────
  ImageStyle _selectedStyle = ImageStyle.vivid;
  ImageQuality _selectedQuality = ImageQuality.standard;

  // ── Image-to-Image state ──────────────────────────────────────────────
  Uint8List? _sourceImageBytes;

  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _service = ImageGenerationService();
    _service.addListener(_onServiceUpdate);
    _gemini.addListener(_onGeminiUpdate);
  }

  void _onServiceUpdate() {
    if (!mounted) return;
    setState(() {
      _isLoading = _service.isLoading;
      _result = _service.lastResult;
    });
  }

  void _onGeminiUpdate() {
    if (!mounted) return;
    setState(() {
      _isLoading = _gemini.busy;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _promptController.dispose();
    _service.removeListener(_onServiceUpdate);
    _service.dispose();
    _gemini.removeListener(_onGeminiUpdate);
    _gemini.dispose();
    super.dispose();
  }

  // ── Actions ──────────────────────────────────────────────────────────

  Future<void> _generateText2Image() async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) {
      _showSnack('Please enter a prompt first');
      return;
    }

    // Clear previous results
    setState(() {
      _result = null;
      _geminiResultBytes = null;
      _geminiResultError = null;
    });

    if (_engine == _AiEngine.gemini) {
      final gemAspect = _selectedSize == ImageSize.portrait
          ? GeminiAspectRatio.portrait
          : _selectedSize == ImageSize.landscape
          ? GeminiAspectRatio.landscape
          : GeminiAspectRatio.square;
      final res = await _gemini.generateFromText(
        prompt: prompt,
        model: _geminiModel,
        aspect: gemAspect,
      );
      if (!mounted) return;
      setState(() {
        _geminiResultBytes = res.imageBytes;
        _geminiResultError = res.error;
      });
    } else {
      await _service.generateFromText(
        prompt: prompt,
        size: _selectedSize,
        style: _selectedStyle,
        quality: _selectedQuality,
      );
    }
  }

  Future<void> _generateImage2Image() async {
    if (_sourceImageBytes == null) {
      _showSnack('Please select a source image first');
      return;
    }
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) {
      _showSnack('Please describe the transformation');
      return;
    }

    // Clear previous results
    setState(() {
      _result = null;
      _geminiResultBytes = null;
      _geminiResultError = null;
    });

    if (_engine == _AiEngine.gemini) {
      final res = await _gemini.generateFromImage(
        imageBytes: _sourceImageBytes!,
        prompt: prompt,
      );
      if (!mounted) return;
      setState(() {
        _geminiResultBytes = res.imageBytes;
        _geminiResultError = res.error;
      });
    } else {
      await _service.generateFromImage(
        imageBytes: _sourceImageBytes!,
        prompt: prompt,
        size: _selectedSize,
      );
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final xFile = await _picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
    );
    if (xFile == null) return;
    final bytes = await xFile.readAsBytes();
    setState(() {
      _sourceImageBytes = bytes;
      _result = null;
    });
  }

  // Sharing functionality disabled for web build

  Future<void> _shareResult() async {
    final url = _result?.imageUrl;
    if (url == null) return;
    // Sharing functionality disabled for web build
    _showSnack('Sharing is not available on web.');
  }

  Future<void> _copyUrl() async {
    final url = _result?.imageUrl;
    if (url == null) return;
    await Clipboard.setData(ClipboardData(text: url));
    _showSnack('URL copied to clipboard');
  }

  Future<void> _downloadImage() async {
    final url = _result?.imageUrl;
    if (url == null) return;
    // Download functionality disabled for web build
    _showSnack('Download is not available on web.');
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.elevated,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
        ),
      ),
    );
  }

  void _clearAll() {
    _promptController.clear();
    _sourceImageBytes = null;
    _service.clearResult();
    setState(() => _result = null);
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return DFCBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: _buildAppBar(),
        body: Column(
          children: [
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [_buildText2ImageTab(), _buildImage2ImageTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: ShaderMask(
        shaderCallback: (bounds) =>
            AppColors.primaryGradient.createShader(bounds),
        child: const Text(
          'AI IMAGE STUDIO',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
            letterSpacing: 2,
          ),
        ),
      ),
      actions: [
        if (_result != null || _sourceImageBytes != null)
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white60),
            onPressed: _clearAll,
            tooltip: 'Clear all',
          ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.elevated.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        border: Border.all(
          color: Colors.white.withValues(
            alpha: DesignTokens.glassBorderOpacity,
          ),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.black,
        unselectedLabelColor: Colors.white54,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          letterSpacing: 0.5,
        ),
        tabs: const [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.text_fields, size: 16),
                SizedBox(width: 6),
                Text('Text → Image'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.image, size: 16),
                SizedBox(width: 6),
                Text('Image → Image'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab 1: Text-to-Image ───────────────────────────────────────────────

  Widget _buildText2ImageTab() {
    final promptSuggestions = [
      'A fighter in neon armor, cyberpunk city, epic lighting',
      'A samurai meditating under cherry blossoms, watercolor style',
      'A boxing ring floating in space, surreal, vibrant colors',
      'A martial artist training with a robot, futuristic gym',
      'A champion holding a glowing trophy, cinematic, dramatic',
      'A crowd cheering in a stadium, confetti, celebration',
      'A fighter and coach strategizing, comic book style',
      'A wild knockout moment, freeze-frame, neon effects',
      'A fighter with AI-generated tattoos, hyperrealistic',
      'A playful mascot in DFC gear, cartoon, fun',
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEngineSelector(),
          const SizedBox(height: 16),
          _buildSectionLabel('DESCRIBE YOUR IMAGE'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildPromptField(
                  hint:
                      'e.g. A fighter shadowboxing in a neon-lit dojo at midnight, cinematic lighting…',
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.neonMagenta,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(Icons.casino, size: 18),
                label: const Text(
                  'Surprise Me',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  final suggestion = (promptSuggestions..shuffle()).first;
                  _promptController.text = suggestion;
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: promptSuggestions
                .take(4)
                .map(
                  (s) => GestureDetector(
                    onTap: () => _promptController.text = s,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.neonCyan.withValues(alpha: 0.13),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.neonCyan.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Text(
                        s,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 20),
          // Options row — varies by engine
          if (_engine == _AiEngine.openai)
            Row(
              children: [
                Expanded(
                  child: _buildOptionSelector<ImageStyle>(
                    label: 'STYLE',
                    icon: Icons.palette_outlined,
                    value: _selectedStyle,
                    items: ImageStyle.values,
                    itemLabel: (s) => s.label,
                    onChanged: (s) => setState(() => _selectedStyle = s),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildOptionSelector<ImageQuality>(
                    label: 'QUALITY',
                    icon: Icons.hd_outlined,
                    value: _selectedQuality,
                    items: ImageQuality.values,
                    itemLabel: (q) => q.label,
                    onChanged: (q) => setState(() => _selectedQuality = q),
                  ),
                ),
              ],
            )
          else
            _buildOptionSelector<GeminiImageModel>(
              label: 'MODEL',
              icon: Icons.memory,
              value: _geminiModel,
              items: GeminiImageModel.values,
              itemLabel: (m) => m.label,
              onChanged: (m) => setState(() => _geminiModel = m),
            ),
          const SizedBox(height: 12),
          _buildSizeSelector(),
          const SizedBox(height: 24),
          _buildGenerateButton(
            onPressed: _isLoading ? null : _generateText2Image,
            label: 'GENERATE IMAGE',
            icon: Icons.auto_awesome,
          ),
          if (_isLoading) _buildLoadingSection(),
          if (_geminiResultError != null)
            _buildErrorSection(_geminiResultError!),
          if (_geminiResultBytes != null) _buildGeminiResultSection(),
          if (_result != null) _buildResultSection(),
        ],
      ),
    );
  }

  // ── Tab 2: Image-to-Image ──────────────────────────────────────────────

  Widget _buildImage2ImageTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEngineSelector(),
          const SizedBox(height: 16),
          _buildSectionLabel('SOURCE IMAGE'),
          const SizedBox(height: 8),
          _buildImagePicker(),
          const SizedBox(height: 20),

          _buildSectionLabel('TRANSFORMATION PROMPT'),
          const SizedBox(height: 8),
          _buildPromptField(
            hint:
                'e.g. Transform into anime style, dramatic lighting, ultra-detailed…',
          ),
          const SizedBox(height: 20),

          _buildSizeSelector(),
          const SizedBox(height: 24),

          _buildGenerateButton(
            onPressed: _isLoading ? null : _generateImage2Image,
            label: 'TRANSFORM IMAGE',
            icon: Icons.auto_fix_high,
          ),

          const SizedBox(height: 12),
          _buildImg2ImgNote(),

          if (_isLoading) _buildLoadingSection(),
          if (_geminiResultError != null)
            _buildErrorSection(_geminiResultError!),
          if (_geminiResultBytes != null) _buildGeminiResultSection(),
          if (_result != null) _buildResultSection(),
        ],
      ),
    );
  }

  // ── Shared Widgets ────────────────────────────────────────────────────

  Widget _buildEngineSelector() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.elevated.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
        border: Border.all(color: AppColors.neonCyan.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.memory, color: AppColors.neonCyan, size: 14),
          const SizedBox(width: 6),
          const Text(
            'ENGINE',
            style: TextStyle(
              color: AppColors.neonCyan,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(width: 12),
          _engineChip(
            label: 'Gemini',
            icon: Icons.auto_awesome,
            selected: _engine == _AiEngine.gemini,
            color: const Color(0xFF4285F4),
            onTap: () => setState(() => _engine = _AiEngine.gemini),
          ),
          const SizedBox(width: 8),
          _engineChip(
            label: 'DALL-E',
            icon: Icons.brush,
            selected: _engine == _AiEngine.openai,
            color: AppColors.neonGreen,
            onTap: () => setState(() => _engine = _AiEngine.openai),
          ),
        ],
      ),
    );
  }

  Widget _engineChip({
    required String label,
    required IconData icon,
    required bool selected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: selected
              ? LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.25),
                    color.withValues(alpha: 0.1),
                  ],
                )
              : null,
          color: selected ? null : AppColors.surface.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : Colors.white.withValues(alpha: 0.1),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: selected ? color : Colors.white38),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: selected ? color : Colors.white38,
                fontSize: 11,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeminiResultSection() {
    final bytes = _geminiResultBytes!;
    return Padding(
      padding: const EdgeInsets.only(top: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.check_circle,
                color: AppColors.neonGreen,
                size: 16,
              ),
              const SizedBox(width: 6),
              _buildSectionLabel('GENERATED IMAGE'),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF4285F4).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF4285F4).withValues(alpha: 0.4),
                  ),
                ),
                child: const Text(
                  'GEMINI',
                  style: TextStyle(
                    color: Color(0xFF4285F4),
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppColors.neonCyan.withValues(alpha: 0.3),
                ),
                borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.neonCyan.withValues(alpha: 0.15),
                    blurRadius: 30,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
                child: Image.memory(bytes, fit: BoxFit.contain),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.elevated.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.format_quote, color: Colors.white30, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _promptController.text.trim(),
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _actionButton(
                  icon: Icons.share_outlined,
                  label: 'Share',
                  onTap: () async {
                    // Sharing disabled on web
                    _showSnack('Sharing is not available on web.');
                  },
                  color: AppColors.neonBlue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _actionButton(
                  icon: Icons.copy,
                  label: 'Copy',
                  onTap: () async {
                    await Clipboard.setData(
                      ClipboardData(
                        text:
                            '[Gemini generated image — ${bytes.length} bytes]',
                      ),
                    );
                    _showSnack('Image info copied');
                  },
                  color: AppColors.neonMagenta,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.neonCyan,
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildPromptField({required String hint}) {
    return Container(
      decoration: GlassDecoration.card(
        accent: AppColors.neonCyan,
      ),
      child: TextField(
        controller: _promptController,
        maxLines: 3,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.3),
            fontSize: 13,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
          suffixIcon: IconButton(
            icon: const Icon(Icons.clear, color: Colors.white38, size: 18),
            onPressed: _promptController.clear,
          ),
        ),
      ),
    );
  }

  Widget _buildOptionSelector<T>({
    required String label,
    required IconData icon,
    required T value,
    required List<T> items,
    required String Function(T) itemLabel,
    required ValueChanged<T> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: GlassDecoration.card(accent: AppColors.neonMagenta),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.neonMagenta, size: 14),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.neonMagenta,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isDense: true,
              isExpanded: true,
              dropdownColor: AppColors.elevated,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              icon: const Icon(
                Icons.keyboard_arrow_down,
                color: Colors.white38,
                size: 16,
              ),
              items: items
                  .map(
                    (item) => DropdownMenuItem<T>(
                      value: item,
                      child: Text(itemLabel(item)),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSizeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('SIZE / ASPECT RATIO'),
        const SizedBox(height: 8),
        Row(
          children: ImageSize.values.map((size) {
            final selected = _selectedSize == size;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedSize = size),
                child: Container(
                  margin: EdgeInsets.only(
                    right: size != ImageSize.values.last ? 8 : 0,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    gradient: selected ? AppColors.primaryGradient : null,
                    color: selected
                        ? null
                        : AppColors.elevated.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(
                      DesignTokens.radiusSmall,
                    ),
                    border: Border.all(
                      color: selected
                          ? Colors.transparent
                          : Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _sizeIcon(size),
                        color: selected ? Colors.black : Colors.white60,
                        size: 18,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        size.label,
                        style: TextStyle(
                          color: selected ? Colors.black : Colors.white60,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  IconData _sizeIcon(ImageSize size) {
    switch (size) {
      case ImageSize.square:
        return Icons.crop_square;
      case ImageSize.portrait:
        return Icons.crop_portrait;
      case ImageSize.landscape:
        return Icons.crop_landscape;
    }
  }

  Widget _buildImagePicker() {
    return Container(
      height: 180,
      decoration: GlassDecoration.card(
        accent: AppColors.neonGreen,
      ),
      child: _sourceImageBytes != null
          ? Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(
                    DesignTokens.radiusMedium,
                  ),
                  child: Image.memory(_sourceImageBytes!, fit: BoxFit.cover),
                ),
                // Overlay with change option
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Row(
                    children: [
                      _pickerChip(
                        icon: Icons.photo_library_outlined,
                        label: 'Change',
                        onTap: () => _pickImage(ImageSource.gallery),
                      ),
                      const SizedBox(width: 6),
                      _pickerChip(
                        icon: Icons.delete_outline,
                        label: 'Remove',
                        onTap: () => setState(() {
                          _sourceImageBytes = null;
                        }),
                        color: AppColors.neonRed,
                      ),
                    ],
                  ),
                ),
              ],
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.add_photo_alternate_outlined,
                  color: AppColors.neonGreen,
                  size: 40,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Select Source Image',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'This image will be transformed by AI',
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _pickerChip(
                      icon: Icons.photo_library_outlined,
                      label: 'Gallery',
                      onTap: () => _pickImage(ImageSource.gallery),
                    ),
                    const SizedBox(width: 12),
                    _pickerChip(
                      icon: Icons.camera_alt_outlined,
                      label: 'Camera',
                      onTap: () => _pickImage(ImageSource.camera),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _pickerChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = AppColors.neonGreen,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenerateButton({
    required VoidCallback? onPressed,
    required String label,
    required IconData icon,
  }) {
    return SizedBox(
      width: double.infinity,
      height: DesignTokens.buttonHeightLarge + 4,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: onPressed != null ? AppColors.primaryGradient : null,
          color: onPressed == null ? AppColors.elevated : null,
          borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
          boxShadow: onPressed != null
              ? [
                  BoxShadow(
                    color: AppColors.neonCyan.withValues(alpha: 0.3),
                    blurRadius: 20,
                  ),
                ]
              : null,
        ),
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 20),
          label: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              fontSize: 14,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: onPressed != null ? Colors.black : Colors.white38,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingSection() {
    return Padding(
      padding: const EdgeInsets.only(top: 32),
      child: Column(
        children: [
          ShaderMask(
            shaderCallback: (bounds) =>
                AppColors.primaryGradient.createShader(bounds),
            child: const SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation(Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _service.statusMessage ?? 'Working on it…',
            style: const TextStyle(color: Colors.white60, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildResultSection() {
    final result = _result!;
    if (!result.success) {
      return _buildErrorSection(result.error ?? 'Unknown error');
    }
    if (result.imageUrl == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.check_circle,
                color: AppColors.neonGreen,
                size: 16,
              ),
              const SizedBox(width: 6),
              _buildSectionLabel('GENERATED IMAGE'),
            ],
          ),
          const SizedBox(height: 12),

          // Image display
          ClipRRect(
            borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppColors.neonCyan.withValues(alpha: 0.3),
                ),
                borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.neonCyan.withValues(alpha: 0.15),
                    blurRadius: 30,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
                child: DfcNetworkImage(
                  url: result.imageUrl!,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          // Prompt used
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.elevated.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.format_quote, color: Colors.white30, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    result.prompt,
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: _actionButton(
                  icon: Icons.download,
                  label: 'Save',
                  onTap: _downloadImage,
                  color: AppColors.neonGreen,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _actionButton(
                  icon: Icons.share_outlined,
                  label: 'Share',
                  onTap: _shareResult,
                  color: AppColors.neonBlue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _actionButton(
                  icon: Icons.link,
                  label: 'Copy URL',
                  onTap: _copyUrl,
                  color: AppColors.neonMagenta,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorSection(String error) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.neonRed.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
          border: Border.all(color: AppColors.neonRed.withValues(alpha: 0.3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline, color: AppColors.neonRed, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Generation Failed',
                    style: TextStyle(
                      color: AppColors.neonRed,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    error,
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImg2ImgNote() {
    final isGemini = _engine == _AiEngine.gemini;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.neonAmber.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
        border: Border.all(color: AppColors.neonAmber.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.neonAmber, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isGemini
                  ? 'Image-to-Image uses Gemini Flash. Upload any image and describe the transformation.'
                  : 'Image-to-Image uses DALL-E 2. For best results, use a clear PNG image under 4MB.',
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}
