import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/utils/app_utils.dart';
import '../../core/constants/app_constants.dart';
import 'app_event.dart';
import 'app_state.dart';

class AppBloc extends Bloc<AppEvent, AppState> {
  AppBloc() : super(AppInitial()) {
    on<AppStarted>(_onAppStarted);
    on<ThemeChanged>(_onThemeChanged);
    on<AppThemeToggled>(_onAppThemeToggled);
    on<LanguageChanged>(_onLanguageChanged);
    on<AppLanguageChanged>(_onAppLanguageChanged);
    on<HighContrastToggled>(_onHighContrastToggled);
    on<AppHighContrastToggled>(_onAppHighContrastToggled);
  }

  Future<void> _onAppStarted(AppStarted event, Emitter<AppState> emit) async {
    emit(AppLoading());

    try {
      // Load saved preferences
      final isDarkMode =
          await AppUtils.getBool(AppConstants.themeKey, defaultValue: false);
      final languageCode =
          await AppUtils.getString(AppConstants.languageKey) ?? 'en';
      final isHighContrast =
          await AppUtils.getBool('high_contrast_key', defaultValue: false);

      emit(AppLoaded(
        isDarkMode: isDarkMode,
        languageCode: languageCode,
        isHighContrast: isHighContrast,
      ));
    } catch (e) {
      emit(AppError('Failed to initialize app: ${e.toString()}'));
    }
  }

  Future<void> _onThemeChanged(
      ThemeChanged event, Emitter<AppState> emit) async {
    try {
      await AppUtils.saveBool(AppConstants.themeKey, event.isDarkMode);

      if (state is AppLoaded) {
        final currentState = state as AppLoaded;
        emit(currentState.copyWith(isDarkMode: event.isDarkMode));
      }
    } catch (e) {
      emit(AppError('Failed to change theme: ${e.toString()}'));
    }
  }

  Future<void> _onAppThemeToggled(
      AppThemeToggled event, Emitter<AppState> emit) async {
    if (state is AppLoaded) {
      final currentState = state as AppLoaded;
      final newDarkMode = !currentState.isDarkMode;

      try {
        await AppUtils.saveBool(AppConstants.themeKey, newDarkMode);
        emit(currentState.copyWith(isDarkMode: newDarkMode));
      } catch (e) {
        emit(AppError('Failed to toggle theme: ${e.toString()}'));
      }
    }
  }

  Future<void> _onLanguageChanged(
      LanguageChanged event, Emitter<AppState> emit) async {
    try {
      await AppUtils.saveString(AppConstants.languageKey, event.languageCode);

      if (state is AppLoaded) {
        final currentState = state as AppLoaded;
        emit(currentState.copyWith(languageCode: event.languageCode));
      }
    } catch (e) {
      emit(AppError('Failed to change language: ${e.toString()}'));
    }
  }

  Future<void> _onAppLanguageChanged(
      AppLanguageChanged event, Emitter<AppState> emit) async {
    try {
      await AppUtils.saveString(AppConstants.languageKey, event.languageCode);

      if (state is AppLoaded) {
        final currentState = state as AppLoaded;
        emit(currentState.copyWith(languageCode: event.languageCode));
      }
    } catch (e) {
      emit(AppError('Failed to change language: ${e.toString()}'));
    }
  }

  Future<void> _onHighContrastToggled(
      HighContrastToggled event, Emitter<AppState> emit) async {
    try {
      await AppUtils.saveBool('high_contrast_key', event.isHighContrast);

      if (state is AppLoaded) {
        final currentState = state as AppLoaded;
        emit(currentState.copyWith(isHighContrast: event.isHighContrast));
      }
    } catch (e) {
      emit(AppError('Failed to change high contrast: ${e.toString()}'));
    }
  }

  Future<void> _onAppHighContrastToggled(
      AppHighContrastToggled event, Emitter<AppState> emit) async {
    if (state is AppLoaded) {
      final currentState = state as AppLoaded;
      final newHighContrast = !currentState.isHighContrast;

      try {
        await AppUtils.saveBool('high_contrast_key', newHighContrast);
        emit(currentState.copyWith(isHighContrast: newHighContrast));
      } catch (e) {
        emit(AppError('Failed to toggle high contrast: ${e.toString()}'));
      }
    }
  }
}
