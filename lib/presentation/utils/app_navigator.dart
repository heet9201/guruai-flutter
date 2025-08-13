import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Navigation utility for consistent routing across the app
class AppNavigator {
  static Future<void> navigateToContentCreation(
    BuildContext context, {
    required String contentType,
    String? subject,
    String? topic,
    String? difficulty,
    Map<String, dynamic>? metadata,
  }) async {
    HapticFeedback.lightImpact();

    try {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => _ContentCreationScreen(
            contentType: contentType,
            subject: subject,
            topic: topic,
            difficulty: difficulty,
            metadata: metadata,
          ),
        ),
      );
    } catch (e) {
      // Handle navigation errors gracefully
      _showErrorSnackBar(context, 'Failed to open $contentType creator');
    }
  }

  static Future<void> navigateToRecommendation(
    BuildContext context,
    Map<String, dynamic> recommendation,
  ) async {
    final contentType = recommendation['type'] as String? ?? 'content';
    final subject = recommendation['subject'] as String?;
    final topic = recommendation['topic'] as String? ??
        recommendation['title'] as String?;
    final difficulty = recommendation['difficulty'] as String?;

    await navigateToContentCreation(
      context,
      contentType: contentType,
      subject: subject,
      topic: topic,
      difficulty: difficulty,
      metadata: recommendation,
    );
  }

  static void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

/// Content creation screen placeholder
class _ContentCreationScreen extends StatefulWidget {
  final String contentType;
  final String? subject;
  final String? topic;
  final String? difficulty;
  final Map<String, dynamic>? metadata;

  const _ContentCreationScreen({
    required this.contentType,
    this.subject,
    this.topic,
    this.difficulty,
    this.metadata,
  });

  @override
  State<_ContentCreationScreen> createState() => _ContentCreationScreenState();
}

class _ContentCreationScreenState extends State<_ContentCreationScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create ${widget.contentType.toUpperCase()}'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getIconForContentType(widget.contentType),
                size: 80,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 24),
              Text(
                'Creating ${widget.contentType}...',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              if (widget.topic != null) ...[
                Text(
                  'Topic: ${widget.topic}',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 8),
              ],
              if (widget.subject != null) ...[
                Text(
                  'Subject: ${widget.subject}',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 8),
              ],
              if (widget.difficulty != null) ...[
                Text(
                  'Difficulty: ${widget.difficulty}',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
              ],
              const CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconForContentType(String contentType) {
    switch (contentType.toLowerCase()) {
      case 'story':
        return Icons.auto_stories;
      case 'worksheet':
        return Icons.assignment;
      case 'quiz':
        return Icons.quiz;
      case 'chat':
        return Icons.chat;
      default:
        return Icons.create;
    }
  }
}
