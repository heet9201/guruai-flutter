# Sahayak - AI Assistant Flutter App

Sahayak is a Flutter application built with Clean Architecture and the BLoC pattern, designed to be an AI assistant supporting both Android and iOS platforms.

## Features

- 🏗️ **Clean Architecture**: Organized codebase with separation of concerns
- 🔄 **BLoC Pattern**: State management using flutter_bloc
- 🌍 **Internationalization**: Multi-language support with flutter_localizations
- 🎨 **Modern UI**: Material Design 3 with dark/light theme support
- 🗣️ **Voice Features**: Text-to-speech and speech-to-text capabilities
- 🤖 **AI Integration**: Ready for AI services integration (Vertex AI, Flutter AI Toolkit)
- 💾 **Offline Storage**: SQLite database for local data persistence
- 🌐 **Network**: HTTP client with Dio for API calls
- 📁 **File Management**: File picker and cached network images
- 🔐 **Permissions**: Comprehensive permission handling

## Dependencies

### Core Dependencies

- `flutter_bloc`: State management
- `dio`: HTTP client for API calls
- `shared_preferences`: Local key-value storage
- `flutter_localizations`: Internationalization support
- `provider`: Additional state management
- `equatable`: Value equality for Dart

### AI & ML

- `vertex_ai`: Google's Vertex AI integration
- `flutter_ai_toolkit`: AI toolkit for Flutter

### UI & Media

- `cached_network_image`: Image caching and loading
- `file_picker`: File selection functionality

### Audio Features

- `flutter_tts`: Text-to-speech functionality
- `speech_to_text`: Speech recognition

### Storage & Utilities

- `sqflite`: SQLite database for local storage
- `permission_handler`: Runtime permissions management
- `path`: Path manipulation utilities

## Project Structure

```
lib/
├── core/                      # Core functionality
│   ├── constants/            # App constants and configuration
│   ├── utils/               # Utility classes and helpers
│   └── theme/               # App theming
├── data/                     # Data layer
│   ├── datasources/         # Data sources (API, Database)
│   ├── models/              # Data models
│   └── repositories/        # Repository implementations
├── domain/                   # Domain layer
│   ├── entities/            # Business entities
│   ├── repositories/        # Repository interfaces
│   └── usecases/           # Business logic use cases
├── presentation/            # Presentation layer
│   ├── screens/            # UI screens
│   ├── widgets/            # Reusable widgets
│   └── bloc/               # BLoC state management
└── main.dart               # App entry point
```

## Getting Started

### Prerequisites

- Flutter SDK (latest stable version)
- Dart SDK
- Android Studio / VS Code
- iOS development tools (for iOS development)

### Installation

1. Clone the repository:

```bash
git clone <repository-url>
cd sahayak
```

2. Install dependencies:

```bash
flutter pub get
```

3. Run the app:

```bash
flutter run
```

### Platform Setup

#### Android

- Minimum SDK: 21
- Target SDK: Latest

#### iOS

- Minimum iOS version: 12.0
- Deployment target: Latest

## Architecture Overview

### Clean Architecture Layers

1. **Presentation Layer** (`presentation/`)

   - UI components (screens, widgets)
   - BLoC state management
   - User interaction handling

2. **Domain Layer** (`domain/`)

   - Business entities
   - Use cases (business logic)
   - Repository interfaces

3. **Data Layer** (`data/`)
   - Repository implementations
   - Data sources (API, local database)
   - Data models

### Key Features

#### State Management

- Uses BLoC pattern for predictable state management
- Separation of events, states, and business logic
- Reactive programming with streams

#### Database

- SQLite integration with sqflite
- Local data persistence
- Database helper with migration support

#### Networking

- Dio HTTP client with interceptors
- Automatic token management
- Error handling and retry logic

#### Audio Services

- Text-to-speech functionality
- Speech recognition
- Audio permission handling

#### Theme Support

- Material Design 3
- Light and dark themes
- Dynamic theme switching

#### Internationalization

- Multi-language support
- Locale-based text rendering
- Language switching capability

## Configuration

### API Configuration

Update `lib/core/constants/app_constants.dart` with your API configuration:

```dart
static const String baseUrl = 'your-api-base-url';
```

### Database

The SQLite database is automatically created on first launch. Schema is defined in `lib/data/datasources/database_helper.dart`.

### Permissions

Required permissions are defined in `app_constants.dart` and handled by the permission service.

## Contributing

1. Follow the established architecture patterns
2. Write tests for new features
3. Update documentation as needed
4. Follow Dart/Flutter coding standards

## License

This project is licensed under the MIT License - see the LICENSE file for details.
