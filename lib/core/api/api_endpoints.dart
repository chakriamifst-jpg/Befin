class ApiEndpoints {
  // Change to your machine IP when testing on physical device
  // Android emulator  → 10.0.2.2
  // iOS simulator     → localhost
  static const String _base = 'http://192.168.11.148:5156/api';

  // Auth
  static const String login = '$_base/auth/login';
  static const String register = '$_base/auth/register';

  // Profile
  static String getProfile(int id) => '$_base/profile/get-profile/$id';
  static String updateProfile(int id) => '$_base/profile/update-profile/$id';
  static String changePassword(int id) => '$_base/profile/changer-passwd/$id';

  // Readings
  static String readings(int patientId) =>
      '$_base/Readings?patientId=$patientId';

  // nbr patients
  // ignore: non_constant_identifier_names
  static String GetMyPatient(int doctorId) =>
      '$_base/Doctor/my-patient-count/$doctorId';

  // Prediction (doctor-only — patient views result only)
  // static String prediction(int patientId) => '$_base/prediction/ML/$patientId';

  // ── Doctor ─────────────────────────────────────────────
  static String myPatients(int doctorId) =>
      '$_base/Doctor/my-patients/$doctorId';
  static String patientCount(int doctorId) =>
      '$_base/Doctor/my-patient-count/$doctorId';
  static String patientProfile(int id) => '$_base/profile/get-profile/$id';
  static String patientReadings(int id) => '$_base/readings?patientId=$id';

  // ── Prediction (doctor only) ───────────────────────────
  static String prediction(int patientId) => '$_base/prediction/ML/$patientId';

  // ── Admin ──────────────────────────────────────────────
  static const String adminDoctors = '$_base/Admin/doctors';
  static const String adminPatients = '$_base/Admin/patients';
  static const String adminCreateUser = '$_base/Admin/create-user';
  static const String adminAssign = '$_base/Admin/assign-doctor-to-patient';
  static String adminDeleteUser(int id) => '$_base/Admin/delete-user/$id';
  static String adminUnassign(int id) =>
      '$_base/Admin/unassign-doctor-from-patient/$id';
  static String adminAssignedDoctor(int id) =>
      '$_base/Admin/patient-t/$id/assigned-doctor';
}
