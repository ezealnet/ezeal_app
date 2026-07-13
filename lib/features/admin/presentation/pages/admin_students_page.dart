import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../controllers/admin_providers.dart';
import '../widgets/admin_navigation_drawer.dart';

class AdminStudentsPage extends ConsumerStatefulWidget {
  const AdminStudentsPage({super.key});

  @override
  ConsumerState<AdminStudentsPage> createState() => _AdminStudentsPageState();
}

class _AdminStudentsPageState extends ConsumerState<AdminStudentsPage> {
  String _searchQuery = '';
  String? _selectedVerification;

  void _showStudentDetails(Map<String, dynamic> student) {
    final profile = student['profiles'] as Map<String, dynamic>? ?? {};
    final fullName = profile['full_name'] ?? 'Unknown Student';
    final email = profile['email'] ?? '';
    final phone = profile['phone'] ?? '';
    final completion = student['profile_completion'] ?? 0;
    final city = student['city'] ?? 'Not Specified';
    final state = student['state'] ?? 'Not Specified';
    final dob = student['date_of_birth'] ?? 'Not Specified';
    final gender = student['gender'] ?? 'Not Specified';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.backgroundLight,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(AppSpacing.radiusMd),
            topRight: Radius.circular(AppSpacing.radiusMd),
          ),
        ),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Student Information', style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: AppSpacing.sm),
            _buildDetailRow('Full Name', fullName),
            _buildDetailRow('Email Address', email),
            _buildDetailRow('Phone Number', phone),
            _buildDetailRow('Date of Birth', dob),
            _buildDetailRow('Gender Type', gender),
            _buildDetailRow('Completion Score', '$completion%'),
            _buildDetailRow('Location', '$city, $state'),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              text: 'Close Panel',
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondaryLight,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimaryLight),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(adminStudentsProvider);
    final verificationsAsync = ref.watch(adminVerificationProvider);
    final accessAsync = ref.watch(adminAccessProvider);

    return AppScaffold(
      title: 'Student Management',
      drawer: const AdminNavigationDrawer(currentPath: '/admin/students'),
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
                    'Student Roster Console',
                    style: AppTextStyles.headlineMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Search and Filters
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
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(labelText: 'Verification Status'),
                          value: _selectedVerification,
                          items: const [
                            DropdownMenuItem(value: null, child: Text('All Verification Statuses')),
                            DropdownMenuItem(value: 'verified', child: Text('Verified Aadhaar')),
                            DropdownMenuItem(value: 'pending', child: Text('Pending KYC')),
                            DropdownMenuItem(value: 'unverified', child: Text('Unverified')),
                          ],
                          onChanged: (val) => setState(() => _selectedVerification = val),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Student Roster List
                  studentsAsync.when(
                    data: (students) {
                      final verifications = verificationsAsync.asData?.value ?? [];
                      final accesses = accessAsync.asData?.value ?? [];

                      final filtered = students.where((s) {
                        final profile = s['profiles'] as Map<String, dynamic>? ?? {};
                        final name = (profile['full_name'] as String? ?? '').toLowerCase();
                        final email = (profile['email'] as String? ?? '').toLowerCase();
                        final userId = s['user_id'] as String? ?? '';

                        final identity = verifications.firstWhere(
                          (v) => v['user_id'] == userId,
                          orElse: () => <String, dynamic>{},
                        );
                        final vStatus = identity['verification_status'] as String? ?? 'unverified';

                        final matchesSearch = name.contains(_searchQuery) || email.contains(_searchQuery);
                        final matchesVerification = _selectedVerification == null || vStatus == _selectedVerification;

                        return matchesSearch && matchesVerification;
                      }).toList();

                      if (filtered.isEmpty) {
                        return const AppCard(
                          padding: EdgeInsets.all(AppSpacing.xl),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.school_outlined, size: 48, color: AppColors.textSecondaryLight),
                                SizedBox(height: AppSpacing.sm),
                                Text('No matching students found.'),
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
                          final student = filtered[index];
                          final userId = student['user_id'] as String? ?? '';
                          final profile = student['profiles'] as Map<String, dynamic>? ?? {};
                          final name = profile['full_name'] ?? 'Unknown Student';
                          final email = profile['email'] ?? '';
                          final completion = student['profile_completion'] ?? 0;

                          final identity = verifications.firstWhere(
                            (v) => v['user_id'] == userId,
                            orElse: () => <String, dynamic>{},
                          );
                          final vStatus = identity['verification_status'] as String? ?? 'unverified';
                          final ezealId = identity['ezeal_id'] as String? ?? 'None';

                          final unlockedTests = accesses.where((a) => a['user_id'] == userId).length;
                          final completedTests = accesses.where((a) => a['user_id'] == userId && a['status'] == 'completed').length;

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
                                    Text('Completion: $completion%', style: AppTextStyles.bodySmall),
                                    Text('Ezeal ID: $ezealId ($vStatus)', style: AppTextStyles.bodySmall),
                                    Text('Tests: $unlockedTests Unlocked, $completedTests Completed', style: AppTextStyles.bodySmall),
                                    const SizedBox(height: AppSpacing.md),
                                    AppButton(
                                      text: 'View Profiles',
                                      onPressed: () => _showStudentDetails(student),
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
                                    child: Text('KYC: $vStatus', style: AppTextStyles.bodyMedium),
                                  ),
                                  Expanded(
                                    child: Text('Prog: $completion%', style: AppTextStyles.bodyMedium),
                                  ),
                                  Expanded(
                                    child: Text('Tests: $completedTests/$unlockedTests', style: AppTextStyles.bodyMedium),
                                  ),
                                  Expanded(
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: AppButton(
                                        text: 'View Info',
                                        onPressed: () => _showStudentDetails(student),
                                        width: 100,
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
                        'Admin RLS policy required for this student roster view.',
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
