import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth/auth_bloc.dart';
import '../navigation/main_navigation_screen.dart';
import 'login_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AuthBloc()..add(AuthCheckRequested()),
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          print('🔄 AuthWrapper: Current state: ${state.runtimeType}');
          if (state is AuthError) {
            print('❌ AuthWrapper: Auth error occurred: ${state.message}');
          }

          if (state is AuthLoading || state is AuthInitial) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          } else if (state is AuthAuthenticated) {
            print('✅ AuthWrapper: Navigating to MainNavigationScreen');
            return const MainNavigationScreen();
          } else {
            print('🔑 AuthWrapper: Showing LoginScreen');
            // Pass the same AuthBloc instance to the LoginScreen
            return const LoginScreen();
          }
        },
      ),
    );
  }
}
