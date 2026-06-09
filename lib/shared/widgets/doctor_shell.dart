import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DoctorShell extends StatelessWidget {
  final Widget child;
  const DoctorShell({super.key, required this.child});

  static const _tabs = [
    (
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard,
      label: 'Dashboard',
      path: '/doctor/dashboard'
    ),
    (
      icon: Icons.people_outline,
      activeIcon: Icons.people,
      label: 'Patients',
      path: '/doctor/patients'
    ),
    (
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: 'Profile',
      path: '/doctor/profile'
    ),
  ];

  int _currentIndex(BuildContext ctx) {
    final loc = GoRouterState.of(ctx).matchedLocation;
    for (var i = 0; i < _tabs.length; i++) {
      if (loc.startsWith(_tabs[i].path)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext ctx) {
    final idx = _currentIndex(ctx);
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: idx,
        onTap: (i) => ctx.go(_tabs[i].path),
        items: _tabs
            .map((t) => BottomNavigationBarItem(
                  icon: Icon(t.icon),
                  activeIcon: Icon(t.activeIcon),
                  label: t.label,
                ))
            .toList(),
      ),
    );
  }
}
