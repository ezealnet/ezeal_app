import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class AdminTokensPage extends ConsumerStatefulWidget {
  const AdminTokensPage({super.key});

  @override
  ConsumerState<AdminTokensPage> createState() => _AdminTokensPageState();
}

class _AdminTokensPageState extends ConsumerState<AdminTokensPage> {
  String _searchQuery = '';
  String? _selectedStatus;
  String? _selectedType;
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

  Future<void> _createTokenDialog() async {
    final assessmentsAsync = ref.read(adminAssessmentsProvider);
    final assessmentsList = assessmentsAsync.asData?.value ?? [];

    final institutionsAsync = ref.read(adminInstitutionsProvider);
    final institutionsList = institutionsAsync.asData?.value ?? [];

    if (assessmentsList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No assessments available to configure tokens.')),
      );
      return;
    }

    String selectedAssessmentId = assessmentsList.first['id'] as String;
    String? selectedInstitutionId;
    int tokenCount = 1;
    String tokenType = 'institution';
    String notes = '';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Generate Code / Offer Tokens'),
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
                    if (val != null) {
                      setDialogState(() {
                        tokenType = val;
                        if (val != 'institution') {
                          selectedInstitutionId = null;
                        }
                      });
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                if (tokenType == 'institution')
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Linked Partner Institution'),
                    value: selectedInstitutionId,
                    items: [
                      const DropdownMenuItem(value: null, child: Text('No Institution')),
                      ...institutionsList.map((i) => DropdownMenuItem(
                            value: i['user_id'] as String,
                            child: Text(i['institution_name'] as String? ?? 'Institution'),
                          )),
                    ],
                    onChanged: (val) => setDialogState(() => selectedInstitutionId = val),
                  ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Bulk count to generate'),
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
                  decoration: const InputDecoration(labelText: 'Notes / Explanations'),
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
              text: _isSaving ? 'Creating...' : 'Generate Codes',
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
                            'institution_id': selectedInstitutionId,
                            'assessment_id': selectedAssessmentId,
                            'status': 'available',
                            'token_type': tokenType,
                            'notes': notes.isNotEmpty ? notes : 'Created via Admin Dashboard',
                            'created_at': now,
                          });
                        }

                        await SupabaseService.client.from('institution_assessment_tokens').insert(tokenPayloads);

                        ref.invalidate(adminTokensProvider);
                        ref.invalidate(adminStatsProvider);
                        ref.invalidate(adminInstitutionsProvider);

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Successfully created $tokenCount code tokens.')),
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

  Future<void> _disableToken(String tokenId) async {
    setState(() => _isSaving = true);
    try {
      await SupabaseService.client
          .from('institution_assessment_tokens')
          .update({'status': 'disabled'})
          .eq('id', tokenId);
      ref.invalidate(adminTokensProvider);
      ref.invalidate(adminStatsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Token status set to disabled.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to disable token. RLS block.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokensAsync = ref.watch(adminTokensProvider);

    return AppScaffold(
      title: 'Token Management',
      drawer: const AdminNavigationDrawer(currentPath: '/admin/tokens'),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Token Registry Control',
                        style: AppTextStyles.headlineMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      AppButton(
                        text: 'Create Token',
                        onPressed: _createTokenDialog,
                        width: 140,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Filters
                  AppCard(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      children: [
                        TextField(
                          decoration: const InputDecoration(
                            labelText: 'Search by Token Code',
                            prefixIcon: Icon(Icons.search),
                          ),
                          onChanged: (val) => setState(() => _searchQuery = val.toUpperCase()),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                decoration: const InputDecoration(labelText: 'Filter by Status'),
                                value: _selectedStatus,
                                items: const [
                                  DropdownMenuItem(value: null, child: Text('All Statuses')),
                                  DropdownMenuItem(value: 'available', child: Text('Available')),
                                  DropdownMenuItem(value: 'assigned', child: Text('Assigned')),
                                  DropdownMenuItem(value: 'used', child: Text('Used')),
                                  DropdownMenuItem(value: 'disabled', child: Text('Disabled')),
                                ],
                                onChanged: (val) => setState(() => _selectedStatus = val),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                decoration: const InputDecoration(labelText: 'Filter by Type'),
                                value: _selectedType,
                                items: const [
                                  DropdownMenuItem(value: null, child: Text('All Types')),
                                  DropdownMenuItem(value: 'institution', child: Text('Institution Grant')),
                                  DropdownMenuItem(value: 'promotional', child: Text('Promotional Offer')),
                                  DropdownMenuItem(value: 'scholarship', child: Text('Scholarship Grant')),
                                  DropdownMenuItem(value: 'admin_grant', child: Text('Admin Grant')),
                                ],
                                onChanged: (val) => setState(() => _selectedType = val),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Tokens registry
                  tokensAsync.when(
                    data: (tokens) {
                      final filtered = tokens.where((t) {
                        final code = (t['token_code'] as String? ?? '').toUpperCase();
                        final status = t['status'] as String? ?? '';
                        final type = t['token_type'] as String? ?? 'institution';

                        final matchesSearch = code.contains(_searchQuery);
                        final matchesStatus = _selectedStatus == null || status == _selectedStatus;
                        final matchesType = _selectedType == null || type == _selectedType;

                        return matchesSearch && matchesStatus && matchesType;
                      }).toList();

                      if (filtered.isEmpty) {
                        return const AppCard(
                          padding: EdgeInsets.all(AppSpacing.xl),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.local_offer_outlined, size: 48, color: AppColors.textSecondaryLight),
                                SizedBox(height: AppSpacing.sm),
                                Text('No matching code tokens found.'),
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
                          final t = filtered[index];
                          final id = t['id'] as String? ?? '';
                          final code = t['token_code'] ?? '';
                          final status = t['status'] as String? ?? 'available';
                          final type = t['token_type'] as String? ?? 'institution';
                          final assessment = t['assessments'] as Map<String, dynamic>? ?? {};
                          final title = assessment['title'] ?? 'Assessment';
                          final inst = t['institution'] as Map<String, dynamic>? ?? {};
                          final instName = inst['full_name'] ?? 'Generic';

                          if (isMobile) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: AppSpacing.md),
                              child: AppCard(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          code,
                                          style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.copy, size: 16),
                                          onPressed: () {
                                            Clipboard.setData(ClipboardData(text: code));
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Code copied to clipboard.')),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                    Text('Assessment: $title', style: AppTextStyles.bodyMedium),
                                    Text('Type: ${type.toUpperCase()}  |  Partner: $instName', style: AppTextStyles.bodySmall),
                                    const SizedBox(height: AppSpacing.xs),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: status == 'available' ? AppColors.success.withValues(alpha: 0.1) : AppColors.error.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        status.toUpperCase(),
                                        style: TextStyle(
                                          color: status == 'available' ? AppColors.success : AppColors.error,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    if (status == 'available') ...[
                                      const SizedBox(height: AppSpacing.md),
                                      AppButton(
                                        text: 'Disable Code',
                                        onPressed: _isSaving ? null : () => _disableToken(id),
                                      ),
                                    ],
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
                                    child: Row(
                                      children: [
                                        Text(
                                          code,
                                          style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.copy, size: 16, color: AppColors.textSecondaryLight),
                                          onPressed: () {
                                            Clipboard.setData(ClipboardData(text: code));
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Copied.')),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(title, style: AppTextStyles.bodyMedium),
                                  ),
                                  Expanded(
                                    child: Text(type.toUpperCase(), style: AppTextStyles.bodyMedium),
                                  ),
                                  Expanded(
                                    child: Text(status.toUpperCase(), style: AppTextStyles.bodyMedium),
                                  ),
                                  Expanded(
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: status == 'available'
                                          ? AppButton(
                                              text: 'Disable',
                                              onPressed: _isSaving ? null : () => _disableToken(id),
                                              width: 90,
                                            )
                                          : const SizedBox(),
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
                        'Admin RLS policy required for this tokens view.',
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
