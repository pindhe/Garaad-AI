import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_page_scaffold.dart';
import '../../../shared/widgets/glass_card.dart';

class CertificatesScreen extends StatefulWidget {
  const CertificatesScreen({super.key});

  @override
  State<CertificatesScreen> createState() => _CertificatesScreenState();
}

class _CertificatesScreenState extends State<CertificatesScreen> {
  List<dynamic> _certs = [];
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
      _certs = await context.read<AuthProvider>().api.getCertificates();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    }
    if (mounted) setState(() => _loading = false);
  }

  void _showCert(Map<String, dynamic> c) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [AppColors.accent, AppColors.accent.withValues(alpha: 0.7)]),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 36),
            ),
            const SizedBox(height: 16),
            Text(c['course_title']?.toString() ?? 'Course', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text('Certificate of Completion', style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 20),
            GlassCard(
              child: Row(
                children: [
                  const Icon(Icons.qr_code_2_rounded, color: AppColors.primary, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Verification code', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        Text(c['certificate_code']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: c['certificate_code']?.toString() ?? ''));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Code copied')));
                    },
                    icon: const Icon(Icons.copy_rounded),
                  ),
                ],
              ),
            ),
            if (c['issued_at'] != null) ...[
              const SizedBox(height: 12),
              Text('Issued ${_fmtDate(c['issued_at'].toString())}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ],
          ],
        ),
      ),
    );
  }

  String _fmtDate(String iso) {
    final d = DateTime.tryParse(iso);
    if (d == null) return iso;
    return '${d.day}/${d.month}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: 'Certificates',
      subtitle: 'Your earned achievements and credentials',
      headerColor: Colors.purple,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? EmptyState(icon: Icons.cloud_off_outlined, title: 'Could not load', subtitle: _error!, action: FilledButton(onPressed: _load, child: const Text('Retry')))
              : _certs.isEmpty
                  ? EmptyState(
                      icon: Icons.workspace_premium_outlined,
                      title: 'No certificates yet',
                      subtitle: 'Complete courses 100% to earn certificates',
                      action: FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Back to courses')),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _certs.length + 1,
                        itemBuilder: (_, i) {
                          if (i == 0) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: PageSummaryRow(chips: [
                                PageSummaryChip(icon: Icons.workspace_premium_rounded, label: '${_certs.length} earned', color: Colors.purple),
                              ]),
                            );
                          }
                          final c = _certs[i - 1] as Map<String, dynamic>;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: GlassCard(
                              onTap: () => _showCert(c),
                              child: Row(
                                children: [
                                  Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)]),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 28),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(c['course_title']?.toString() ?? 'Course', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                                        const SizedBox(height: 4),
                                        Text('Code: ${c['certificate_code']}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                        if (c['issued_at'] != null)
                                          Text('Issued ${_fmtDate(c['issued_at'].toString())}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
