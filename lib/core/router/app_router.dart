import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smm_app/main.dart';
import 'package:provider/provider.dart';
import '../../shared/pages/profile_page.dart';
import '../providers/auth_provider.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/welcome/welcome_screen.dart';
import '../../features/auth/admin/admin_login_screen.dart';
import '../../features/auth/admin/admin_register_screen.dart';
import '../../features/auth/user/user_login_screen.dart';
import '../../features/auth/user/role_selection_screen.dart';
import '../../features/dashboard/admin/admin_dashboard_screen.dart';
import '../../features/dashboard/designer/designer_dashboard_screen.dart';
import '../../features/dashboard/smm/smm_dashboard_screen.dart';
import '../../features/dashboard/client/client_dashboard_screen.dart';
import '../../features/dashboard/smm/sheets/create_post_page.dart';
import '../../features/dashboard/smm/sheets/posts_tab_page.dart';
import '../../features/dashboard/smm/sheets/connected_accounts_page.dart';
import '../../features/dashboard/smm/sheets/assign_task_page.dart';
import '../../features/dashboard/smm/pages/smm_design_projects_page.dart';
import '../../features/dashboard/smm/pages/smm_add_client_page.dart';
import '../../shared/pages/notifications_page.dart';
import '../theme/app_theme.dart';

class AppRouter {
  static GoRouter createRouter(BuildContext context) {
    return GoRouter(
      navigatorKey: rootNavigatorKey,
      initialLocation: '/splash',
      redirect: (context, state) {
        final auth = Provider.of<AuthProvider>(context, listen: false);
        final isOnAuth = state.matchedLocation.startsWith('/auth') ||
            state.matchedLocation == '/welcome' ||
            state.matchedLocation == '/splash';
        if (auth.isLoggedIn && isOnAuth) return auth.dashboardRoute;
        return null;
      },
      routes: [
        GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
        GoRoute(path: '/welcome', builder: (_, __) => const WelcomeScreen()),
        GoRoute(path: '/auth/admin/login', builder: (_, __) => const AdminLoginScreen()),
        // GoRoute(path: '/auth/admin/register', builder: (_, __) => const AdminRegisterScreen()),
        GoRoute(path: '/auth/user/role', builder: (_, __) => const RoleSelectionScreen()),
        GoRoute(path: '/auth/user/login', builder: (_, __) => const UserLoginScreen()),
        GoRoute(path: '/dashboard/admin', builder: (_, __) => const AdminDashboardScreen()),
        GoRoute(path: '/dashboard/designer', builder: (_, __) => const DesignerDashboardScreen()),
        GoRoute(path: '/dashboard/smm', builder: (_, __) => const SmmDashboardScreen()),
        GoRoute(path: '/smm/connected-accounts', builder: (_, __) => const ConnectedAccountsPage()),
        GoRoute(path: '/smm/assign-task', builder: (_, __) => const AssignTaskPage()),
        GoRoute(path: '/smm/design-projects', builder: (_, __) => const SmmDesignProjectsListPage()),
        GoRoute(path: '/smm/add-client', builder: (_, __) => const SmmAddClientPage()),
        GoRoute(
          path: '/smm/posts',
          builder: (_, state) {
            final tab = (state.extra as int?) ?? 0;
            return PostsTabPage(initialTab: tab);
          },
        ),
        GoRoute(
          path: '/smm/create-post',
          builder: (_, __) => const CreatePostPage(),
        ),
        GoRoute(
          path: '/notifications',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>? ?? {};
            return NotificationsPage(
              accentColor: (extra['accentColor'] as Color?) ?? AppColors.primary,
              gradient: (extra['gradient'] as LinearGradient?) ?? AppColors.adminGradient,
            );
          },
        ),
        GoRoute(path: '/dashboard/client', builder: (_, __) => const ClientDashboardScreen()),
        // GoRoute(
        //   path: '/profile',
        //   builder: (context, state) => const ProfilePage( accentColor: AppColors.primary,
        //     gradient: AppColors.adminGradient,),
        // ),
      ],
      errorBuilder: (_, state) => Scaffold(
        backgroundColor: const Color(0xFF0A0E1A),
        body: Center(child: Text('Page not found: ${state.error}',
            style: const TextStyle(color: Colors.white))),
      ),
    );
  }
}