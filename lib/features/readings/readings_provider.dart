import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/auth/auth_storage.dart';
import '../../core/models/models.dart';

final readingsProvider = FutureProvider<List<Reading>>((ref) async {
  final patientId = await AuthStorage.getUserId();
  if (patientId == null) throw Exception('User not authenticated');
  final url = ApiEndpoints.readings(patientId);
  print("Flutter appelle l'URL : $url");
  final res = await ApiClient.dio.get(url);
  print("we are callin the api !!!");

  final list = res.data as List<dynamic>;

  return list.map((j) => Reading.fromJson(j as Map<String, dynamic>)).toList();
});
