import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/models/api_models.dart';
import '../../../core/services/service_locator.dart';

// Events
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginRequested({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}

class AuthRegisterRequested extends AuthEvent {
  final String email;
  final String password;
  final String firstName;
  final String lastName;
  final String? phoneNumber;
  final String? grade;
  final String? subject;

  const AuthRegisterRequested({
    required this.email,
    required this.password,
    required this.firstName,
    required this.lastName,
    this.phoneNumber,
    this.grade,
    this.subject,
  });

  @override
  List<Object?> get props => [
        email,
        password,
        firstName,
        lastName,
        phoneNumber,
        grade,
        subject,
      ];
}

class AuthLogoutRequested extends AuthEvent {}

class AuthUserUpdated extends AuthEvent {
  final UserModel user;

  const AuthUserUpdated({required this.user});

  @override
  List<Object?> get props => [user];
}

class AuthPasswordResetRequested extends AuthEvent {
  final String email;

  const AuthPasswordResetRequested({required this.email});

  @override
  List<Object?> get props => [email];
}

class AuthProfileUpdateRequested extends AuthEvent {
  final String? firstName;
  final String? lastName;
  final String? phoneNumber;
  final String? school;
  final String? grade;
  final String? subject;

  const AuthProfileUpdateRequested({
    this.firstName,
    this.lastName,
    this.phoneNumber,
    this.school,
    this.grade,
    this.subject,
  });

  @override
  List<Object?> get props => [
        firstName,
        lastName,
        phoneNumber,
        school,
        grade,
        subject,
      ];
}

// States
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final UserModel user;
  final String token;

  const AuthAuthenticated({
    required this.user,
    required this.token,
  });

  @override
  List<Object?> get props => [user, token];
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;

  const AuthError({required this.message});

  @override
  List<Object?> get props => [message];
}

class AuthPasswordResetSent extends AuthState {
  final String email;

  const AuthPasswordResetSent({required this.email});

  @override
  List<Object?> get props => [email];
}

// BLoC
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthLoginRequested>(_onAuthLoginRequested);
    on<AuthRegisterRequested>(_onAuthRegisterRequested);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
    on<AuthUserUpdated>(_onAuthUserUpdated);
    on<AuthPasswordResetRequested>(_onAuthPasswordResetRequested);
    on<AuthProfileUpdateRequested>(_onAuthProfileUpdateRequested);
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      print('🔍 AuthBloc: Checking authentication status...');

      // Use the new combined authentication and user retrieval method
      final user = await ServiceLocator.authService.isAuthenticatedAndGetUser();

      if (user != null) {
        final token = await ServiceLocator.apiClient.getStoredAccessToken();
        print('✅ AuthBloc: Authentication verified, user: ${user.email}');
        emit(AuthAuthenticated(
          user: user,
          token: token!,
        ));
      } else {
        print('❌ AuthBloc: User is not authenticated');
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      print('❌ AuthBloc: Authentication check failed: $e');
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onAuthLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      print('🔄 AuthBloc: Starting login process...');
      final authResponse = await ServiceLocator.authService.login(
        event.email,
        event.password,
      );
      print(
          '✅ AuthBloc: Login API successful, got user: ${authResponse.user.email}');

      // Try to connect to WebSocket, but don't fail auth if it fails
      try {
        print('🔌 AuthBloc: Attempting WebSocket connection...');
        await ServiceLocator.webSocketService.connect(authResponse.token);
        print('✅ AuthBloc: WebSocket connected successfully');
      } catch (wsError) {
        print('⚠️ AuthBloc: WebSocket connection failed: $wsError');
        // Continue with authentication even if WebSocket fails
      }

      print('🔐 AuthBloc: Emitting AuthAuthenticated state');
      emit(AuthAuthenticated(
        user: authResponse.user,
        token: authResponse.token,
      ));
    } catch (e) {
      print('❌ AuthBloc: Login failed with error: $e');
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onAuthRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      final authResponse = await ServiceLocator.authService.register(
        email: event.email,
        password: event.password,
        firstName: event.firstName,
        lastName: event.lastName,
        phoneNumber: event.phoneNumber,
        grade: event.grade,
        subject: event.subject,
      );

      // Connect to WebSocket after successful registration
      await ServiceLocator.webSocketService.connect(authResponse.token);

      emit(AuthAuthenticated(
        user: authResponse.user,
        token: authResponse.token,
      ));
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onAuthLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await ServiceLocator.authService.logout();
      ServiceLocator.webSocketService.disconnect();
      ServiceLocator.apiClient.clearCache();
      emit(AuthUnauthenticated());
    } catch (e) {
      // Even if logout fails on server, clear local state
      ServiceLocator.webSocketService.disconnect();
      ServiceLocator.apiClient.clearCache();
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onAuthUserUpdated(
    AuthUserUpdated event,
    Emitter<AuthState> emit,
  ) async {
    if (state is AuthAuthenticated) {
      final currentState = state as AuthAuthenticated;
      emit(AuthAuthenticated(
        user: event.user,
        token: currentState.token,
      ));
    }
  }

  Future<void> _onAuthPasswordResetRequested(
    AuthPasswordResetRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      await ServiceLocator.authService.resetPassword(event.email);
      emit(AuthPasswordResetSent(email: event.email));
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onAuthProfileUpdateRequested(
    AuthProfileUpdateRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (state is! AuthAuthenticated) return;

    final currentState = state as AuthAuthenticated;
    emit(AuthLoading());

    try {
      final updatedUser = await ServiceLocator.authService.updateUserProfile(
        firstName: event.firstName,
        lastName: event.lastName,
        phoneNumber: event.phoneNumber,
        school: event.school,
        grade: event.grade,
        subject: event.subject,
      );

      emit(AuthAuthenticated(
        user: updatedUser,
        token: currentState.token,
      ));
    } catch (e) {
      emit(AuthError(message: e.toString()));
      // Restore previous state
      Future.delayed(const Duration(seconds: 3), () {
        if (!isClosed) {
          emit(currentState);
        }
      });
    }
  }
}
