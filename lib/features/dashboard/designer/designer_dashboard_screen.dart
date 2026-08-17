import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/network/api_service.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../../shared/pages/messages_page.dart';
import '../../../shared/pages/profile_page.dart';
import 'pages/designer_inner_pages.dart';

// ─── Models ──────────────────────────────────────────────────────────────────

class DashboardStats {
  final int totalTasks;
  final int pendingTasks;
  final int inProgressTasks;
  final int revisionTasks;
  final int completedTasks;
  final int dueToday;

  const DashboardStats({
    required this.totalTasks,
    required this.pendingTasks,
    required this.inProgressTasks,
    required this.revisionTasks,
    required this.completedTasks,
    required this.dueToday,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> j) => DashboardStats(
    totalTasks:       j['totalTasks']       as int? ?? 0,
    pendingTasks:     j['pendingTasks']     as int? ?? 0,
    inProgressTasks:  j['inProgressTasks']  as int? ?? 0,
    revisionTasks:    j['revisionTasks']    as int? ?? 0,
    completedTasks:   j['completedTasks']   as int? ?? 0,
    dueToday:         j['dueToday']         as int? ?? 0,
  );

  factory DashboardStats.empty() => const DashboardStats(
    totalTasks: 0, pendingTasks: 0, inProgressTasks: 0,
    revisionTasks: 0, completedTasks: 0, dueToday: 0,
  );
}

class ProjectTask {
  final String id;
  final String title;
  final String status;
  final String? dueDate;
  final String? clientName;
  final String? priority;

  const ProjectTask({
    required this.id,
    required this.title,
    required this.status,
    this.dueDate,
    this.clientName,
    this.priority,
  });

  factory ProjectTask.fromJson(Map<String, dynamic> j) => ProjectTask(
    id:         j['_id']?.toString() ?? j['id']?.toString() ?? '',
    title:      j['title'] ?? j['name'] ?? j['projectName'] ?? 'Untitled',
    status:     j['status'] ?? 'pending',
    dueDate:    j['dueDate']?.toString() ?? j['deadline']?.toString(),
    clientName: j['clientName']?.toString() ??
        (j['client'] is Map ? (j['client'] as Map)['companyName']?.toString() : j['client']?.toString()),
    priority:   j['priority']?.toString(),
  );

  bool get isDueToday {
    if (dueDate == null) return false;
    try {
      final d = DateTime.parse(dueDate!).toLocal();
      final now = DateTime.now();
      return d.year == now.year && d.month == now.month && d.day == now.day;
    } catch (_) { return false; }
  }

  String get formattedDue {
    if (dueDate == null) return '';
    try {
      final d = DateTime.parse(dueDate!).toLocal();
      const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return 'Due ${months[d.month - 1]} ${d.day}, ${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}';
    } catch (_) { return dueDate!; }
  }
}

// ─── API Service (uses ApiService — no manual token needed) ──────────────────

class _GdApiService {
  static final _api = ApiService();

  static Future<DashboardStats> fetchDashboard() async {
    try {
      final body = await _api.get('/api/gd/dashboard');
      if (body['success'] == true) {
        final data = body['data'];
        if (data is Map<String, dynamic>) return DashboardStats.fromJson(data);
      }
      return DashboardStats.empty();
    } catch (_) { return DashboardStats.empty(); }
  }

  static Future<List<ProjectTask>> fetchProjects() async {
    try {
      final body = await _api.get(AppConstants.gdProjects);
      if (body['success'] == true) {
        final data = body['data'];
        List raw = [];
        if (data is Map) {
          raw = data['projects'] as List? ?? data['tasks'] as List? ?? [];
        } else if (data is List) {
          raw = data;
        }
        return raw
            .cast<Map<String, dynamic>>()
            .map(ProjectTask.fromJson)
            .toList();
      }
      return [];
    } catch (_) { return []; }
  }
}

// ─── Main Screen ─────────────────────────────────────────────────────────────

class DesignerDashboardScreen extends StatefulWidget {
  const DesignerDashboardScreen({super.key});
  @override
  State<DesignerDashboardScreen> createState() => _DesignerDashboardScreenState();
}

class _DesignerDashboardScreenState extends State<DesignerDashboardScreen> {
  int _navIndex = 0;

