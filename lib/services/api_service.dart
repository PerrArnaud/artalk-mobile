import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'storage_service.dart';

class ApiService {
  final StorageService _storageService = StorageService();

  Future<Map<String, String>> _getHeaders({bool includeAuth = false}) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'ngrok-skip-browser-warning': 'true', // Bypass ngrok warning page
    };

    if (includeAuth) {
      final token = await _storageService.getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  Future<http.Response> get(
    String url, {
    bool includeAuth = false,
  }) async {
    try {
      final headers = await _getHeaders(includeAuth: includeAuth);
      
      // Create HTTP client that allows self-signed certificates for development
      final client = HttpClient()
        ..badCertificateCallback = ((X509Certificate cert, String host, int port) => true);
      
      final request = await client.getUrl(Uri.parse(url));
      headers.forEach((key, value) {
        request.headers.add(key, value);
      });
      
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      
      client.close();
      
      // Convert HttpHeaders to Map<String, String>
      final responseHeaders = <String, String>{};
      response.headers.forEach((name, values) {
        responseHeaders[name] = values.join(',');
      });
      
      return http.Response(
        responseBody,
        response.statusCode,
        headers: responseHeaders,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<http.Response> post(
    String url,
    Map<String, dynamic> body, {
    bool includeAuth = false,
  }) async {
    try {
      final headers = await _getHeaders(includeAuth: includeAuth);
      
      // Create HTTP client that allows self-signed certificates for development
      final client = HttpClient()
        ..badCertificateCallback = ((X509Certificate cert, String host, int port) => true);
      
      final request = await client.postUrl(Uri.parse(url));
      headers.forEach((key, value) {
        request.headers.add(key, value);
      });
      
      request.write(jsonEncode(body));
      
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      
      client.close();
      
      // Convert HttpHeaders to Map<String, String>
      final responseHeaders = <String, String>{};
      response.headers.forEach((name, values) {
        responseHeaders[name] = values.join(',');
      });
      
      return http.Response(
        responseBody,
        response.statusCode,
        headers: responseHeaders,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> handleResponse(http.Response response) async {
    final responseData = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return responseData;
    } else if (response.statusCode == 401) {
      // Token expired or invalid - clear storage
      await _storageService.clearAll();
      throw Exception('Authentication failed. Please login again.');
    } else {
      final message = responseData['message'] as String? ?? 'An error occurred';
      throw Exception(message);
    }
  }
}
