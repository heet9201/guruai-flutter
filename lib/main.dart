import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme/app_theme.dart';
import 'core/localization/app_locales.dart';
import 'presentation/bloc/app_bloc.dart';
import 'presentation/bloc/app_event.dart';
import 'presentation/bloc/app_state.dart';
import 'presentation/navigation/main_navigation_screen.dart';

void main() {
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
                ? AppTheme.highContrastTheme(
                    languageCode: languageCode, isDark: false)
                : AppTheme.lightTheme(languageCode: languageCode),
            darkTheme: isHighContrast
                ? AppTheme.highContrastTheme(
                    languageCode: languageCode, isDark: true)
                : AppTheme.darkTheme(languageCode: languageCode),
            themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: SahayakLocales.supportedLocales,
            locale: SahayakLocales.getLocale(languageCode),
            home: const MainNavigationScreen(),
          );
        },
      ),
    );
  }
}
