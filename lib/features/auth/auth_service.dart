import 'dart:convert';
import 'package:bfine/features/profile/profile_provider.dart';
import 'package:bfine/features/readings/readings_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/auth/auth_storage.dart';

class AuthService {
  final _dio = ApiClient.dio;

  // POST /api/auth/login
  Future<void> login(String username, String password) async {
    try {
      final res = await _dio.post(ApiEndpoints.login, data: {
        'username': username,
        'password': password,
      });
      print(res.data); // Debug: print the entire response data
      final token = res.data['token'] as String;
      final userType = res.data['userType'] as String;
      final userId = _extractUserId(token);
      await AuthStorage.saveSession(
          token: token, userId: userId, userType: userType);
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  // POST /api/auth/register
  Future<void> register(String username, String password) async {
    try {
      await _dio.post(ApiEndpoints.register, data: {
        'username': username,
        'password': password,
      });
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  Future<void> logout(dynamic ref) async {
    await AuthStorage.clear();
    // Cette ligne va forcer TOUS les providers qui dépendent de l'auth
    // ou le provider actuel à se réinitialiser.
    if (ref is WidgetRef || ref is Ref) {
      ref.invalidate(readingsProvider);
      ref.invalidate(profileProvider);
    } // Si tu as un provider pour les infos du docteur ou du patient :
  }

  // Decode JWT payload → extract UserId claim
  String _extractUserId(String token) {
    final parts = token.split('.');
    if (parts.length != 3) throw Exception('Invalid token format');
    final padded = parts[1].padRight((parts[1].length + 3) & ~3, '=');
    final decoded = utf8.decode(base64Url.decode(padded));
    final claims = jsonDecode(decoded) as Map<String, dynamic>;
    return claims['UserId']?.toString() ?? '';
  }

  String _parseError(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['message'] != null)
      return data['message'] as String;
    return 'An error occurred. Please try again.';
  }
}
