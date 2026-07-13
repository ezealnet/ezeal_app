import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/services/supabase_service.dart';
import '../controllers/admin_providers.dart';
import '../widgets/admin_navigation_drawer.dart';

class AdminInstitutionsPage extends ConsumerStatefulWidget {
  const AdminInstitutionsPage({super.key});

  @override
  ConsumerState<AdminInstitutionsPage> createState() => _AdminInstitutionsPageState();
}

class _AdminInstitutionsPageState extends ConsumerState<AdminInstitutionsPage> {
  String _searchQuery = '';
  bool _isSaving = false;

  String _generateRandomCode(String prefix) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = Random();
    final buffer = StringBuffer(prefix);
    for (int i = 0; i < 8; i++) {
      buffer.write(chars[rand.nextInt(chars.length)]);
    }
    return buffer.toString();
  }

  Future<void> _issueTokensDialog(Map<String, dynamic> institution) async {
    final profile = institution['profiles'] as Map<String, dynamic>? ?? {};
    final institutionId = studentProfileId(institution);
    final institutionName = institution['institution_name'] ?? profile['full_name'] ?? 'Institution';

    final assessmentsAsync = ref.read(adminAssessmentsProvider);
    final assessmentsList = assessmentsAsync.asData?.value ?? [];

    if (assessmentsList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No assessments loaded to generate tokens.')),
      );
      return;
    }

    String selectedAssessmentId = assessmentsList.first['id'] as String;
    int tokenCount = 5;
    String tokenType = 'institution';
    String notes = '';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Issue Tokens - $institutionName'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Select Assessment'),
                  value: selectedAssessmentId,
                  items: assessmentsList
                      .map((a) => DropdownMenuItem(
                            value: a['id'] as String,
                            child: Text(a['title'] as String? ?? 'Assessment'),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedAssessmentId = val);
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Token Type'),
                  value: tokenType,
                  items: const [
                    DropdownMenuItem(value: 'institution', child: Text('Institution Grant')),
                    DropdownMenuItem(value: 'promotional', child: Text('Promotional Offer')),
                    DropdownMenuItem(value: 'scholarship', child: Text('Scholarship Grant')),
                    DropdownMenuItem(value: 'admin_grant', child: Text('Admin Direct Grant')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => tokenType = val);
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Number of Tokens to Create'),
                  initialValue: '$tokenCount',
                  keyboardType: TextInputType.number,
                  onChanged: (val) {
                    final parsed = int.tryParse(val);
                    if (parsed != null && parsed > 0) {
                      setDialogState(() => tokenCount = parsed);
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Notes / Context'),
                  maxLines: 2,
                  onChanged: (val) => setDialogState(() => notes = val),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            AppButton(
              text: _isSaving ? 'Generating...' : 'Generate Tokens',
              onPressed: _isSaving
                  ? null
                  : () async {
                      setDialogState(() => _isSaving = true);
                      try {
                        final List<Map<String, dynamic>> tokenPayloads = [];
                        final now = DateTime.now().toIso8601String();
                        final prefix = tokenType == 'promotional'
                            ? 'PROM-'
                            : tokenType == 'scholarship'
                                ? 'SCHL-'
                                : tokenType == 'admin_grant'
                                    ? 'ADMN-'
                                    : 'INST-';

                        for (int i = 0; i < tokenCount; i++) {
                          final code = _generateRandomCode(prefix);
                          tokenPayloads.add({
                            'token_code': code,
                            'institution_id': institutionId,
                            'assessment_id': selectedAssessmentId,
                            'status': 'available',
                            'token_type': tokenType,
                            'notes': notes.isNotEmpty ? notes : 'Generated by Admin Console',
                            'created_at': now,
                          });
                        }

                        await SupabaseService.client.from('institution_assessment_tokens').insert(tokenPayloads);

                        ref.invalidate(adminTokensProvider);
                        ref.invalidate(adminStatsProvider);
                        ref.invalidate(adminInstitutionsProvider);

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Successfully issued $tokenCount tokens.')),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Failed to generate tokens. RLS policies block.')),
                          );
                        }
                      } finally {
                        setDialogState(() => _isSaving = false);
                        if (mounted) Navigator.pop(context);
                      }
                    },
              width: 140,
            ),
          ],
        ),
      ),
    );
  }

  String studentProfileId(Map<String, dynamic> inst) {
    return inst['user_id'] as String? ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final institutionsAsync = ref.watch(adminInstitutionsProvider);
    final tokensAsync = ref.watch(adminTokensProvider);
    final studentsAsync = ref.watch(adminStudentsProvider);

    return AppScaffold(
      title: 'Institution Management',
      drawer: const AdminNavigationDrawer(currentPath: '/admin/institutions'),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Partner Institutions Management',
                    style: AppTextStyles.headlineMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Search panel
                  AppCard(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'Search by Institution Name',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Institutions List
                  institutionsAsync.when(
                    data: (institutions) {
                      final tokens = tokensAsync.asData?.value ?? [];
                      final students = studentsAsync.asData?.value ?? [];

                      final filtered = institutions.where((inst) {
                        final profile = inst['profiles'] as Map<String, dynamic>? ?? {};
                        final name = (inst['institution_name'] as String? ?? profile['full_name'] as String? ?? '').toLowerCase();
                        return name.contains(_searchQuery);
                      }).toList();

                      if (filtered.isEmpty) {
                        return const AppCard(
                          padding: EdgeInsets.all(AppSpacing.xl),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.business_outlined, size: 48, color: AppColors.textSecondaryLight),
                                SizedBox(height: AppSpacing.sm),
                                Text('No matching institutions found.'),
                              ],
                            ),
                          ),
                        );
                      }

                      final bool isMobile = MediaQuery.of(context).size.width < 700;

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final inst = filtered[index];
                          final instId = inst['user_id'] as String? ?? '';
                          final profile = inst['profiles'] as Map<String, dynamic>? ?? {};
                          final name = inst['institution_name'] ?? profile['full_name'] ?? 'Institution';
                          final contact = inst['contact_person'] ?? 'None';
                          final status = profile['status'] ?? 'pending';

                          final instTokens = tokens.where((t) => t['institution_id'] == instId);
                          final tokensIssued = instTokens.length;
                          final tokensUsed = instTokens.where((t) => t['status'] == 'used').length;
                          final linkedStudents = students.where((s) => s['education_metadata'] != null && s['education_metadata'].toString().contains(name)).length;

                          if (isMobile) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: AppSpacing.md),
                              child: AppCard(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text('Contact: $contact', style: AppTextStyles.bodyMedium),
                                    Text('Status: ${status.toUpperCase()}', style: AppTextStyles.bodySmall),
                                    const SizedBox(height: AppSpacing.xs),
                                    Text('Tokens: $tokensIssued Issued, $tokensUsed Used', style: AppTextStyles.bodySmall),
                                    Text('Linked Students: $linkedStudents', style: AppTextStyles.bodySmall),
                                    const SizedBox(height: AppSpacing.md),
                                    AppButton(
                                      text: 'Issue Tokens',
                                      onPressed: () => _issueTokensDialog(inst),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: AppCard(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text('Contact: $contact', style: AppTextStyles.bodySmall),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Text('Linked: $linkedStudents', style: AppTextStyles.bodyMedium),
                                  ),
                                  Expanded(
                                    child: Text('Tokens: $tokensUsed/$tokensIssued', style: AppTextStyles.bodyMedium),
                                  ),
                                  Expanded(
                                    child: Text('Status: ${status.toUpperCase()}', style: AppTextStyles.bodyMedium),
                                  ),
                                  Expanded(
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: AppButton(
                                        text: 'Issue Tokens',
                                        onPressed: () => _issueTokensDialog(inst),
                                        width: 120,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(AppSpacing.xl),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (err, _) => Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      color: AppColors.error.withValues(alpha: 0.1),
                      child: const Text(
                        'Admin RLS policy required for this institutions view.',
                        style: TextStyle(color: AppColors.error),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
