import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/network/api_service.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exceptions.dart';

// ─────────────────────────────────────────
// NOTIFICATION MODEL
// ─────────────────────────────────────────
class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final DateTime createdAt;

  const NotificationModel({
    required this.id, required this.title, required this.message,
    required this.type, required this.isRead, required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      title: (json['title'] ?? json['subject'] ?? 'Notification').toString(),
      message: (json['message'] ?? json['body'] ?? json['description'] ?? '').toString(),
      type: (json['type'] ?? 'general').toString().toLowerCase(),
      isRead: json['isRead'] == true || json['read'] == true || json['is_read'] == true,
      createdAt: _parseDate(json['createdAt'] ?? json['created_at'] ?? json['timestamp']),
    );
  }

  static DateTime _parseDate(dynamic raw) {
    if (raw == null) return DateTime.now();
    try { return DateTime.parse(raw.toString()).toLocal(); } catch (_) { return DateTime.now(); }
  }
}

// ─────────────────────────────────────────
// NOTIFICATIONS PAGE
// ─────────────────────────────────────────
class NotificationsPage extends StatefulWidget {
  final Color accentColor;
  final LinearGradient gradient;

  const NotificationsPage({
    super.key,
    required this.accentColor,
    required this.gradient,
  });

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final _api = ApiService();
  List<NotificationModel> _notifications = [];
  bool _loading = true;
  String? _error;
  final Set<String> _deletingIds = {};

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await _api.get(AppConstants.notifications);
      final raw = res['data']?['notifications'] ?? [];
      setState(() {
        _notifications = (raw as List).map((e) => NotificationModel.fromJson(e)).toList();
        _loading = false;
      });
    } on NetworkException catch (_) {
      setState(() { _error = 'No internet connection.'; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _deleteNotification(String id) async {
    setState(() => _deletingIds.add(id));
    try {
      await _api.delete('${AppConstants.notifications}/$id');
      setState(() { _notifications.removeWhere((n) => n.id == id); _deletingIds.remove(id); });
      _showSnack('Notification deleted', AppColors.success, Icons.check_circle_rounded);
    } on NetworkException catch (_) {
      setState(() => _deletingIds.remove(id));
      _showSnack('No internet connection.', AppColors.error, Icons.wifi_off_rounded);
    } on UnauthorizedException catch (_) {
      setState(() => _deletingIds.remove(id));
      _showSnack('Session expired. Please log in again.', AppColors.error, Icons.lock_outline_rounded);
    } on AppException catch (e) {
      setState(() => _deletingIds.remove(id));
      _showSnack(e.message, AppColors.error, Icons.error_outline_rounded);
    } catch (_) {
      setState(() => _deletingIds.remove(id));
      _showSnack('Failed to delete notification.', AppColors.error, Icons.error_outline_rounded);
    }
  }

  Future<void> _clearAll() async {
    if (_notifications.isEmpty) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Clear All Notifications', style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        content: Text('This will delete all notifications permanently.', style: GoogleFonts.sora(fontSize: 13, color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel', style: GoogleFonts.sora(fontSize: 13, color: AppColors.textSecondary))),
          GestureDetector(
            onTap: () => Navigator.pop(ctx, true),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
              decoration: BoxDecoration(color: AppColors.error.withOpacity(0.15), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.error.withOpacity(0.4))),
              child: Text('Delete All', style: GoogleFonts.sora(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.error)),
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final ids = _notifications.map((n) => n.id).toList();
    for (final id in ids) { _deleteNotification(id); }
  }

  void _showSnack(String msg, Color color, IconData icon) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(icon, color: Colors.white, size: 16),
        const SizedBox(width: 8),
        Expanded(child: Text(msg, style: GoogleFonts.sora(fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis)),
      ]),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'post': return Icons.post_add_rounded;
      case 'project': return Icons.design_services_rounded;
      case 'approval': return Icons.check_circle_outline_rounded;
      case 'revision': return Icons.history_rounded;
      case 'deadline': return Icons.timer_outlined;
      case 'message': return Icons.chat_bubble_outline_rounded;
      case 'system': return Icons.settings_outlined;
      default: return Icons.notifications_outlined;
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'post': return widget.accentColor;
      case 'project': return AppColors.primary;
      case 'approval': return AppColors.success;
      case 'revision': return AppColors.warning;
      case 'deadline': return AppColors.error;
      case 'message': return AppColors.info;
      case 'system': return AppColors.textSecondary;
      default: return widget.accentColor;
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textSecondary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShaderMask(
              shaderCallback: (b) => widget.gradient.createShader(b),
              child: Text('Notifications', style: GoogleFonts.sora(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
            if (!_loading && _error == null)
              Text(
                _notifications.isEmpty ? 'All caught up!' : unreadCount > 0 ? '$unreadCount unread · ${_notifications.length} total' : '${_notifications.length} notification${_notifications.length == 1 ? '' : 's'}',
                style: GoogleFonts.sora(fontSize: 11, color: AppColors.textSecondary),
              ),
          ],
        ),
        actions: [
          if (!_loading && _error == null && _notifications.isNotEmpty)
            GestureDetector(
              onTap: _clearAll,
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: AppColors.error.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.error.withOpacity(0.3))),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.delete_sweep_rounded, color: AppColors.error, size: 14),
                  const SizedBox(width: 4),
                  Text('Clear All', style: GoogleFonts.sora(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.error)),
                ]),
              ),
            ),
          GestureDetector(
            onTap: _loading ? null : _fetchNotifications,
            child: Container(
              width: 36, height: 36,
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
              child: _loading
                  ? Padding(padding: const EdgeInsets.all(8), child: CircularProgressIndicator(strokeWidth: 2, color: widget.accentColor))
                  : Icon(Icons.refresh_rounded, color: widget.accentColor, size: 18),
            ),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(color: AppColors.border, height: 1),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return _buildSkeleton();
    if (_error != null) return _buildError();
    if (_notifications.isEmpty) return _buildEmpty();
    return _buildList();
  }

  Widget _buildSkeleton() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, __) => const _NotificationSkeleton(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 72, height: 72, decoration: BoxDecoration(color: AppColors.error.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.wifi_off_rounded, color: AppColors.error, size: 32)),
          const SizedBox(height: 20),
          Text('Oops! Something went wrong', style: GoogleFonts.sora(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Text(_error!, textAlign: TextAlign.center, style: GoogleFonts.sora(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _fetchNotifications,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
              decoration: BoxDecoration(gradient: widget.gradient, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: widget.accentColor.withOpacity(0.35), blurRadius: 14, offset: const Offset(0, 5))]),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.refresh_rounded, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text('Try Again', style: GoogleFonts.sora(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ShaderMask(
            shaderCallback: (b) => widget.gradient.createShader(b),
            child: const Icon(Icons.notifications_off_outlined, size: 72, color: Colors.white),
          ),
          const SizedBox(height: 20),
          Text("You're all caught up!", style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Text('No notifications at the moment.\nCheck back later.', textAlign: TextAlign.center, style: GoogleFonts.sora(fontSize: 12, color: AppColors.textSecondary)),
        ]),
      ),
    );
  }

  Widget _buildList() {
    return RefreshIndicator(
      color: widget.accentColor,
      backgroundColor: AppColors.surface,
      onRefresh: _fetchNotifications,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _notifications.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final n = _notifications[i];
          return NotificationCard(
            key: ValueKey(n.id),
            notification: n,
            accentColor: widget.accentColor,
            gradient: widget.gradient,
            isDeleting: _deletingIds.contains(n.id),
            typeIcon: _typeIcon(n.type),
            typeColor: _typeColor(n.type),
            timeAgo: _timeAgo(n.createdAt),
            onDelete: () => _deleteNotification(n.id),
          ).animate(delay: Duration(milliseconds: i * 50)).fadeIn().slideX(begin: 0.1, end: 0);
        },
      ),
    );
  }
}

