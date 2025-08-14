import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../core/theme/responsive_layout.dart';
import '../bloc/app_bloc.dart';
import '../bloc/app_state.dart';
import '../bloc/chat/chat_bloc.dart';
import '../screens/enhanced_dashboard_screen.dart';
import '../screens/create_content_screen.dart';
import '../screens/enhanced_intelligent_chat_screen.dart';
import '../screens/lesson_planner_screen.dart';
import '../screens/profile_settings_screen.dart';
import '../widgets/enhanced_instant_assist_fab_v2.dart';
import '../widgets/offline_indicator.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  late PageController _pageController;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;

  // Connectivity state
  late Stream<List<ConnectivityResult>> _connectivityStream;
  bool _isOnline = true;

  // Tab preservation states
  final Map<int, GlobalKey<NavigatorState>> _navigatorKeys = {
    0: GlobalKey<NavigatorState>(),
    1: GlobalKey<NavigatorState>(),
    2: GlobalKey<NavigatorState>(),
    3: GlobalKey<NavigatorState>(),
    4: GlobalKey<NavigatorState>(),
  };

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimation = CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeInOut,
    );
    _fabAnimationController.forward();

    // Initialize connectivity monitoring
    _connectivityStream = Connectivity().onConnectivityChanged;
    _checkInitialConnectivity();
    _listenToConnectivity();
  }

  void _checkInitialConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    setState(() {
      _isOnline = !result.contains(ConnectivityResult.none);
    });
  }

  void _listenToConnectivity() {
    _connectivityStream.listen((List<ConnectivityResult> result) {
      setState(() {
        _isOnline = !result.contains(ConnectivityResult.none);
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (_currentIndex != index) {
      setState(() {
        _currentIndex = index;
      });

      // Smooth page transition
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );

      // Haptic feedback for accessibility
      if (ResponsiveLayout.isMobile(context)) {
        // Add haptic feedback on mobile
      }
    }
  }

  Widget _buildTabNavigator(int index, Widget child) {
    return Navigator(
      key: _navigatorKeys[index],
      onGenerateRoute: (routeSettings) {
        return MaterialPageRoute(
          builder: (context) => child,
          settings: routeSettings,
        );
      },
    );
  }

  List<NavigationDestination> _getNavigationDestinations(String languageCode) {
    return [
      NavigationDestination(
        icon: const Icon(Icons.dashboard_outlined),
        selectedIcon: const Icon(Icons.dashboard),
        label: _getDashboardLabel(languageCode),
        tooltip: _getDashboardTooltip(languageCode),
      ),
      NavigationDestination(
        icon: const Icon(Icons.add_circle_outline),
        selectedIcon: const Icon(Icons.add_circle),
        label: _getCreateLabel(languageCode),
        tooltip: _getCreateTooltip(languageCode),
      ),
      NavigationDestination(
        icon: const Icon(Icons.chat_bubble_outline),
        selectedIcon: const Icon(Icons.chat_bubble),
        label: _getQALabel(languageCode),
        tooltip: _getQATooltip(languageCode),
      ),
      NavigationDestination(
        icon: const Icon(Icons.calendar_today_outlined),
        selectedIcon: const Icon(Icons.calendar_today),
        label: _getLessonLabel(languageCode),
        tooltip: _getLessonTooltip(languageCode),
      ),
      NavigationDestination(
        icon: const Icon(Icons.person_outline),
        selectedIcon: const Icon(Icons.person),
        label: _getProfileLabel(languageCode),
        tooltip: _getProfileTooltip(languageCode),
      ),
    ];
  }

  List<Widget> _buildPages() {
    return [
      _buildTabNavigator(0, const EnhancedDashboardScreen()),
      _buildTabNavigator(1, const CreateContentScreen()),
      _buildTabNavigator(
          2,
          BlocProvider(
            create: (context) => ChatBloc(),
            child: const EnhancedIntelligentChatScreen(),
          )),
      _buildTabNavigator(3, const LessonPlannerScreen()),
      _buildTabNavigator(4, const ProfileSettingsScreen()),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppBloc, AppState>(
      builder: (context, state) {
        final languageCode = state is AppLoaded ? state.languageCode : 'en';

        return Scaffold(
          appBar: AppBar(
            title: Text(_getAppTitle(languageCode)),
            actions: [
              // Offline indicator
              if (!_isOnline) OfflineIndicator(languageCode: languageCode),

              // Additional app bar actions can be added here
              const SizedBox(width: 8),
            ],
          ),
          body: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            children: _buildPages(),
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: _onTabTapped,
              destinations: _getNavigationDestinations(languageCode),
              height: ResponsiveLayout.isMobile(context) ? 80 : 90,
              elevation: 0,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              animationDuration: const Duration(milliseconds: 300),
            ),
          ),
          floatingActionButton: ScaleTransition(
            scale: _fabAnimation,
            child: EnhancedInstantAssistFAB(
              languageCode: languageCode,
              isOnline: _isOnline,
            ),
          ),
          floatingActionButtonLocation: _getFABLocation(),
        );
      },
    );
  }

  FloatingActionButtonLocation _getFABLocation() {
    // Position FAB for optimal thumb reach on mobile
    if (ResponsiveLayout.isMobile(context)) {
      return FloatingActionButtonLocation.endFloat;
    } else {
      return FloatingActionButtonLocation.endFloat;
    }
  }

  // Localization methods for navigation labels
  String _getAppTitle(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'साहायक';
      case 'mr':
        return 'साहायक';
      case 'ta':
        return 'சஹாயக்';
      case 'te':
        return 'సహాయక్';
      case 'kn':
        return 'ಸಹಾಯಕ';
      case 'ml':
        return 'സഹായക്';
      case 'gu':
        return 'સાહાયક';
      case 'bn':
        return 'সাহায্যক';
      case 'pa':
        return 'ਸਹਾਇਕ';
      default:
        return 'Sahayak';
    }
  }

  String _getDashboardLabel(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'डैशबोर्ड';
      case 'mr':
        return 'डॅशबोर्ड';
      case 'ta':
        return 'முகப்பு';
      case 'te':
        return 'డాష్‌బోర్డ్';
      case 'kn':
        return 'ಡ್ಯಾಶ್‌ಬೋರ್ಡ್';
      case 'ml':
        return 'ഡാഷ്‌ബോർഡ്';
      case 'gu':
        return 'ડેશબોર્ડ';
      case 'bn':
        return 'ড্যাশবোর্ড';
      case 'pa':
        return 'ਡੈਸ਼ਬੋਰਡ';
      default:
        return 'Dashboard';
    }
  }

  String _getCreateLabel(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'बनाएं';
      case 'mr':
        return 'तयार करा';
      case 'ta':
        return 'உருவாக்கு';
      case 'te':
        return 'సృష్టించు';
      case 'kn':
        return 'ಸೃಷ್ಟಿಸು';
      case 'ml':
        return 'സൃഷ്ടിക്കുക';
      case 'gu':
        return 'બનાવો';
      case 'bn':
        return 'তৈরি করুন';
      case 'pa':
        return 'ਬਣਾਓ';
      default:
        return 'Create';
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

  String _getLessonLabel(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'पाठ योजना';
      case 'mr':
        return 'धडा योजना';
      case 'ta':
        return 'பாட திட்டம்';
      case 'te':
        return 'పాఠ ప్రణాళిక';
      case 'kn':
        return 'ಪಾಠ ಯೋಜನೆ';
      case 'ml':
        return 'പാഠ പദ്ധതി';
      case 'gu':
        return 'પાઠ યોજના';
      case 'bn':
        return 'পাঠ পরিকল্পনা';
      case 'pa':
        return 'ਪਾਠ ਯੋਜਨਾ';
      default:
        return 'Lessons';
    }
  }

  String _getProfileLabel(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'प्रोफ़ाइल';
      case 'mr':
        return 'प्रोफाइल';
      case 'ta':
        return 'சுயவிவரம்';
      case 'te':
        return 'ప్రొఫైల్';
      case 'kn':
        return 'ಪ್ರೊಫೈಲ್';
      case 'ml':
        return 'പ്രൊഫൈൽ';
      case 'gu':
        return 'પ્રોફાઇલ';
      case 'bn':
        return 'প্রোফাইল';
      case 'pa':
        return 'ਪ੍ਰੋਫਾਈਲ';
      default:
        return 'Profile';
    }
  }

  // Tooltip methods for accessibility
  String _getDashboardTooltip(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'मुख्य डैशबोर्ड देखें';
      case 'mr':
        return 'मुख्य डॅशबोर्ड पहा';
      case 'ta':
        return 'முக்கிய முகப்பைப் பார்க்கவும்';
      default:
        return 'View main dashboard';
    }
  }

  String _getCreateTooltip(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'नई सामग्री बनाएं';
      case 'mr':
        return 'नवीन सामग्री तयार करा';
      case 'ta':
        return 'புதிய உள்ளடக்கத்தை உருவாக்கவும்';
      default:
        return 'Create new content';
    }
  }

  String _getQATooltip(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'प्रश्न पूछें और उत्तर पाएं';
      case 'mr':
        return 'प्रश्न विचारा आणि उत्तर मिळवा';
      case 'ta':
        return 'கேள்விகள் கேட்டு பதில் பெறுங்கள்';
      default:
        return 'Ask questions and get answers';
    }
  }

  String _getLessonTooltip(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'पाठ योजना देखें और बनाएं';
      case 'mr':
        return 'धडा योजना पहा आणि तयार करा';
      case 'ta':
        return 'பாட திட்டங்களைப் பார்க்கவும் உருவாக்கவும்';
      default:
        return 'View and create lesson plans';
    }
  }

  String _getProfileTooltip(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'प्रोफ़ाइल और सेटिंग्स';
      case 'mr':
        return 'प्रोफाइल आणि सेटिंग्ज';
      case 'ta':
        return 'சுயவிவரம் மற்றும் அமைப்புகள்';
      default:
        return 'Profile and settings';
    }
  }
}
