import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/services/supabase_service.dart';
import '../controllers/admin_providers.dart';
import '../widgets/admin_navigation_drawer.dart';

class AdminAccessPage extends ConsumerStatefulWidget {
  const AdminAccessPage({super.key});

  @override
  ConsumerState<AdminAccessPage> createState() => _AdminAccessPageState();
}

class _AdminAccessPageState extends ConsumerState<AdminAccessPage> {
  String _searchQuery = '';
  String? _selectedStatus;
  String? _selectedSource;
  bool _isSaving = false;

  Future<void> _grantAccessDialog() async {
    final assessmentsAsync = ref.read(adminAssessmentsProvider);
    final assessmentsList = assessmentsAsync.asData?.value ?? [];

    if (assessmentsList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No assessments available to grant.')),
      );
      return;
    }

    String selectedAssessmentId = assessmentsList.first['id'] as String;
    String studentEmail = '';
    String source = 'individual';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Grant Manual Assessment Access'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Student Email Address',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  onChanged: (val) => setDialogState(() => studentEmail = val),
                ),
                const SizedBox(height: AppSpacing.sm),
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
                  decoration: const InputDecoration(labelText: 'Access Source'),
                  value: source,
                  items: const [
                    DropdownMenuItem(value: 'individual', child: Text('Individual Purchase')),
                    DropdownMenuItem(value: 'institution', child: Text('Institution Token')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => source = val);
                  },
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
              text: _isSaving ? 'Granting...' : 'Grant Access',
              onPressed: _isSaving
                  ? null
                  : () async {
                      if (studentEmail.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter email.')),
                        );
                        return;
                      }

                      setDialogState(() => _isSaving = true);
                      try {
                        // 1. Lookup student user and their Ezeal ID
                        final profileRes = await SupabaseService.client
                            .from('profiles')
                            .select('id')
                            .eq('email', studentEmail.trim().toLowerCase())
                            .maybeSingle();

                        if (profileRes == null) {
                          throw Exception('No registered student account matches this email.');
                        }

                        final studentId = profileRes['id'] as String;

                        final identityRes = await SupabaseService.client
                            .from('ezeal_identities')
                            .select('id')
                            .eq('user_id', studentId)
                            .eq('role_type', 'student')
                            .eq('verification_status', 'verified')
                            .maybeSingle();

                        final String? identityId = identityRes?['id'] as String?;

                        // 2. Insert assessment access
                        await SupabaseService.client.from('assessment_access').insert({
                          'user_id': studentId,
                          'assessment_id': selectedAssessmentId,
                          'ezeal_identity_id': identityId,
                          'access_source': source,
                          'status': 'unlocked',
                        });

                        ref.invalidate(adminAccessProvider);
                        ref.invalidate(adminStatsProvider);

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Assessment access granted successfully.')),
                          );
                        }
                      } catch (e) {
                        String msg = 'Failed to grant access.';
                        if (e.toString().contains('No registered student')) {
                          msg = 'No student found with this email.';
                        } else if (e.toString().contains('23505')) {
                          msg = 'This student already has access to this assessment.';
                        }
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(msg)),
                          );
                        }
                      } finally {
                        setDialogState(() => _isSaving = false);
                        if (mounted) Navigator.pop(context);
                      }
                    },
              width: 130,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accessAsync = ref.watch(adminAccessProvider);

    return AppScaffold(
      title: 'Access Management',
      drawer: const AdminNavigationDrawer(currentPath: '/admin/access'),
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
                        'Assessment Access control',
                        style: AppTextStyles.headlineMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      AppButton(
                        text: 'Grant Access',
                        onPressed: _grantAccessDialog,
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
                            labelText: 'Search by Student Name or Email',
                            prefixIcon: Icon(Icons.search),
                          ),
                          onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
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
                                  DropdownMenuItem(value: 'unlocked', child: Text('Unlocked')),
                                  DropdownMenuItem(value: 'started', child: Text('Started')),
                                  DropdownMenuItem(value: 'completed', child: Text('Completed')),
                                ],
                                onChanged: (val) => setState(() => _selectedStatus = val),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                decoration: const InputDecoration(labelText: 'Filter by Source'),
                                value: _selectedSource,
                                items: const [
                                  DropdownMenuItem(value: null, child: Text('All Sources')),
                                  DropdownMenuItem(value: 'individual', child: Text('Individual')),
                                  DropdownMenuItem(value: 'institution', child: Text('Institution')),
                                ],
                                onChanged: (val) => setState(() => _selectedSource = val),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Access list
                  accessAsync.when(
                    data: (accessList) {
                      final filtered = accessList.where((a) {
                        final profile = a['profiles'] as Map<String, dynamic>? ?? {};
                        final name = (profile['full_name'] as String? ?? '').toLowerCase();
                        final email = (profile['email'] as String? ?? '').toLowerCase();
                        final status = a['status'] as String? ?? '';
                        final source = a['access_source'] as String? ?? '';

                        final matchesSearch = name.contains(_searchQuery) || email.contains(_searchQuery);
                        final matchesStatus = _selectedStatus == null || status == _selectedStatus;
                        final matchesSource = _selectedSource == null || source == _selectedSource;

                        return matchesSearch && matchesStatus && matchesSource;
                      }).toList();

                      if (filtered.isEmpty) {
                        return const AppCard(
                          padding: EdgeInsets.all(AppSpacing.xl),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.vpn_key_outlined, size: 48, color: AppColors.textSecondaryLight),
                                SizedBox(height: AppSpacing.sm),
                                Text('No matching access grants found.'),
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
                          final a = filtered[index];
                          final profile = a['profiles'] as Map<String, dynamic>? ?? {};
                          final name = profile['full_name'] ?? 'Unknown Student';
                          final email = profile['email'] ?? '';
                          final assessment = a['assessments'] as Map<String, dynamic>? ?? {};
                          final title = assessment['title'] ?? 'Assessment';
                          final source = a['access_source'] as String? ?? 'individual';
                          final status = a['status'] as String? ?? 'unlocked';
                          final date = a['created_at'] != null ? a['created_at'].toString().split('T').first : '';

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
                                    Text(email, style: AppTextStyles.bodyMedium),
                                    const SizedBox(height: AppSpacing.xs),
                                    Text('Assessment: $title', style: AppTextStyles.bodySmall),
                                    Text('Source: ${source.toUpperCase()}  |  Date: $date', style: AppTextStyles.bodySmall),
                                    const SizedBox(height: AppSpacing.xs),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: status == 'completed' ? AppColors.success.withValues(alpha: 0.1) : AppColors.info.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        status.toUpperCase(),
                                        style: TextStyle(
                                          color: status == 'completed' ? AppColors.success : AppColors.info,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
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
                                        Text(email, style: AppTextStyles.bodySmall),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(title, style: AppTextStyles.bodyMedium),
                                  ),
                                  Expanded(
                                    child: Text(source.toUpperCase(), style: AppTextStyles.bodyMedium),
                                  ),
                                  Expanded(
                                    child: Text(status.toUpperCase(), style: AppTextStyles.bodyMedium),
                                  ),
                                  Expanded(
                                    child: Text(date, style: AppTextStyles.bodyMedium),
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
                        'Admin RLS policy required for this access list.',
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
