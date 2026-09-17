import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/utils/responsive.dart';

/// One entry in the app's top-level navigation.
class _NavItem {
  const _NavItem(this.path, this.label, this.icon, this.selectedIcon);

  final String path;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

const _navItems = [
  _NavItem('/dashboard', 'Dashboard', Icons.dashboard_outlined, Icons.dashboard),
  _NavItem('/accounts', 'Accounts', Icons.account_balance_outlined, Icons.account_balance),
  _NavItem('/transactions', 'Transactions', Icons.receipt_long_outlined, Icons.receipt_long),
  _NavItem('/savings', 'Savings', Icons.savings_outlined, Icons.savings),
  _NavItem('/reports', 'Reports', Icons.bar_chart_outlined, Icons.bar_chart),
  _NavItem('/settings', 'Settings', Icons.settings_outlined, Icons.settings),
];

/// Responsive navigation shell wrapping every top-level page.
///
/// Used as the `builder` of a [ShellRoute] in `app/router.dart`, so [child]
/// is whatever the active [GoRoute] resolves to.
class NavigationShell extends StatelessWidget {
  const NavigationShell({super.key, required this.child});

  final Widget child;

  int _indexForLocation(String location) {
    final index = _navItems.indexWhere((item) => location.startsWith(item.path));
    return index == -1 ? 0 : index;
  }

  void _onSelect(BuildContext context, int index) {
    context.go(_navItems[index].path);
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final selectedIndex = _indexForLocation(location);
    final isWide = isWideScreen(context);

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: selectedIndex,
              onDestinationSelected: (index) => _onSelect(context, index),
              destinations: [
                for (final item in _navItems)
                  NavigationRailDestination(
                    icon: Icon(item.icon),
                    selectedIcon: Icon(item.selectedIcon),
                    label: Text(item.label),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: child),
          ],
        ),
      );
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) => _onSelect(context, index),
        destinations: [
          for (final item in _navItems)
            NavigationDestination(
              icon: Icon(item.icon),
              selectedIcon: Icon(item.selectedIcon),
              label: item.label,
            ),
        ],
      ),
    );
  }
}
