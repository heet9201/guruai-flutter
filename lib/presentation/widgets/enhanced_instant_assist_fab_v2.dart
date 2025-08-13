import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../utils/app_navigator.dart';

/// Enhanced Instant Assist FAB with proper UI/UX positioning and opacity handling
class EnhancedInstantAssistFAB extends StatefulWidget {
  final String languageCode;
  final bool isOnline;

  const EnhancedInstantAssistFAB({
    super.key,
    required this.languageCode,
    required this.isOnline,
  });

  @override
  State<EnhancedInstantAssistFAB> createState() =>
      _EnhancedInstantAssistFABState();
}

class _EnhancedInstantAssistFABState extends State<EnhancedInstantAssistFAB>
    with TickerProviderStateMixin {
  late AnimationController _expansionController;
  late AnimationController _breathingController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _breathingAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _expansionController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _breathingController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _expansionController,
      curve: Curves.easeOutBack,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.125, // 45 degrees
    ).animate(CurvedAnimation(
      parent: _expansionController,
      curve: Curves.easeInOut,
    ));

    _breathingAnimation = Tween<double>(
      begin: 1.0,
      end: 1.03, // Very subtle breathing effect
    ).animate(CurvedAnimation(
      parent: _breathingController,
      curve: Curves.easeInOut,
    ));

    // Start breathing animation
    _breathingController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _expansionController.dispose();
    _breathingController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    HapticFeedback.lightImpact();

    setState(() {
      _isExpanded = !_isExpanded;
    });

    if (_isExpanded) {
      _expansionController.forward();
      _breathingController.stop();
    } else {
      _expansionController.reverse();
      _breathingController.repeat(reverse: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Action buttons arranged vertically for better UX
        if (_isExpanded) ..._buildActionButtons(context, screenSize),

        const SizedBox(height: 16),

        // Main FAB
        AnimatedBuilder(
          animation: _breathingAnimation,
          builder: (context, child) {
            final breathingScale =
                _isExpanded ? 1.0 : _breathingAnimation.value;
            // Clamp the breathing scale to ensure it stays within valid range
            final safeScale = breathingScale.clamp(0.95, 1.1);

            return Transform.scale(
              scale: safeScale,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      SahayakColors.ochre,
                      SahayakColors.burntSienna,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: SahayakColors.ochre.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: FloatingActionButton(
                  onPressed: _toggleExpanded,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  heroTag: "enhanced_main_fab",
                  tooltip: _getMainFABTooltip(widget.languageCode),
                  child: AnimatedBuilder(
                    animation: _rotationAnimation,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _rotationAnimation.value * 2 * 3.14159,
                        child: Icon(
                          _isExpanded ? Icons.close : Icons.auto_awesome,
                          color: Colors.white,
                          size: 28,
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  List<Widget> _buildActionButtons(BuildContext context, Size screenSize) {
    final actions = [
      _ActionButtonData(
        icon: Icons.auto_stories,
        label: _getCreateStoryLabel(widget.languageCode),
        color: SahayakColors.deepTeal,
        actionType: 'story',
      ),
      _ActionButtonData(
        icon: Icons.assignment,
        label: _getCreateWorksheetLabel(widget.languageCode),
        color: SahayakColors.forestGreen,
        actionType: 'worksheet',
      ),
      _ActionButtonData(
        icon: Icons.quiz,
        label: _getQuickQuizLabel(widget.languageCode),
        color: SahayakColors.clayOrange,
        actionType: 'quiz',
      ),
      _ActionButtonData(
        icon: Icons.chat,
        label: _getAskQuestionLabel(widget.languageCode),
        color: SahayakColors.burntSienna,
        actionType: 'chat',
      ),
    ];

    return actions.asMap().entries.map((entry) {
      final index = entry.key;
      final action = entry.value;

      return AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          // Ensure opacity is always between 0.0 and 1.0
          final opacity = _scaleAnimation.value.clamp(0.0, 1.0);
          final scale = _scaleAnimation.value.clamp(0.0, 1.0);

          return AnimatedOpacity(
            opacity: opacity,
            duration: Duration(milliseconds: 150 + (index * 50)),
            child: Transform.scale(
              scale: scale,
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: _buildActionButton(action),
              ),
            ),
          );
        },
      );
    }).toList();
  }

  Widget _buildActionButton(_ActionButtonData action) {
    return Material(
      color: Colors.transparent,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Label with background
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              action.label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Action button
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  action.color,
                  action.color.withOpacity(0.8),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: action.color.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () {
                  _handleAction(context, action.actionType);
                  _toggleExpanded(); // Close FAB after action
                },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      action.icon,
                      color: Colors.white,
                      size: 24,
                    ),
                    // Offline indicator
                    if (!widget.isOnline &&
                        _actionRequiresInternet(action.actionType))
                      Positioned(
                        right: 4,
                        top: 4,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.wifi_off,
                            size: 10,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleAction(BuildContext context, String actionType) {
    HapticFeedback.lightImpact();

    if (!widget.isOnline && _actionRequiresInternet(actionType)) {
      _showOfflineMessage(context);
      return;
    }

    // Navigate to content creation screen
    AppNavigator.navigateToContentCreation(
      context,
      contentType: actionType,
    );
  }

  bool _actionRequiresInternet(String actionType) {
    return ['story', 'worksheet', 'quiz', 'chat'].contains(actionType);
  }

  void _showOfflineMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.wifi_off,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _getOfflineMessage(widget.languageCode),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 100, left: 16, right: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Localization methods
  String _getMainFABTooltip(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'तुरंत सहायता';
      case 'mr':
        return 'त्वरित सहाय्य';
      default:
        return 'Instant Assist';
    }
  }

  String _getCreateStoryLabel(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'कहानी';
      case 'mr':
        return 'कथा';
      default:
        return 'Story';
    }
  }

  String _getCreateWorksheetLabel(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'वर्कशीट';
      case 'mr':
        return 'वर्कशीट';
      default:
        return 'Worksheet';
    }
  }

  String _getQuickQuizLabel(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'प्रश्नोत्तरी';
      case 'mr':
        return 'प्रश्नमंजुषा';
      default:
        return 'Quiz';
    }
  }

  String _getAskQuestionLabel(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'पूछें';
      case 'mr':
        return 'विचारा';
      default:
        return 'Ask';
    }
  }

  String _getOfflineMessage(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'AI सुविधाओं के लिए इंटरनेट कनेक्शन की आवश्यकता है';
      case 'mr':
        return 'AI वैशिष्ट्यांसाठी इंटरनेट कनेक्शन आवश्यक आहे';
      default:
        return 'Internet connection required for AI features';
    }
  }
}

/// Data class for action button configuration
class _ActionButtonData {
  final IconData icon;
  final String label;
  final Color color;
  final String actionType;

  const _ActionButtonData({
    required this.icon,
    required this.label,
    required this.color,
    required this.actionType,
  });
}
