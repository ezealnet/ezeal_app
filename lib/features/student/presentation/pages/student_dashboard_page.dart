import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/services/auth_provider.dart';
import '../../data/models/student_profile_model.dart';
import '../controllers/student_profile_controller.dart';
import '../../../cart/presentation/controllers/cart_providers.dart';
import '../../../ezeal_identity/presentation/controllers/ezeal_identity_providers.dart';
import '../../../assessment_access/presentation/controllers/assessment_access_providers.dart';

class StudentDashboardPage extends ConsumerWidget {
  const StudentDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentProfileAsync = ref.watch(studentProfileProvider);
    final user = ref.watch(currentUserProvider);
    final identityAsync = ref.watch(ezealIdentityProvider);
    final accessAsync = ref.watch(assessmentAccessProvider);
    final cartItemsAsync = ref.watch(cartItemsProvider);

    // Resolve unified loading state
    final bool isLoading = studentProfileAsync.isLoading || identityAsync.isLoading || accessAsync.isLoading;
    final profile = studentProfileAsync.asData?.value;

    if (isLoading && profile == null) {
      return const AppScaffold(
        title: 'Student Dashboard',
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final identity = identityAsync.asData?.value;
    final accesses = accessAsync.asData?.value ?? [];
    final cartCount = cartItemsAsync.asData?.value.length ?? 0;

    final isVerified = identity != null && identity.aadhaarVerified && identity.verificationStatus == 'verified';
    final int completion = profile != null 
        ? StudentProfileController.calculateLiveCompletion(profile, isVerified: isVerified) 
        : 0;

    final unlockedCount = accesses.length;
    final completedCount = accesses.where((a) => a.status == 'completed').length;
    final pendingCount = unlockedCount - completedCount;
    final lastAccessed = accesses.isNotEmpty ? accesses.first : null;

    final double screenWidth = MediaQuery.of(context).size.width - (AppSpacing.lg * 2);

    return AppScaffold(
      title: 'Student Dashboard',
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // A. Header Section
                  _buildHeader(
                    profile?.fullName ?? user?.email ?? 'Student',
                    profile?.educationStage ?? 'Portal Member',
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // B. KPI Summary
                  _buildMetricGrid(
                    context,
                    screenWidth: screenWidth,
                    completion: completion,
                    identityStatus: isVerified ? 'Verified' : 'Unverified',
                    unlockedCount: unlockedCount,
                    completedCount: completedCount,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // C. Hero Next Action Recommendation Card
                  _buildNextActionHero(
                    context,
                    completion: completion,
                    isVerified: isVerified,
                    unlockedCount: unlockedCount,
                    pendingCount: pendingCount,
                    completedCount: completedCount,
                    ezealId: identity?.ezealId,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // D. Dashboard Grid
                  _buildDashboardGrid(
                    context,
                    screenWidth: screenWidth,
                    profile: profile,
                    completion: completion,
                    isVerified: isVerified,
                    identity: identity,
                    unlockedCount: unlockedCount,
                    completedCount: completedCount,
                    pendingCount: pendingCount,
                    lastAccessed: lastAccessed,
                    cartCount: cartCount,
                  ),
                  
                  // E. Tips & Insights (Conditional)
                  if (completion < 100 || !isVerified) ...[
                    const SizedBox(height: AppSpacing.md),
                    _buildTipsSection(completion, isVerified),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String name, String stage) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back,',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                name,
                style: AppTextStyles.headlineMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                stage,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondaryLight,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Row(
          children: [
            // Notifications Badge Placeholder
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.notifications_none_outlined,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                Positioned(
                  right: -1,
                  top: -1,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: AppSpacing.sm),
            // Profile Photo / Initials Placeholder
            Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
              ),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primaryLight,
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'S',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricGrid(
    BuildContext context, {
    required double screenWidth,
    required int completion,
    required String identityStatus,
    required int unlockedCount,
    required int completedCount,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        int cols = 1;
        if (width > 900) {
          cols = 4;
        } else if (width > 600) {
          cols = 2;
        }

        final double spacing = AppSpacing.md.toDouble();
        final double cardWidth = (width - (spacing * (cols - 1))) / cols;

        if (kDebugMode) {
          print('DEBUG: [LayoutGrid] Screen width: $width, Mode: ${cols == 4 ? "Desktop" : (cols == 2 ? "Tablet" : "Mobile")}, KPI columns: $cols, KPI cardWidth: $cardWidth');
        }

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            SizedBox(
              width: cardWidth,
              child: _buildMetricCard('Profile Completion', '$completion%', Icons.donut_large_outlined, AppColors.primary),
            ),
            SizedBox(
              width: cardWidth,
              child: _buildMetricCard(
                'Identity Status',
                identityStatus,
                identityStatus == 'Verified' ? Icons.verified_user_outlined : Icons.shield_outlined,
                identityStatus == 'Verified' ? AppColors.success : AppColors.warning,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _buildMetricCard('Unlocked Tests', '$unlockedCount', Icons.assignment_outlined, AppColors.info),
            ),
            SizedBox(
              width: cardWidth,
              child: _buildMetricCard('Completed Tests', '$completedCount', Icons.task_alt_outlined, AppColors.success),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.xs),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondaryLight,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTextStyles.titleLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimaryLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextActionHero(
    BuildContext context, {
    required int completion,
    required bool isVerified,
    required int unlockedCount,
    required int pendingCount,
    required int completedCount,
    required String? ezealId,
  }) {
    String title = 'Next Step';
    String description = '';
    String buttonText = '';
    IconData icon = Icons.next_plan_outlined;
    Color color = AppColors.primary;
    VoidCallback onPressed = () {};

    if (completion < 90) {
      title = 'Complete Your Profile';
      description = 'Provide your parent/guardian details and full qualifications to unlock career reports.';
      buttonText = 'Complete Profile';
      icon = Icons.assignment_ind_outlined;
      color = AppColors.primary;
      onPressed = () => context.go('/student/profile');
    } else if (!isVerified) {
      title = 'Verify Your Identity';
      description = 'Complete your Aadhaar KYC verification to issue official career guidance credentials.';
      buttonText = 'Verify Identity';
      icon = Icons.badge_outlined;
      color = AppColors.warning;
      onPressed = () => context.go('/student/verify-identity');
    } else if (unlockedCount == 0) {
      title = 'Browse the Assessment Catalog';
      description = 'Select a RIASEC, VARK learning style, or Aptitude test to begin mapping your career.';
      buttonText = 'Browse Marketplace';
      icon = Icons.shopping_bag_outlined;
      color = AppColors.accentDark;
      onPressed = () => context.go('/student/assessments');
    } else if (pendingCount > 0) {
      title = 'Resume Your Pending Assessments';
      description = 'You have assessments in progress. Complete them now to generate your guidance reports.';
      buttonText = 'Resume Test';
      icon = Icons.play_circle_outline;
      color = AppColors.info;
      onPressed = () => context.go('/student/access');
    } else if (completedCount > 0) {
      title = 'View Your Competency Reports';
      description = 'All career assessments have been completed successfully. Download your certified results.';
      buttonText = 'View Results';
      icon = Icons.workspace_premium_outlined;
      color = AppColors.success;
      onPressed = () => context.go('/student/access');
    }

    final bool isMobile = MediaQuery.of(context).size.width < 600;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: color, width: 4),
          ),
        ),
        padding: const EdgeInsets.only(left: AppSpacing.md),
        child: isMobile
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(icon, color: color, size: 24),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          title,
                          style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    description,
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondaryLight),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppButton(
                    text: buttonText,
                    onPressed: onPressed,
                  ),
                ],
              )
            : Row(
                children: [
                  Icon(icon, color: color, size: 28),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondaryLight),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  AppButton(
                    text: buttonText,
                    onPressed: onPressed,
                    width: 180,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildDashboardGrid(
    BuildContext context, {
    required double screenWidth,
    required StudentProfileModel? profile,
    required int completion,
    required bool isVerified,
    required dynamic identity,
    required int unlockedCount,
    required int completedCount,
    required int pendingCount,
    required dynamic lastAccessed,
    required int cartCount,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        int cols = 1;
        if (width > 800) {
          cols = 2;
        }

        final double spacing = AppSpacing.md.toDouble();
        final double cardWidth = (width - (spacing * (cols - 1))) / cols;

        if (kDebugMode) {
          print('DEBUG: [LayoutGrid] Main grid width: $width, columns: $cols, Main cardWidth: $cardWidth');
        }

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            SizedBox(
              width: cardWidth,
              child: _buildProfileCard(context, profile, completion, isVerified),
            ),
            SizedBox(
              width: cardWidth,
              child: _buildIdentityCard(context, isVerified, identity),
            ),
            SizedBox(
              width: cardWidth,
              child: _buildAssessmentCard(context, unlockedCount, completedCount, pendingCount, lastAccessed),
            ),
            SizedBox(
              width: cardWidth,
              child: _buildMarketplaceCard(context, cartCount, isVerified),
            ),
            SizedBox(
              width: cardWidth,
              child: _buildRecentActivityCard(profile, isVerified, lastAccessed),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProfileCard(BuildContext context, StudentProfileModel? profile, int completion, bool isVerified) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.person_outline, color: AppColors.primary, size: 22),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Profile Completion',
                  style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '$completion%',
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildChecklistRow('Personal Details (Name, Phone)', profile != null && profile.fullName.isNotEmpty),
          _buildChecklistRow('Identity Data (Gender, DOB)', profile != null && profile.gender != null && profile.gender!.isNotEmpty && profile.dateOfBirth != null),
          _buildChecklistRow('Location Settings (City, State)', profile != null && profile.city != null && profile.city!.isNotEmpty),
          _buildChecklistRow('Academic Qualifications details', profile != null && profile.qualifications.isNotEmpty && profile.qualifications.first.institutionName.isNotEmpty),
          _buildChecklistRow('Parent / Guardian Contacts', profile != null && profile.educationMetadata['guardian_name'] != null && profile.educationMetadata['guardian_name'].toString().isNotEmpty),
          _buildChecklistRow('KYC Identity Verification', isVerified),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            text: 'View & Edit Profile',
            onPressed: () => context.go('/student/profile'),
          ),
        ],
      ),
    );
  }

  Widget _buildIdentityCard(BuildContext context, bool isVerified, dynamic identity) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                isVerified ? Icons.verified : Icons.gpp_maybe,
                color: isVerified ? AppColors.success : AppColors.warning,
                size: 22,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Identity Verification',
                  style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            isVerified
                ? 'Your identity is fully verified. You are authorized to take official exams and secure professional reports.'
                : 'Verify your Aadhaar card to authenticate your identity, generate official credentials, and download certifications.',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondaryLight),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: isVerified ? AppColors.success.withValues(alpha: 0.1) : AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isVerified ? 'Ezeal ID: ${identity?.ezealId}' : 'Status: Unverified Learner',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: isVerified ? AppColors.success : AppColors.warning,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            text: isVerified ? 'View Verification Details' : 'Verify Identity Now',
            onPressed: () => context.go(isVerified ? '/student/profile' : '/student/verify-identity'),
          ),
        ],
      ),
    );
  }

  Widget _buildAssessmentCard(BuildContext context, int unlockedCount, int completedCount, int pendingCount, dynamic lastAccessed) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.assignment_turned_in_outlined, color: AppColors.primary, size: 22),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Assessment Portal',
                  style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Unlocked', '$unlockedCount'),
              _buildStatItem('Completed', '$completedCount'),
              _buildStatItem('Pending', '$pendingCount'),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Last Accessed Assessment:',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondaryLight,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            lastAccessed != null
                ? '${lastAccessed.assessment?.title ?? "Career Assessment"} (${lastAccessed.status})'
                : 'No assessments started yet',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w500,
              color: lastAccessed != null ? AppColors.primary : AppColors.textSecondaryLight,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            text: 'Go to Assessment Portal',
            onPressed: () => context.go('/student/access'),
          ),
        ],
      ),
    );
  }

  Widget _buildMarketplaceCard(BuildContext context, int cartCount, bool isVerified) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.explore_outlined, color: AppColors.accentDark, size: 22),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Assessment Marketplace',
                  style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Explore RIASEC personality, Big Five characteristics, VARK learning types, and other expert aptitude evaluations.',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondaryLight),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.accentDark.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              cartCount == 0 ? 'Your shopping cart is empty.' : '$cartCount assessment${cartCount > 1 ? "s" : ""} in cart.',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.accentDark,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            text: 'Browse Assessments',
            onPressed: () => context.go(isVerified ? '/student/assessments' : '/student/verify-identity'),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivityCard(StudentProfileModel? profile, bool isVerified, dynamic lastAccessed) {
    final List<Map<String, dynamic>> activities = [];
    if (profile != null) {
      if (profile.fullName.isNotEmpty) {
        activities.add({
          'text': 'Profile initialized & saved',
          'icon': Icons.person_outline,
          'color': AppColors.primary
        });
      }
    }
    if (isVerified) {
      activities.add({
        'text': 'Aadhaar identity verified successfully',
        'icon': Icons.verified_outlined,
        'color': AppColors.success
      });
    }
    if (lastAccessed != null) {
      activities.add({
        'text': 'Accessed "${lastAccessed.assessment?.title}" (${lastAccessed.status})',
        'icon': Icons.assignment_outlined,
        'color': AppColors.info
      });
    }

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.history, color: AppColors.primary, size: 22),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Recent Activity',
                  style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (activities.isEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_toggle_off, color: AppColors.textSecondaryLight, size: 40),
                  SizedBox(height: AppSpacing.xs),
                  Text(
                    'No recent activity yet.',
                    style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 13),
                  ),
                ],
               ),
             ),
             const SizedBox(height: AppSpacing.lg),
          ] else ...[
            ...activities.map(
              (act) => Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Row(
                  children: [
                    Icon(act['icon'] as IconData, color: act['color'] as Color, size: 18),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        act['text'] as String,
                        style: AppTextStyles.bodyMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChecklistRow(String text, bool checked) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Icon(
            checked ? Icons.check_circle : Icons.error_outline,
            color: checked ? AppColors.success : AppColors.warning,
            size: 18,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodySmall.copyWith(
                color: checked ? AppColors.textPrimaryLight : AppColors.textSecondaryLight,
                fontWeight: checked ? FontWeight.w500 : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.headlineSmall.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondaryLight),
        ),
      ],
    );
  }

  Widget _buildTipsSection(int completion, bool isVerified) {
    String tip = '';
    if (completion < 90) {
      tip = 'Completing all fields in your student profile yields 20% more accurate guidance mappings.';
    } else if (!isVerified) {
      tip = 'KYC Aadhaar checks ensure that downloaded certifications and career reports remain officially valid.';
    }

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          const Icon(Icons.lightbulb_outline, color: AppColors.accentDark, size: 22),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              tip,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondaryLight),
            ),
          ),
        ],
      ),
    );
  }
}
