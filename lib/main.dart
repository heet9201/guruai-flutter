import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme/app_theme.dart';
import 'core/localization/app_locales.dart';
import 'core/di/injection_container.dart' as di;
import 'core/services/service_locator.dart';
import 'core/accessibility/accessibility_manager.dart';
import 'presentation/bloc/app_bloc.dart';
import 'presentation/bloc/app_event.dart';
import 'presentation/bloc/app_state.dart';
import 'presentation/screens/auth_wrapper.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/register_screen.dart';
import 'presentation/navigation/main_navigation_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize dependency injection
  await di.initializeDependencies();

  // Initialize API services
  ServiceLocator.setup();

  runApp(const SahayakApp());
}

class SahayakApp extends StatelessWidget {
  const SahayakApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AppBloc()..add(AppStarted()),
      child: BlocBuilder<AppBloc, AppState>(
        builder: (context, state) {
          // Get current language and theme settings
          final languageCode = state is AppLoaded ? state.languageCode : 'en';
          final isDarkMode = state is AppLoaded ? state.isDarkMode : false;
          final isHighContrast =
              state is AppLoaded ? state.isHighContrast : false;

          return MaterialApp(
            title: 'Sahayak - साहायक',
            debugShowCheckedModeBanner: false,
            theme: isHighContrast
                ? AppTheme.accessibleTheme(
                    languageCode: languageCode,
                    isDark: false,
                    isHighContrast: true,
                  )
                : AppTheme.lightTheme(languageCode: languageCode),
            darkTheme: isHighContrast
                ? AppTheme.accessibleDarkTheme(
                    languageCode: languageCode,
                    isHighContrast: true,
                  )
                : AppTheme.darkTheme(languageCode: languageCode),
            themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: SahayakLocales.supportedLocales,
            locale: SahayakLocales.getLocale(languageCode),
            builder: (context, child) {
              // Initialize accessibility manager with current context
              AccessibilityManager.initialize(context);
              return child!;
            },
            // Set up routing
            initialRoute: '/',
            routes: {
              '/': (context) => const AuthWrapper(),
              '/login': (context) => const LoginScreen(),
              '/register': (context) => const RegisterScreen(),
              '/main': (context) => const MainNavigationScreen(),
            },
          );
        },
      ),
    );
  }
}
