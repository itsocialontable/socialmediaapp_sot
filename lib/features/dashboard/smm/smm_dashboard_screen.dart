import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_exceptions.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../../shared/pages/messages_page.dart';
import '../../../shared/pages/profile_page.dart';
import '../../../shared/pages/analytics_page.dart';
import 'pages/smm_inner_pages.dart';
import 'sheets/create_post_page.dart';
import 'sheets/posts_tab_page.dart';
import 'sheets/connected_accounts_page.dart';
import 'sheets/assign_task_page.dart';

// POST MODEL
// ─────────────────────────────────────────
class PostModel {
  final String id;
  final String content;
  final List<String> platforms;
  final DateTime? scheduledAt;
  final bool hasMedia;
  final DateTime createdAt;

  PostModel({
    required this.id,
    required this.content,
    required this.platforms,
    this.scheduledAt,
    required this.hasMedia,
    required this.createdAt,
  });
}

// ─────────────────────────────────────────
// POSTS PROVIDER  (in-memory state)
// ─────────────────────────────────────────
class PostsProvider extends ChangeNotifier {
  final List<PostModel> _queue = [];
  final List<PostModel> _drafts = [];

  List<PostModel> get queue => List.unmodifiable(_queue);
  List<PostModel> get drafts => List.unmodifiable(_drafts);

  void addToQueue(PostModel post) {
    _queue.insert(0, post);
    notifyListeners();
  }

  void saveDraft(PostModel post) {
    _drafts.insert(0, post);
    notifyListeners();
  }