  String get _title {
    switch (_navIndex) {
      case 0: return 'Dashboard';
      case 1: return 'My Tasks';
      case 2: return 'Upload';
      case 3: return 'Messages';
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
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _navIndex == 0
                          ? Text('Hi, ${auth.userName} 🔥',
                          style: GoogleFonts.sora(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary))
                          : ShaderMask(
                        shaderCallback: (b) =>
                            AppColors.designerGradient.createShader(b),
                        child: Text(_title,
                            style: GoogleFonts.sora(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                      ),
                      if (_navIndex == 0)
                        Text("Let's create something amazing today",
                            style: GoogleFonts.sora(
                                fontSize: 11,
                                color: AppColors.textSecondary)),
                    ],
                  ),
                  // const Spacer(),
                  // Stack(
                  //   children: [
                  //     Container(
                  //       width: 40, height: 40,
                  //       decoration: BoxDecoration(
                  //           gradient: AppColors.designerGradient,
                  //           shape: BoxShape.circle),
                  //       child: Center(
                  //         child: Text(
                  //           auth.userName.isNotEmpty
                  //               ? auth.userName[0].toUpperCase()
                  //               : 'D',
                  //           style: GoogleFonts.sora(
                  //               fontWeight: FontWeight.w700,
                  //               color: Colors.white),
                  //         ),
                  //       ),
                  //     ),
                  //     Positioned(
                  //       bottom: 0, right: 0,
                  //       child: Container(
                  //         width: 12, height: 12,
                  //         decoration: BoxDecoration(
                  //             color: AppColors.success,
                  //             shape: BoxShape.circle,
                  //             border: Border.all(
                  //                 color: AppColors.background, width: 2)),
                  //       ),
                  //     ),
                  //   ],
                  // ),
                ],
              ).animate().fadeIn(),
            ),
            Expanded(child: _buildPage()),
          ],
        ),
      ),
      bottomNavigationBar: CommonBottomNav(
        currentIndex: _navIndex,
        activeColor: AppColors.designerColor,
        onTap: (i) => setState(() => _navIndex = i),
        items: const [
          BottomNavItem(
              icon: Icons.home_outlined,
              activeIcon: Icons.home_rounded,
              label: 'Home'),
          BottomNavItem(
              icon: Icons.task_outlined,
              activeIcon: Icons.task_alt_rounded,
              label: 'Tasks'),
          BottomNavItem(
              icon: Icons.cloud_upload_outlined,
              activeIcon: Icons.cloud_upload_rounded,
              label: 'Upload'),
          BottomNavItem(
              icon: Icons.chat_bubble_outline_rounded,
              activeIcon: Icons.chat_bubble_rounded,
              label: 'Messages'),
          BottomNavItem(
              icon: Icons.person_outline_rounded,
              activeIcon: Icons.person_rounded,
              label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildPage() {
    switch (_navIndex) {
      case 0:
        return _DesignerHome(onNav: (i) => setState(() => _navIndex = i));
      case 1:
        return const DesignerTasksPage();
      case 2:
        return const DesignerUploadPage();
      case 3:
        return MessagesPage(
            accentColor: AppColors.designerColor,
            gradient: AppColors.designerGradient);
      case 4:
        return ProfilePage(
            accentColor: AppColors.designerColor,
            gradient: AppColors.designerGradient);
      default:
        return _DesignerHome(onNav: (i) => setState(() => _navIndex = i));
    }
  }
}

// ─── Home Page ────────────────────────────────────────────────────────────────

class _DesignerHome extends StatefulWidget {
  final Function(int) onNav;
  const _DesignerHome({required this.onNav});

  @override
  State<_DesignerHome> createState() => _DesignerHomeState();
}

class _DesignerHomeState extends State<_DesignerHome> {
  DashboardStats? _stats;
  List<ProjectTask> _projects = [];
  bool _statsLoading = true;
  bool _projectsLoading = true;
  String? _statsError;
  String? _projectsError;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
    _loadProjects();
  }

  Future<void> _loadDashboard() async {
    try {
      final stats = await _GdApiService.fetchDashboard();
      if (mounted) setState(() { _stats = stats; _statsLoading = false; });
    } catch (e) {
      if (mounted) setState(() {
        _statsError = 'Failed to load stats';
        _statsLoading = false;
      });
    }
  }

  Future<void> _loadProjects() async {
    try {
      final projects = await _GdApiService.fetchProjects();
      if (mounted) setState(() { _projects = projects; _projectsLoading = false; });
    } catch (e) {
      if (mounted) setState(() {
        _projectsError = 'Failed to load tasks';
        _projectsLoading = false;
      });
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _statsLoading = true;
      _projectsLoading = true;
      _statsError = null;
      _projectsError = null;
    });
    await Future.wait([_loadDashboard(), _loadProjects()]);
  }

  List<ProjectTask> get _todayTasks =>
      _projects.where((p) => p.isDueToday).toList();

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.designerColor,
      onRefresh: _refresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            _buildStatsSection(),
            const SizedBox(height: 24),
            _buildTasksSection(),
            const SizedBox(height: 20),
            // _buildQuickActions(),
          ],
        ),
      ),
    );
  }

  // ── Stats Section ────────────────────────────────────────────────────────

  Widget _buildStatsSection() {
    if (_statsLoading) return _shimmerGrid();
    if (_statsError != null) return _errorCard(_statsError!, _loadDashboard);

    final s = _stats!;
    return Column(
      children: [
        CommonCard(
          gradient: AppColors.designerGradient,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('My Tasks',
                  style: GoogleFonts.sora(fontSize: 12, color: Colors.white70)),
              const SizedBox(height: 10),
              Row(
                children: [
                  _gradientStat('${s.inProgressTasks}', 'In Progress'),
                  const SizedBox(width: 24),
                  _gradientStat('${s.pendingTasks}', 'Pending'),
                  const SizedBox(width: 24),
                  _gradientStat('${s.revisionTasks}', 'Revision'),
                ],
              ),
            ],
          ),
        ).animate(delay: 100.ms).fadeIn(),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: StatCard(
                label: 'Total',
                value: '${s.totalTasks}',
                icon: Icons.layers_rounded,
                color: AppColors.designerColor)),
            const SizedBox(width: 12),
            Expanded(child: StatCard(
                label: 'Completed',
                value: '${s.completedTasks}',
                icon: Icons.check_circle_outline_rounded,
                color: AppColors.success)),
            const SizedBox(width: 12),
            Expanded(child: StatCard(
                label: 'Due Today',
                value: '${s.dueToday}',
                icon: Icons.today_rounded,
                color: AppColors.error)),
          ],
        ).animate(delay: 180.ms).fadeIn(),
      ],
    );
  }

  Widget _gradientStat(String value, String label) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(value,
          style: GoogleFonts.sora(
              fontSize: 26, fontWeight: FontWeight.w700, color: Colors.white)),
      Text(label,
          style: GoogleFonts.sora(fontSize: 10, color: Colors.white70)),
    ],
  );

  // ── Tasks Section ────────────────────────────────────────────────────────

  Widget _buildTasksSection() {
    // Loading skeleton
    if (_projectsLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Today's Tasks",
                  style: GoogleFonts.sora(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 12),
          ...List.generate(3, (_) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              height: 72,
              decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(14)),
            ),
          )),
        ],
      );
    }

    // Error state
    if (_projectsError != null) {
      return _errorCard(_projectsError!, _loadProjects);
    }

    final today = _todayTasks;
    final showSeeAll = today.length > 4;
    final displayTasks = showSeeAll ? today.take(4).toList() : today;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header row ──────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Today's Tasks",
                style: GoogleFonts.sora(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            if (showSeeAll)
              GestureDetector(
                onTap: () => widget.onNav(1),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: AppColors.designerGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('See All',
                          style: GoogleFonts.sora(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white)),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward_rounded,
                          size: 12, color: Colors.white),
                    ],
                  ),
                ),
              ),
          ],
        ).animate(delay: 200.ms).fadeIn(),
        const SizedBox(height: 12),

        // ── Empty state ──────────────────────────────────
        if (today.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 28),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.check_circle_outline_rounded,
                      size: 40,
                      color: AppColors.textSecondary.withOpacity(0.4)),
                  const SizedBox(height: 8),
                  Text("No tasks due today 🎉",
                      style: GoogleFonts.sora(
                          fontSize: 13,
                          color: AppColors.textSecondary)),
                ],
              ),
            ),
          ).animate(delay: 220.ms).fadeIn()
        else
        // ── Task list (max 4) ────────────────────────
          ...displayTasks.asMap().entries.map((e) {
            final i = e.key;
            final t = e.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _TaskCard(task: t)
                  .animate(delay: Duration(milliseconds: 250 + i * 70))
                  .fadeIn()
                  .slideX(begin: 0.15, end: 0),
            );
          }),

        // ── "See All" bottom button if >4 ───────────────
        if (showSeeAll) ...[
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () => widget.onNav(1),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                color: AppColors.designerColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.designerColor.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'View All ${today.length} Tasks',
                    style: GoogleFonts.sora(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.designerColor),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.arrow_forward_rounded,
                      size: 14, color: AppColors.designerColor),
                ],
              ),
            ),
          ).animate(delay: 500.ms).fadeIn(),
        ],
      ],
    );
  }

  // ── Quick Actions ────────────────────────────────────────────────────────

  // Widget _buildQuickActions() {
  //   return Row(
  //     children: [
  //       Expanded(
  //         child: GestureDetector(
  //           onTap: () => widget.onNav(2),
  //           child: CommonCard(
  //             padding: const EdgeInsets.all(14),
  //             child: Column(children: [
  //               Container(
  //                 width: 40, height: 40,
  //                 decoration: BoxDecoration(
  //                     gradient: AppColors.designerGradient,
  //                     borderRadius: BorderRadius.circular(10)),
  //                 child: const Icon(Icons.cloud_upload_rounded,
  //                     color: Colors.white, size: 20),
  //               ),
  //               const SizedBox(height: 8),
  //               Text('Upload Design',
  //                   style: GoogleFonts.sora(
  //                       fontSize: 12,
  //                       fontWeight: FontWeight.w600,
  //                       color: AppColors.textPrimary)),
  //             ]),
  //           ),
  //         ),
  //       ),
  //       const SizedBox(width: 12),
  //       Expanded(
  //         child: GestureDetector(
  //           onTap: () => widget.onNav(3),
  //           child: CommonCard(
  //             padding: const EdgeInsets.all(14),
  //             child: Column(children: [
  //               Container(
  //                 width: 40, height: 40,
  //                 decoration: BoxDecoration(
  //                     color: AppColors.secondary.withOpacity(0.15),
  //                     borderRadius: BorderRadius.circular(10)),
  //                 child: const Icon(Icons.chat_bubble_rounded,
  //                     color: AppColors.secondary, size: 20),
  //               ),
  //               const SizedBox(height: 8),
  //               Text('Messages',
  //                   style: GoogleFonts.sora(
  //                       fontSize: 12,
  //                       fontWeight: FontWeight.w600,
  //                       color: AppColors.textPrimary)),
  //             ]),
  //           ),
  //         ),
  //       ),
  //       const SizedBox(width: 12),
  //       Expanded(
  //         child: GestureDetector(
  //           onTap: () => widget.onNav(1),
  //           child: CommonCard(
  //             padding: const EdgeInsets.all(14),
  //             child: Column(children: [
  //               Container(
  //                 width: 40, height: 40,
  //                 decoration: BoxDecoration(
  //                     color: AppColors.primaryLight.withOpacity(0.15),
  //                     borderRadius: BorderRadius.circular(10)),
  //                 child: const Icon(Icons.task_alt_rounded,
  //                     color: AppColors.designerColor, size: 20),
  //               ),
  //               const SizedBox(height: 8),
  //               Text('All Tasks',
  //                   style: GoogleFonts.sora(
  //                       fontSize: 12,
  //                       fontWeight: FontWeight.w600,
  //                       color: AppColors.textPrimary)),
  //             ]),
  //           ),
  //         ),
  //       ),
  //     ],
  //   ).animate(delay: 700.ms).fadeIn();
  // }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Widget _shimmerGrid() {
    return Column(
      children: [
        Container(
          height: 100,
          decoration: BoxDecoration(
              color: AppColors.textSecondary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16)),
        ),
        const SizedBox(height: 12),
        Row(
          children: List.generate(3, (_) => Expanded(
            child: Container(
              height: 64,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                  color: AppColors.textSecondary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12)),
            ),
          )),
        ),
      ],
    );
  }

  Widget _errorCard(String msg, VoidCallback retry) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.error.withOpacity(0.2))),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.error, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(msg,
              style: GoogleFonts.sora(fontSize: 13, color: AppColors.error))),
          TextButton(
            onPressed: retry,
            child: Text('Retry',
                style: GoogleFonts.sora(
                    fontSize: 12, color: AppColors.designerColor)),
          ),
        ],
      ),
    );
  }
}

