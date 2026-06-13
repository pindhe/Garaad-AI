import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'app_drawer.dart';

class AppShell extends StatelessWidget {
  final Widget body;
  final int currentIndex;
  final ValueChanged<int> onTabChanged;
  final String title;
  final bool showHeader;
  final List<Widget>? headerActions;
  final VoidCallback onAssignments;
  final VoidCallback onCertificates;
  final VoidCallback onNotifications;
  final VoidCallback onLogout;
  final String userName;
  final String userEmail;
  final int totalXp;

  const AppShell({
    super.key,
    required this.body,
    required this.currentIndex,
    required this.onTabChanged,
    required this.title,
    this.showHeader = true,
    this.headerActions,
    required this.onAssignments,
    required this.onCertificates,
    required this.onNotifications,
    required this.onLogout,
    required this.userName,
    required this.userEmail,
    this.totalXp = 0,
  });

  static const _tabs = [
    _TabItem(Icons.home_outlined, Icons.home_rounded, 'Home'),
    _TabItem(Icons.menu_book_outlined, Icons.menu_book_rounded, 'Courses'),
    _TabItem(Icons.smart_toy_outlined, Icons.smart_toy_rounded, 'AI Chat'),
    _TabItem(Icons.person_outline, Icons.person_rounded, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      drawer: AppDrawer(
        currentIndex: currentIndex,
        onTabChanged: onTabChanged,
        onAssignments: onAssignments,
        onCertificates: onCertificates,
        onNotifications: onNotifications,
        onLogout: onLogout,
        userName: userName,
        userEmail: userEmail,
        totalXp: totalXp,
      ),
      appBar: showHeader
          ? AppBar(
              leading: Builder(
                builder: (ctx) => IconButton(
                  icon: const Icon(Icons.menu_rounded),
                  tooltip: 'Menu',
                  onPressed: () => Scaffold.of(ctx).openDrawer(),
                ),
              ),
              title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
              actions: headerActions,
              centerTitle: false,
            )
          : null,
      body: body,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
          border: Border(top: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade200)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: List.generate(_tabs.length, (i) {
                final tab = _tabs[i];
                final selected = currentIndex == i;
                return Expanded(
                  child: _BottomNavItem(
                    icon: selected ? tab.selectedIcon : tab.icon,
                    label: tab.label,
                    selected: selected,
                    onTap: () => onTabChanged(i),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  const _TabItem(this.icon, this.selectedIcon, this.label);
}

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = selected ? AppColors.primary : (isDark ? Colors.white54 : AppColors.textSecondary);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(fontSize: 11, fontWeight: selected ? FontWeight.w700 : FontWeight.w500, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