  void removeFromQueue(String id) {
    _queue.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  void removeFromDrafts(String id) {
    _drafts.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  // Move draft → queue
  void publishDraft(String id) {
    final idx = _drafts.indexWhere((p) => p.id == id);
    if (idx == -1) return;
    final post = _drafts.removeAt(idx);
    _queue.insert(0, post);
    notifyListeners();
  }
}

// ─────────────────────────────────────────
// SMM DASHBOARD SCREEN

// ─────────────────────────────────────────
// SMM DASHBOARD SCREEN
// ─────────────────────────────────────────
class SmmDashboardScreen extends StatefulWidget {
  const SmmDashboardScreen({super.key});
  @override
  State<SmmDashboardScreen> createState() => _SmmDashboardScreenState();
}

class _SmmDashboardScreenState extends State<SmmDashboardScreen> {
  int _navIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String get _title {
    switch (_navIndex) {
      case 0: return 'Dashboard';
      case 1: return 'Analytics';
      case 2: return 'Messages';
      case 3: return 'Profile';
      default: return 'Dashboard';
    }
  }

  void _openCreatePost() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: context.read<PostsProvider>(),
          child: const CreatePostPage(),
        ),
      ),
    );
  }

  void _closeDrawerThen(VoidCallback fn) {
    _scaffoldKey.currentState?.closeEndDrawer();
    Future.delayed(const Duration(milliseconds: 260), fn);
  }

  void _openConnectedAccounts() => _closeDrawerThen(() {
    context.push('/smm/connected-accounts');
  });

  void _openAssignTask() => _closeDrawerThen(() {
    context.push('/smm/assign-task');
  });

  void _openDesignProjects() => _closeDrawerThen(() {
    context.push('/smm/design-projects');
  });

  void _openAddClient() => _closeDrawerThen(() {
    context.push('/smm/add-client');
  });

  void _openPostsPage({int initialTab = 0}) => _closeDrawerThen(() {
    context.push('/smm/posts', extra: initialTab);
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final posts = context.watch<PostsProvider>();

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,

      endDrawer: _SideDrawer(
        queueCount: posts.queue.length,
        draftCount: posts.drafts.length,
        onConnectedAccounts: _openConnectedAccounts,
        onAssignTask: _openAssignTask,
        onDesignProjects: _openDesignProjects,
        onAddClient: _openAddClient,
        onPosts: _openPostsPage,
      ),

      body: CommonScaffold(
        body: SafeArea(
          child: Column(
            children: [

              /// ───── TOP BAR ─────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [

                    /// LEFT SIDE
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        /// TITLE
                        _navIndex == 0
                            ? Text(
                          'Hi, ${auth.userName} 👋',
                          style: GoogleFonts.sora(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        )
                            : ShaderMask(
                          shaderCallback: (bounds) =>
                              AppColors.smmGradient.createShader(bounds),
                          child: Text(
                            _title,
                            style: GoogleFonts.sora(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),

                        /// SUBTITLE
                        if (_navIndex == 0)
                          Text(
                            "Here's what's happening today!",
                            style: GoogleFonts.sora(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),

                    const Spacer(),

                    /// MENU BUTTON
                    GestureDetector(
                      onTap: () =>
                          _scaffoldKey.currentState?.openEndDrawer(),
                      child: Container(
                        width: 38,
                        height: 38,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.border,
                          ),
                        ),
                        child: const Icon(
                          Icons.menu_rounded,
                          color: AppColors.smmColor,
                          size: 20,
                        ),
                      ),
                    ),

                    /// AVATAR
                    Stack(
                      children: [

                        /// PROFILE CIRCLE
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: AppColors.smmGradient,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              auth.userName.isNotEmpty
                                  ? auth.userName[0].toUpperCase()
                                  : '?',
                              style: GoogleFonts.sora(
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),

                        /// NOTIFICATION BADGE
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.background,
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '3',
                                style:GoogleFonts.sora(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ).animate().fadeIn(),
              ),

              /// PAGE BODY
              Expanded(
                child: _buildPage(),
              ),
            ],
          ),
        ),

        /// ───── BOTTOM NAVIGATION ─────
        bottomNavigationBar: Stack(
          clipBehavior: Clip.none,
          children: [

            /// NAV BAR
            CommonBottomNav(
              currentIndex: _navIndex,
              activeColor: AppColors.smmColor,
              onTap: (index) {
                setState(() {
                  _navIndex = index;
                });
              },
              items: const [

                BottomNavItem(
                  icon: Icons.dashboard_outlined,
                  activeIcon: Icons.dashboard_rounded,
                  label: 'Dashboard',
                ),

                BottomNavItem(
                  icon: Icons.bar_chart_outlined,
                  activeIcon: Icons.bar_chart_rounded,
                  label: 'Analytics',
                ),

                BottomNavItem(
                  icon: Icons.chat_bubble_outline_rounded,
                  activeIcon: Icons.chat_bubble_rounded,
                  label: 'Messages',
                ),

                BottomNavItem(
                  icon: Icons.person_outline_rounded,
                  activeIcon: Icons.person_rounded,
                  label: 'Profile',
                ),
              ],
            ),

            /// FLOATING ADD BUTTON
            Positioned(
              top: -24,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: _openCreatePost,
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: AppColors.smmGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color:
                          AppColors.smmColor.withOpacity(0.5),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage() {
    switch (_navIndex) {
      case 0:
        return _SmmHome(
            onNav: (i) => setState(() => _navIndex = i),
            onCreatePost: _openCreatePost);
      case 1:
        return AnalyticsPage(
            accentColor: AppColors.smmColor,
            gradient: AppColors.smmGradient);
      case 2:
        return MessagesPage(
            accentColor: AppColors.smmColor,
            gradient: AppColors.smmGradient);
      case 3:
        return ProfilePage(
            accentColor: AppColors.smmColor,
            gradient: AppColors.smmGradient);
      default:
        return _SmmHome(
            onNav: (i) => setState(() => _navIndex = i),
            onCreatePost: _openCreatePost);
    }
  }
}

// ─────────────────────────────────────────
// RIGHT SIDE DRAWER  (4 items now)
// ─────────────────────────────────────────
class _SideDrawer extends StatelessWidget {
  final int queueCount;
  final int draftCount;
  final VoidCallback onConnectedAccounts;
  final VoidCallback onAssignTask;
  final VoidCallback onDesignProjects;
  final VoidCallback onAddClient;
  final void Function({int initialTab}) onPosts;

  const _SideDrawer({
    required this.queueCount,
    required this.draftCount,
    required this.onConnectedAccounts,
    required this.onAssignTask,
    required this.onDesignProjects,
    required this.onAddClient,
    required this.onPosts,
  });

  @override
  Widget build(BuildContext context) {
    final totalCount = queueCount + draftCount;
    return Drawer(
      width: 275,
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              decoration: const BoxDecoration(
                  border: Border(
                      bottom: BorderSide(color: AppColors.border))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46, height: 46,
                    decoration: BoxDecoration(
                      gradient: AppColors.smmGradient,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(Icons.manage_accounts_rounded,
                        color: Colors.white, size: 24),
                  ),
                  const SizedBox(height: 12),
                  ShaderMask(
                    shaderCallback: (b) =>
                        AppColors.smmGradient.createShader(b),
                    child: Text('Quick Actions',
                        style: GoogleFonts.sora(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ),
                  Text('Manage your workspace',
                      style: GoogleFonts.sora(
                          fontSize: 11,
                          color: AppColors.textSecondary)),
                ],
              ),
            ),

            const SizedBox(height: 14),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                children: [
                  // 1. Connected Accounts
                  _DrawerMenuItem(
                    icon: Icons.link_rounded,
                    label: 'Connected Accounts',
                    subtitle: 'Manage social platforms',
                    gradient: const LinearGradient(
                        colors: [Color(0xFFE1306C), Color(0xFF833AB4)]),
                    onTap: onConnectedAccounts,
                  ),
                  const SizedBox(height: 10),

                  // 2. Assign Task
                  _DrawerMenuItem(
                    icon: Icons.assignment_ind_rounded,
                    label: 'Assign to Designer',
                    subtitle: 'assign to a designer',
                    gradient: AppColors.smmGradient,
                    onTap: onAssignTask,
                  ),
                  const SizedBox(height: 10),

                  // 3. Design Projects (list · view · edit · delete)
                  _DrawerMenuItem(
                    icon: Icons.design_services_rounded,
                    label: 'Design Projects',
                    subtitle: 'view · edit · delete',
                    gradient: const LinearGradient(
                        colors: [Color(0xFFFF9A3C), Color(0xFFFF6B6B)]),
                    onTap: onDesignProjects,
                  ),
                  const SizedBox(height: 10),

                  // 4. Add Client
                  _DrawerMenuItem(
                    icon: Icons.person_add_rounded,
                    label: 'Add Client',
                    subtitle: 'onboard a new client',
                    gradient: const LinearGradient(
                        colors: [Color(0xFF00C6AE), Color(0xFF00A8CC)]),
                    onTap: onAddClient,
                  ),
                  const SizedBox(height: 10),

                  // 5. Posts (Queue + Drafts merged)
                  _DrawerMenuItem(
                    icon: Icons.dynamic_feed_rounded,
                    label: 'Posts',
                    subtitle: 'queued · draft',
                    gradient: const LinearGradient(
                        colors: [Color(0xFF00D4AA), Color(0xFF6C63FF)]),
                    badge: totalCount > 0 ? '$totalCount' : null,
                    onTap: () => onPosts(initialTab: 0),
                  ),
                ],
              ),
            ),

            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text('GrowthCraft SMM',
                  style: GoogleFonts.sora(
                      fontSize: 11, color: AppColors.textMuted)),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final LinearGradient gradient;
  final String? badge;
  final VoidCallback onTap;

  const _DrawerMenuItem({
    required this.icon,
    required this.label,
    required  this.subtitle,
    required this.gradient,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(11)),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: GoogleFonts.sora(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                  Text(subtitle,
                      style: GoogleFonts.sora(
                          fontSize: 11,
                          color: AppColors.textSecondary)),
                ],
              ),
            ),
            if (badge != null)
              Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(badge!,
                    style: GoogleFonts.sora(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 13, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// DASHBOARD DATA MODEL
// ─────────────────────────────────────────
class _DashboardData {
  final int totalPosts;
  final int scheduledPosts;
  final int publishedPosts;
  final int totalProjects;
  final int pendingProjects;
  final int inProgressProjects;
  final int completedProjects;
  final List<Map<String, dynamic>> recentProjects;

  const _DashboardData({
    required this.totalPosts,
    required this.scheduledPosts,
    required this.publishedPosts,
    required this.totalProjects,
    required this.pendingProjects,
    required this.inProgressProjects,
    required this.completedProjects,
    required this.recentProjects,
  });

  factory _DashboardData.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    final postStats = data['postStats'] as Map<String, dynamic>? ?? {};
    final designStats = data['designStats'] as Map<String, dynamic>? ?? {};
    final recentProjects = (data['recentProjects'] as List?)
        ?.cast<Map<String, dynamic>>() ?? [];
    return _DashboardData(
      totalPosts: (postStats['totalPosts'] as num?)?.toInt() ?? 0,
      scheduledPosts: (postStats['scheduledPosts'] as num?)?.toInt() ?? 0,
      publishedPosts: (postStats['publishedPosts'] as num?)?.toInt() ?? 0,
      totalProjects: (designStats['totalProjects'] as num?)?.toInt() ?? 0,
      pendingProjects: (designStats['pendingProjects'] as num?)?.toInt() ?? 0,
      inProgressProjects: (designStats['inProgressProjects'] as num?)?.toInt() ?? 0,
      completedProjects: (designStats['completedProjects'] as num?)?.toInt() ?? 0,
      recentProjects: recentProjects,
    );
  }
}

// ─────────────────────────────────────────
// SMM HOME PAGE
// ─────────────────────────────────────────
class _SmmHome extends StatefulWidget {
  final Function(int) onNav;
  final VoidCallback onCreatePost;
  const _SmmHome({required this.onNav, required this.onCreatePost});

  @override
  State<_SmmHome> createState() => _SmmHomeState();
}

class _SmmHomeState extends State<_SmmHome> {
  final _api = ApiService();

  _DashboardData? _data;
  bool _loading = true;
  String? _error;

  // ── Today's Schedule (from /api/posts/queued, filtered to today) ──
  List<Map<String, dynamic>> _todaySchedule = [];
  bool _scheduleLoading = true;
  String? _scheduleError;

  static const Map<String, ({String label, IconData icon, Color color})> _schedulePlatformMeta = {
    'instagram': (label: 'Instagram Post', icon: Icons.camera_alt_rounded, color: Color(0xFFE1306C)),
    'facebook': (label: 'Facebook Post', icon: Icons.facebook_rounded, color: Color(0xFF1877F2)),
    'twitter': (label: 'Twitter / X Post', icon: Icons.alternate_email_rounded, color: Color(0xFF1DA1F2)),
    'linkedin': (label: 'LinkedIn Post', icon: Icons.work_rounded, color: Color(0xFF0A66C2)),
    'pinterest': (label: 'Pinterest Post', icon: Icons.push_pin_rounded, color: Color(0xFFE60023)),
    'youtube': (label: 'YouTube Post', icon: Icons.play_circle_fill_rounded, color: Color(0xFFFF0000)),
    'threads': (label: 'Threads Post', icon: Icons.tag_rounded, color: Color(0xFF000000)),
  };

  @override
  void initState() {
    super.initState();
    _fetchDashboard();
    _fetchTodaySchedule();
  }

  Future<void> _fetchDashboard() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await _api.get(AppConstants.smmDashboard);
      setState(() {
        _data = _DashboardData.fromJson(res);
        _loading = false;
      });
    } on NetworkException catch (_) {
      setState(() { _error = 'No internet connection.'; _loading = false; });
    } on UnauthorizedException catch (_) {
      setState(() { _error = 'Session expired. Please log in again.'; _loading = false; });
    } on AppException catch (e) {
      setState(() { _error = e.message; _loading = false; });
    } catch (_) {
      setState(() { _error = 'Something went wrong. Please try again.'; _loading = false; });
    }
  }

  // Queued posts come from /api/posts/queued (same endpoint used in the
  // Posts tab's Queue list) — here we just filter down to today's date so
  // the dashboard shows what's actually scheduled for today.
  Future<void> _fetchTodaySchedule() async {
    setState(() { _scheduleLoading = true; _scheduleError = null; });
    try {
      final res = await _api.get(AppConstants.queuedPosts);
      final raw = res['data'] ?? res['posts'] ?? res;
      final list = raw is List ? raw.cast<Map<String, dynamic>>() : <Map<String, dynamic>>[];

      final today = DateTime.now();
      bool isToday(Map<String, dynamic> p) {
        // Drafts sitting in this list without a confirmed schedule
        // shouldn't show up as "today's schedule".
        final status = (p['status'] ?? '').toString().toLowerCase();
        if (status == 'draft' || status == 'cancelled' || status == 'failed') return false;

        final rawDate = (p['scheduleAt'] ?? p['scheduleDate'] ?? p['scheduledDate'] ?? p['date'])?.toString();
        DateTime? d;
        if (rawDate != null && rawDate.isNotEmpty) {
          d = DateTime.tryParse(rawDate);
        }
        d ??= DateTime.tryParse((p['scheduledAt'] ?? '').toString());
        if (d == null) return false;
        return d.year == today.year && d.month == today.month && d.day == today.day;
      }

      final todays = list.where(isToday).toList();
      // Earliest scheduled time first.
      todays.sort((a, b) => _scheduleTimeOf(a).compareTo(_scheduleTimeOf(b)));

      setState(() { _todaySchedule = todays; _scheduleLoading = false; });
    } on NetworkException catch (_) {
      setState(() { _scheduleError = 'No internet connection.'; _scheduleLoading = false; });
    } on UnauthorizedException catch (_) {
      setState(() { _scheduleError = 'Session expired.'; _scheduleLoading = false; });
    } on NotFoundException catch (_) {
      setState(() { _todaySchedule = []; _scheduleLoading = false; });
    } on AppException catch (e) {
      setState(() { _scheduleError = e.message; _scheduleLoading = false; });
    } catch (_) {
      setState(() { _scheduleError = 'Something went wrong.'; _scheduleLoading = false; });
    }
  }

  String _scheduleTimeOf(Map<String, dynamic> p) {
    final scheduleTime = (p['scheduleTime'] ?? '').toString();
    if (scheduleTime.isNotEmpty) return scheduleTime;
    final dt = DateTime.tryParse((p['scheduleAt'] ?? '').toString());
    if (dt != null) return DateFormat('HH:mm').format(dt.toLocal());
    return '';
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return AppColors.warning;
      case 'in progress': return AppColors.info;
      case 'completed': return AppColors.success;
      case 'revision': return AppColors.accent;
      case 'overdue': return AppColors.error;
      default: return AppColors.textSecondary;
    }
  }

  String _formatDeadline(String? isoDate) {
    if (isoDate == null) return '—';
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return '—';
    }
  }

  // ── Today's Schedule builder ──────────────
  String _formatScheduleTime(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    try {
      final t = DateFormat('HH:mm').parse(raw);
      return DateFormat('hh:mm a').format(t);
    } catch (_) {
      return raw;
    }
  }

  // scheduleTime ('HH:mm') is the primary source; if it's missing, fall
  // back to the time portion of scheduleAt (a full ISO datetime).
  String _displayScheduleTime(Map<String, dynamic> p) {
    final scheduleTime = (p['scheduleTime'] ?? '').toString();
    if (scheduleTime.isNotEmpty) return _formatScheduleTime(scheduleTime);
    final scheduleAt = (p['scheduleAt'] ?? '').toString();
    final dt = DateTime.tryParse(scheduleAt);
    if (dt != null) return DateFormat('hh:mm a').format(dt.toLocal());
    return '';
  }

  String _scheduleClientLabel(Map<String, dynamic> p) {
    final client = p['client'];
    if (client is Map) {
      final name = client['companyName'] ?? client['name'];
      if (name != null && name.toString().trim().isNotEmpty) return name.toString();
    }
    final content = (p['content'] as String? ?? '').trim();
    if (content.isNotEmpty) {
      return content.length > 40 ? '${content.substring(0, 40)}…' : content;
    }
    return 'No description';
  }

  Widget _buildTodaySchedule() {
    if (_scheduleLoading) {
      return Column(
        children: List.generate(
          2,
              (i) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              height: 66,
              decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border)),
            ),
          ),
        ),
      );
    }
    if (_scheduleError != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: AppColors.error.withOpacity(0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.error.withOpacity(0.3))),
        child: Row(children: [
          const Icon(Icons.error_outline_rounded, size: 16, color: AppColors.error),
          const SizedBox(width: 8),
          Expanded(child: Text(_scheduleError!, style: GoogleFonts.sora(fontSize: 12, color: AppColors.error))),
          GestureDetector(
            onTap: _fetchTodaySchedule,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: AppColors.error.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
              child: Text('Retry', style: GoogleFonts.sora(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.error)),
            ),
          ),
        ]),
      );
    }
    if (_todaySchedule.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border)),
        child: Row(children: [
          const Icon(Icons.event_available_rounded, size: 18, color: AppColors.textMuted),
          const SizedBox(width: 10),
          Expanded(child: Text('No posts scheduled for today', style: GoogleFonts.sora(fontSize: 12, color: AppColors.textMuted))),
        ]),
      );
    }

    return Column(
      children: _todaySchedule.asMap().entries.map((e) {
        final p = e.value;
        final rawPlatforms = p['platforms'];
        final firstPlatform = (rawPlatforms is List && rawPlatforms.isNotEmpty)
            ? rawPlatforms.first.toString().toLowerCase()
            : '';
        final meta = _schedulePlatformMeta[firstPlatform];
        final title = meta?.label ?? (firstPlatform.isEmpty ? 'Scheduled Post' : '${firstPlatform[0].toUpperCase()}${firstPlatform.substring(1)} Post');
        final icon = meta?.icon ?? Icons.public_rounded;
        final color = meta?.color ?? AppColors.smmColor;
        final time = _displayScheduleTime(p);
        final subtitle = _scheduleClientLabel(p);

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: CommonCard(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, color: color, size: 18)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: GoogleFonts.sora(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary)),
                      Text(subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.sora(
                              fontSize: 11,
                              color: AppColors.textSecondary)),
                    ]),
              ),
              Text(time,
                  style: GoogleFonts.sora(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.smmColor)),
            ]),
          ).animate(
              delay: Duration(milliseconds: 620 + e.key * 80))
              .fadeIn(),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return _buildSkeleton();
    if (_error != null) return _buildError();
    return _buildContent();
  }

  Widget _buildSkeleton() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12, mainAxisSpacing: 12,
            childAspectRatio: 1.2,
            children: List.generate(4, (_) => _StatCardSkeleton()),
          ),
          const SizedBox(height: 24),
          _skeletonBox(120, 16),
          const SizedBox(height: 12),
          ...List.generate(3, (_) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _skeletonBox(double.infinity, 68, radius: 14),
          )),
        ],
      ),
    );
  }

  Widget _skeletonBox(double w, double h, {double radius = 8}) => Container(
    width: w, height: h,
    margin: const EdgeInsets.only(bottom: 4),
    decoration: BoxDecoration(
      color: AppColors.border,
      borderRadius: BorderRadius.circular(radius),
    ),
  );

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                shape: BoxShape.circle),
            child: const Icon(Icons.error_outline_rounded,
                color: AppColors.error, size: 30),
          ),
          const SizedBox(height: 16),
          Text(_error!,
              textAlign: TextAlign.center,
              style: GoogleFonts.sora(
                  fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _fetchDashboard,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 11),
              decoration: BoxDecoration(
                  gradient: AppColors.smmGradient,
                  borderRadius: BorderRadius.circular(10)),
              child: Text('Retry',
                  style: GoogleFonts.sora(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white)),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildContent() {
    final d = _data!;
    return RefreshIndicator(
        color: AppColors.smmColor,
        backgroundColor: AppColors.surface,
        onRefresh: _fetchDashboard,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12, mainAxisSpacing: 12,
                childAspectRatio: 1,
                children: [
                  StatCard(
                    label: 'Scheduled Posts',
                    value: '${d.scheduledPosts}',
                    icon: Icons.schedule_rounded,
                    color: AppColors.smmColor,
                  ),
                  StatCard(
                    label: 'Published Posts',
                    value: '${d.publishedPosts}',
                    icon: Icons.check_circle_outline_rounded,
                    color: AppColors.success,
                  ),
                  StatCard(
                    label: 'Active Projects',
                    value: '${d.inProgressProjects}',
                    icon: Icons.folder_rounded,
                    color: AppColors.accent,
                  ),
                  StatCard(
                    label: 'Total Projects',
                    value: '${d.totalProjects}',
                    icon: Icons.work_outline_rounded,
                    color: AppColors.secondary,
                  ),
                ],
              ).animate(delay: 100.ms).fadeIn(),

              const SizedBox(height: 24),

              // ── Recent Projects ──
              if (d.recentProjects.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Recent Projects',
                        style: GoogleFonts.sora(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6)),
                      child: Text('${d.pendingProjects} Pending',
                          style: GoogleFonts.sora(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.warning)),
                    ),
                  ],
                ).animate(delay: 300.ms).fadeIn(),
                const SizedBox(height: 12),

                ...d.recentProjects.asMap().entries.map((e) {
                  final p = e.value;
                  final clientMap = p['client'] as Map<String, dynamic>? ?? {};
                  final designerMap = p['designer'] as Map<String, dynamic>? ?? {};
                  final status = (p['status'] as String? ?? 'Pending');
                  final priority = (p['priority'] as String? ?? '');
                  final title = (p['title'] as String? ?? 'Untitled');
                  final clientName = (clientMap['companyName'] ?? clientMap['name'] ?? '—').toString();
                  final designerName = (designerMap['name'] ?? '—').toString();
                  final deadline = _formatDeadline(p['deadline'] as String?);
                  final statusColor = _getStatusColor(status);

                  Color priorityColor = AppColors.info;
                  if (priority == 'High') priorityColor = AppColors.error;
                  else if (priority == 'Medium') priorityColor = AppColors.warning;
                  else if (priority == 'Urgent') priorityColor = const Color(0xFFFF3B30);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: CommonCard(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Container(
                                width: 40, height: 40,
                                decoration: BoxDecoration(
                                    gradient: AppColors.smmGradient,
                                    borderRadius: BorderRadius.circular(10)),
                                child: const Icon(Icons.design_services_rounded,
                                    color: Colors.white, size: 20)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(title,
                                        style: GoogleFonts.sora(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPrimary)),
                                    Text(clientName,
                                        style: GoogleFonts.sora(
                                            fontSize: 11,
                                            color: AppColors.textSecondary)),
                                  ]),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(6)),
                              child: Text(status,
                                  style: GoogleFonts.sora(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: statusColor)),
                            ),
                          ]),
                          const SizedBox(height: 10),
                          Row(children: [
                            const Icon(Icons.person_outline_rounded,
                                size: 12, color: AppColors.textMuted),
                            const SizedBox(width: 4),
                            Text(designerName,
                                style: GoogleFonts.sora(
                                    fontSize: 11, color: AppColors.textSecondary)),
                            const SizedBox(width: 12),
                            const Icon(Icons.calendar_today_rounded,
                                size: 12, color: AppColors.textMuted),
                            const SizedBox(width: 4),
                            Text(deadline,
                                style: GoogleFonts.sora(
                                    fontSize: 11, color: AppColors.textSecondary)),
                            const Spacer(),
                            if (priority.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                    color: priorityColor.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(5)),
                                child: Text(priority,
                                    style: GoogleFonts.sora(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: priorityColor)),
                              ),
                          ]),
                        ],
                      ),
                    ).animate(
                        delay: Duration(milliseconds: 350 + e.key * 80))
                        .fadeIn(),
                  );
                }),
                const SizedBox(height: 24),
              ],

              // ── Today's Schedule ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Today's Schedule",
                      style: GoogleFonts.sora(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  GestureDetector(
                    onTap: widget.onCreatePost,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                          gradient: AppColors.smmGradient,
                          borderRadius: BorderRadius.circular(8)),
                      child: Row(children: [
                        const Icon(Icons.add_rounded,
                            color: Colors.white, size: 14),
                        const SizedBox(width: 3),
                        Text('New Post',
                            style: GoogleFonts.sora(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white)),
                      ]),
                    ),
                  ),
                ],
              ).animate(delay: 550.ms).fadeIn(),
              const SizedBox(height: 12),

              _buildTodaySchedule(),

              const SizedBox(height: 80),
            ],
          ),
        ));
  }
}

