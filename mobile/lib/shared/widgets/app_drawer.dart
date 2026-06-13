import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class AppDrawer extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabChanged;
  final VoidCallback onAssignments;
  final VoidCallback onCertificates;
  final VoidCallback onNotifications;
  final VoidCallback onLogout;
  final String userName;
  final String userEmail;
  final int totalXp;

  const AppDrawer({
    super.key,
    required this.currentIndex,
    required this.onTabChanged,
    required this.onAssignments,
    required this.onCertificates,
    required this.onNotifications,
    required this.onLogout,
    required this.userName,
    required this.userEmail,
    this.totalXp = 0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [const Color(0xFF1E3A8A), AppColors.darkSurface]
                      : [AppColors.primary, const Color(0xFF1D4ED8)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    child: Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : 'S',
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(userName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                  Text(userEmail, style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 13)),
                  if (totalXp > 0) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.bolt_rounded, size: 14, color: AppColors.accent.withValues(alpha: 0.95)),
                          const SizedBox(width: 4),
                          Text('$totalXp XP', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _DrawerItem(
                    icon: Icons.home_rounded,
                    label: 'Home',
                    selected: currentIndex == 0,
                    onTap: () => _go(context, 0),
                  ),
                  _DrawerItem(
                    icon: Icons.menu_book_rounded,
                    label: 'Courses',
                    selected: currentIndex == 1,
                    onTap: () => _go(context, 1),
                  ),
                  _DrawerItem(
                    icon: Icons.smart_toy_rounded,
                    label: 'AI Chat',
                    selected: currentIndex == 2,
                    onTap: () => _go(context, 2),
                  ),
                  _DrawerItem(
                    icon: Icons.person_rounded,
                    label: 'Profile',
                    selected: currentIndex == 3,
                    onTap: () => _go(context, 3),
                  ),
                  const Divider(height: 24, indent: 20, endIndent: 20),
                  _DrawerItem(icon: Icons.assignment_rounded, label: 'Assignments', onTap: () { Navigator.pop(context); onAssignments(); }),
                  _DrawerItem(icon: Icons.workspace_premium_rounded, label: 'Certificates', onTap: () { Navigator.pop(context); onCertificates(); }),
                  _DrawerItem(icon: Icons.notifications_rounded, label: 'Notifications', onTap: () { Navigator.pop(context); onNotifications(); }),
                  _DrawerItem(icon: Icons.star_rounded, label: 'Subscription', onTap: () { Navigator.pop(context); Navigator.pushNamed(context, '/subscription'); }),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  onLogout();
                },
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text('Sign Out'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: BorderSide(color: Colors.red.shade200),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _go(BuildContext context, int index) {
    Navigator.pop(context);
    onTabChanged(index);
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    this.selected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      leading: Icon(icon, color: selected ? AppColors.primary : (isDark ? Colors.white70 : AppColors.textSecondary)),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? AppColors.primary : null,
        ),
      ),
      selected: selected,
      selectedTileColor: AppColors.primary.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      onTap: onTap,
    );
  }
}
