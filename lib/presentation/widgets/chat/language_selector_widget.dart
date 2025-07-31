import 'package:flutter/material.dart';

class LanguageSelectorWidget extends StatelessWidget {
  final String currentLanguage;
  final Function(String) onLanguageChanged;
  final bool isVisible;

  const LanguageSelectorWidget({
    super.key,
    required this.currentLanguage,
    required this.onLanguageChanged,
    this.isVisible = true,
  });

  static const Map<String, Map<String, String>> _languages = {
    'en': {
      'name': 'English',
      'nativeName': 'English',
      'flag': '🇺🇸',
    },
    'hi': {
      'name': 'Hindi',
      'nativeName': 'हिन्दी',
      'flag': '🇮🇳',
    },
    'te': {
      'name': 'Telugu',
      'nativeName': 'తెలుగు',
      'flag': '🇮🇳',
    },
    'ta': {
      'name': 'Tamil',
      'nativeName': 'தமிழ்',
      'flag': '🇮🇳',
    },
    'kn': {
      'name': 'Kannada',
      'nativeName': 'ಕನ್ನಡ',
      'flag': '🇮🇳',
    },
    'ml': {
      'name': 'Malayalam',
      'nativeName': 'മലയാളം',
      'flag': '🇮🇳',
    },
    'gu': {
      'name': 'Gujarati',
      'nativeName': 'ગુજરાતી',
      'flag': '🇮🇳',
    },
    'bn': {
      'name': 'Bengali',
      'nativeName': 'বাংলা',
      'flag': '🇮🇳',
    },
    'mr': {
      'name': 'Marathi',
      'nativeName': 'मराठी',
      'flag': '🇮🇳',
    },
    'pa': {
      'name': 'Punjabi',
      'nativeName': 'ਪੰਜਾਬੀ',
      'flag': '🇮🇳',
    },
  };

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.translate,
                    size: 16,
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Language:',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: currentLanguage,
                        isDense: true,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSecondaryContainer,
                        ),
                        dropdownColor: theme.colorScheme.surface,
                        items: _languages.entries.map((entry) {
                          final lang = entry.value;
                          return DropdownMenuItem<String>(
                            value: entry.key,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(lang['flag']!,
                                    style: const TextStyle(fontSize: 16)),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      lang['name']!,
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      lang['nativeName']!,
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        fontSize: 10,
                                        color: theme.colorScheme.onSurface
                                            .withOpacity(0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            onLanguageChanged(newValue);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          _buildQuickLanguageToggle(context),
        ],
      ),
    );
  }

  Widget _buildQuickLanguageToggle(BuildContext context) {
    final theme = Theme.of(context);

    // Show English-Hindi toggle for quick switching
    final alternateLanguage = currentLanguage == 'en' ? 'hi' : 'en';
    final alternateLang = _languages[alternateLanguage]!;

    return Tooltip(
      message: 'Switch to ${alternateLang['name']}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onLanguageChanged(alternateLanguage),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  alternateLang['flag']!,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.swap_horiz,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LanguageBottomSheet extends StatelessWidget {
  final String currentLanguage;
  final Function(String) onLanguageSelected;

  const LanguageBottomSheet({
    super.key,
    required this.currentLanguage,
    required this.onLanguageSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.translate,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Select Language',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Choose your preferred language for conversations:',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          ...LanguageSelectorWidget._languages.entries.map((entry) {
            final langCode = entry.key;
            final lang = entry.value;
            final isSelected = langCode == currentLanguage;

            return ListTile(
              leading: Text(
                lang['flag']!,
                style: const TextStyle(fontSize: 24),
              ),
              title: Text(
                lang['name']!,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              subtitle: Text(
                lang['nativeName']!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              trailing: isSelected
                  ? Icon(
                      Icons.check_circle,
                      color: theme.colorScheme.primary,
                    )
                  : null,
              onTap: () {
                onLanguageSelected(langCode);
                Navigator.pop(context);
              },
            );
          }).toList(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
