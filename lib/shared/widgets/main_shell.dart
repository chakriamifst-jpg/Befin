import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  static const _tabs = [
    (icon: Icons.dashboard_outlined,  activeIcon: Icons.dashboard,  label: 'Home',       path: '/dashboard'),
    (icon: Icons.water_drop_outlined, activeIcon: Icons.water_drop, label: 'Readings',   path: '/readings'),
    (icon: Icons.psychology_outlined, activeIcon: Icons.psychology, label: 'Prediction', path: '/prediction'),
    (icon: Icons.person_outline,      activeIcon: Icons.person,     label: 'Profile',    path: '/profile'),
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
        items: _tabs.map((t) => BottomNavigationBarItem(
          icon:       Icon(t.icon),
          activeIcon: Icon(t.activeIcon),
          label:      t.label,
        )).toList(),
      ),
    );
  }
}
