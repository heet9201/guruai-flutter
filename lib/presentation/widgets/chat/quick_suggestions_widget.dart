import 'package:flutter/material.dart';
import '../../../domain/entities/chat_message.dart';

class QuickSuggestionsWidget extends StatelessWidget {
  final List<QuickSuggestion> suggestions;
  final String currentLanguage;
  final Function(String) onSuggestionTap;

  const QuickSuggestionsWidget({
    super.key,
    required this.suggestions,
    required this.currentLanguage,
    required this.onSuggestionTap,
  });

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 45,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: suggestions.length,
        itemBuilder: (context, index) {
          final suggestion = suggestions[index];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _SuggestionChip(
              suggestion: suggestion,
              currentLanguage: currentLanguage,
              onTap: () =>
                  onSuggestionTap(suggestion.getTranslation(currentLanguage)),
            ),
          );
        },
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final QuickSuggestion suggestion;
  final String currentLanguage;
  final VoidCallback onTap;

  const _SuggestionChip({
    required this.suggestion,
    required this.currentLanguage,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                _getCategoryIcon(suggestion.category),
                size: 16,
                color: theme.colorScheme.onSecondaryContainer,
              ),
              const SizedBox(width: 6),
              Text(
                suggestion.getTranslation(currentLanguage),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSecondaryContainer,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'lesson_planning':
        return Icons.school;
      case 'assessment':
        return Icons.quiz;
      case 'content_creation':
        return Icons.create;
      case 'science':
        return Icons.science;
      case 'math':
        return Icons.calculate;
      case 'language':
        return Icons.translate;
      default:
        return Icons.lightbulb_outline;
    }
  }
}
