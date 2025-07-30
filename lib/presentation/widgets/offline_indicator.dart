import 'package:flutter/material.dart';

class OfflineIndicator extends StatelessWidget {
  final String languageCode;

  const OfflineIndicator({
    super.key,
    required this.languageCode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.wifi_off,
            size: 16,
            color: Theme.of(context).colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 4),
          Text(
            _getOfflineLabel(languageCode),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }

  String _getOfflineLabel(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'ऑफलाइन';
      case 'mr':
        return 'ऑफलाइन';
      case 'ta':
        return 'ஆஃப்லைன்';
      case 'te':
        return 'ఆఫ్‌లైన్';
      case 'kn':
        return 'ಆಫ್‌ಲೈನ್';
      case 'ml':
        return 'ഓഫ്‌ലൈൻ';
      case 'gu':
        return 'ઓફલાઇન';
      case 'bn':
        return 'অফলাইন';
      case 'pa':
        return 'ਆਫਲਾਈਨ';
      default:
        return 'Offline';
    }
  }
}
