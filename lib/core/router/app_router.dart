import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Services, enums, providers
import '../services/auth_provider.dart';
import '../enums/user_role.dart';

// Pages
import '../../features/auth/presentation/pages/auth_login_page.dart';
import '../../features/auth/presentation/pages/auth_signup_page.dart';
import '../../features/auth/presentation/pages/auth_verify_email_page.dart';
import '../../features/auth/presentation/pages/auth_callback_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_route_page.dart';
import '../../features/student/presentation/pages/student_dashboard_page.dart';
import '../../features/student/presentation/pages/student_profile_page.dart';
import '../../features/admin/presentation/pages/admin_dashboard_page.dart';
import '../../features/institution/presentation/pages/institution_dashboard_page.dart';
import '../../features/counsellor/presentation/pages/counsellor_dashboard_page.dart';
import '../../features/assessments/presentation/pages/assessment_marketplace_page.dart';
import '../../features/assessments/presentation/pages/assessment_detail_page.dart';
import '../../features/cart/presentation/pages/cart_page.dart';
import '../../features/ezeal_identity/presentation/pages/verify_identity_page.dart';
import '../../features/ezeal_identity/presentation/controllers/ezeal_identity_providers.dart';
import '../../features/payments/presentation/pages/checkout_page.dart';
import '../../features/assessment_access/presentation/pages/redeem_token_page.dart';
import '../../features/assessment_access/presentation/pages/assessment_access_page.dart';
import '../../features/assessment_engine/presentation/pages/question_preview_page.dart';
import '../../features/assessment_runner/presentation/pages/assessment_runner_page.dart';

// Refresh notifier to trigger GoRouter evaluations on state updates
class GoRouterRefreshNotifier extends ChangeNotifier {
  final Ref _ref;
  late final ProviderSubscription _authSub;
  late final ProviderSubscription _profileSub;
  late final ProviderSubscription _identitySub;

  GoRouterRefreshNotifier(this._ref) {
    // Notify router on user state transitions
    _authSub = _ref.listen(currentUserProvider, (prev, next) => notifyListeners());
    _profileSub = _ref.listen(currentProfileProvider, (prev, next) => notifyListeners());
    _identitySub = _ref.listen(ezealIdentityProvider, (prev, next) => notifyListeners());
  }

