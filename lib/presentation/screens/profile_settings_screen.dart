import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/responsive_layout.dart';
import '../bloc/app_bloc.dart';
import '../bloc/app_state.dart';
import '../bloc/app_event.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppBloc, AppState>(
      builder: (context, state) {
        final languageCode = state is AppLoaded ? state.languageCode : 'en';
        final isDark = state is AppLoaded ? state.isDarkMode : false;
        final isHighContrast =
            state is AppLoaded ? state.isHighContrast : false;

        return Scaffold(
          body: SingleChildScrollView(
            padding:
                EdgeInsets.all(ResponsiveLayout.getHorizontalPadding(context)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),

                // Profile Header
                _buildProfileHeader(context, languageCode),

                const SizedBox(height: 32),

                // Appearance Settings
                _buildAppearanceSettings(
                    context, languageCode, isDark, isHighContrast),

                const SizedBox(height: 24),

                // Language Settings
                _buildLanguageSettings(context, languageCode),

                const SizedBox(height: 24),

                // Teaching Settings
                _buildTeachingSettings(context, languageCode),

                const SizedBox(height: 24),

                // Account Settings
                _buildAccountSettings(context, languageCode),

                const SizedBox(height: 24),

                // About & Support
                _buildAboutSupport(context, languageCode),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader(BuildContext context, String languageCode) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(
                Icons.person,
                size: 40,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getTeacherName(languageCode),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getSchoolName(languageCode),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getGradeLevel(languageCode),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _editProfile(context, languageCode),
              icon: const Icon(Icons.edit),
              tooltip: _getEditProfileTooltip(languageCode),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppearanceSettings(BuildContext context, String languageCode,
      bool isDark, bool isHighContrast) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.palette,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  _getAppearanceTitle(languageCode),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
          SwitchListTile(
            title: Text(_getDarkModeTitle(languageCode)),
            subtitle: Text(_getDarkModeDescription(languageCode)),
            value: isDark,
            onChanged: (value) {
              context.read<AppBloc>().add(AppThemeToggled());
            },
            secondary: Icon(
              isDark ? Icons.dark_mode : Icons.light_mode,
            ),
          ),
          SwitchListTile(
            title: Text(_getHighContrastTitle(languageCode)),
            subtitle: Text(_getHighContrastDescription(languageCode)),
            value: isHighContrast,
            onChanged: (value) {
              context.read<AppBloc>().add(AppHighContrastToggled());
            },
            secondary: const Icon(Icons.contrast),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSettings(BuildContext context, String languageCode) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.language,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  _getLanguageTitle(languageCode),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
          ListTile(
            title: Text(_getCurrentLanguageTitle(languageCode)),
            subtitle: Text(_getLanguageName(languageCode)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showLanguageDialog(context, languageCode),
          ),
          ListTile(
            title: Text(_getTranslationTitle(languageCode)),
            subtitle: Text(_getTranslationDescription(languageCode)),
            trailing: Switch(
              value: true, // Assume translation is enabled
              onChanged: (value) => _toggleTranslation(value),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeachingSettings(BuildContext context, String languageCode) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.school,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  _getTeachingTitle(languageCode),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
          ListTile(
            title: Text(_getSubjectsTitle(languageCode)),
            subtitle: Text(_getSubjectsDescription(languageCode)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _editSubjects(context, languageCode),
          ),
          ListTile(
            title: Text(_getGradeLevelsTitle(languageCode)),
            subtitle: Text(_getGradeLevelsDescription(languageCode)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _editGradeLevels(context, languageCode),
          ),
          ListTile(
            title: Text(_getClassSizeTitle(languageCode)),
            subtitle: Text(_getClassSizeDescription(languageCode)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _editClassSize(context, languageCode),
          ),
          SwitchListTile(
            title: Text(_getOfflineModeTitle(languageCode)),
            subtitle: Text(_getOfflineModeDescription(languageCode)),
            value: false, // Assume offline mode is disabled
            onChanged: (value) => _toggleOfflineMode(value),
            secondary: const Icon(Icons.offline_bolt),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSettings(BuildContext context, String languageCode) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.account_circle,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  _getAccountTitle(languageCode),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
          ListTile(
            title: Text(_getDataBackupTitle(languageCode)),
            subtitle: Text(_getDataBackupDescription(languageCode)),
            leading: const Icon(Icons.backup),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _backupData(context, languageCode),
          ),
          ListTile(
            title: Text(_getExportDataTitle(languageCode)),
            subtitle: Text(_getExportDataDescription(languageCode)),
            leading: const Icon(Icons.download),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _exportData(context, languageCode),
          ),
          ListTile(
            title: Text(_getPrivacyTitle(languageCode)),
            subtitle: Text(_getPrivacyDescription(languageCode)),
            leading: const Icon(Icons.privacy_tip),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showPrivacySettings(context, languageCode),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSupport(BuildContext context, String languageCode) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.help,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  _getAboutSupportTitle(languageCode),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
          ListTile(
            title: Text(_getHelpTitle(languageCode)),
            subtitle: Text(_getHelpDescription(languageCode)),
            leading: const Icon(Icons.help_outline),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showHelp(context, languageCode),
          ),
          ListTile(
            title: Text(_getTutorialTitle(languageCode)),
            subtitle: Text(_getTutorialDescription(languageCode)),
            leading: const Icon(Icons.play_circle_outline),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showTutorial(context, languageCode),
          ),
          ListTile(
            title: Text(_getFeedbackTitle(languageCode)),
            subtitle: Text(_getFeedbackDescription(languageCode)),
            leading: const Icon(Icons.feedback),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _sendFeedback(context, languageCode),
          ),
          ListTile(
            title: Text(_getAboutTitle(languageCode)),
            subtitle: Text(_getVersionInfo(languageCode)),
            leading: const Icon(Icons.info),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showAbout(context, languageCode),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, String currentLanguageCode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_getSelectLanguageTitle(currentLanguageCode)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              'en',
              'hi',
              'mr',
              'ta',
              'te',
              'kn',
              'ml',
              'gu',
              'bn',
              'pa',
              'or',
              'as'
            ].map((langCode) {
              return RadioListTile<String>(
                title: Text(_getLanguageName(langCode)),
                value: langCode,
                groupValue: currentLanguageCode,
                onChanged: (value) {
                  if (value != null) {
                    context.read<AppBloc>().add(AppLanguageChanged(value));
                    Navigator.pop(context);
                  }
                },
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_getCancelLabel(currentLanguageCode)),
          ),
        ],
      ),
    );
  }

  // Action methods
  void _editProfile(BuildContext context, String languageCode) {
    // Edit profile logic
  }

  void _toggleTranslation(bool value) {
    // Toggle translation logic
  }

  void _editSubjects(BuildContext context, String languageCode) {
    // Edit subjects logic
  }

  void _editGradeLevels(BuildContext context, String languageCode) {
    // Edit grade levels logic
  }

  void _editClassSize(BuildContext context, String languageCode) {
    // Edit class size logic
  }

  void _toggleOfflineMode(bool value) {
    // Toggle offline mode logic
  }

  void _backupData(BuildContext context, String languageCode) {
    // Backup data logic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_getBackupStartedMessage(languageCode))),
    );
  }

  void _exportData(BuildContext context, String languageCode) {
    // Export data logic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_getExportStartedMessage(languageCode))),
    );
  }

  void _showPrivacySettings(BuildContext context, String languageCode) {
    // Show privacy settings
  }

  void _showHelp(BuildContext context, String languageCode) {
    // Show help
  }

  void _showTutorial(BuildContext context, String languageCode) {
    // Show tutorial
  }

  void _sendFeedback(BuildContext context, String languageCode) {
    // Send feedback
  }

  void _showAbout(BuildContext context, String languageCode) {
    showAboutDialog(
      context: context,
      applicationName: _getAppName(languageCode),
      applicationVersion: '1.0.0',
      applicationIcon: Icon(
        Icons.school,
        size: 64,
        color: Theme.of(context).colorScheme.primary,
      ),
      children: [
        Text(_getAboutDescription(languageCode)),
      ],
    );
  }

  // Localization methods
  String _getTeacherName(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'राज कुमार शर्मा';
      case 'mr':
        return 'राज कुमार शर्मा';
      case 'ta':
        return 'ராஜ் குமார் சர்மா';
      default:
        return 'Raj Kumar Sharma';
    }
  }

  String _getSchoolName(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'सरस्वती विद्यालय';
      case 'mr':
        return 'सरस्वती विद्यालय';
      case 'ta':
        return 'சரஸ்வதி பள்ளி';
      default:
        return 'Saraswati School';
    }
  }

  String _getGradeLevel(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'कक्षा 4-6 के शिक्षक';
      case 'mr':
        return 'इयत्ता 4-6 चे शिक्षक';
      case 'ta':
        return '4-6 வகுப்பு ஆசிரியர்';
      default:
        return 'Grade 4-6 Teacher';
    }
  }

  String _getEditProfileTooltip(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'प्रोफ़ाइल संपादित करें';
      case 'mr':
        return 'प्रोफाइल संपादित करा';
      case 'ta':
        return 'சுயவிவரத்தைத் திருத்து';
      default:
        return 'Edit profile';
    }
  }

  String _getAppearanceTitle(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'दिखावट';
      case 'mr':
        return 'दिसणे';
      case 'ta':
        return 'தோற்றம்';
      default:
        return 'Appearance';
    }
  }

  String _getDarkModeTitle(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'डार्क मोड';
      case 'mr':
        return 'डार्क मोड';
      case 'ta':
        return 'இருண்ட பயன்முறை';
      default:
        return 'Dark Mode';
    }
  }

  String _getDarkModeDescription(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'आंखों के लिए आरामदायक गहरे रंग का थीम';
      case 'mr':
        return 'डोळ्यांसाठी आरामदायक गडद रंगाची थीम';
      case 'ta':
        return 'கண்களுக்கு வசதியான இருண்ட நிற தீம்';
      default:
        return 'Comfortable dark theme for your eyes';
    }
  }

  String _getHighContrastTitle(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'उच्च कंट्रास्ट';
      case 'mr':
        return 'उच्च कॉन्ट्रास्ट';
      case 'ta':
        return 'உயர் நிறமாறுபாடு';
      default:
        return 'High Contrast';
    }
  }

  String _getHighContrastDescription(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'बेहतर दृश्यता के लिए उच्च कंट्रास्ट';
      case 'mr':
        return 'चांगल्या दृश्यतेसाठी उच्च कॉन्ट्रास्ट';
      case 'ta':
        return 'சிறந்த பார்வைக்கு உயர் நிறமாறுபाடு';
      default:
        return 'High contrast for better visibility';
    }
  }

  String _getLanguageTitle(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'भाषा';
      case 'mr':
        return 'भाषा';
      case 'ta':
        return 'மொழி';
      default:
        return 'Language';
    }
  }

  String _getCurrentLanguageTitle(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'वर्तमान भाषा';
      case 'mr':
        return 'सध्याची भाषा';
      case 'ta':
        return 'தற்போதைய மொழி';
      default:
        return 'Current Language';
    }
  }

  String _getLanguageName(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'हिंदी';
      case 'mr':
        return 'मराठी';
      case 'ta':
        return 'தமிழ்';
      case 'te':
        return 'తెలుగు';
      case 'kn':
        return 'ಕನ್ನಡ';
      case 'ml':
        return 'മലയാളം';
      case 'gu':
        return 'ગુજરાતી';
      case 'bn':
        return 'বাংলা';
      case 'pa':
        return 'ਪੰਜਾਬੀ';
      case 'or':
        return 'ଓଡ଼ିଆ';
      case 'as':
        return 'অসমীয়া';
      default:
        return 'English';
    }
  }

  String _getTranslationTitle(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'स्वचालित अनुवाद';
      case 'mr':
        return 'स्वयंचलित भाषांतर';
      case 'ta':
        return 'தானியங்கு மொழிபெயர்ப்பு';
      default:
        return 'Auto Translation';
    }
  }

  String _getTranslationDescription(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'AI की मदद से सामग्री का अनुवाद';
      case 'mr':
        return 'AI च्या मदतीने सामग्रीचे भाषांतर';
      case 'ta':
        return 'AI உதவியுடன் உள்ளடக்க மொழிபெயர்ப்பு';
      default:
        return 'AI-powered content translation';
    }
  }

  String _getTeachingTitle(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'शिक्षण सेटिंग्स';
      case 'mr':
        return 'शिक्षण सेटिंग्ज';
      case 'ta':
        return 'கற்பித்தல் அமைப்புகள்';
      default:
        return 'Teaching Settings';
    }
  }

  String _getSubjectsTitle(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'पढ़ाए जाने वाले विषय';
      case 'mr':
        return 'शिकवले जाणारे विषय';
      case 'ta':
        return 'கற்பிக்கப்படும் பாடங்கள்';
      default:
        return 'Subjects Taught';
    }
  }

  String _getSubjectsDescription(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'गणित, विज्ञान, अंग्रेजी';
      case 'mr':
        return 'गणित, विज्ञान, इंग्रजी';
      case 'ta':
        return 'கணிதம், அறிவியல், ஆங்கிலம்';
      default:
        return 'Math, Science, English';
    }
  }

  String _getGradeLevelsTitle(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'कक्षा स्तर';
      case 'mr':
        return 'इयत्ता स्तर';
      case 'ta':
        return 'வகுப்பு நிலைகள்';
      default:
        return 'Grade Levels';
    }
  }

  String _getGradeLevelsDescription(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'कक्षा 4, 5, 6';
      case 'mr':
        return 'इयत्ता 4, 5, 6';
      case 'ta':
        return '4, 5, 6 ஆம் வகுப்பு';
      default:
        return 'Grade 4, 5, 6';
    }
  }

  String _getClassSizeTitle(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'कक्षा का आकार';
      case 'mr':
        return 'वर्गाचा आकार';
      case 'ta':
        return 'வகுப்பு அளவு';
      default:
        return 'Class Size';
    }
  }

  String _getClassSizeDescription(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return '25-30 छात्र';
      case 'mr':
        return '25-30 विद्यार्थी';
      case 'ta':
        return '25-30 மாணவர்கள்';
      default:
        return '25-30 students';
    }
  }

  String _getOfflineModeTitle(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'ऑफलाइन मोड';
      case 'mr':
        return 'ऑफलाइन मोड';
      case 'ta':
        return 'ஆஃப்லைன் பயன்முறை';
      default:
        return 'Offline Mode';
    }
  }

  String _getOfflineModeDescription(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'इंटरनेट के बिना बुनियादी सुविधाएं';
      case 'mr':
        return 'इंटरनेटशिवाय मूलभूत सुविधा';
      case 'ta':
        return 'இணையம் இல்லாமல் அடிப்படை வசதிகள்';
      default:
        return 'Basic features without internet';
    }
  }

  String _getAccountTitle(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'खाता सेटिंग्स';
      case 'mr':
        return 'खाते सेटिंग्ज';
      case 'ta':
        return 'கணக்கு அமைப்புகள்';
      default:
        return 'Account Settings';
    }
  }

  String _getDataBackupTitle(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'डेटा बैकअप';
      case 'mr':
        return 'डेटा बॅकअप';
      case 'ta':
        return 'தரவு காப்பு';
      default:
        return 'Data Backup';
    }
  }

  String _getDataBackupDescription(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'अपने डेटा का सुरक्षित बैकअप लें';
      case 'mr':
        return 'तुमच्या डेटाचा सुरक्षित बॅकअप घ्या';
      case 'ta':
        return 'உங்கள் தரவின் பாதுகாப்பான காப்புப்பிரதி';
      default:
        return 'Secure backup of your data';
    }
  }

  String _getExportDataTitle(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'डेटा निर्यात';
      case 'mr':
        return 'डेटा निर्यात';
      case 'ta':
        return 'தரவு ஏற்றுமதி';
      default:
        return 'Export Data';
    }
  }

  String _getExportDataDescription(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'अपना डेटा PDF/Excel में निर्यात करें';
      case 'mr':
        return 'तुमचा डेटा PDF/Excel मध्ये निर्यात करा';
      case 'ta':
        return 'உங்கள் தரவை PDF/Excel இல் ஏற்றுமதி செய்யுங்கள்';
      default:
        return 'Export your data to PDF/Excel';
    }
  }

  String _getPrivacyTitle(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'गोपनीयता';
      case 'mr':
        return 'गोपनीयता';
      case 'ta':
        return 'தனியுரிமை';
      default:
        return 'Privacy';
    }
  }

  String _getPrivacyDescription(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'गोपनीयता सेटिंग्स और डेटा नियंत्रण';
      case 'mr':
        return 'गोपनीयता सेटिंग्ज आणि डेटा नियंत्रण';
      case 'ta':
        return 'தனியுரிமை அமைப்புகள் மற்றும் தரவு கட்டுப்பாடு';
      default:
        return 'Privacy settings and data control';
    }
  }

  String _getAboutSupportTitle(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'सहायता और जानकारी';
      case 'mr':
        return 'मदत आणि माहिती';
      case 'ta':
        return 'உதவி மற்றும் தகவல்';
      default:
        return 'Help & Information';
    }
  }

  String _getHelpTitle(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'सहायता केंद्र';
      case 'mr':
        return 'मदत केंद्र';
      case 'ta':
        return 'உதவி மையம்';
      default:
        return 'Help Center';
    }
  }

  String _getHelpDescription(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'अक्सर पूछे जाने वाले प्रश्न और गाइड';
      case 'mr':
        return 'वारंवार विचारले जाणारे प्रश्न आणि गाइड';
      case 'ta':
        return 'அடிக்கடி கேட்கப்படும் கேள்விகள் மற்றும் வழிகாட்டி';
      default:
        return 'FAQs and guides';
    }
  }

  String _getTutorialTitle(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'ट्यूटोरियल';
      case 'mr':
        return 'ट्यूटोरियल';
      case 'ta':
        return 'பயிற்சி';
      default:
        return 'Tutorial';
    }
  }

  String _getTutorialDescription(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'ऐप का उपयोग कैसे करें';
      case 'mr':
        return 'अॅपचा वापर कसा करावा';
      case 'ta':
        return 'ஆப்ஸை எப்படி பயன்படுத்துவது';
      default:
        return 'How to use the app';
    }
  }

  String _getFeedbackTitle(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'फीडबैक भेजें';
      case 'mr':
        return 'फीडबॅक पाठवा';
      case 'ta':
        return 'கருத்து அனுப்பவும்';
      default:
        return 'Send Feedback';
    }
  }

  String _getFeedbackDescription(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'अपने सुझाव और समस्याएं साझा करें';
      case 'mr':
        return 'तुमच्या सूचना आणि समस्या सामायिक करा';
      case 'ta':
        return 'உங்கள் ஆலோசனைகள் மற்றும் பிரச்சினைகளைப் பகிரவும்';
      default:
        return 'Share your suggestions and issues';
    }
  }

  String _getAboutTitle(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'ऐप के बारे में';
      case 'mr':
        return 'अॅपबद्दल';
      case 'ta':
        return 'ஆப்ஸைப் பற்றி';
      default:
        return 'About App';
    }
  }

  String _getVersionInfo(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'संस्करण 1.0.0';
      case 'mr':
        return 'आवृत्ती 1.0.0';
      case 'ta':
        return 'பதிப்பு 1.0.0';
      default:
        return 'Version 1.0.0';
    }
  }

  String _getSelectLanguageTitle(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'भाषा चुनें';
      case 'mr':
        return 'भाषा निवडा';
      case 'ta':
        return 'மொழியைத் தேர்ந்தெடுங்கள்';
      default:
        return 'Select Language';
    }
  }

  String _getCancelLabel(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'रद्द करें';
      case 'mr':
        return 'रद्द करा';
      case 'ta':
        return 'ரத்து செய்';
      default:
        return 'Cancel';
    }
  }

  String _getBackupStartedMessage(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'बैकअप शुरू किया गया...';
      case 'mr':
        return 'बॅकअप सुरू केला...';
      case 'ta':
        return 'காப்புப்பிரதி தொடங்கப்பட்டது...';
      default:
        return 'Backup started...';
    }
  }

  String _getExportStartedMessage(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'निर्यात शुरू किया गया...';
      case 'mr':
        return 'निर्यात सुरू केला...';
      case 'ta':
        return 'ஏற்றுமதி தொடங்கப்பட்டது...';
      default:
        return 'Export started...';
    }
  }

  String _getAppName(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'साहायक';
      case 'mr':
        return 'साहायक';
      case 'ta':
        return 'சஹாயக்';
      default:
        return 'Sahayak';
    }
  }

  String _getAboutDescription(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'साहायक एक AI-संचालित शिक्षण सहायक है जो शिक्षकों को बेहतर शैक्षिक सामग्री बनाने में मदद करता है।';
      case 'mr':
        return 'साहायक हा एक AI-चालित शिक्षण सहाय्यक आहे जो शिक्षकांना चांगली शैक्षणिक सामग्री तयार करण्यात मदत करतो।';
      case 'ta':
        return 'சஹாயக் ஒரு AI-இயங்கும் கற்பித்தல் உதவியாளர் ஆகும், இது ஆசிரியர்களுக்கு சிறந்த கல்வி உள்ளடக்கத்தை உருவாக்க உதவுகிறது.';
      default:
        return 'Sahayak is an AI-powered teaching assistant that helps teachers create better educational content.';
    }
  }
}
