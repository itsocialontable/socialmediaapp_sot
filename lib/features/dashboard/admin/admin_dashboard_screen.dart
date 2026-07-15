import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../../shared/pages/profile_page.dart';
import '../../../shared/pages/messages_page.dart';
import '../../../shared/pages/analytics_page.dart';
import 'pages/admin_inner_pages.dart';
import 'pages/admin_assign_task_page.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});
  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _navIndex = 0;

  String get _title {
    switch (_navIndex) {
      case 0: return 'Dashboard';
      case 1: return 'Clients';
      case 2: return 'Team';
      case 3: return 'Reports';
      case 4: return 'Profile';
      default: return 'Dashboard';
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return CommonScaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _navIndex == 0
                          ? Text('Hi, ${auth.userName} 👋',
                          style: GoogleFonts.sora(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary))
                          : ShaderMask(
                        shaderCallback: (b) => AppColors.adminGradient.createShader(b),
                        child: Text(_title,
                            style: GoogleFonts.sora(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
                      ),
                      if (_navIndex == 0)
                        Text('Welcome back!',
                            style: GoogleFonts.sora(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                  const Spacer(),
                  Stack(
                    children: [
                      GestureDetector(
                        onTap:(){},
                        child: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            gradient: AppColors.adminGradient, shape: BoxShape.circle,
                          ),
                          child: ClipOval(
                            child: (auth.profileImageUrl != null && auth.profileImageUrl!.isNotEmpty)
                                ? Image.network(
                              auth.profileImageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Center(
                                child: Text(
                                  auth.userName.isNotEmpty ? auth.userName[0].toUpperCase() : 'A',
                                  style: GoogleFonts.sora(fontWeight: FontWeight.w700, color: Colors.white),
                                ),
                              ),
                            )
                                : Center(
                              child: Text(
                                auth.userName.isNotEmpty ? auth.userName[0].toUpperCase() : 'A',
                                style: GoogleFonts.sora(fontWeight: FontWeight.w700, color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 0, top: 0,
                        child: Container(
                          width: 12, height: 12,
                          decoration: BoxDecoration(color: AppColors.success, shape: BoxShape.circle,
                              border: Border.all(color: AppColors.background, width: 2)),
                        ),
                      ),
                    ],
                  ),
                ],
              ).animate().fadeIn(),
            ),

            Expanded(child: _buildPage(auth)),
          ],
        ),
      ),
      bottomNavigationBar: CommonBottomNav(
        currentIndex: _navIndex,
        activeColor: AppColors.adminColor,
        onTap: (i) => setState(() => _navIndex = i),
        items: const [
          BottomNavItem(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard_rounded, label: 'Dashboard'),
          BottomNavItem(icon: Icons.people_outline_rounded, activeIcon: Icons.people_rounded, label: 'Clients'),
          BottomNavItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Team'),
          BottomNavItem(icon: Icons.bar_chart_outlined, activeIcon: Icons.bar_chart_rounded, label: 'Reports'),
          BottomNavItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildPage(AuthProvider auth) {
    switch (_navIndex) {
      case 0: return _AdminHome(auth: auth, onNav: (i) => setState(() => _navIndex = i));
      case 1: return const AdminClientsPage();
      case 2: return const AdminTeamPage();
      case 3: return const AdminReportsPage();
      case 4: return const ProfilePage(accentColor: AppColors.smmColor, gradient: AppColors.smmGradient);
      default: return _AdminHome(auth: auth, onNav: (i) => setState(() => _navIndex = i));
    }
  }
}

class _AdminHome extends StatefulWidget {
  final AuthProvider auth;
  final Function(int) onNav;
  const _AdminHome({required this.auth, required this.onNav});

  @override
  State<_AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<_AdminHome> {
  final _apiService = ApiService();
  bool isLoading = true;
  String? error;

  int totalClients = 0;
  int totalSMMs = 0;
  int totalGDs = 0;
  int totalUsers = 0;
  int activeUsers = 0;
  @override
  void initState() {
    super.initState();
    fetchDashboard();
  }
  Future<void> fetchDashboard() async {
    try {
      setState(() {
        isLoading = true;
      });

      final response = await _apiService.get(
        AppConstants.adminDashboard,
      );

      if (response['success'] == true) {
        final users = response['data']['users'];

        setState(() {
          totalClients = users['totalClients'] ?? 0;
          totalSMMs = users['totalSMMs'] ?? 0;
          totalGDs = users['totalGDs'] ?? 0;
          totalUsers = users['totalUsers'] ?? 0;
          activeUsers = users['activeUsers'] ?? 0;
        });
      }
    } catch (e) {
      debugPrint('Dashboard Error: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          CommonCard(
            gradient: AppColors.adminGradient,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Revenue', style: GoogleFonts.sora(fontSize: 13, color: Colors.white70)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                      child: Text('This Month', style: GoogleFonts.sora(fontSize: 11, color: Colors.white)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('\$24,850', style: GoogleFonts.sora(fontSize: 32, fontWeight: FontWeight.w700, color: Colors.white)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.trending_up_rounded, color: Colors.white70, size: 14),
                    const SizedBox(width: 4),
                    Text('+12.5% this month', style: GoogleFonts.sora(fontSize: 11, color: Colors.white70)),
                  ],
                ),
              ],
            ),
          ).animate(delay: 100.ms).fadeIn(),

          const SizedBox(height: 16),

          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12, mainAxisSpacing: 12,
            childAspectRatio: 1.0,
            children: [
              StatCard(
                label: 'Total Clients',
                value: '$totalClients',
                icon: Icons.people_rounded,
                color: AppColors.adminColor,
              ),

              StatCard(
                label: 'Total GD',
                value: '$totalGDs',
                icon: Icons.person_rounded,
                color: AppColors.secondary,
              ),

              StatCard(
                label: 'Total SMM',
                value: '$totalSMMs',
                icon: Icons.folder_rounded,
                color: AppColors.accent,
              ),

              StatCard(
                label: 'Active Users',
                value: '$activeUsers',
                icon: Icons.check_circle_rounded,
                color: AppColors.success,
              ),
            ],
          ).animate(delay: 200.ms).fadeIn(),

          const SizedBox(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Assign Task', style: GoogleFonts.sora(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            ],
          ).animate(delay: 300.ms).fadeIn(),

          const SizedBox(height: 12),

          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminAssignTaskPage()),
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppColors.adminGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: AppColors.adminColor.withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 6))],
              ),
              child: Row(
                children: [
                  Container(
                    width: 46, height: 46,
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.assignment_add, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Assign a New Task', style: GoogleFonts.sora(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                        const SizedBox(height: 2),
                        Text('Assign a design project to a client & designer', style: GoogleFonts.sora(fontSize: 11, color: Colors.white70)),
                      ],
                    ),
                  ),
                  Container(
                    width: 30, height: 30,
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
                  ),
                ],
              ),
            ),
          ).animate(delay: 400.ms).fadeIn(),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction(this.icon, this.label, this.color, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CommonCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 6),
            Text(label, style: GoogleFonts.sora(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }
}