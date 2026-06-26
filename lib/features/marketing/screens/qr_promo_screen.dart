import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';

/// QR Promo Screen — Generate QR codes for DFC resources.
/// Uses qr_flutter ^4.1.0 package. 5 presets + custom URL.
class QRPromoScreen extends StatefulWidget {
  const QRPromoScreen({super.key});

  @override
  State<QRPromoScreen> createState() => _QRPromoScreenState();
}

class _QRPromoScreenState extends State<QRPromoScreen> {
  final TextEditingController _customUrlController = TextEditingController();
  String _selectedPreset = 'app';
  String _currentUrl = AppConstants.publicWebBaseUrl;
  Color _qrColor = AppTheme.neonCyan;

  final _presets = <String, _QRPreset>{
    'app': _QRPreset(
      label: 'DFC App',
      url: AppConstants.publicWebBaseUrl,
      icon: Icons.sports_mma,
      color: AppTheme.neonCyan,
    ),
    'events': _QRPreset(
      label: 'Events',
      url: '${AppConstants.publicWebBaseUrl}/events',
      icon: Icons.event,
      color: AppTheme.neonOrange,
    ),
    'social': _QRPreset(
      label: 'Social Feed',
      url: '${AppConstants.publicWebBaseUrl}/home',
      icon: Icons.share,
      color: AppTheme.neonMagenta,
    ),
    'promoter': _QRPreset(
      label: 'Promoter Hub',
      url: '${AppConstants.publicWebBaseUrl}/promoter',
      icon: Icons.campaign,
      color: AppTheme.neonGreen,
    ),
    'custom': _QRPreset(
      label: 'Custom URL',
      url: '',
      icon: Icons.edit,
      color: AppTheme.neonPurple,
    ),
  };

  @override
  void dispose() {
    _customUrlController.dispose();
    super.dispose();
  }

  void _selectPreset(String key) {
    final preset = _presets[key]!;
    setState(() {
      _selectedPreset = key;
      _qrColor = preset.color;
      if (key != 'custom') {
        _currentUrl = preset.url;
      } else {
        _currentUrl = _customUrlController.text.isNotEmpty
            ? _customUrlController.text
            : AppConstants.publicWebBaseUrl;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      appBar: AppBar(
        title: const Text('QR PROMO GENERATOR'),
        backgroundColor: AppTheme.cardBackground,
        foregroundColor: const Color(0xFFFFD700),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Preset selector
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _presets.entries.map((entry) {
                final isActive = _selectedPreset == entry.key;
                return ChoiceChip(
                  avatar: Icon(
                    entry.value.icon,
                    color: isActive
                        ? AppTheme.primaryBackground
                        : entry.value.color,
                    size: 18,
                  ),
                  label: Text(
                    entry.value.label,
                    style: TextStyle(
                      color: isActive
                          ? AppTheme.primaryBackground
                          : AppTheme.textPrimary,
                      fontSize: 12,
                    ),
                  ),
                  selected: isActive,
                  selectedColor: entry.value.color,
                  backgroundColor: AppTheme.cardBackground,
                  side: BorderSide(
                    color: entry.value.color.withValues(alpha: 0.4),
                  ),
                  onSelected: (_) => _selectPreset(entry.key),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Custom URL input
            if (_selectedPreset == 'custom')
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: TextField(
                  controller: _customUrlController,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Enter URL...',
                    hintStyle: const TextStyle(color: AppTheme.textMuted),
                    filled: true,
                    fillColor: AppTheme.cardBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: AppTheme.neonPurple.withValues(alpha: 0.4),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: AppTheme.neonPurple.withValues(alpha: 0.4),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppTheme.neonPurple),
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.check, color: AppTheme.neonGreen),
                      onPressed: () {
                        setState(() {
                          _currentUrl = _customUrlController.text.isNotEmpty
                              ? _customUrlController.text
                              : AppConstants.publicWebBaseUrl;
                        });
                      },
                    ),
                  ),
                  onSubmitted: (val) {
                    setState(() {
                      _currentUrl = val.isNotEmpty
                          ? val
                          : AppConstants.publicWebBaseUrl;
                    });
                  },
                ),
              ),

            // QR Code display
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: _qrColor.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: QrImageView(
                data: _currentUrl,
                size: 240,
              ),
            ),
            const SizedBox(height: 16),

            // URL display
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _qrColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.link, color: _qrColor, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _currentUrl,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 18),
                    color: AppTheme.neonCyan,
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _currentUrl));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('URL copied to clipboard'),
                          backgroundColor: AppTheme.neonGreen,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Info card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.neonCyan.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'QR CODE TIPS',
                    style: TextStyle(
                      color: AppTheme.neonCyan,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _tipRow('Print on flyers, posters, and fight cards'),
                  _tipRow('Add to social media stories and posts'),
                  _tipRow('Include on event tickets and wristbands'),
                  _tipRow('Display on gym walls and equipment'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tipRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline,
            color: AppTheme.neonGreen,
            size: 14,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _QRPreset {
  final String label;
  final String url;
  final IconData icon;
  final Color color;
  _QRPreset({
    required this.label,
    required this.url,
    required this.icon,
    required this.color,
  });
}
