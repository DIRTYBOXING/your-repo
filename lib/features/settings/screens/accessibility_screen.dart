import 'package:flutter/material.dart';
import 'package:datafightcentral/core/theme/design_tokens.dart';

/// Accessibility Screen — DFC believes every athlete deserves access.
/// Font size, contrast, screen reader, reduced motion, color-blind modes.
/// Tech-smart and inclusive by design.
class AccessibilityScreen extends StatefulWidget {
  const AccessibilityScreen({super.key});

  @override
  State<AccessibilityScreen> createState() => _AccessibilityScreenState();
}

class _AccessibilityScreenState extends State<AccessibilityScreen> {
  double _fontSize = 1.0; // multiplier
  bool _highContrast = false;
  bool _reducedMotion = false;
  bool _screenReader = false;
  bool _largeTouch = false;
  int _colorMode = 0; // 0=normal, 1=deuteranopia, 2=protanopia, 3=tritanopia

  static const _colorModes = [
    'Normal Vision',
    'Deuteranopia (Green-Blind)',
    'Protanopia (Red-Blind)',
    'Tritanopia (Blue-Blind)',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgPrimary,
        elevation: 0,
        title: const Text(
          'Accessibility',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
        actions: [
          TextButton(
            onPressed: _resetAll,
            child: Text(
              'Reset',
              style: TextStyle(
                color: DesignTokens.neonCyan.withValues(alpha: 0.7),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _buildMissionBanner(),
          const SizedBox(height: 20),
          _sectionLabel('Display'),
          const SizedBox(height: 10),
          _buildFontSizeSlider(),
          const SizedBox(height: 12),
          _buildToggle(
            icon: Icons.contrast,
            title: 'High Contrast',
            subtitle: 'Increase text and UI contrast for better readability',
            value: _highContrast,
            color: DesignTokens.neonAmber,
            onChanged: (v) => setState(() => _highContrast = v),
          ),
          const SizedBox(height: 12),
          _buildToggle(
            icon: Icons.touch_app,
            title: 'Large Touch Targets',
            subtitle: 'Increase button and interactive element sizes',
            value: _largeTouch,
            color: DesignTokens.neonMagenta,
            onChanged: (v) => setState(() => _largeTouch = v),
          ),
          const SizedBox(height: 24),
          _sectionLabel('Motion & Audio'),
          const SizedBox(height: 10),
          _buildToggle(
            icon: Icons.animation,
            title: 'Reduce Motion',
            subtitle: 'Minimize animations and auto-playing media',
            value: _reducedMotion,
            color: DesignTokens.neonGreen,
            onChanged: (v) => setState(() => _reducedMotion = v),
          ),
          const SizedBox(height: 12),
          _buildToggle(
            icon: Icons.record_voice_over,
            title: 'Screen Reader Support',
            subtitle: 'Optimize layouts and labels for assistive technology',
            value: _screenReader,
            color: DesignTokens.neonCyan,
            onChanged: (v) => setState(() => _screenReader = v),
          ),
          const SizedBox(height: 24),
          _sectionLabel('Color Vision'),
          const SizedBox(height: 10),
          _buildColorModeSelector(),
          const SizedBox(height: 24),
          _buildInfoCard(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildMissionBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            DesignTokens.neonCyan.withValues(alpha: 0.08),
            DesignTokens.neonMagenta.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        border: Border.all(
          color: DesignTokens.neonCyan.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          const Text('♿', style: TextStyle(fontSize: 32)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Everyone Belongs on the Mat',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.95),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'DFC is committed to making combat sports accessible to athletes of all abilities. '
                  'Customize your experience below.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFontSizeSlider() {
    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.text_fields, color: DesignTokens.neonCyan, size: 20),
              const SizedBox(width: 10),
              const Text(
                'Text Size',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: DesignTokens.neonCyan.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
                ),
                child: Text(
                  '${(_fontSize * 100).round()}%',
                  style: const TextStyle(
                    color: DesignTokens.neonCyan,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text(
                'A',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              Expanded(
                child: Slider(
                  value: _fontSize,
                  min: 0.8,
                  max: 1.6,
                  divisions: 8,
                  activeColor: DesignTokens.neonCyan,
                  inactiveColor: Colors.white.withValues(alpha: 0.1),
                  onChanged: (v) => setState(() => _fontSize = v),
                ),
              ),
              const Text(
                'A',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          Text(
            _fontSize == 1.0
                ? 'Default size — comfortable reading'
                : _fontSize > 1.0
                ? 'Larger text — easier to read at a distance'
                : 'Compact text — fits more content on screen',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggle({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Color color,
    required ValueChanged<bool> onChanged,
  }) {
    return _glassCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeThumbColor: color,
            activeTrackColor: color.withValues(alpha: 0.3),
            inactiveTrackColor: Colors.white.withValues(alpha: 0.08),
          ),
        ],
      ),
    );
  }

  Widget _buildColorModeSelector() {
    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.palette, color: DesignTokens.neonGold, size: 20),
              SizedBox(width: 10),
              Text(
                'Color Vision Mode',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...List.generate(_colorModes.length, (i) {
            final selected = _colorMode == i;
            return GestureDetector(
              onTap: () => setState(() => _colorMode = i),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? DesignTokens.neonGold.withValues(alpha: 0.1)
                      : Colors.white.withValues(alpha: 0.02),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
                  border: Border.all(
                    color: selected
                        ? DesignTokens.neonGold.withValues(alpha: 0.3)
                        : Colors.white.withValues(alpha: 0.06),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: selected
                            ? DesignTokens.neonGold
                            : Colors.transparent,
                        border: Border.all(
                          color: selected
                              ? DesignTokens.neonGold
                              : Colors.white.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: selected
                          ? const Icon(
                              Icons.check,
                              size: 14,
                              color: Colors.black,
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _colorModes[i],
                      style: TextStyle(
                        color: selected
                            ? DesignTokens.neonGold
                            : Colors.white.withValues(alpha: 0.6),
                        fontSize: 13,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DesignTokens.neonGreen.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        border: Border.all(
          color: DesignTokens.neonGreen.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: DesignTokens.neonGreen,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Adaptive Athletes',
                style: TextStyle(
                  color: DesignTokens.neonGreen,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Combat sports are for everyone. Adaptive martial arts programs worldwide prove that '
            'physical ability is never a barrier to discipline, fitness, and personal growth. '
            'DFC proudly supports organizations bringing martial arts to athletes of all abilities.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.35),
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _glassCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard.withValues(
          alpha: DesignTokens.glassOpacity + 0.04,
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        border: Border.all(
          color: Colors.white.withValues(
            alpha: DesignTokens.glassBorderOpacity,
          ),
        ),
      ),
      child: child,
    );
  }

  void _resetAll() {
    setState(() {
      _fontSize = 1.0;
      _highContrast = false;
      _reducedMotion = false;
      _screenReader = false;
      _largeTouch = false;
      _colorMode = 0;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Accessibility settings reset to defaults')),
    );
  }
}
