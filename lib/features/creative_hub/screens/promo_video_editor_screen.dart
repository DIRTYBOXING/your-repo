import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:web/web.dart' as web;

/// ═══════════════════════════════════════════════════════════════════════════
/// DFC PROMO VIDEO EDITOR — "Octane Engine"
/// Upload 6 photos → 15/20 sec promotional fight video
/// Ken Burns · Flash Cuts · Action Zoom · Neon Overlays
/// Built for DFC — No external tools. All in one room.
/// ═══════════════════════════════════════════════════════════════════════════

// ── DFC Brand Palette ────────────────────────────────────────────────────
const _kBg = Color(0xFF030810);
const _kPanel = Color(0xFF0D1B2A);
const _kCyan = Color(0xFF00F5FF);
const _kMagenta = Color(0xFFFF0080);
const _kGold = Color(0xFFFFD700);
const _kGreen = Color(0xFF00E676);
const _kRed = Color(0xFFFF5252);
const _kBlue = Color(0xFF2979FF);
const _kWhite = Colors.white;
const _kGrey = Color(0xFF8892A4);

/// Transition styles for the promo video
enum PromoTransition {
  flashCut('Flash Cut', 'Hard cuts with flash — action packed', Icons.flash_on),
  kenBurns('Ken Burns', 'Slow zoom & pan — cinematic', Icons.zoom_in),
  slideBlast('Slide Blast', 'Fast directional slides', Icons.swap_horiz),
  zoomPunch(
    'Zoom Punch',
    'Explosive zoom transitions',
    Icons.center_focus_strong,
  ),
  fadeSmoke('Fade Smoke', 'Smooth fades — dramatic', Icons.blur_on),
  glitchWar('Glitch War', 'Digital glitch — underground', Icons.warning_amber);

  final String label;
  final String desc;
  final IconData icon;
  const PromoTransition(this.label, this.desc, this.icon);
}

/// Video theme presets
enum PromoTheme {
  fightNight('Fight Night', 'Red & black — PPV energy', _kRed, [
    'FIGHT NIGHT',
    'LIVE ON PPV',
    'DON\'T MISS IT',
  ]),
  championship('Championship', 'Gold & black — title fight', _kGold, [
    'WORLD CHAMPIONSHIP',
    'TITLE ON THE LINE',
    'HISTORY WILL BE MADE',
  ]),
  underground('Underground', 'Neon cyan — street vibes', _kCyan, [
    'UNDERGROUND',
    'RAW & UNCUT',
    'NO RULES',
  ]),
  neonWar('Neon War', 'Magenta blaze — DFC style', _kMagenta, [
    'WAR IS COMING',
    'TOTAL WAR',
    'THERE CAN BE ONLY ONE',
  ]),
  iceBlue('Ice Blue', 'Cool blue — technical', _kBlue, [
    'PRECISION',
    'CALCULATED',
    'DOMINANCE',
  ]),
  greenMachine('Green Machine', 'Money green — prize fight', _kGreen, [
    'BIG MONEY',
    'PRIZE FIGHT',
    'WINNER TAKES ALL',
  ]);

  final String label;
  final String desc;
  final Color accent;
  final List<String> defaultTexts;
  const PromoTheme(this.label, this.desc, this.accent, this.defaultTexts);
}

class PromoVideoEditorScreen extends StatefulWidget {
  const PromoVideoEditorScreen({super.key});
  @override
  State<PromoVideoEditorScreen> createState() => _PromoVideoEditorScreenState();
}

