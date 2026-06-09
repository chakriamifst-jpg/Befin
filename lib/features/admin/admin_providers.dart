import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';

// ── Models ─────────────────────────────────────────────────

class AdminUser {
  final int id;
  final String fullName;
  final String username;
  final String? phoneNumber;

  const AdminUser({
    required this.id,
    required this.fullName,
    required this.username,
    this.phoneNumber,
  });

  factory AdminUser.fromJson(Map<String, dynamic> j) => AdminUser(
        id: j['id'] as int,
        fullName: (j['fullName'] as String?) ?? '—',
        username: (j['username'] as String?) ?? '—',
        phoneNumber: j['phoneNumber'] as String?,
      );
}

class AssignedDoctor {
  final int doctorId;
  final String doctorName;

  const AssignedDoctor({required this.doctorId, required this.doctorName});

  factory AssignedDoctor.fromJson(Map<String, dynamic> j) => AssignedDoctor(
        doctorId: j['doctorId'] as int,
        doctorName: j['doctorName'] as String,
      );
}

class PatientWithDoctor {
  final AdminUser patient;
  AssignedDoctor? assignedDoctor;

  PatientWithDoctor({required this.patient, this.assignedDoctor});
}

// ── Doctors list ───────────────────────────────────────────
final adminDoctorsProvider = FutureProvider<List<AdminUser>>((ref) async {
  final res = await ApiClient.dio.get(ApiEndpoints.adminDoctors);
  final list = res.data as List<dynamic>;
  return list
      .map((j) => AdminUser.fromJson(j as Map<String, dynamic>))
      .toList();
});

// ── Patients list (with assigned doctor) ───────────────────
final adminPatientsProvider =
    FutureProvider<List<PatientWithDoctor>>((ref) async {
  final res = await ApiClient.dio.get(ApiEndpoints.adminPatients);
  final list = res.data as List<dynamic>;
  final patients = list
      .map((j) => PatientWithDoctor(
          patient: AdminUser.fromJson(j as Map<String, dynamic>)))
      .toList();

  // Load assigned doctor for each patient
  for (final p in patients) {
    try {
      final r = await ApiClient.dio
          .get(ApiEndpoints.adminAssignedDoctor(p.patient.id));
      final data = r.data as Map<String, dynamic>;
      if (data['doctorName'] != null) {
        p.assignedDoctor = AssignedDoctor.fromJson(data);
      }
    } catch (_) {
      p.assignedDoctor = null;
    }
  }
  return patients;
});

// ── Admin actions notifier ─────────────────────────────────
class AdminNotifier extends StateNotifier<AsyncValue<void>> {
  AdminNotifier() : super(const AsyncData(null));

  Future<void> createUser(
      String username, String password, String userType) async {
    state = const AsyncLoading();
    try {
      await ApiClient.dio.post(ApiEndpoints.adminCreateUser, data: {
        'username': username,
        'password': password,
        'userType': userType,
      });
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> deleteUser(int id) async {
    state = const AsyncLoading();
    try {
      await ApiClient.dio.delete(ApiEndpoints.adminDeleteUser(id));
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> assignDoctor(int doctorId, int patientId) async {
    state = const AsyncLoading();
    try {
      await ApiClient.dio.post(ApiEndpoints.adminAssign, data: {
        'doctorId': doctorId,
        'patientId': patientId,
      });
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> unassignDoctor(int patientId) async {
    state = const AsyncLoading();
    try {
      await ApiClient.dio.delete(ApiEndpoints.adminUnassign(patientId));
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final adminNotifierProvider =
    StateNotifierProvider<AdminNotifier, AsyncValue<void>>(
        (_) => AdminNotifier());