  void disposeNotifier() {
    _authSub.close();
    _profileSub.close();
    _identitySub.close();
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = GoRouterRefreshNotifier(ref);

  ref.onDispose(() {
    refreshNotifier.disposeNotifier();
  });

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    refreshListenable: refreshNotifier,
    routes: [
      GoRoute(
        path: '/',
        redirect: (context, state) => '/auth/login',
      ),
      GoRoute(
        path: '/auth/login',
        builder: (context, state) => const AuthLoginPage(),
      ),
      GoRoute(
        path: '/auth/signup',
        builder: (context, state) => const AuthSignupPage(),
      ),
      GoRoute(
        path: '/auth/verify-email',
        builder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          return AuthVerifyEmailPage(email: email);
        },
      ),
      GoRoute(
        path: '/auth/callback',
        builder: (context, state) => const AuthCallbackPage(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardRoutePage(),
      ),
      GoRoute(
        path: '/student/dashboard',
        builder: (context, state) => const StudentDashboardPage(),
      ),
      GoRoute(
        path: '/student/profile',
        builder: (context, state) => const StudentProfilePage(),
      ),
      GoRoute(
        path: '/student/assessments',
        builder: (context, state) => const AssessmentMarketplacePage(),
      ),
      GoRoute(
        path: '/student/assessments/:slug',
        builder: (context, state) => AssessmentDetailPage(
          slug: state.pathParameters['slug'] ?? '',
        ),
      ),
      GoRoute(
        path: '/student/cart',
        builder: (context, state) => const CartPage(),
      ),
      GoRoute(
        path: '/student/verify-identity',
        builder: (context, state) => const VerifyIdentityPage(),
      ),
      GoRoute(
        path: '/student/checkout',
        builder: (context, state) => const CheckoutPage(),
      ),
      GoRoute(
        path: '/student/redeem-token',
        builder: (context, state) => const RedeemTokenPage(),
      ),
      GoRoute(
        path: '/student/access',
        builder: (context, state) => const AssessmentAccessPage(),
      ),
      GoRoute(
        path: '/student/assessments/:slug/questions-preview',
        builder: (context, state) => QuestionPreviewPage(
          slug: state.pathParameters['slug'] ?? '',
        ),
      ),
      GoRoute(
        path: '/student/assessments/:slug/runner',
        builder: (context, state) => AssessmentRunnerPage(
          slug: state.pathParameters['slug'] ?? '',
        ),
      ),
      GoRoute(
        path: '/admin/dashboard',
        builder: (context, state) => const AdminDashboardPage(),
      ),
      GoRoute(
        path: '/institution/dashboard',
        builder: (context, state) => const InstitutionDashboardPage(),
      ),
      GoRoute(
        path: '/counsellor/dashboard',
        builder: (context, state) => const CounsellorDashboardPage(),
      ),
    ],
    redirect: (context, state) {
      final user = ref.read(currentUserProvider);
      final profileAsync = ref.read(currentProfileProvider);
      
      final currentLoc = state.uri.toString();
      final currentPath = state.uri.path;
      final isLoginLoc = currentPath == '/auth/login';
      final isSignupLoc = currentPath == '/auth/signup';
      final isVerifyEmailLoc = currentPath == '/auth/verify-email';
      final isCallbackLoc = currentPath == '/auth/callback';

      // 1. Unauthenticated users guard
      if (user == null) {
        if (!isLoginLoc && !isSignupLoc && !isVerifyEmailLoc && !isCallbackLoc) {
          return '/auth/login';
        }
        return null;
      }

      // 2. Authenticated users on Auth pages / Landing -> redirect to generic /dashboard path
      if (currentPath == '/' || isLoginLoc || isSignupLoc || isVerifyEmailLoc || isCallbackLoc) {
        return '/dashboard';
      }

      // We need profile information for role redirection/guards
      final profile = profileAsync.asData?.value;
      if (profile == null) {
        // Let it load, redirect will re-run when profile state updates
        return null;
      }

      // 3. /dashboard redirect based on role
      if (currentLoc == '/dashboard') {
        switch (profile.role) {
          case UserRole.student:
            return '/student/dashboard';
          case UserRole.admin:
            return '/admin/dashboard';
          case UserRole.institution:
            return '/institution/dashboard';
          case UserRole.counsellor:
            return '/counsellor/dashboard';
          default:
            return '/auth/login';
        }
      }

      // 4. Role page cross-access protection (By-passed in kDebugMode for dev testing)
      if (currentLoc.startsWith('/student/') && profile.role != UserRole.student) {
        if (kDebugMode) return null;
        return '/dashboard';
      }

      // Ezeal ID Verification Gate for student assessments and checkout
      if (profile.role == UserRole.student &&
          (currentLoc.startsWith('/student/assessments') || currentLoc.startsWith('/student/checkout'))) {
        final identityAsync = ref.read(ezealIdentityProvider);
        if (identityAsync.isLoading) {
          return null; // Wait for identity to load
        }
        final identity = identityAsync.asData?.value;
        if (identity == null || !identity.aadhaarVerified || identity.verificationStatus != 'verified') {
          return '/student/verify-identity';
        }
      }
      if (currentLoc.startsWith('/admin/') && profile.role != UserRole.admin) {
        if (kDebugMode) return null;
        return '/dashboard';
      }
      if (currentLoc.startsWith('/institution/') && profile.role != UserRole.institution) {
        if (kDebugMode) return null;
        return '/dashboard';
      }
      if (currentLoc.startsWith('/counsellor/') && profile.role != UserRole.counsellor) {
        if (kDebugMode) return null;
        return '/dashboard';
      }

      return null;
    },
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.error}'),
      ),
    ),
  );
});
