import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/responsive_layout.dart';
import '../../core/localization/app_locales.dart';
import '../bloc/app_bloc.dart';
import '../bloc/app_event.dart';
import '../bloc/app_state.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppBloc, AppState>(
      builder: (context, state) {
        final isLoaded = state is AppLoaded;
        final currentLanguage = isLoaded ? state.languageCode : 'en';
        final isDarkMode = isLoaded ? state.isDarkMode : false;
        final isHighContrast = isLoaded ? state.isHighContrast : false;

        return Scaffold(
          appBar: AppBar(
            title: Text(_getGreeting(currentLanguage)),
            elevation: 0,
            actions: [
              // Language selector
              PopupMenuButton<String>(
                icon: const Icon(Icons.language),
                onSelected: (languageCode) {
                  context.read<AppBloc>().add(LanguageChanged(languageCode));
                },
                itemBuilder: (context) => SahayakLocales.supportedLocales
                    .map((locale) => PopupMenuItem<String>(
                          value: locale.languageCode,
                          child: Text(
                            SahayakLocales.getLanguageName(locale.languageCode),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ))
                    .toList(),
              ),
              // Theme toggle
              IconButton(
                icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
                onPressed: () {
                  context.read<AppBloc>().add(ThemeChanged(!isDarkMode));
                },
              ),
              // High contrast toggle
              IconButton(
                icon: Icon(
                  isHighContrast ? Icons.contrast : Icons.contrast_outlined,
                ),
                onPressed: () {
                  context
                      .read<AppBloc>()
                      .add(HighContrastToggled(!isHighContrast));
                },
              ),
            ],
          ),
          body: ResponsiveLayout.adaptive(
            context: context,
            mobile: _buildMobileLayout(context, currentLanguage),
            tablet: _buildTabletLayout(context, currentLanguage),
            desktop: _buildDesktopLayout(context, currentLanguage),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              // Navigate to chat or voice input
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_getActionText(currentLanguage)),
                  action: SnackBarAction(
                    label: _getOkText(currentLanguage),
                    onPressed: () {},
                  ),
                ),
              );
            },
            icon: const Icon(Icons.chat),
            label: Text(_getStartChatText(currentLanguage)),
          ),
        );
      },
    );
  }

  Widget _buildMobileLayout(BuildContext context, String languageCode) {
    return SingleChildScrollView(
      padding: ResponsiveLayout.getScreenPadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeCard(context, languageCode),
          const SizedBox(height: 24),
          _buildFeatureGrid(context, languageCode, crossAxisCount: 2),
          const SizedBox(height: 24),
          _buildRecentActivities(context, languageCode),
        ],
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context, String languageCode) {
    return SingleChildScrollView(
      padding: ResponsiveLayout.getScreenPadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeCard(context, languageCode),
          const SizedBox(height: 32),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child:
                    _buildFeatureGrid(context, languageCode, crossAxisCount: 2),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 1,
                child: _buildRecentActivities(context, languageCode),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, String languageCode) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: ResponsiveLayout.getMaxContentWidth(context),
        ),
        child: SingleChildScrollView(
          padding: ResponsiveLayout.getScreenPadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeCard(context, languageCode),
              const SizedBox(height: 40),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: _buildFeatureGrid(context, languageCode,
                        crossAxisCount: 3),
                  ),
                  const SizedBox(width: 32),
                  Expanded(
                    flex: 1,
                    child: _buildRecentActivities(context, languageCode),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context, String languageCode) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.assistant,
                  size: ResponsiveLayout.getIconSize(context, baseSize: 48),
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getWelcomeTitle(languageCode),
                        style: theme.textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getWelcomeSubtitle(languageCode),
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.mic),
              label: Text(_getVoiceInputText(languageCode)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureGrid(BuildContext context, String languageCode,
      {required int crossAxisCount}) {
    final features = _getFeatures(languageCode);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _getFeaturesTitle(languageCode),
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.2,
          ),
          itemCount: features.length,
          itemBuilder: (context, index) {
            final feature = features[index];
            return Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {},
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        feature['icon'] as IconData,
                        size:
                            ResponsiveLayout.getIconSize(context, baseSize: 32),
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        feature['title'] as String,
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        feature['description'] as String,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.7),
                            ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecentActivities(BuildContext context, String languageCode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _getRecentActivitiesTitle(languageCode),
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        Card(
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 3,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  child: Icon(
                    Icons.chat_bubble_outline,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                title: Text(_getActivityTitle(languageCode, index)),
                subtitle: Text(_getActivityTime(languageCode)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              );
            },
          ),
        ),
      ],
    );
  }

  // Localization methods
  String _getGreeting(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'नमस्ते - साहायक';
      case 'mr':
        return 'नमस्कार - साहायक';
      case 'ta':
        return 'வணக்கம் - सहायक';
      case 'te':
        return 'నమస్కారం - सहायक';
      case 'kn':
        return 'ನಮಸ್ಕಾರ - सहायक';
      case 'ml':
        return 'നമസ്കാരം - सहायक';
      case 'gu':
        return 'નમસ્તે - સાહાયક';
      case 'bn':
        return 'নমস্কার - সাহায্যক';
      case 'pa':
        return 'ਸਤ ਸ੍ਰੀ ਅਕਾਲ - ਸਹਾਇਕ';
      default:
        return 'Sahayak - Your AI Assistant';
    }
  }

  String _getWelcomeTitle(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'साहायक में आपका स्वागत है';
      case 'mr':
        return 'साहायकमध्ये आपले स्वागत आहे';
      case 'ta':
        return 'சஹாயக்கில் உங்களை வரவேற்கிறோம்';
      default:
        return 'Welcome to Sahayak';
    }
  }

  String _getWelcomeSubtitle(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'आपका व्यक्तिगत AI शिक्षा सहायक';
      case 'mr':
        return 'तुमचा वैयक्तिक AI शिक्षण सहायक';
      case 'ta':
        return 'உங்கள் தனிப்பட்ட AI கல்வி உதவியாளர்';
      default:
        return 'Your Personal AI Learning Assistant';
    }
  }

  String _getVoiceInputText(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'आवाज़ से पूछें';
      case 'mr':
        return 'आवाजाने विचारा';
      case 'ta':
        return 'குரல் மூலம் கேளுங்கள்';
      default:
        return 'Ask with Voice';
    }
  }

  String _getFeaturesTitle(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'मुख्य सुविधाएं';
      case 'mr':
        return 'मुख्य वैशिष्ट्ये';
      case 'ta':
        return 'முக்கிய அம்சங்கள்';
      default:
        return 'Key Features';
    }
  }

  String _getRecentActivitiesTitle(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'हाल की गतिविधियां';
      case 'mr':
        return 'अलीकडील गतिविधी';
      case 'ta':
        return 'சமீபத்திய செயல்பாடுகள்';
      default:
        return 'Recent Activities';
    }
  }

  String _getStartChatText(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'बातचीत शुरू करें';
      case 'mr':
        return 'संभाषण सुरू करा';
      case 'ta':
        return 'அரட்டை தொடங்கவும்';
      default:
        return 'Start Chat';
    }
  }

  String _getActionText(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'चैट सुविधा जल्द आ रही है!';
      case 'mr':
        return 'चॅट वैशिष्ट्य लवकरच येत आहे!';
      case 'ta':
        return 'அரட்டை அம்சம் விரைவில் வருகிறது!';
      default:
        return 'Chat feature coming soon!';
    }
  }

  String _getOkText(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'ठीक है';
      case 'mr':
        return 'ठीक आहे';
      case 'ta':
        return 'சரி';
      default:
        return 'OK';
    }
  }

  String _getActivityTitle(String languageCode, int index) {
    final titles = {
      'en': [
        'Math Problem Solved',
        'Science Quiz Completed',
        'Reading Assignment'
      ],
      'hi': [
        'गणित की समस्या हल की',
        'विज्ञान प्रश्नोत्तरी पूरी की',
        'पठन असाइनमेंट'
      ],
      'mr': [
        'गणित समस्या सोडवली',
        'विज्ञान प्रश्नमंजुषा पूर्ण केली',
        'वाचन कार्य'
      ],
      'ta': [
        'கணித பிரச்சனை தீர்வு',
        'அறிவியல் வினாடி வினா முடிந்தது',
        'வாசிப்பு பணி'
      ],
    };
    return titles[languageCode]?[index] ?? titles['en']![index];
  }

  String _getActivityTime(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return '2 घंटे पहले';
      case 'mr':
        return '2 तासांपूर्वी';
      case 'ta':
        return '2 மணி நேரம் முன்பு';
      default:
        return '2 hours ago';
    }
  }

  List<Map<String, dynamic>> _getFeatures(String languageCode) {
    return [
      {
        'icon': Icons.quiz,
        'title': languageCode == 'hi'
            ? 'प्रश्नोत्तरी'
            : languageCode == 'mr'
                ? 'प्रश्नमंजुषा'
                : languageCode == 'ta'
                    ? 'வினாடி வினா'
                    : 'Quiz',
        'description': languageCode == 'hi'
            ? 'इंटरैक्टिव प्रश्न'
            : languageCode == 'mr'
                ? 'परस्पर प्रश्न'
                : languageCode == 'ta'
                    ? 'ஊடாடும் கேள்விகள்'
                    : 'Interactive Questions',
      },
      {
        'icon': Icons.book,
        'title': languageCode == 'hi'
            ? 'अध्ययन सामग्री'
            : languageCode == 'mr'
                ? 'अभ्यास साहित्य'
                : languageCode == 'ta'
                    ? 'படிப்பு பொருள்'
                    : 'Study Material',
        'description': languageCode == 'hi'
            ? 'विषयवार सामग्री'
            : languageCode == 'mr'
                ? 'विषयनिहाय साहित्य'
                : languageCode == 'ta'
                    ? 'பாடம் வாரியான உள்ளடக்கம்'
                    : 'Subject-wise Content',
      },
      {
        'icon': Icons.assignment,
        'title': languageCode == 'hi'
            ? 'असाइनमेंट'
            : languageCode == 'mr'
                ? 'कार्य'
                : languageCode == 'ta'
                    ? 'பணிகள்'
                    : 'Assignments',
        'description': languageCode == 'hi'
            ? 'दैनिक कार्य'
            : languageCode == 'mr'
                ? 'दैनंदिन कार्य'
                : languageCode == 'ta'
                    ? 'தினசரி பணிகள்'
                    : 'Daily Tasks',
      },
      {
        'icon': Icons.group,
        'title': languageCode == 'hi'
            ? 'सहयोग'
            : languageCode == 'mr'
                ? 'सहकार्य'
                : languageCode == 'ta'
                    ? 'ஒத்துழைப்பு'
                    : 'Collaboration',
        'description': languageCode == 'hi'
            ? 'समूह अध्ययन'
            : languageCode == 'mr'
                ? 'सामूहिक अभ्यास'
                : languageCode == 'ta'
                    ? 'குழு படிப்பு'
                    : 'Group Study',
      },
    ];
  }
}