// ─────────────────────────────────────────
// STAT CARD SKELETON
// ─────────────────────────────────────────
class _StatCardSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(10))),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(width: 40, height: 20,
                decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(6))),
            const SizedBox(height: 6),
            Container(width: 80, height: 10,
                decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(4))),
          ]),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// CREATE POST SHEET  (2 buttons)
// ─────────────────────────────────────────
class _ApiPostCard extends StatelessWidget {
  final String content;
  final List<String> platforms;
  final bool hasMedia;
  final DateTime? scheduledAt;
  final DateTime createdAt;
  final Color accentColor;
  final Map<String, Color> platformColors;
  final Map<String, IconData> platformIcons;
  final bool isQueue;

  const _ApiPostCard({
    required this.content,
    required this.platforms,
    required this.hasMedia,
    required this.scheduledAt,
    required this.createdAt,
    required this.accentColor,
    required this.platformColors,
    required this.platformIcons,
    required this.isQueue,
  });

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '\${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '\${diff.inHours}h ago';
    return '\${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final displayContent = content.isNotEmpty ? content : '(No content)';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [accentColor, accentColor.withOpacity(0.6)]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              hasMedia ? Icons.image_rounded : Icons.text_fields_rounded,
              color: Colors.white, size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                displayContent.length > 60
                    ? '\${displayContent.substring(0, 60)}…'
                    : displayContent,
                style: GoogleFonts.sora(
                    fontSize: 12, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 4),
              Text(_timeAgo(createdAt),
                  style: GoogleFonts.sora(
                      fontSize: 10, color: AppColors.textMuted)),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              isQueue ? 'Queued' : 'Draft',
              style: GoogleFonts.sora(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: accentColor),
            ),
          ),
        ]),
        if (platforms.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 5, runSpacing: 5,
            children: platforms.map((pid) {
              final col = platformColors[pid] ?? AppColors.textMuted;
              final ico = platformIcons[pid] ?? Icons.public_rounded;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: col.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(ico, color: col, size: 11),
                  const SizedBox(width: 4),
                  Text(pid[0].toUpperCase() + pid.substring(1),
                      style: GoogleFonts.sora(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: col)),
                ]),
              );
            }).toList(),
          ),
        ],
        if (scheduledAt != null) ...[
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.schedule_rounded,
                size: 12, color: AppColors.textMuted),
            const SizedBox(width: 4),
            Text(
              'Scheduled: \${scheduledAt!.day}/\${scheduledAt!.month}/\${scheduledAt!.year} '
                  '\${scheduledAt!.hour.toString().padLeft(2, "0")}:\${scheduledAt!.minute.toString().padLeft(2, "0")}',
              style: GoogleFonts.sora(fontSize: 10, color: AppColors.textMuted),
            ),
          ]),
        ],
      ]),
    );
  }
}

