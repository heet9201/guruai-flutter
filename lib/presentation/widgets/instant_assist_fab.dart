import 'package:flutter/material.dart';

class InstantAssistFAB extends StatefulWidget {
  final String languageCode;
  final bool isOnline;

  const InstantAssistFAB({
    super.key,
    required this.languageCode,
    required this.isOnline,
  });

  @override
  State<InstantAssistFAB> createState() => _InstantAssistFABState();
}

class _InstantAssistFABState extends State<InstantAssistFAB>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));
    _rotateAnimation = Tween<double>(
      begin: 0.0,
      end: 0.125, // 45 degrees rotation
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });

    if (_isExpanded) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        // Mini FABs
        ..._buildMiniFABs(context),

        // Main FAB
        FloatingActionButton(
          onPressed: _toggleExpanded,
          heroTag: "main_fab",
          tooltip: _getMainFABTooltip(widget.languageCode),
          child: AnimatedBuilder(
            animation: _rotateAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotateAnimation.value * 2 * 3.14159,
                child: Icon(
                  _isExpanded ? Icons.close : Icons.auto_awesome,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  List<Widget> _buildMiniFABs(BuildContext context) {
    final miniFABs = [
      _MiniFABData(
        icon: Icons.auto_stories,
        label: _getStoryLabel(widget.languageCode),
        onPressed: () => _createStory(context),
        offset: const Offset(0, -70),
      ),
      _MiniFABData(
        icon: Icons.assignment,
        label: _getWorksheetLabel(widget.languageCode),
        onPressed: () => _createWorksheet(context),
        offset: const Offset(-50, -50),
      ),
      _MiniFABData(
        icon: Icons.chat,
        label: _getQALabel(widget.languageCode),
        onPressed: () => _openQAChat(context),
        offset: const Offset(-70, 0),
      ),
      _MiniFABData(
        icon: Icons.image,
        label: _getVisualLabel(widget.languageCode),
        onPressed: () => _createVisual(context),
        offset: const Offset(-50, 50),
      ),
    ];

    return miniFABs.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;

      return AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: data.offset * _scaleAnimation.value,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Opacity(
                opacity: _scaleAnimation.value.clamp(0.0, 1.0),
                child: _buildMiniFAB(
                  context,
                  data,
                  // Stagger animation delay
                  delay: Duration(milliseconds: index * 50),
                ),
              ),
            ),
          );
        },
      );
    }).toList();
  }

  Widget _buildMiniFAB(BuildContext context, _MiniFABData data,
      {Duration delay = Duration.zero}) {
    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(16),
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: InkWell(
        onTap: () {
          _toggleExpanded(); // Close menu first
          Future.delayed(const Duration(milliseconds: 100), () {
            data.onPressed();
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                data.icon,
                size: 20,
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
              const SizedBox(width: 8),
              Text(
                data.label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Action methods
  void _createStory(BuildContext context) {
    if (!widget.isOnline) {
      _showOfflineMessage(context);
      return;
    }

    // Navigate to story creation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_getCreatingStoryMessage(widget.languageCode)),
      ),
    );
  }

  void _createWorksheet(BuildContext context) {
    if (!widget.isOnline) {
      _showOfflineMessage(context);
      return;
    }

    // Navigate to worksheet creation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_getCreatingWorksheetMessage(widget.languageCode)),
      ),
    );
  }

  void _openQAChat(BuildContext context) {
    if (!widget.isOnline) {
      _showOfflineMessage(context);
      return;
    }

    // Navigate to Q&A chat
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_getOpeningChatMessage(widget.languageCode)),
      ),
    );
  }

  void _createVisual(BuildContext context) {
    if (!widget.isOnline) {
      _showOfflineMessage(context);
      return;
    }

    // Navigate to visual creation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_getCreatingVisualMessage(widget.languageCode)),
      ),
    );
  }

  void _showOfflineMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.wifi_off, color: Colors.white),
            const SizedBox(width: 8),
            Text(_getOfflineMessage(widget.languageCode)),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  // Localization methods
  String _getMainFABTooltip(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'त्वरित सहायता';
      case 'mr':
        return 'त्वरित मदत';
      case 'ta':
        return 'விரைவு உதவி';
      case 'te':
        return 'త్వరిత సహాయం';
      case 'kn':
        return 'ತ್ವರಿತ ಸಹಾಯ';
      case 'ml':
        return 'പെട്ടെന്നുള്ള സഹായം';
      case 'gu':
        return 'ઝડપી મદદ';
      case 'bn':
        return 'দ্রুত সাহায্য';
      case 'pa':
        return 'ਤੇਜ਼ ਮਦਦ';
      default:
        return 'Instant Assist';
    }
  }

  String _getStoryLabel(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'कहानी';
      case 'mr':
        return 'कथा';
      case 'ta':
        return 'கதை';
      case 'te':
        return 'కథ';
      case 'kn':
        return 'ಕಥೆ';
      case 'ml':
        return 'കഥ';
      case 'gu':
        return 'વાર્તા';
      case 'bn':
        return 'গল্প';
      case 'pa':
        return 'ਕਹਾਣੀ';
      default:
        return 'Story';
    }
  }

  String _getWorksheetLabel(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'कार्यपत्रक';
      case 'mr':
        return 'कार्यपत्रिका';
      case 'ta':
        return 'பணிப்பத்திரம்';
      case 'te':
        return 'వర్క్‌షీట్';
      case 'kn':
        return 'ಕಾರ್ಯಪತ್ರಿಕೆ';
      case 'ml':
        return 'വർക്ക്ഷീറ്റ്';
      case 'gu':
        return 'કાર્યપત્રક';
      case 'bn':
        return 'ওয়ার্কশীট';
      case 'pa':
        return 'ਵਰਕਸ਼ੀਟ';
      default:
        return 'Worksheet';
    }
  }

  String _getQALabel(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'प्रश्न-उत्तर';
      case 'mr':
        return 'प्रश्न-उत्तर';
      case 'ta':
        return 'கேள்வி-பதில்';
      case 'te':
        return 'ప్రశ్న-సమాధానం';
      case 'kn':
        return 'ಪ್ರಶ್ನೆ-ಉತ್ತರ';
      case 'ml':
        return 'ചോദ്യം-ഉത്തരം';
      case 'gu':
        return 'પ્રશ્ન-ઉત્તર';
      case 'bn':
        return 'প্রশ্ন-উত্তর';
      case 'pa':
        return 'ਸਵਾਲ-ਜਵਾਬ';
      default:
        return 'Q&A';
    }
  }

  String _getVisualLabel(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'दृश्य';
      case 'mr':
        return 'दृश्य';
      case 'ta':
        return 'காட்சி';
      case 'te':
        return 'దృశ్య';
      case 'kn':
        return 'ದೃಶ್ಯ';
      case 'ml':
        return 'ദൃശ്യം';
      case 'gu':
        return 'દૃશ્ય';
      case 'bn':
        return 'ভিজ্যুয়াল';
      case 'pa':
        return 'ਦ੍ਰਿਸ਼';
      default:
        return 'Visual';
    }
  }

  String _getCreatingStoryMessage(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'कहानी निर्माता खोला जा रहा है...';
      case 'mr':
        return 'कथा निर्माता उघडला जात आहे...';
      case 'ta':
        return 'கதை உருவாக்கி திறக்கப்படுகிறது...';
      default:
        return 'Opening story creator...';
    }
  }

  String _getCreatingWorksheetMessage(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'कार्यपत्रक निर्माता खोला जा रहा है...';
      case 'mr':
        return 'कार्यपत्रिका निर्माता उघडला जात आहे...';
      case 'ta':
        return 'பணிப்பத்திர உருவாக்கி திறக்கப்படுகிறது...';
      default:
        return 'Opening worksheet creator...';
    }
  }

  String _getOpeningChatMessage(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'AI चैट खोला जा रहा है...';
      case 'mr':
        return 'AI चॅट उघडला जात आहे...';
      case 'ta':
        return 'AI அரட்டை திறக்கப்படுகிறது...';
      default:
        return 'Opening AI chat...';
    }
  }

  String _getCreatingVisualMessage(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'दृश्य निर्माता खोला जा रहा है...';
      case 'mr':
        return 'दृश्य निर्माता उघडला जात आहे...';
      case 'ta':
        return 'காட்சி உருவாக்கி திறக்கப்படுகிறது...';
      default:
        return 'Opening visual creator...';
    }
  }

  String _getOfflineMessage(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'इस सुविधा के लिए इंटरनेट कनेक्शन आवश्यक है';
      case 'mr':
        return 'या सुविधेसाठी इंटरनेट कनेक्शन आवश्यक आहे';
      case 'ta':
        return 'இந்த அம்சத்திற்கு இணைய இணைப்பு தேவை';
      default:
        return 'Internet connection required for this feature';
    }
  }
}

class _MiniFABData {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Offset offset;

  const _MiniFABData({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.offset,
  });
}
