import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/glass_card.dart';

class CertificatesScreen extends StatefulWidget {
  const CertificatesScreen({super.key});

  @override
  State<CertificatesScreen> createState() => _CertificatesScreenState();
}

class _CertificatesScreenState extends State<CertificatesScreen> {
  List<dynamic> _certs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      _certs = await context.read<AuthProvider>().api.getCertificates();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Certificates')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _certs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.workspace_premium_outlined, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      const Text('Complete courses to earn certificates'),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _certs.length,
                  itemBuilder: (_, i) {
                    final c = _certs[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GlassCard(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.workspace_premium, color: AppColors.accent, size: 32),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(c['course_title'] ?? 'Course', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text('Code: ${c['certificate_code']}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                                ],
                              ),
                            ),
                            const Icon(Icons.qr_code, color: AppColors.primary),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