// ─────────────────────────────────────────
// SKELETON CARD
// ─────────────────────────────────────────
class _PostCardSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          _box(40, 40, radius: 10),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _box(double.infinity, 11, radius: 6),
              const SizedBox(height: 6),
              _box(80, 9, radius: 6),
            ]),
          ),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          _box(64, 22, radius: 6),
          const SizedBox(width: 6),
          _box(64, 22, radius: 6),
        ]),
      ]),
    );
  }

  Widget _box(double w, double h, {required double radius}) => Container(
    width: w, height: h,
    decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(radius)),
  );
}

//     style:
//     GoogleFonts.sora(fontSize: 13, color: AppColors.textPrimary),
//     decoration: InputDecoration(
//       hintText: hint,
//       hintStyle:
//       GoogleFonts.sora(fontSize: 13, color: AppColors.textMuted),
//       border: InputBorder.none,
//       contentPadding: const EdgeInsets.all(14),
//     ),
//   ),
// );

Widget _emptyState({
  required IconData icon,
  required String title,
  required String subtitle,
  required Color color,
}) =>
    Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 34),
          ),
          const SizedBox(height: 16),
          Text(title,
              style: GoogleFonts.sora(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.sora(
                  fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );

class _PlatformOption {
  final String id, name;
  final Color color;
  final IconData icon;
  const _PlatformOption(this.id, this.name, this.color, this.icon);
}

// ─────────────────────────────────────────
// HELPER WIDGETS
// ─────────────────────────────────────────
class _QuickNav extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickNav(this.icon, this.label, this.color, this.onTap);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: CommonCard(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(children: [
            Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(9)),
                child: Icon(icon, color: color, size: 16)),
            const SizedBox(height: 5),
            Text(label,
                style: GoogleFonts.sora(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
          ]),
        ),
      ),
    );
  }
}

class _ApprBtn extends StatelessWidget {
  final String label;
  final Color color;
  final bool outlined;
  const _ApprBtn(this.label, this.color, {this.outlined = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: outlined ? Colors.transparent : color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(7),
        border:
        outlined ? Border.all(color: color.withOpacity(0.4)) : null,
      ),
      child: Text(label,
          style: GoogleFonts.sora(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color)),
    );
  }
}