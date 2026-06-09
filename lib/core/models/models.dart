import 'dart:convert';

// ─────────────────────────────────────────────
// ReadingData — parsed from JsonContent string
// ─────────────────────────────────────────────
class ReadingData {
  final double glucose;
  final double bloodPressure;
  final double skinThickness;
  final double insulin;

  const ReadingData({
    required this.glucose,
    required this.bloodPressure,
    required this.skinThickness,
    required this.insulin,
  });

  factory ReadingData.fromJson(Map<String, dynamic> j) => ReadingData(
        glucose: ((j['glucose'] ?? j['Glucose'] ?? 0) as num? ?? 0).toDouble(),
        bloodPressure:
            ((j['bloodPressure'] ?? j['BloodPressure'] ?? 0) as num? ?? 0)
                .toDouble(),
        skinThickness:
            ((j['skinThickness'] ?? j['SkinThickness'] ?? 0) as num? ?? 0)
                .toDouble(),
        insulin: ((j['insulin'] ?? j['Insulin'] ?? 0) as num? ?? 0).toDouble(),
      );
}

// ─────────────────────────────────────────────
// Reading — one entry from GET /api/readings
// ─────────────────────────────────────────────
class Reading {
  final ReadingData data;
  final DateTime timestamp;

  const Reading({required this.data, required this.timestamp});

  factory Reading.fromJson(Map<String, dynamic> j) {
    // On récupère la string, si elle est nulle on met un objet JSON vide "{}"
    final String rawContent = j['jsonContent'] as String? ?? '{}';

    return Reading(
      data:
          ReadingData.fromJson(jsonDecode(rawContent) as Map<String, dynamic>),
      timestamp: DateTime.parse(j['timestamp'] as String),
    );
  }
}

// ─────────────────────────────────────────────
// UserProfile — GET /api/profile/get-profile/{id}
// ─────────────────────────────────────────────
class UserProfile {
  final String username;
  final String? firstName;
  final String? lastName;
  final String? phoneNumber;
  final DateTime? dateOfBirth;
  final double? weightKg;
  final double? heightCm;
  final int? pregnancies;

  const UserProfile({
    required this.username,
    this.firstName,
    this.lastName,
    this.phoneNumber,
    this.dateOfBirth,
    this.weightKg,
    this.heightCm,
    this.pregnancies,
  });

  // Computed — BMI from weight & height
  double? get bmi {
    if (weightKg == null || heightCm == null || heightCm == 0) return null;
    final h = heightCm! / 100;
    return weightKg! / (h * h);
  }

  // Computed — age from dateOfBirth
  int? get age {
    if (dateOfBirth == null) return null;
    final now = DateTime.now();
    int a = now.year - dateOfBirth!.year;
    if (now.month < dateOfBirth!.month ||
        (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) a--;
    return a;
  }

  String get fullName {
    final parts =
        [firstName, lastName].where((p) => p != null && p.isNotEmpty).toList();
    return parts.isNotEmpty ? parts.join(' ') : username;
  }

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
        username: j['username'] as String,
        firstName: j['firstName'] as String?,
        lastName: j['lastName'] as String?,
        phoneNumber: j['phoneNumber'] as String?,
        dateOfBirth: j['dateOfBirth'] != null
            ? DateTime.tryParse(j['dateOfBirth'] as String)
            : null,
        weightKg: (j['weightKg'] as num?)?.toDouble(),
        heightCm: (j['heightCm'] as num?)?.toDouble(),
        pregnancies: j['pregnancies'] as int?,
      );
}
