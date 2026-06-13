import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_page_scaffold.dart';
import '../../../shared/widgets/glass_card.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<dynamic> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _items = await context.read<AuthProvider>().api.getNotifications();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _markRead(int id) async {
    await context.read<AuthProvider>().api.markNotificationRead(id);
    _load();
  }

  int get _unread => _items.where((n) => n['is_read'] != true && n['is_read'] != 1).length;

  IconData _iconFor(String? type) {
    switch (type) {
      case 'announcement':
        return Icons.campaign_rounded;
      case 'success':
        return Icons.check_circle_rounded;
      case 'warning':
        return Icons.warning_amber_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _colorFor(String? type) {
    switch (type) {
      case 'announcement':
        return AppColors.primary;
      case 'success':
        return const Color(0xFF10B981);
      case 'warning':
        return AppColors.accent;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: 'Notifications',
      subtitle: _unread > 0 ? '$_unread unread messages' : 'You are all caught up',
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? EmptyState(icon: Icons.cloud_off_outlined, title: 'Could not load', subtitle: _error!, action: FilledButton(onPressed: _load, child: const Text('Retry')))
              : _items.isEmpty
                  ? const EmptyState(
                      icon: Icons.notifications_none_rounded,
                      title: 'No notifications',
                      subtitle: 'Announcements and updates will appear here',
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _items.length + 1,
                        itemBuilder: (_, i) {
                          if (i == 0) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: PageSummaryRow(chips: [
                                PageSummaryChip(icon: Icons.inbox_rounded, label: '${_items.length} total'),
                                PageSummaryChip(icon: Icons.mark_email_unread_rounded, label: '$_unread unread', color: AppColors.accent),
                              ]),
                            );
                          }
                          final n = _items[i - 1] as Map<String, dynamic>;
                          final isRead = n['is_read'] == true || n['is_read'] == 1;
                          final type = n['type']?.toString();
                          final color = _colorFor(type);

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: GlassCard(
                              onTap: () => _markRead(n['id']),
                              padding: EdgeInsets.all(isRead ? 14 : 16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: isRead ? 0.06 : 0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(_iconFor(type), color: isRead ? AppColors.textSecondary : color, size: 22),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          n['title']?.toString() ?? '',
                                          style: TextStyle(fontWeight: isRead ? FontWeight.w500 : FontWeight.w700, fontSize: 15),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          n['message']?.toString() ?? '',
                                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                                        ),
                                        if (n['created_at'] != null) ...[
                                          const SizedBox(height: 8),
                                          Text(_timeAgo(n['created_at'].toString()), style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                        ],
                                      ],
                                    ),
                                  ),
                                  if (!isRead)
                                    Container(
                                      width: 10,
                                      height: 10,
                                      margin: const EdgeInsets.only(top: 4),
                                      decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }

  String _timeAgo(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