class _PromoVideoEditorScreenState extends State<PromoVideoEditorScreen>
    with TickerProviderStateMixin {
  // ── Image slots (6 max) ─────────────────────────────────────────────
  final List<_ImageSlot> _slots = List.generate(6, (_) => _ImageSlot());

  // ── Settings ────────────────────────────────────────────────────────
  int _durationSecs = 15;
  PromoTransition _transition = PromoTransition.flashCut;
  PromoTheme _theme = PromoTheme.fightNight;

  // ── Text overlays ──────────────────────────────────────────────────
  final _headlineCtrl = TextEditingController(text: 'FIGHT NIGHT');
  final _sublineCtrl = TextEditingController(text: 'LIVE ON DFC');
  final _dateCtrl = TextEditingController(text: 'MARCH 15, 2026');
  final _venueCtrl = TextEditingController(text: '');
  final _ctaCtrl = TextEditingController(text: 'WATCH NOW ON DFC');

  // ── Preview animation ──────────────────────────────────────────────
  late AnimationController _previewCtrl;
  bool _isPreviewing = false;
  bool _isExporting = false;
  double _exportProgress = 0.0;
  int _currentSlide = 0;

  // ── Canvas export state ────────────────────────────────────────────
  web.HTMLCanvasElement? _exportCanvas;
  web.CanvasRenderingContext2D? _exportCtx;

  @override
  void initState() {
    super.initState();
    _previewCtrl =
        AnimationController(
            vsync: this,
            duration: Duration(seconds: _durationSecs),
          )
          ..addListener(_onPreviewTick)
          ..addStatusListener(_onPreviewStatusChanged);
  }

  void _onPreviewStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed && _isPreviewing) {
      setState(() => _isPreviewing = false);
    }
  }

  @override
  void dispose() {
    _previewCtrl.dispose();
    _headlineCtrl.dispose();
    _sublineCtrl.dispose();
    _dateCtrl.dispose();
    _venueCtrl.dispose();
    _ctaCtrl.dispose();
    super.dispose();
  }

  void _onPreviewTick() {
    final totalSlots = _loadedSlotCount;
    if (totalSlots == 0) return;
    final perSlide = 1.0 / totalSlots;
    final newSlide = (_previewCtrl.value / perSlide).floor().clamp(
      0,
      totalSlots - 1,
    );
    if (newSlide != _currentSlide) {
      setState(() => _currentSlide = newSlide);
    }
  }

  int get _loadedSlotCount => _slots.where((s) => s.bytes != null).length;

  List<_ImageSlot> get _loadedSlots =>
      _slots.where((s) => s.bytes != null).toList();

  // ═══════════════════════════════════════════════════════════════════════════
  // IMAGE PICKING (web file picker)
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _pickImage(int index) async {
    final input = web.HTMLInputElement()
      ..type = 'file'
      ..accept = 'image/*';
    input.click();

    await input.onChange.first;
    final files = input.files;
    if (files == null || files.length == 0) return;
    final file = files.item(0)!;
    final reader = web.FileReader();
    reader.readAsArrayBuffer(file);
    await reader.onLoadEnd.first;
    final result = reader.result;
    if (result == null) return;
    final jsBuffer = result as JSArrayBuffer;
    final bytes = jsBuffer.toDart.asUint8List();
    // Also create an object URL for canvas export
    final blob = web.Blob([bytes.toJS].toJS);
    final objUrl = web.URL.createObjectURL(blob);
    setState(() {
      _slots[index] = _ImageSlot(
        bytes: bytes,
        name: file.name,
        objectUrl: objUrl,
      );
    });
  }

  void _removeImage(int index) {
    if (_slots[index].objectUrl != null) {
      web.URL.revokeObjectURL(_slots[index].objectUrl!);
    }
    setState(() => _slots[index] = _ImageSlot());
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PREVIEW
  // ═══════════════════════════════════════════════════════════════════════════

  void _togglePreview() {
    if (_loadedSlotCount < 2) {
      _showSnack('Upload at least 2 images to preview', _kRed);
      return;
    }
    setState(() {
      _isPreviewing = !_isPreviewing;
      if (_isPreviewing) {
        _previewCtrl.duration = Duration(seconds: _durationSecs);
        _currentSlide = 0;
        _previewCtrl.forward(from: 0);
      } else {
        _previewCtrl.stop();
        _previewCtrl.reset();
      }
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // EXPORT — Canvas + MediaRecorder → WebM
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _exportVideo() async {
    if (_loadedSlotCount < 2) {
      _showSnack('Upload at least 2 images to export', _kRed);
      return;
    }
    setState(() {
      _isExporting = true;
      _exportProgress = 0;
    });

    try {
      const width = 1080;
      const height = 1920;
      _exportCanvas = web.HTMLCanvasElement()
        ..width = width
        ..height = height;
      _exportCtx =
          _exportCanvas!.getContext('2d')! as web.CanvasRenderingContext2D;

      // Load all images as HTMLImageElement
      final images = <web.HTMLImageElement>[];
      for (final slot in _loadedSlots) {
        final img = web.HTMLImageElement()..src = slot.objectUrl!;
        final c = Completer<void>();
        img.onLoad.first.then((_) => c.complete());
        await c.future;
        images.add(img);
      }

      // Use JS interop for captureStream + MediaRecorder (not in package:web typings)
      final canvasJs = _exportCanvas! as JSObject;
      final stream = canvasJs.callMethod<JSObject>(
        'captureStream'.toJS,
        30.toJS,
      );

      // Create MediaRecorder via eval (not in package:web bindings)
      final recorderFn = globalContext.callMethod<JSFunction>(
        'eval'.toJS,
        '(function(s,o){ return new MediaRecorder(s,o); })'.toJS,
      );
      final options = {
        'mimeType': 'video/webm;codecs=vp9',
        'videoBitsPerSecond': 5000000,
      }.jsify()!;
      final recorderObj =
          recorderFn.callAsFunction(null, stream, options)! as JSObject;

      final chunks = <JSAny>[];
      final completer = Completer<void>();

      recorderObj['ondataavailable'] = ((JSAny event) {
        final data = (event as JSObject)['data'];
        if (data != null) chunks.add(data);
      }).toJS;

      recorderObj['onstop'] = (completer.complete).toJS;

      recorderObj.callMethod<JSAny?>('start'.toJS);

      // Render frames
      final totalFrames = _durationSecs * 30; // 30fps
      final framesPerSlide = totalFrames ~/ images.length;
      final accent = _theme.accent;
      final r = (accent.r * 255.0).round().clamp(0, 255);
      final g = (accent.g * 255.0).round().clamp(0, 255);
      final b = (accent.b * 255.0).round().clamp(0, 255);

      for (var frame = 0; frame < totalFrames; frame++) {
        final slideIdx = (frame ~/ framesPerSlide).clamp(0, images.length - 1);
        final slideProgress = (frame % framesPerSlide) / framesPerSlide;
        final img = images[slideIdx];

        // Clear
        _exportCtx!.fillStyle = '#000000'.toJS;
        _exportCtx!.fillRect(0, 0, width, height);

        // Draw image with Ken Burns / zoom effect
        _exportCtx!.save();
        final scale = 1.0 + (slideProgress * 0.15);
        final tx = width / 2;
        final ty = height / 2;
        _exportCtx!.translate(tx.toDouble(), ty.toDouble());
        _exportCtx!.scale(scale, scale);
        _exportCtx!.translate(-tx.toDouble(), -ty.toDouble());

        // Cover-fit the image
        final imgAspect = img.naturalWidth / img.naturalHeight;
        final canvasAspect = width / height;
        double drawW, drawH, drawX, drawY;
        if (imgAspect > canvasAspect) {
          drawH = height.toDouble();
          drawW = drawH * imgAspect;
          drawX = (width - drawW) / 2;
          drawY = 0;
        } else {
          drawW = width.toDouble();
          drawH = drawW / imgAspect;
          drawX = 0;
          drawY = (height - drawH) / 2;
        }
        _exportCtx!.drawImage(img, drawX, drawY, drawW, drawH);
        _exportCtx!.restore();

        // Flash transition between slides
        if (slideProgress < 0.05 && slideIdx > 0) {
          final flashAlpha = (1.0 - slideProgress / 0.05);
          _exportCtx!.fillStyle =
              'rgba(255,255,255,${flashAlpha.toStringAsFixed(2)})'.toJS;
          _exportCtx!.fillRect(0, 0, width, height);
        }

        // Vignette overlay
        final gradient = _exportCtx!.createRadialGradient(
          (width / 2).toDouble(),
          (height / 2).toDouble(),
          width * 0.3,
          (width / 2).toDouble(),
          (height / 2).toDouble(),
          width * 0.8,
        );
        gradient.addColorStop(0, 'rgba(0,0,0,0)');
        gradient.addColorStop(1, 'rgba(0,0,0,0.7)');
        _exportCtx!.fillStyle = gradient as JSAny;
        _exportCtx!.fillRect(0, 0, width, height);

        // Top gradient bar
        final topGrad = _exportCtx!.createLinearGradient(0, 0, 0, 300);
        topGrad.addColorStop(0, 'rgba(0,0,0,0.9)');
        topGrad.addColorStop(1, 'rgba(0,0,0,0)');
        _exportCtx!.fillStyle = topGrad as JSAny;
        _exportCtx!.fillRect(0, 0, width, 300);

        // Bottom gradient bar
        final botGrad = _exportCtx!.createLinearGradient(
          0,
          (height - 400).toDouble(),
          0,
          height.toDouble(),
        );
        botGrad.addColorStop(0, 'rgba(0,0,0,0)');
        botGrad.addColorStop(1, 'rgba(0,0,0,0.9)');
        _exportCtx!.fillStyle = botGrad as JSAny;
        _exportCtx!.fillRect(0, 0, width, height);

        // DFC watermark top-left
        _exportCtx!.font = 'bold 28px Arial';
        _exportCtx!.fillStyle = 'rgba(0,245,255,0.6)'.toJS;
        _exportCtx!.fillText('D.F.C', 30, 50);

        // Headline text (bottom area)
        if (_headlineCtrl.text.isNotEmpty) {
          _exportCtx!.font = 'bold 72px Arial';
          _exportCtx!.fillStyle = '#FFFFFF'.toJS;
          _exportCtx!.textAlign = 'center';
          _exportCtx!.fillText(
            _headlineCtrl.text.toUpperCase(),
            (width / 2).toDouble(),
            (height - 280).toDouble(),
          );
        }

        // Subline
        if (_sublineCtrl.text.isNotEmpty) {
          _exportCtx!.font = 'bold 42px Arial';
          _exportCtx!.fillStyle = 'rgb($r,$g,$b)'.toJS;
          _exportCtx!.textAlign = 'center';
          _exportCtx!.fillText(
            _sublineCtrl.text.toUpperCase(),
            (width / 2).toDouble(),
            (height - 210).toDouble(),
          );
        }

        // Date
        if (_dateCtrl.text.isNotEmpty) {
          _exportCtx!.font = '32px Arial';
          _exportCtx!.fillStyle = '#CCCCCC'.toJS;
          _exportCtx!.textAlign = 'center';
          _exportCtx!.fillText(
            _dateCtrl.text,
            (width / 2).toDouble(),
            (height - 150).toDouble(),
          );
        }

        // CTA
        if (_ctaCtrl.text.isNotEmpty) {
          _exportCtx!.font = 'bold 36px Arial';
          _exportCtx!.fillStyle = 'rgb($r,$g,$b)'.toJS;
          _exportCtx!.textAlign = 'center';
          _exportCtx!.fillText(
            _ctaCtrl.text.toUpperCase(),
            (width / 2).toDouble(),
            (height - 80).toDouble(),
          );
        }

        // Accent line under headline
        _exportCtx!.fillStyle = 'rgb($r,$g,$b)'.toJS;
        _exportCtx!.fillRect(
          ((width / 2) - 150).toDouble(),
          (height - 260).toDouble(),
          300,
          4,
        );

        // Wait for next frame (roughly 33ms for 30fps)
        await Future.delayed(const Duration(milliseconds: 33));

        if (mounted) {
          setState(() => _exportProgress = frame / totalFrames);
        }
      }

      recorderObj.callMethod<JSAny?>('stop'.toJS);
      await completer.future;

      // Create downloadable blob
      final blob = web.Blob(
        chunks.toJS,
        web.BlobPropertyBag(type: 'video/webm'),
      );
      final url = web.URL.createObjectURL(blob);
      web.HTMLAnchorElement()
        ..href = url
        ..download = 'DFC_Promo_${DateTime.now().millisecondsSinceEpoch}.webm'
        ..click();
      web.URL.revokeObjectURL(url);

      if (mounted) {
        _showSnack('Video exported! Check your downloads', _kGreen);
      }
    } catch (e) {
      debugPrint('Export error: $e');
      if (mounted) {
        _showSnack('Export failed — try Chrome for best results: $e', _kRed);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
          _exportProgress = 0;
        });
      }
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: _kWhite)),
        backgroundColor: color.withValues(alpha: 0.9),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kPanel,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _kCyan),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/creative-hub'),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_kMagenta, _kCyan]),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'OCTANE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: _kWhite,
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Promo Video Engine',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: _kWhite,
              ),
            ),
          ],
        ),
        actions: [
          if (_isExporting)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 120,
                  child: LinearProgressIndicator(
                    value: _exportProgress,
                    backgroundColor: _kPanel,
                    color: _kCyan,
                  ),
                ),
              ),
            )
          else ...[
            IconButton(
              icon: Icon(
                _isPreviewing ? Icons.stop : Icons.play_arrow,
                color: _kGreen,
              ),
              tooltip: _isPreviewing ? 'Stop Preview' : 'Play Preview',
              onPressed: _togglePreview,
            ),
            const SizedBox(width: 4),
            _actionButton(
              icon: Icons.download,
              label: 'EXPORT',
              color: _kCyan,
              onTap: _exportVideo,
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
      body: isWide ? _buildWideLayout() : _buildNarrowLayout(),
    );
  }

  // ── Wide (desktop) layout ──────────────────────────────────────────
  Widget _buildWideLayout() {
    return Row(
      children: [
        // Left panel — controls
        SizedBox(width: 360, child: _buildControlPanel()),
        // Center — preview
        Expanded(child: _buildPreviewArea()),
        // Right panel — image grid
        SizedBox(width: 280, child: _buildImageGrid()),
      ],
    );
  }

  // ── Narrow (mobile) layout ─────────────────────────────────────────
  Widget _buildNarrowLayout() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _buildPreviewArea(),
        const SizedBox(height: 16),
        _buildImageGrid(),
        const SizedBox(height: 16),
        _buildControlPanel(),
        const SizedBox(height: 40),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PREVIEW AREA
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildPreviewArea() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 700),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isPreviewing ? _theme.accent : _kPanel,
            width: _isPreviewing ? 2 : 1,
          ),
          boxShadow: _isPreviewing
              ? [
                  BoxShadow(
                    color: _theme.accent.withValues(alpha: 0.3),
                    blurRadius: 20,
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: AspectRatio(
            aspectRatio: 9 / 16,
            child: _loadedSlotCount == 0
                ? _buildEmptyPreview()
                : _isPreviewing
                ? _buildAnimatedPreview()
                : _buildStaticPreview(),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyPreview() {
    return Container(
      color: Colors.black,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.videocam, color: _kGrey.withValues(alpha: 0.3), size: 64),
          const SizedBox(height: 12),
          Text(
            'Upload images to start',
            style: TextStyle(
              color: _kGrey.withValues(alpha: 0.5),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '6 max · 15 or 20 sec video',
            style: TextStyle(
              color: _kGrey.withValues(alpha: 0.3),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaticPreview() {
    final loaded = _loadedSlots;
    if (loaded.isEmpty) return _buildEmptyPreview();
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.memory(loaded.first.bytes!, fit: BoxFit.cover),
        // Vignette
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [Colors.transparent, Colors.black.withValues(alpha: 0.6)],
              radius: 1.2,
            ),
          ),
        ),
        // Top gradient
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 120,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.8),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        // Bottom gradient + text
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.95),
                  Colors.black.withValues(alpha: 0.6),
                  Colors.transparent,
                ],
                stops: const [0, 0.6, 1],
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 60),
                if (_headlineCtrl.text.isNotEmpty)
                  Text(
                    _headlineCtrl.text.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: _kWhite,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      height: 1.1,
                    ),
                  ),
                Container(
                  height: 3,
                  width: 100,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  color: _theme.accent,
                ),
                if (_sublineCtrl.text.isNotEmpty)
                  Text(
                    _sublineCtrl.text.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _theme.accent,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                if (_dateCtrl.text.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      _dateCtrl.text,
                      style: TextStyle(
                        color: _kGrey.withValues(alpha: 0.8),
                        fontSize: 13,
                      ),
                    ),
                  ),
                if (_ctaCtrl.text.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: _theme.accent, width: 1.5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _ctaCtrl.text.toUpperCase(),
                        style: TextStyle(
                          color: _theme.accent,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
        // DFC watermark top-left
        Positioned(
          top: 14,
          left: 14,
          child: Text(
            'D.F.C',
            style: TextStyle(
              color: _kCyan.withValues(alpha: 0.5),
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 3,
            ),
          ),
        ),
        // Image counter
        Positioned(
          top: 14,
          right: 14,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '1/$_loadedSlotCount',
              style: const TextStyle(color: _kWhite, fontSize: 11),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedPreview() {
    final loaded = _loadedSlots;
    if (loaded.isEmpty) return _buildEmptyPreview();

    return AnimatedBuilder(
      animation: _previewCtrl,
      builder: (context, _) {
        final totalSlots = loaded.length;
        final perSlide = 1.0 / totalSlots;
        final slideIdx = (_previewCtrl.value / perSlide).floor().clamp(
          0,
          totalSlots - 1,
        );
        final slideProgress = ((_previewCtrl.value % perSlide) / perSlide)
            .clamp(0.0, 1.0);

        // Ken Burns zoom
        final scale = 1.0 + (slideProgress * 0.12);
        // Flash at start of each slide
        final showFlash = slideProgress < 0.06 && slideIdx > 0;

        return Stack(
          fit: StackFit.expand,
          children: [
            Transform.scale(
              scale: scale,
              child: Image.memory(loaded[slideIdx].bytes!, fit: BoxFit.cover),
            ),
            // Flash overlay
            if (showFlash)
              AnimatedOpacity(
                duration: const Duration(milliseconds: 80),
                opacity: 1.0 - (slideProgress / 0.06),
                child: Container(color: _kWhite),
              ),
            // Vignette
            Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.6),
                  ],
                  radius: 1.2,
                ),
              ),
            ),
            // Bottom text overlay
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.95),
                      Colors.black.withValues(alpha: 0.5),
                      Colors.transparent,
                    ],
                    stops: const [0, 0.5, 1],
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    if (_headlineCtrl.text.isNotEmpty)
                      Text(
                        _headlineCtrl.text.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: _kWhite,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                    Container(
                      height: 3,
                      width: 100,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      color: _theme.accent,
                    ),
                    if (_sublineCtrl.text.isNotEmpty)
                      Text(
                        _sublineCtrl.text.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _theme.accent,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    if (_ctaCtrl.text.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          _ctaCtrl.text.toUpperCase(),
                          style: TextStyle(
                            color: _theme.accent,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
            // DFC watermark
            Positioned(
              top: 14,
              left: 14,
              child: Text(
                'D.F.C',
                style: TextStyle(
                  color: _kCyan.withValues(alpha: 0.5),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                ),
              ),
            ),
            // Slide counter
            Positioned(
              top: 14,
              right: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${slideIdx + 1}/$totalSlots',
                  style: const TextStyle(color: _kWhite, fontSize: 11),
                ),
              ),
            ),
            // Progress bar at bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                value: _previewCtrl.value,
                backgroundColor: Colors.transparent,
                color: _theme.accent,
                minHeight: 3,
              ),
            ),
          ],
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // IMAGE GRID (6 slots)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildImageGrid() {
    return Container(
      color: _kBg,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _sectionLabel('IMAGES', '$_loadedSlotCount/6'),
          const SizedBox(height: 8),
          ...List.generate(6, _buildImageSlot),
          const SizedBox(height: 12),
          if (_loadedSlotCount > 0)
            TextButton.icon(
              onPressed: () {
                for (var i = 0; i < 6; i++) {
                  _removeImage(i);
                }
              },
              icon: const Icon(Icons.clear_all, color: _kRed, size: 16),
              label: const Text(
                'Clear All',
                style: TextStyle(color: _kRed, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImageSlot(int index) {
    final slot = _slots[index];
    final hasImage = slot.bytes != null;
    return Container(
      height: 72,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: _kPanel,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: hasImage
              ? _kCyan.withValues(alpha: 0.3)
              : _kGrey.withValues(alpha: 0.15),
        ),
      ),
      child: hasImage
          ? Row(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(9),
                  ),
                  child: Image.memory(
                    slot.bytes!,
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Slide ${index + 1}',
                        style: const TextStyle(
                          color: _kWhite,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        slot.name ?? 'image',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _kGrey.withValues(alpha: 0.6),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 16, color: _kRed),
                  onPressed: () => _removeImage(index),
                ),
              ],
            )
          : InkWell(
              onTap: () => _pickImage(index),
              borderRadius: BorderRadius.circular(10),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate,
                      color: _kGrey.withValues(alpha: 0.3),
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Slide ${index + 1}',
                      style: TextStyle(
                        color: _kGrey.withValues(alpha: 0.4),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CONTROL PANEL (settings, text, theme, transitions)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildControlPanel() {
    return Container(
      color: _kBg,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // ── Duration ───────────────────────────────────────────────
          _sectionLabel('DURATION', '${_durationSecs}s'),
          const SizedBox(height: 8),
          Row(
            children: [
              _durationChip(15),
              const SizedBox(width: 8),
              _durationChip(20),
            ],
          ),
          const SizedBox(height: 20),

          // ── Theme ──────────────────────────────────────────────────
          _sectionLabel('THEME', _theme.label),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: PromoTheme.values.map(_themeChip).toList(),
          ),
          const SizedBox(height: 20),

          // ── Transition ─────────────────────────────────────────────
          _sectionLabel('TRANSITION', _transition.label),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: PromoTransition.values.map(_transitionChip).toList(),
          ),
          const SizedBox(height: 20),

          // ── Text Overlays ──────────────────────────────────────────
          _sectionLabel('TEXT OVERLAYS', ''),
          const SizedBox(height: 8),
          _textField(_headlineCtrl, 'Headline', 'FIGHT NIGHT'),
          _textField(_sublineCtrl, 'Subline', 'LIVE ON DFC'),
          _textField(_dateCtrl, 'Date', 'MARCH 15, 2026'),
          _textField(_venueCtrl, 'Venue (optional)', 'Brisbane, QLD'),
          _textField(_ctaCtrl, 'Call to Action', 'WATCH NOW ON DFC'),
          const SizedBox(height: 20),

          // ── Quick Text Presets ─────────────────────────────────────
          _sectionLabel('QUICK PRESETS', ''),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _presetChip('PPV NIGHT', 'LIVE ON PPV', 'ORDER NOW'),
              _presetChip('TITLE FIGHT', 'CHAMPIONSHIP BOUT', 'DON\'T MISS IT'),
              _presetChip('WAR', 'THIS IS WAR', 'WATCH THE CHAOS'),
              _presetChip('DEBUT', 'DFC DEBUT', 'WITNESS GREATNESS'),
              _presetChip('GRUDGE MATCH', 'UNFINISHED BUSINESS', 'SETTLE IT'),
              _presetChip('IBC III', 'BRISBANE 2026', 'TICKETS ON SALE'),
            ],
          ),
          const SizedBox(height: 20),

          // ── Export options ──────────────────────────────────────────
          _sectionLabel('OUTPUT', '1080×1920'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _kPanel,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _kGrey.withValues(alpha: 0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: _kCyan.withValues(alpha: 0.5),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Export as WebM video (1080×1920)\nVertical format — perfect for TikTok, Reels, Stories\n30fps · High quality',
                        style: TextStyle(
                          color: _kGrey,
                          fontSize: 11,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isExporting ? null : _exportVideo,
                    icon: _isExporting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: _kBg,
                            ),
                          )
                        : const Icon(Icons.movie_creation, size: 18),
                    label: Text(
                      _isExporting
                          ? 'RENDERING ${(_exportProgress * 100).toInt()}%'
                          : 'GENERATE VIDEO',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kCyan,
                      foregroundColor: _kBg,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // UI COMPONENTS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _sectionLabel(String title, String badge) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: _kGrey,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        if (badge.isNotEmpty) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _kCyan.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              badge,
              style: const TextStyle(
                color: _kCyan,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _durationChip(int secs) {
    final sel = _durationSecs == secs;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _durationSecs = secs);
          _previewCtrl.duration = Duration(seconds: secs);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: sel ? _kCyan.withValues(alpha: 0.15) : _kPanel,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: sel ? _kCyan : _kGrey.withValues(alpha: 0.15),
            ),
          ),
          child: Center(
            child: Text(
              '${secs}s',
              style: TextStyle(
                color: sel ? _kCyan : _kGrey,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _themeChip(PromoTheme t) {
    final sel = _theme == t;
    return GestureDetector(
      onTap: () => setState(() => _theme = t),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: sel ? t.accent.withValues(alpha: 0.15) : _kPanel,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: sel ? t.accent : _kGrey.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: t.accent,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              t.label,
              style: TextStyle(
                color: sel ? t.accent : _kGrey,
                fontSize: 12,
                fontWeight: sel ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _transitionChip(PromoTransition t) {
    final sel = _transition == t;
    return GestureDetector(
      onTap: () => setState(() => _transition = t),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: sel ? _kMagenta.withValues(alpha: 0.15) : _kPanel,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: sel ? _kMagenta : _kGrey.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              t.icon,
              size: 14,
              color: sel ? _kMagenta : _kGrey.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 4),
            Text(
              t.label,
              style: TextStyle(
                color: sel ? _kMagenta : _kGrey,
                fontSize: 11,
                fontWeight: sel ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _textField(TextEditingController ctrl, String label, String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: ctrl,
        style: const TextStyle(color: _kWhite, fontSize: 13),
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: TextStyle(
            color: _kGrey.withValues(alpha: 0.6),
            fontSize: 12,
          ),
          hintStyle: TextStyle(
            color: _kGrey.withValues(alpha: 0.25),
            fontSize: 12,
          ),
          filled: true,
          fillColor: _kPanel,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: _kGrey.withValues(alpha: 0.15)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: _kGrey.withValues(alpha: 0.15)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: _kCyan),
          ),
        ),
      ),
    );
  }

  Widget _presetChip(String headline, String sub, String cta) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _headlineCtrl.text = headline;
          _sublineCtrl.text = sub;
          _ctaCtrl.text = cta;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: _kPanel,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: _kGold.withValues(alpha: 0.2)),
        ),
        child: Text(
          headline,
          style: const TextStyle(color: _kGold, fontSize: 11),
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: TextButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: color, size: 18),
        label: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        style: TextButton.styleFrom(
          backgroundColor: color.withValues(alpha: 0.1),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DATA MODELS
// ═══════════════════════════════════════════════════════════════════════════

class _ImageSlot {
  final Uint8List? bytes;
  final String? name;
  final String? objectUrl;

  _ImageSlot({this.bytes, this.name, this.objectUrl});
}