// ─── Task Card Widget ─────────────────────────────────────────────────────────

class _TaskCard extends StatelessWidget {
  final ProjectTask task;
  const _TaskCard({required this.task});

  Color get _statusColor {
    switch (task.status.toLowerCase().replaceAll('_', '').replaceAll(' ', '')) {
      case 'inprogress': return AppColors.designerColor;
      case 'revision':   return AppColors.warning;
      case 'completed':
      case 'done':       return AppColors.success;
      default:           return AppColors.error;
    }
  }

  String get _statusLabel {
    switch (task.status.toLowerCase().replaceAll('_', '').replaceAll(' ', '')) {
      case 'inprogress': return 'In Progress';
      case 'revision':   return 'Revision';
      case 'completed':
      case 'done':       return 'Completed';
      default:           return 'Pending';
    }
  }

  Color get _priorityColor {
    switch ((task.priority ?? '').toLowerCase()) {
      case 'high':   return AppColors.error;
      case 'medium': return AppColors.warning;
      default:       return AppColors.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    return TaskItem(
      title: task.title,
      subtitle: [
        if (task.clientName != null && task.clientName!.isNotEmpty) task.clientName!,
        if (task.formattedDue.isNotEmpty) task.formattedDue,
      ].join(' • '),
      priority: task.priority != null && task.priority!.isNotEmpty
          ? '${task.priority![0].toUpperCase()}${task.priority!.substring(1)}'
          : _statusLabel,
      priorityColor: task.priority != null && task.priority!.isNotEmpty
          ? _priorityColor
          : _statusColor,
    );
  }
}