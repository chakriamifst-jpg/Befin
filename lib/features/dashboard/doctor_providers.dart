import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/auth/auth_storage.dart';
import '../../core/models/models.dart';

// ── Patient summary model ──────────────────────────────────
class PatientSummary {
  final int id;
  final String fullName;
  final String? phoneNumber;

  const PatientSummary({
    required this.id,
    required this.fullName,
    this.phoneNumber,
  });

  factory PatientSummary.fromJson(Map<String, dynamic> j) => PatientSummary(
        id: j['id'] as int,
        fullName: j['fullName'] as String,
        phoneNumber: j['phoneNumber'] as String?,
      );
}

// ── My patients list ───────────────────────────────────────
final myPatientsProvider = FutureProvider<List<PatientSummary>>((ref) async {
  final doctorId = await AuthStorage.getUserId();
  if (doctorId == null) throw Exception('Not authenticated');

  final res = await ApiClient.dio.get(ApiEndpoints.myPatients(doctorId));
  final list = res.data as List<dynamic>;
  return list
      .map((j) => PatientSummary.fromJson(j as Map<String, dynamic>))
      .toList();
});

// ── Patient count ──────────────────────────────────────────
final patientCountProvider = FutureProvider<int>((ref) async {
  final doctorId = await AuthStorage.getUserId();
  if (doctorId == null) throw Exception('Not authenticated');

  final res = await ApiClient.dio.get(ApiEndpoints.patientCount(doctorId));
  return res.data['patientCount'] as int;
});

// ── Patient profile (by id) ────────────────────────────────
final patientProfileProvider =
    FutureProvider.family<UserProfile, int>((ref, patientId) async {
  final res = await ApiClient.dio.get(ApiEndpoints.patientProfile(patientId));
  return UserProfile.fromJson(res.data as Map<String, dynamic>);
});

// ── Patient readings (by id) ───────────────────────────────
final patientReadingsProvider =
    FutureProvider.family<List<Reading>, int>((ref, patientId) async {
  final res = await ApiClient.dio.get(ApiEndpoints.patientReadings(patientId));
  final list = res.data as List<dynamic>;
  return list.map((j) => Reading.fromJson(j as Map<String, dynamic>)).toList();
});

// ── ML Prediction (by patientId) ───────────────────────────
class PredictionState {
  final bool isLoading;
  final String? result; // "Diabetic" | "Not Diabetic"
  final String? error;

  const PredictionState({
    this.isLoading = false,
    this.result,
    this.error,
  });

  PredictionState copyWith({bool? isLoading, String? result, String? error}) =>
      PredictionState(
        isLoading: isLoading ?? this.isLoading,
        result: result ?? this.result,
        error: error,
      );
}

class PredictionNotifier extends StateNotifier<PredictionState> {
  PredictionNotifier() : super(const PredictionState());

  Future<void> predict(int patientId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await ApiClient.dio.get(ApiEndpoints.prediction(patientId));
      final result = res.data['prediction'] as String;
      state = state.copyWith(isLoading: false, result: result);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void reset() => state = const PredictionState();
}

final predictionProvider =
    StateNotifierProvider.family<PredictionNotifier, PredictionState, int>(
  (ref, patientId) => PredictionNotifier(),
);
