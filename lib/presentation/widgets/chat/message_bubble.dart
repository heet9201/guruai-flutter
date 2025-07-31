import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../domain/entities/chat_message.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final String currentLanguage;
  final Function(String) onPlayVoice;
  final Function(String) onPlayTts;
  final Function(String) onToggleFavorite;
  final Function(String) onSaveAsFaq;
  final bool isPlayingVoice;
  final bool isPlayingTts;

  const MessageBubble({
    super.key,
    required this.message,
    required this.currentLanguage,
    required this.onPlayVoice,
    required this.onPlayTts,
    required this.onToggleFavorite,
    required this.onSaveAsFaq,
    this.isPlayingVoice = false,
    this.isPlayingTts = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.isUser;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            _buildAvatar(context),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: GestureDetector(
              onLongPress: () => _showMessageOptions(context),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isUser
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(16).copyWith(
                    bottomLeft: isUser
                        ? const Radius.circular(16)
                        : const Radius.circular(4),
                    bottomRight: isUser
                        ? const Radius.circular(4)
                        : const Radius.circular(16),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (message.type == MessageType.voice)
                      _buildVoiceMessage(context)
                    else
                      _buildTextMessage(context),
                    const SizedBox(height: 4),
                    _buildMessageFooter(context),
                  ],
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            _buildAvatar(context),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: message.isUser
            ? theme.colorScheme.primary
            : theme.colorScheme.secondary,
        shape: BoxShape.circle,
      ),
      child: Icon(
        message.isUser ? Icons.person : Icons.smart_toy,
        color: Colors.white,
        size: 18,
      ),
    );
  }

  Widget _buildTextMessage(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          message.text,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: message.isUser
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
        if (!message.isUser) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildActionButton(
                context,
                isPlayingTts ? Icons.volume_off : Icons.volume_up,
                'Play',
                () => onPlayTts(message.text),
              ),
              const SizedBox(width: 8),
              _buildActionButton(
                context,
                message.isFavorite ? Icons.favorite : Icons.favorite_border,
                'Favorite',
                () => onToggleFavorite(message.id),
                color: message.isFavorite ? Colors.red : null,
              ),
              const SizedBox(width: 8),
              _buildActionButton(
                context,
                message.isSavedAsFaq ? Icons.bookmark : Icons.bookmark_border,
                'Save as FAQ',
                () => onSaveAsFaq(message.id),
                color: message.isSavedAsFaq ? Colors.blue : null,
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildVoiceMessage(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: () => onPlayVoice(message.voiceFilePath ?? ''),
          icon: Icon(
            isPlayingVoice ? Icons.pause : Icons.play_arrow,
            color: message.isUser
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Voice Message',
              style: theme.textTheme.bodySmall?.copyWith(
                color: message.isUser
                    ? theme.colorScheme.onPrimary.withOpacity(0.8)
                    : theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
            if (message.voiceDuration != null)
              Text(
                _formatDuration(message.voiceDuration!),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: message.isUser
                      ? theme.colorScheme.onPrimary.withOpacity(0.6)
                      : theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildMessageFooter(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          DateFormat('HH:mm').format(message.timestamp),
          style: theme.textTheme.bodySmall?.copyWith(
            color: message.isUser
                ? theme.colorScheme.onPrimary.withOpacity(0.6)
                : theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
            fontSize: 10,
          ),
        ),
        if (message.isUser) ...[
          const SizedBox(width: 4),
          Icon(
            _getStatusIcon(message.status),
            size: 12,
            color: message.isUser
                ? theme.colorScheme.onPrimary.withOpacity(0.6)
                : theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
          ),
        ],
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    IconData icon,
    String tooltip,
    VoidCallback onPressed, {
    Color? color,
  }) {
    final theme = Theme.of(context);

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(4),
          child: Icon(
            icon,
            size: 16,
            color: color ?? theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
          ),
        ),
      ),
    );
  }

  IconData _getStatusIcon(MessageStatus status) {
    switch (status) {
      case MessageStatus.sending:
        return Icons.access_time;
      case MessageStatus.sent:
        return Icons.check;
      case MessageStatus.delivered:
        return Icons.done_all;
      case MessageStatus.read:
        return Icons.done_all;
      case MessageStatus.error:
        return Icons.error_outline;
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _showMessageOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy'),
              onTap: () {
                Clipboard.setData(ClipboardData(text: message.text));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copied to clipboard')),
                );
              },
            ),
            if (!message.isUser) ...[
              ListTile(
                leading: Icon(
                  message.isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: message.isFavorite ? Colors.red : null,
                ),
                title: Text(message.isFavorite
                    ? 'Remove from favorites'
                    : 'Add to favorites'),
                onTap: () {
                  onToggleFavorite(message.id);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(
                  message.isSavedAsFaq ? Icons.bookmark : Icons.bookmark_border,
                  color: message.isSavedAsFaq ? Colors.blue : null,
                ),
                title: Text(
                    message.isSavedAsFaq ? 'Remove from FAQ' : 'Save as FAQ'),
                onTap: () {
                  onSaveAsFaq(message.id);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.volume_up),
                title: const Text('Play with TTS'),
                onTap: () {
                  onPlayTts(message.text);
                  Navigator.pop(context);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
