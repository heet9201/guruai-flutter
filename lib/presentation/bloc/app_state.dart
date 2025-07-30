import 'package:equatable/equatable.dart';

abstract class AppState extends Equatable {
  const AppState();

  @override
  List<Object?> get props => [];
}

class AppInitial extends AppState {}

class AppLoading extends AppState {}

class AppLoaded extends AppState {
  final bool isDarkMode;
  final bool isHighContrast;
  final String languageCode;

  const AppLoaded({
    required this.isDarkMode,
    this.isHighContrast = false,
    required this.languageCode,
  });

  @override
  List<Object?> get props => [isDarkMode, isHighContrast, languageCode];

  AppLoaded copyWith({
    bool? isDarkMode,
    bool? isHighContrast,
    String? languageCode,
  }) {
    return AppLoaded(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      isHighContrast: isHighContrast ?? this.isHighContrast,
      languageCode: languageCode ?? this.languageCode,
    );
  }
}

class AppError extends AppState {
  final String message;

  const AppError(this.message);

  @override
  List<Object?> get props => [message];
}
