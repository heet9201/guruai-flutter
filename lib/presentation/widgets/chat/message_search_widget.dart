import 'package:flutter/material.dart';
import '../../../domain/entities/chat_message.dart';
import 'message_bubble.dart';

class MessageSearchWidget extends StatefulWidget {
  final Function(String) onSearch;
  final List<ChatMessage> searchResults;
  final String currentLanguage;
  final Function(String) onPlayVoice;
  final Function(String) onPlayTts;
  final Function(String) onToggleFavorite;
  final Function(String) onSaveAsFaq;

  const MessageSearchWidget({
    super.key,
    required this.onSearch,
    required this.searchResults,
    required this.currentLanguage,
    required this.onPlayVoice,
    required this.onPlayTts,
    required this.onToggleFavorite,
    required this.onSaveAsFaq,
  });

  @override
  State<MessageSearchWidget> createState() => _MessageSearchWidgetState();
}

class _MessageSearchWidgetState extends State<MessageSearchWidget>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _startSearch() {
    setState(() {
      _isSearching = true;
    });
    _animationController.forward();
    _focusNode.requestFocus();
  }

  void _stopSearch() {
    setState(() {
      _isSearching = false;
    });
    _animationController.reverse();
    _searchController.clear();
    widget.onSearch('');
    _focusNode.unfocus();
  }

  void _performSearch() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      widget.onSearch(query);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Search bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: theme.colorScheme.outline.withOpacity(0.2),
              ),
            ),
          ),
          child: Row(
            children: [
              if (!_isSearching)
                IconButton(
                  onPressed: _startSearch,
                  icon: const Icon(Icons.search),
                  tooltip: 'Search messages',
                )
              else
                AnimatedBuilder(
                  animation: _slideAnimation,
                  builder: (context, child) {
                    return Expanded(
                      flex: (_slideAnimation.value * 100).round(),
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: TextField(
                          controller: _searchController,
                          focusNode: _focusNode,
                          style: theme.textTheme.bodyMedium,
                          decoration: InputDecoration(
                            hintText: 'Search messages...',
                            hintStyle: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant
                                  .withOpacity(0.6),
                            ),
                            prefixIcon: const Icon(Icons.search, size: 20),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                          onChanged: (value) {
                            if (value.trim().isEmpty) {
                              widget.onSearch('');
                            }
                          },
                          onSubmitted: (_) => _performSearch(),
                        ),
                      ),
                    );
                  },
                ),
              if (_isSearching) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _performSearch,
                  icon: const Icon(Icons.search),
                  tooltip: 'Search',
                ),
                IconButton(
                  onPressed: _stopSearch,
                  icon: const Icon(Icons.close),
                  tooltip: 'Close search',
                ),
              ],
            ],
          ),
        ),

        // Search results
        if (_isSearching)
          Expanded(
            child: _buildSearchResults(context),
          ),
      ],
    );
  }

  Widget _buildSearchResults(BuildContext context) {
    final theme = Theme.of(context);

    if (_searchController.text.trim().isEmpty) {
      return _buildSearchSuggestions(context);
    }

    if (widget.searchResults.isEmpty) {
      return _buildNoResults(context);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            '${widget.searchResults.length} result${widget.searchResults.length == 1 ? '' : 's'} found',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: widget.searchResults.length,
            itemBuilder: (context, index) {
              final message = widget.searchResults[index];
              return MessageBubble(
                message: message,
                currentLanguage: widget.currentLanguage,
                onPlayVoice: widget.onPlayVoice,
                onPlayTts: widget.onPlayTts,
                onToggleFavorite: widget.onToggleFavorite,
                onSaveAsFaq: widget.onSaveAsFaq,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchSuggestions(BuildContext context) {
    final theme = Theme.of(context);

    final suggestions = [
      'lesson plan',
      'quiz',
      'story',
      'math',
      'science',
      'homework',
      'activities',
      'assessment',
    ];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Search suggestions:',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: suggestions.map((suggestion) {
              return ActionChip(
                label: Text(suggestion),
                onPressed: () {
                  _searchController.text = suggestion;
                  _performSearch();
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Text(
            'Recent searches:',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your recent searches will appear here',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No messages found',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try different keywords or check your spelling',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
