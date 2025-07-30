import 'package:equatable/equatable.dart';

abstract class AppEvent extends Equatable {
  const AppEvent();

  @override
  List<Object?> get props => [];
}

class AppStarted extends AppEvent {}

class ThemeChanged extends AppEvent {
  final bool isDarkMode;

  const ThemeChanged(this.isDarkMode);

  @override
  List<Object?> get props => [isDarkMode];
}

class AppThemeToggled extends AppEvent {}

class LanguageChanged extends AppEvent {
  final String languageCode;

  const LanguageChanged(this.languageCode);

  @override
  List<Object?> get props => [languageCode];
}

class AppLanguageChanged extends AppEvent {
  final String languageCode;

  const AppLanguageChanged(this.languageCode);

  @override
  List<Object?> get props => [languageCode];
}

class HighContrastToggled extends AppEvent {
  final bool isHighContrast;

  const HighContrastToggled(this.isHighContrast);

  @override
  List<Object?> get props => [isHighContrast];
}

class AppHighContrastToggled extends AppEvent {}
