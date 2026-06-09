import 'package:bfine/core/api/api_client.dart';
import 'package:bfine/core/api/api_endpoints.dart';
import 'package:bfine/core/auth/auth_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// final mesPatientProvider = FutureProvider.autoDispose<int>((ref) async {
//   final doctorId = await AuthStorage.getUserId();
//   if (doctorId == null) throw Exception('user not authenticated');

//   final res = await ApiClient.dio.get(ApiEndpoints.GetMyPatient(doctorId));

//   final nbr = res.data as int;
//   return nbr;
// });

final mesPatientProvider = FutureProvider.autoDispose<int>((ref) async {
  final doctorId = await AuthStorage.getUserId();
  if (doctorId == null) throw Exception('Non authentifié');

  final url = ApiEndpoints.GetMyPatient(doctorId);
  final res = await ApiClient.dio.get(url);
  print("!!!!!!!!!!!!!! DATA REÇUE : ${res.data}");
  // Si l'API renvoie {"count": 10} par exemple :
  if (res.data is Map) {
    return (res.data['patientCount'] ?? 0) as int;
  }

  // Si l'API renvoie juste le chiffre 10 :
  return res.data as int;
});
