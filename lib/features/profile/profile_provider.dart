import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/auth/auth_storage.dart';
import '../../core/models/models.dart';

final profileProvider = FutureProvider<UserProfile>((ref) async {
  final id = await AuthStorage.getUserId();
  if (id == null) {
    print("id non trouver");
    throw Exception('Not authenticated');
  }
  final res = await ApiClient.dio.get(ApiEndpoints.getProfile(id));
  return UserProfile.fromJson(res.data as Map<String, dynamic>);
});

class ProfileNotifier extends AsyncNotifier<UserProfile> {
  @override
  Future<UserProfile> build() async {
    final id = await AuthStorage.getUserId();
    if (id == null) {
      print("id non trouver");
      throw Exception('Not authenticated');
    }
    final res = await ApiClient.dio.get(ApiEndpoints.getProfile(id));
    return UserProfile.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    final id = await AuthStorage.getUserId();
    if (id == null) throw Exception('Not authenticated');
    await ApiClient.dio.post(ApiEndpoints.updateProfile(id), data: data);
    ref.invalidateSelf();
  }

  Future<void> changePassword(String current, String newPass) async {
    final id = await AuthStorage.getUserId();
    if (id == null) throw Exception('Not authenticated');
    await ApiClient.dio.post(ApiEndpoints.changePassword(id), data: {
      'currentPassword': current,
      'newPassword': newPass,
    });
  }
}

final profileNotifierProvider =
    AsyncNotifierProvider<ProfileNotifier, UserProfile>(ProfileNotifier.new);
