// import 'package:bfine/features/dashboard/doctor_providers.dart';
// import 'package:bfine/features/dashboard/screens/dashboard_doctor.dart';
// import 'package:bfine/features/doctor_patients/doctor_patients_screen.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:go_router/go_router.dart';
// import '../auth/auth_storage.dart';
// import '../../features/auth/screens/login_screen.dart';
// import '../../features/dashboard/screens/dashboard_screen.dart';
// import '../../features/readings/screens/readings_screen.dart';
// import '../../features/prediction/screens/prediction_screen.dart';
// import '../../features/profile/screens/profile_screen.dart';
// import '../../features/profile/screens/edit_profile_screen.dart';
// import '../../features/profile/screens/change_password_screen.dart';
// import '../../shared/widgets/main_shell.dart';

// final appRouterProvider = Provider<GoRouter>((ref) {
//   return GoRouter(
//     initialLocation: '/dashboard',
//     redirect: (ctx, state) async {
//       final loggedIn = await AuthStorage.hasSession();
//       final onAuth = state.matchedLocation == '/login';
//       if (!loggedIn && !onAuth) return '/login';
//       if (loggedIn && onAuth) return '/dashboard';
//       return null;
//     },
//     routes: [
//       GoRoute(
//         path: '/login',
//         builder: (_, __) => const LoginScreen(),
//       ),
//       ShellRoute(
//         builder: (_, __, child) => MainShell(child: child),
//         routes: [
//           GoRoute(
//             path: '/dashboard',
//             builder: (_, __) => const DashboardScreen(),
//           ),
//           GoRoute(
//             path: '/dashDoctor',
//             builder: (_, __) => const DashboardDoctor(),
//           ),
//           GoRoute(
//             path: '/doctor/patients',
//             builder: (_, __) => const DoctorPatientsScreen(),
//             routes: [
//               // Route enfant pour le détail d'un patient spécifique
//               GoRoute(
//                 path: ':id',
//                 builder: (context, state) {
//                   // On récupère l'ID depuis l'URL
//                   final patientId = int.parse(state.pathParameters['id']!);

//                   // On récupère l'objet patient passé via l'extra (recommandé avec GoRouter)
//                   // Si l'extra est nul, on génère un résumé minimal à partir de l'ID
//                   final patient = state.extra as PatientSummary? ??
//                       PatientSummary(
//                           id: patientId, fullName: 'Patient #$patientId');

//                   return PatientDetailScreen(patient: patient);
//                 },
//               ),
//             ],
//           ),
//           GoRoute(
//             path: '/readings',
//             builder: (_, __) => const ReadingsScreen(),
//           ),
//           GoRoute(
//             path: '/prediction',
//             builder: (_, __) => const PredictionScreen(),
//           ),
//           GoRoute(
//             path: '/profile',
//             builder: (_, __) => const ProfileScreen(),
//             routes: [
//               GoRoute(
//                 path: 'edit',
//                 builder: (_, __) => const EditProfileScreen(),
//               ),
//               GoRoute(
//                 path: 'change-password',
//                 builder: (_, __) => const ChangePasswordScreen(),
//               ),
//             ],
//           ),
//         ],
//       ),
//     ],
//   );
// });
import 'package:bfine/features/admin/admin_shell.dart';
import 'package:bfine/features/admin/screens/admin_screen.dart';
import 'package:bfine/features/dashboard/doctor_providers.dart';
import 'package:bfine/features/dashboard/screens/dashboard_doctor.dart';
import 'package:bfine/features/doctor_patients/doctor_patients_screen.dart';
import 'package:bfine/shared/widgets/doctor_shell.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../auth/auth_storage.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/readings/screens/readings_screen.dart';
import '../../features/prediction/screens/prediction_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/profile/screens/edit_profile_screen.dart';
import '../../features/profile/screens/change_password_screen.dart';
import '../../shared/widgets/main_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    redirect: (ctx, state) async {
      final loggedIn = await AuthStorage.hasSession();
      final onLogin = state.matchedLocation == '/login';

      if (!loggedIn && !onLogin) return '/login';
      if (loggedIn && onLogin) {
        final userType = await AuthStorage.getUserType();
        switch (userType?.toLowerCase()) {
          case 'doctor':
            return '/doctor/dashboard';
          case 'admin':
            return '/admin/dashboard';
          default:
            return '/dashboard';
        }
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', redirect: (_, __) => '/login'),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),

      // ── Patient shell ──────────────────────────────────
      ShellRoute(
        builder: (_, __, child) => MainShell(child: child),
        routes: [
          GoRoute(
              path: '/dashboard', builder: (_, __) => const DashboardScreen()),
          GoRoute(
              path: '/readings', builder: (_, __) => const ReadingsScreen()),
          GoRoute(
              path: '/prediction',
              builder: (_, __) => const PredictionScreen()),
          GoRoute(
            path: '/profile',
            builder: (_, __) => const ProfileScreen(),
            routes: [
              GoRoute(
                  path: 'edit', builder: (_, __) => const EditProfileScreen()),
              GoRoute(
                  path: 'change-password',
                  builder: (_, __) => const ChangePasswordScreen()),
            ],
          ),
        ],
      ),

      // ── Doctor shell ───────────────────────────────────
      ShellRoute(
        builder: (_, __, child) => DoctorShell(child: child),
        routes: [
          GoRoute(
              path: '/doctor/dashboard',
              builder: (_, __) => const DashboardDoctor()),
          GoRoute(
            path: '/doctor/patients',
            builder: (_, __) => const DoctorPatientsScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (ctx, state) {
                  final patientId = int.parse(state.pathParameters['id']!);
                  final patient = state.extra as PatientSummary? ??
                      PatientSummary(
                          id: patientId, fullName: 'Patient #$patientId');
                  return PatientDetailScreen(patient: patient);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/doctor/profile',
            builder: (_, __) => const ProfileScreen(),
            routes: [
              GoRoute(
                  path: 'edit', builder: (_, __) => const EditProfileScreen()),
              GoRoute(
                  path: 'change-password',
                  builder: (_, __) => const ChangePasswordScreen()),
            ],
          ),
        ],
      ),

      // ── Admin shell ────────────────────────────────────
      ShellRoute(
        builder: (_, __, child) => AdminShell(child: child),
        routes: [
          GoRoute(
              path: '/admin/dashboard',
              builder: (_, __) => const AdminScreen()),
          GoRoute(
            path: '/admin/profile',
            builder: (_, __) => const ProfileScreen(),
            routes: [
              GoRoute(
                  path: 'edit', builder: (_, __) => const EditProfileScreen()),
              GoRoute(
                  path: 'change-password',
                  builder: (_, __) => const ChangePasswordScreen()),
            ],
          ),
        ],
      ),
    ],
  );
});
