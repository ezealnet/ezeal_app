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

class AdminUsersPage extends ConsumerStatefulWidget {
  const AdminUsersPage({super.key});

  @override
  ConsumerState<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends ConsumerState<AdminUsersPage> {
  String _searchQuery = '';
  String? _selectedRole;
  String? _selectedStatus;
  bool _isSaving = false;

  Future<void> _toggleUserStatus(String profileId, String currentStatus) async {
    setState(() => _isSaving = true);
    final targetStatus = currentStatus == 'active' ? 'suspended' : 'active';
    try {
      await SupabaseService.client
          .from('profiles')
          .update({'status': targetStatus})
          .eq('id', profileId);
      ref.invalidate(adminUsersProvider);
      ref.invalidate(adminStatsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Account status updated to $targetStatus.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update status. RLS policy might be missing.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(adminUsersProvider);

    return AppScaffold(
      title: 'User Management',
      drawer: const AdminNavigationDrawer(currentPath: '/admin/users'),
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
                    'System Users Directory',
                    style: AppTextStyles.headlineMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Filters panel
                  AppCard(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      children: [
                        TextField(
                          decoration: const InputDecoration(
                            labelText: 'Search by Name or Email',
                            prefixIcon: Icon(Icons.search),
                          ),
                          onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                decoration: const InputDecoration(labelText: 'Filter by Role'),
                                value: _selectedRole,
                                items: const [
                                  DropdownMenuItem(value: null, child: Text('All Roles')),
                                  DropdownMenuItem(value: 'student', child: Text('Student')),
                                  DropdownMenuItem(value: 'institution', child: Text('Institution')),
                                  DropdownMenuItem(value: 'counsellor', child: Text('Counsellor')),
                                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                                ],
                                onChanged: (val) => setState(() => _selectedRole = val),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                decoration: const InputDecoration(labelText: 'Filter by Status'),
                                value: _selectedStatus,
                                items: const [
                                  DropdownMenuItem(value: null, child: Text('All Statuses')),
                                  DropdownMenuItem(value: 'active', child: Text('Active')),
                                  DropdownMenuItem(value: 'pending', child: Text('Pending')),
                                  DropdownMenuItem(value: 'suspended', child: Text('Suspended')),
                                ],
                                onChanged: (val) => setState(() => _selectedStatus = val),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Data view list
                  usersAsync.when(
                    data: (users) {
                      final filtered = users.where((u) {
                        final email = (u['email'] as String? ?? '').toLowerCase();
                        final name = (u['full_name'] as String? ?? '').toLowerCase();
                        final role = u['role'] as String? ?? '';
                        final status = u['status'] as String? ?? '';

                        final matchesSearch = email.contains(_searchQuery) || name.contains(_searchQuery);
                        final matchesRole = _selectedRole == null || role == _selectedRole;
                        final matchesStatus = _selectedStatus == null || status == _selectedStatus;

                        return matchesSearch && matchesRole && matchesStatus;
                      }).toList();

                      if (filtered.isEmpty) {
                        return const AppCard(
                          padding: EdgeInsets.all(AppSpacing.xl),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.people_outline, size: 48, color: AppColors.textSecondaryLight),
                                SizedBox(height: AppSpacing.sm),
                                Text('No matching system users found.'),
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
                          final user = filtered[index];
                          final status = user['status'] as String? ?? 'active';
                          final roleStr = user['role'] as String? ?? 'student';

                          if (isMobile) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: AppSpacing.md),
                              child: AppCard(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user['full_name'] ?? 'Unknown Name',
                                      style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(user['email'] ?? '', style: AppTextStyles.bodyMedium),
                                    const SizedBox(height: AppSpacing.xs),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Role: ${roleStr.toUpperCase()}', style: AppTextStyles.bodySmall),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: status == 'active' ? AppColors.success.withValues(alpha: 0.1) : AppColors.error.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            status.toUpperCase(),
                                            style: TextStyle(
                                              color: status == 'active' ? AppColors.success : AppColors.error,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    if (roleStr != 'admin')
                                      AppButton(
                                        text: status == 'active' ? 'Suspend Account' : 'Activate Account',
                                        onPressed: _isSaving ? null : () => _toggleUserStatus(user['id'], status),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          }

                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: AppCard(
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          user['full_name'] ?? 'Unknown Name',
                                          style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(user['email'] ?? '', style: AppTextStyles.bodySmall),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(roleStr.toUpperCase(), style: AppTextStyles.bodyMedium),
                                  ),
                                  Expanded(
                                    child: Center(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: status == 'active' ? AppColors.success.withValues(alpha: 0.1) : AppColors.error.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          status.toUpperCase(),
                                          style: TextStyle(
                                            color: status == 'active' ? AppColors.success : AppColors.error,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: roleStr == 'admin'
                                          ? const SizedBox()
                                          : AppButton(
                                              text: status == 'active' ? 'Suspend' : 'Activate',
                                              onPressed: _isSaving ? null : () => _toggleUserStatus(user['id'], status),
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
                        'Admin RLS policy required for this management view.',
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
