import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import '../models/api_models.dart';
import '../datasources/api_service.dart';
import '../../core/constants/api_constants.dart';

class AuthService {
  final ApiClient _apiClient;

  AuthService(this._apiClient);

  Future<String> _getDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.id;
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return iosInfo.identifierForVendor ?? 'unknown_ios_device';
    }
    return 'unknown_device';
  }

  Future<AuthResponse> login(String email, String password) async {
    final deviceId = await _getDeviceId();

    final loginRequest = LoginRequest(
      email: email,
      password: password,
      deviceId: deviceId,
    );

    print('🔐 AuthService: Making login request...');
    final response = await _apiClient.post<AuthResponse>(
      ApiConstants.login,
      data: loginRequest.toJson(),
      fromJson: (json) {
        print('🔍 AuthService: Raw response data: $json');
        try {
          return AuthResponse.fromJson(json);
        } catch (e) {
          print('❌ AuthService: Error parsing AuthResponse: $e');
          rethrow;
        }
      },
    );

    print(
        '🔍 AuthService: Response success: ${response.isSuccess}, data: ${response.data != null}');
    if (response.isSuccess && response.data != null) {
      final authResponse = response.data!;
      print(
          '✅ AuthService: Login successful for user: ${authResponse.user.email}');
      // Store tokens securely after successful login
      await _apiClient.storeAuthTokens(
          authResponse.token, authResponse.refreshToken);
      return authResponse;
    } else {
      print('❌ AuthService: Login failed - Error: ${response.error}');
      throw ApiError(message: response.error ?? 'Login failed');
    }
  }

  Future<AuthResponse> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phoneNumber,
    String? grade,
    String? subject,
  }) async {
    final deviceId = await _getDeviceId();

    final registerRequest = RegisterRequest(
      email: email,
      password: password,
      firstName: firstName,
      lastName: lastName,
      phoneNumber: phoneNumber,
      grade: grade,
      subject: subject,
      deviceId: deviceId,
    );

    final response = await _apiClient.post<AuthResponse>(
      ApiConstants.register,
      data: registerRequest.toJson(),
      fromJson: (json) => AuthResponse.fromJson(json),
    );

    if (response.isSuccess && response.data != null) {
      final authResponse = response.data!;
      // Store tokens securely after successful registration
      await _apiClient.storeAuthTokens(
          authResponse.token, authResponse.refreshToken);
      return authResponse;
    } else {
      throw ApiError(message: response.error ?? 'Registration failed');
    }
  }

  Future<void> logout() async {
    final response = await _apiClient.post(ApiConstants.logout);

    // Clear tokens regardless of API response (for local logout)
    await _apiClient.clearAuthTokens();

    if (!response.isSuccess) {
      throw ApiError(message: response.error ?? 'Logout failed');
    }
  }

  Future<void> resetPassword(String email) async {
    final response = await _apiClient.post(
      ApiConstants.resetPassword,
      data: {'email': email},
    );

    if (!response.isSuccess) {
      throw ApiError(message: response.error ?? 'Password reset failed');
    }
  }

  Future<UserModel> getUserProfile() async {
    final user = await getCurrentUser();
    if (user != null) {
      return user;
    } else {
      throw ApiError(
          message: 'Failed to get user profile - authentication required');
    }
  }

  Future<UserModel> updateUserProfile({
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? school,
    String? grade,
    String? subject,
  }) async {
    final updateData = <String, dynamic>{};
    if (firstName != null) updateData['firstName'] = firstName;
    if (lastName != null) updateData['lastName'] = lastName;
    if (phoneNumber != null) updateData['phoneNumber'] = phoneNumber;
    if (school != null) updateData['school'] = school;
    if (grade != null) updateData['grade'] = grade;
    if (subject != null) updateData['subject'] = subject;

    final response = await _apiClient.put<UserModel>(
      ApiConstants.userProfile,
      data: updateData,
      fromJson: (json) => UserModel.fromJson(json),
    );

    if (response.isSuccess && response.data != null) {
      return response.data!;
    } else {
      throw ApiError(message: response.error ?? 'Failed to update profile');
    }
  }

  Future<void> deleteAccount() async {
    final response = await _apiClient.delete(ApiConstants.deleteAccount);

    if (!response.isSuccess) {
      throw ApiError(message: response.error ?? 'Failed to delete account');
    }
  }

  // Token verification and refresh methods
  Future<UserModel?> verifyTokenAndGetUser(String token) async {
    try {
      print('🔍 AuthService: Verifying token...');
      final response = await _apiClient.post(
        ApiConstants.verifyToken,
        data: {'token': token},
      );

      print('✅ AuthService: Token verification response: ${response.data}');

      if (response.isSuccess &&
          response.data['valid'] == true &&
          response.data['user'] != null) {
        // Token is valid and we have user data
        final userData = response.data['user'];
        print('✅ AuthService: Token valid, user: ${userData['email']}');
        return UserModel.fromJson(userData);
      } else {
        print('❌ AuthService: Token is invalid or no user data');
        return null;
      }
    } catch (e) {
      print('❌ AuthService: Token verification failed: $e');
      return null;
    }
  }

  Future<bool> verifyToken(String token) async {
    final user = await verifyTokenAndGetUser(token);
    return user != null;
  }

  Future<AuthResponse?> refreshToken() async {
    try {
      final refreshToken = await _apiClient.getStoredRefreshToken();
      if (refreshToken == null) {
        print('❌ AuthService: No refresh token found');
        return null;
      }

      print('🔄 AuthService: Refreshing token...');
      final response = await _apiClient.post<AuthResponse>(
        ApiConstants.refreshToken,
        data: {'refreshToken': refreshToken},
        fromJson: (json) => AuthResponse.fromJson(json),
      );

      if (response.isSuccess && response.data != null) {
        final authResponse = response.data!;
        print('✅ AuthService: Token refresh successful');

        // Store new tokens
        await _apiClient.storeAuthTokens(
            authResponse.token, authResponse.refreshToken);

        return authResponse;
      } else {
        print('❌ AuthService: Token refresh failed: ${response.error}');
        return null;
      }
    } catch (e) {
      print('❌ AuthService: Token refresh error: $e');
      return null;
    }
  }

  Future<UserModel?> isAuthenticatedAndGetUser() async {
    try {
      final accessToken = await _apiClient.getStoredAccessToken();
      if (accessToken == null) {
        print('🔍 AuthService: No access token found');
        return null;
      }

      // First try to verify the current token and get user data
      print('🔍 AuthService: Checking if current token is valid...');
      final user = await verifyTokenAndGetUser(accessToken);

      if (user != null) {
        print('✅ AuthService: Current token is valid, user: ${user.email}');
        return user;
      }

      // If token is invalid, try to refresh
      print('🔄 AuthService: Token invalid, attempting refresh...');
      final refreshResult = await refreshToken();

      if (refreshResult != null) {
        print(
            '✅ AuthService: Token refreshed successfully, user: ${refreshResult.user.email}');
        return refreshResult.user;
      }

      print('❌ AuthService: Authentication failed - clearing tokens');
      await _apiClient.clearAuthTokens();
      return null;
    } catch (e) {
      print('❌ AuthService: Authentication check failed: $e');
      await _apiClient.clearAuthTokens();
      return null;
    }
  }

  Future<bool> isAuthenticated() async {
    final user = await isAuthenticatedAndGetUser();
    return user != null;
  }

  Future<UserModel?> getCurrentUser() async {
    try {
      // Use the combined authentication and user retrieval method
      print('👤 AuthService: Getting current user...');
      final user = await isAuthenticatedAndGetUser();

      if (user != null) {
        print('✅ AuthService: User retrieved successfully: ${user.email}');
        return user;
      } else {
        print('❌ AuthService: Not authenticated or failed to get user');
        return null;
      }
    } catch (e) {
      print('❌ AuthService: Error getting user: $e');
      // If getting user fails, clear tokens and return null
      await _apiClient.clearAuthTokens();
      return null;
    }
  }
}
