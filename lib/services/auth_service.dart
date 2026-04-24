import '../models/user.dart';
import '../models/api_response.dart';
import '../config/api_config.dart';
import 'api_service.dart';
import 'storage_service.dart';

class AuthService {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();

  Future<ApiResponse<Map<String, dynamic>>> register({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final response = await _apiService.post(
        ApiConfig.registerUrl,
        {
          'email': email,
          'password': password,
          'name': name,
        },
      );

      final data = await _apiService.handleResponse(response);
      
      // Save token and user data if registration successful
      if (data['success'] == true && data['data'] != null) {
        final responseData = data['data'] as Map<String, dynamic>;
        final token = responseData['token'] as String;
        final userData = responseData['user'] as Map<String, dynamic>;

        await _storageService.saveToken(token);
        await _storageService.saveUserData(
          id: userData['id'] as int,
          email: userData['email'] as String,
          name: userData['name'] as String,
          role: userData['role'] as String,
        );
      }

      return ApiResponse.fromJson(data, (json) => json as Map<String, dynamic>);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: e.toString(),
      );
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiService.post(
        ApiConfig.loginUrl,
        {
          'email': email,
          'password': password,
        },
      );

      // DEBUG - À supprimer après diagnostic
      print('=== LOGIN DEBUG ===');
      print('URL: ${ApiConfig.loginUrl}');
      print('STATUS: ${response.statusCode}');
      print('BODY: ${response.body}');
      print('==================');

      final data = await _apiService.handleResponse(response);

      // Save token and user data if login successful
      if (data['token'] != null && data['user'] != null) {
        final token = data['token'] as String;
        final userData = data['user'] as Map<String, dynamic>;

        await _storageService.saveToken(token);
        await _storageService.saveUserData(
          id: userData['id'] as int,
          email: userData['email'] as String,
          name: userData['name'] as String,
          role: userData['role'] as String,
        );

        return ApiResponse(
          success: true,
          data: data,
        );
      }

      return ApiResponse(
        success: false,
        message: 'Invalid response from server',
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: e.toString(),
      );
    }
  }

  Future<ApiResponse<User>> getCurrentUser() async {
    try {
      final response = await _apiService.get(
        ApiConfig.meUrl,
        includeAuth: true,
      );

      final data = await _apiService.handleResponse(response);

      if (data['success'] == true && data['data'] != null) {
        final user = User.fromJson(data['data'] as Map<String, dynamic>);
        return ApiResponse(
          success: true,
          data: user,
        );
      }

      return ApiResponse(
        success: false,
        message: 'Failed to get user data',
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: e.toString(),
      );
    }
  }

  Future<void> logout() async {
    await _storageService.clearAll();
  }

  Future<bool> isAuthenticated() async {
    return await _storageService.hasToken();
  }

  Future<User?> getStoredUser() async {
    final userData = await _storageService.getUserData();
    
    if (userData['id'] != null && userData['email'] != null) {
      return User(
        id: int.parse(userData['id']!),
        email: userData['email']!,
        name: userData['name'] ?? '',
        role: userData['role'] ?? '',
      );
    }
    
    return null;
  }
}
