import 'package:flutter/material.dart';
import '../../core/theme/design_tokens.dart';

/// Language Badge — Earth icon with language selector
/// Shows supported languages: English, Español, Português, etc.
class LanguageBadge extends StatefulWidget {
  final void Function(String languageCode)? onLanguageChanged;

  const LanguageBadge({super.key, this.onLanguageChanged});

  @override
  State<LanguageBadge> createState() => _LanguageBadgeState();
}

class _LanguageBadgeState extends State<LanguageBadge> {
  String _selectedLanguage = 'en';

  static const _languages = [
    {'code': 'en', 'name': 'English', 'flag': '🇺🇸'},
    {'code': 'es', 'name': 'Español', 'flag': '🇪🇸'},
    {'code': 'pt', 'name': 'Português', 'flag': '🇧🇷'},
    {'code': 'fr', 'name': 'Français', 'flag': '🇫🇷'},
    {'code': 'de', 'name': 'Deutsch', 'flag': '🇩🇪'},
    {'code': 'it', 'name': 'Italiano', 'flag': '🇮🇹'},
    {'code': 'ja', 'name': '日本語', 'flag': '🇯🇵'},
    {'code': 'ko', 'name': '한국어', 'flag': '🇰🇷'},
    {'code': 'zh', 'name': '中文', 'flag': '🇨🇳'},
    {'code': 'ru', 'name': 'Русский', 'flag': '🇷🇺'},
    {'code': 'ar', 'name': 'العربية', 'flag': '🇸🇦'},
    {'code': 'th', 'name': 'ไทย', 'flag': '🇹🇭'},
  ];

  String get _currentLanguageName =>
      _languages.firstWhere((l) => l['code'] == _selectedLanguage)['name']!;

  void _showLanguageSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: const BoxConstraints(maxHeight: 500),
        decoration: BoxDecoration(
          color: DesignTokens.bgSecondary,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(DesignTokens.radiusLarge),
          ),
          border: Border.all(
            color: DesignTokens.neonCyan.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          DesignTokens.neonCyan.withValues(alpha: 0.2),
                          DesignTokens.neonMagenta.withValues(alpha: 0.2),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(
                        DesignTokens.radiusSmall,
                      ),
                    ),
                    child: const Icon(
                      Icons.public,
                      color: DesignTokens.neonCyan,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select Language',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Combat sports unite us globally 🌍',
                          style: TextStyle(
                            color: DesignTokens.textMuted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white12, height: 1),
            // Language list
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _languages.length,
                itemBuilder: (context, index) {
                  final lang = _languages[index];
                  final isSelected = lang['code'] == _selectedLanguage;

                  return InkWell(
                    onTap: () {
                      setState(() => _selectedLanguage = lang['code']!);
                      widget.onLanguageChanged?.call(lang['code']!);
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? DesignTokens.neonCyan.withValues(alpha: 0.1)
                            : Colors.transparent,
                      ),
                      child: Row(
                        children: [
                          Text(
                            lang['flag']!,
                            style: const TextStyle(fontSize: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              lang['name']!,
                              style: TextStyle(
                                color: isSelected
                                    ? DesignTokens.neonCyan
                                    : Colors.white,
                                fontSize: 15,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.check_circle,
                              color: DesignTokens.neonCyan,
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.02),
                border: Border(
                  top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.translate,
                    color: DesignTokens.textMuted,
                    size: 16,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Help us translate DFC to more languages',
                    style: TextStyle(
                      color: DesignTokens.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _showLanguageSheet,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: DesignTokens.neonCyan.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
          border: Border.all(
            color: DesignTokens.neonCyan.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Earth icon
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    DesignTokens.neonCyan.withValues(alpha: 0.3),
                    DesignTokens.neonGreen.withValues(alpha: 0.3),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.public,
                color: DesignTokens.neonCyan,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            // Language name
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _currentLanguageName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Text(
                  '12 languages',
                  style: TextStyle(color: DesignTokens.textMuted, fontSize: 10),
                ),
              ],
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.keyboard_arrow_down,
              color: DesignTokens.neonCyan.withValues(alpha: 0.7),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
