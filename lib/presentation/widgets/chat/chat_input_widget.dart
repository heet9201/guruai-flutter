import 'package:flutter/material.dart';

class ChatInputWidget extends StatefulWidget {
  final Function(String) onSendMessage;
  final VoidCallback onStartVoiceRecording;
  final VoidCallback onStopVoiceRecording;
  final VoidCallback onCancelVoiceRecording;
  final bool isRecording;
  final bool isTyping;
  final bool isConnected;

  const ChatInputWidget({
    super.key,
    required this.onSendMessage,
    required this.onStartVoiceRecording,
    required this.onStopVoiceRecording,
    required this.onCancelVoiceRecording,
    this.isRecording = false,
    this.isTyping = false,
    this.isConnected = true,
  });

  @override
  State<ChatInputWidget> createState() => _ChatInputWidgetState();
}

class _ChatInputWidgetState extends State<ChatInputWidget>
    with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late AnimationController _micAnimationController;
  late Animation<double> _micAnimation;

  bool _hasText = false;
  static const int _maxCharacters = 1000;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);

    _micAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _micAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _micAnimationController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(ChatInputWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRecording && !oldWidget.isRecording) {
      _micAnimationController.repeat(reverse: true);
    } else if (!widget.isRecording && oldWidget.isRecording) {
      _micAnimationController.stop();
      _micAnimationController.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _micAnimationController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {
      _hasText = _controller.text.trim().isNotEmpty;
    });
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isNotEmpty && text.length <= _maxCharacters) {
      widget.onSendMessage(text);
      _controller.clear();
      setState(() {
        _hasText = false;
      });
    }
  }

  void _handleMicTap() {
    if (widget.isRecording) {
      widget.onStopVoiceRecording();
    } else {
      widget.onStartVoiceRecording();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final remainingChars = _maxCharacters - _controller.text.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!widget.isConnected) _buildOfflineIndicator(context),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 120),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: theme.colorScheme.outline.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          maxLines: null,
                          maxLength: _maxCharacters,
                          textInputAction: TextInputAction.newline,
                          keyboardType: TextInputType.multiline,
                          style: theme.textTheme.bodyMedium,
                          decoration: InputDecoration(
                            hintText: widget.isConnected
                                ? 'Ask your teaching assistant...'
                                : 'Offline - message will be sent when connected',
                            hintStyle: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant
                                  .withOpacity(0.6),
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            counterText: '',
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                        if (_controller.text.length > _maxCharacters * 0.8)
                          _buildCharacterCounter(context, remainingChars),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _buildMicButton(context),
                const SizedBox(width: 8),
                _buildSendButton(context),
              ],
            ),
            if (widget.isRecording) _buildRecordingControls(context),
          ],
        ),
      ),
    );
  }

  Widget _buildOfflineIndicator(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud_off,
            size: 16,
            color: Colors.orange,
          ),
          const SizedBox(width: 6),
          Text(
            'Offline - messages will be queued',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.orange.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCharacterCounter(BuildContext context, int remainingChars) {
    final theme = Theme.of(context);
    final isNearLimit = remainingChars < 100;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            '$remainingChars characters remaining',
            style: theme.textTheme.bodySmall?.copyWith(
              color: isNearLimit
                  ? Colors.red
                  : theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMicButton(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _micAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.isRecording ? _micAnimation.value : 1.0,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color:
                  widget.isRecording ? Colors.red : theme.colorScheme.primary,
              shape: BoxShape.circle,
              boxShadow: widget.isRecording
                  ? [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: _handleMicTap,
                onLongPress: widget.onStartVoiceRecording,
                child: Icon(
                  widget.isRecording ? Icons.stop : Icons.mic,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSendButton(BuildContext context) {
    final theme = Theme.of(context);
    final canSend = _hasText && _controller.text.length <= _maxCharacters;

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: canSend
            ? theme.colorScheme.primary
            : theme.colorScheme.surfaceVariant,
        shape: BoxShape.circle,
        boxShadow: canSend
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: canSend ? _sendMessage : null,
          child: Icon(
            Icons.send,
            color: canSend
                ? Colors.white
                : theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildRecordingControls(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Recording... Tap mic to stop',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          TextButton(
            onPressed: widget.onCancelVoiceRecording,
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.red.shade700),
            ),
          ),
        ],
      ),
    );
  }
}
