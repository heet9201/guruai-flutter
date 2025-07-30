import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme/app_theme.dart';
import 'presentation/bloc/app_bloc.dart';
import 'presentation/bloc/app_event.dart';
import 'presentation/bloc/app_state.dart';
import 'presentation/screens/home_screen.dart';

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
          return MaterialApp(
            title: 'Sahayak',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme(),
            darkTheme: AppTheme.darkTheme(),
            themeMode: state is AppLoaded && state.isDarkMode
                ? ThemeMode.dark
                : ThemeMode.light,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en', ''), // English
              Locale('hi', ''), // Hindi
            ],
            locale: state is AppLoaded
                ? Locale(state.languageCode, '')
                : const Locale('en', ''),
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}