// ─────────────────────────────────────────
// NOTIFICATION CARD
// ─────────────────────────────────────────
class NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final Color accentColor;
  final LinearGradient gradient;
  final bool isDeleting;
  final IconData typeIcon;
  final Color typeColor;
  final String timeAgo;
  final VoidCallback onDelete;

  const NotificationCard({
    super.key,
    required this.notification, required this.accentColor, required this.gradient,
    required this.isDeleting, required this.typeIcon, required this.typeColor,
    required this.timeAgo, required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey('dismissible_${notification.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async { HapticFeedback.mediumImpact(); return true; },
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(color: AppColors.error.withOpacity(0.15), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.error.withOpacity(0.3))),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 24),
          const SizedBox(height: 4),
          Text('Delete', style: GoogleFonts.sora(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.error)),
        ]),
      ),
      child: AnimatedOpacity(
        opacity: isDeleting ? 0.4 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: notification.isRead ? AppColors.surfaceLight : typeColor.withOpacity(0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: notification.isRead ? AppColors.border : typeColor.withOpacity(0.25)),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Stack(clipBehavior: Clip.none, children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: typeColor.withOpacity(0.15), borderRadius: BorderRadius.circular(13)),
                child: Icon(typeIcon, color: typeColor, size: 20),
              ),
              if (!notification.isRead)
                Positioned(
                  top: -3, right: -3,
                  child: Container(
                    width: 10, height: 10,
                    decoration: BoxDecoration(color: accentColor, shape: BoxShape.circle, border: Border.all(color: AppColors.surface, width: 1.5)),
                  ),
                ),
            ]),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child: Text(notification.title, style: GoogleFonts.sora(fontSize: 13, fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.w700, color: AppColors.textPrimary))),
                  const SizedBox(width: 8),
                  Text(timeAgo, style: GoogleFonts.sora(fontSize: 10, color: AppColors.textMuted)),
                ]),
                if (notification.message.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(notification.message, style: GoogleFonts.sora(fontSize: 12, color: AppColors.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
                const SizedBox(height: 8),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: typeColor.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                    child: Text(_capitalize(notification.type), style: GoogleFonts.sora(fontSize: 10, fontWeight: FontWeight.w600, color: typeColor)),
                  ),
                  const Spacer(),
                  isDeleting
                      ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.error))
                      : GestureDetector(
                    onTap: onDelete,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(color: AppColors.error.withOpacity(0.08), borderRadius: BorderRadius.circular(7)),
                      child: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 14),
                    ),
                  ),
                ]),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

// ─────────────────────────────────────────
// NOTIFICATION SKELETON
// ─────────────────────────────────────────
class _NotificationSkeleton extends StatefulWidget {
  const _NotificationSkeleton();
  @override
  State<_NotificationSkeleton> createState() => _NotificationSkeletonState();
}

class _NotificationSkeletonState extends State<_NotificationSkeleton> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat(reverse: true);
    _anim = Tween(begin: 0.4, end: 0.9).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Opacity(
        opacity: _anim.value,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _box(44, 44, radius: 13),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: _box(double.infinity, 13, radius: 6)),
                const SizedBox(width: 40),
                _box(40, 10, radius: 4),
              ]),
              const SizedBox(height: 8),
              _box(double.infinity, 10, radius: 4),
              const SizedBox(height: 4),
              _box(200, 10, radius: 4),
              const SizedBox(height: 10),
              _box(60, 20, radius: 6),
            ])),
          ]),
        ),
      ),
    );
  }

  Widget _box(double w, double h, {required double radius}) => Container(
    width: w, height: h,
    margin: const EdgeInsets.only(bottom: 2),
    decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(radius)),
  );
}
