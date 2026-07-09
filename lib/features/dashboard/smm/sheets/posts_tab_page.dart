import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/app_exceptions.dart';
import 'edit_draft_page.dart';

// ─────────────────────────────────────────
// POSTS TAB PAGE  (Queue · Drafts · Published)
// ─────────────────────────────────────────
class PostsTabPage extends StatefulWidget {
  final int initialTab;
  const PostsTabPage({super.key, this.initialTab = 0});

  @override
  State<PostsTabPage> createState() => _PostsTabPageState();
}

class _PostsTabPageState extends State<PostsTabPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _api = ApiService();

  // Queue
  List<Map<String, dynamic>> _queuePosts = [];
  bool _queueLoading = true;
  String? _queueError;

  // Drafts
  List<Map<String, dynamic>> _draftPosts = [];
  bool _draftsLoading = true;
  String? _draftsError;

  // Published
  List<Map<String, dynamic>> _publishedPosts = [];
  bool _publishedLoading = true;
  String? _publishedError;

  // ── Platform helpers ──────────────────────
  static const _platformColors = {
    'instagram': Color(0xFFE1306C),
    'facebook':  Color(0xFF1877F2),
    'twitter':   Color(0xFF1DA1F2),
    'youtube':   Color(0xFFFF0000),
    'linkedin':  Color(0xFF0A66C2),
    'pinterest': Color(0xFFE60023),
  };
  static const _platformIcons = {
    'instagram': Icons.camera_alt_rounded,
    'facebook':  Icons.facebook_rounded,
    'twitter':   Icons.alternate_email_rounded,
    'youtube':   Icons.play_circle_filled_rounded,
    'linkedin':  Icons.work_rounded,
    'pinterest': Icons.push_pin_rounded,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
        length: 3, vsync: this, initialIndex: widget.initialTab);
    _fetchQueue();
    _fetchDrafts();
    _fetchPublished();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Fetch helpers ─────────────────────────
  Future<void> _fetchQueue() async {
    setState(() { _queueLoading = true; _queueError = null; });
    try {
      final res = await _api.get(AppConstants.queuedPosts);
      final raw = res['data'] ?? res['posts'] ?? res;
      setState(() {
        _queuePosts = raw is List ? raw.cast<Map<String, dynamic>>() : [];
        _queueLoading = false;
      });
    } on NetworkException catch (_) {
      setState(() { _queueError = 'No internet connection.'; _queueLoading = false; });
    } on UnauthorizedException catch (_) {
      setState(() { _queueError = 'Session expired.'; _queueLoading = false; });
    } on NotFoundException catch (_) {
      setState(() { _queuePosts = []; _queueLoading = false; });
    } on AppException catch (e) {
      setState(() { _queueError = e.message; _queueLoading = false; });
    } catch (_) {
      setState(() { _queueError = 'Something went wrong.'; _queueLoading = false; });
    }
  }

  Future<void> _fetchDrafts() async {
    setState(() { _draftsLoading = true; _draftsError = null; });
    try {
      final res = await _api.get(AppConstants.draftPosts);
      final raw = res['data'] ?? res['posts'] ?? res;
      setState(() {
        _draftPosts = raw is List ? raw.cast<Map<String, dynamic>>() : [];
        _draftsLoading = false;
      });
    } on NetworkException catch (_) {
      setState(() { _draftsError = 'No internet connection.'; _draftsLoading = false; });
    } on UnauthorizedException catch (_) {
      setState(() { _draftsError = 'Session expired.'; _draftsLoading = false; });
    } on NotFoundException catch (_) {
      setState(() { _draftPosts = []; _draftsLoading = false; });
    } on AppException catch (e) {
      setState(() { _draftsError = e.message; _draftsLoading = false; });
    } catch (_) {
      setState(() { _draftsError = 'Something went wrong.'; _draftsLoading = false; });
    }
  }

  Future<void> _fetchPublished() async {
    setState(() { _publishedLoading = true; _publishedError = null; });
    try {
      final res = await _api.get(AppConstants.publishedPosts);
      final raw = res['data'] ?? res['posts'] ?? res;
      setState(() {
        _publishedPosts = raw is List ? raw.cast<Map<String, dynamic>>() : [];
        _publishedLoading = false;
      });
    } on NetworkException catch (_) {
      setState(() { _publishedError = 'No internet connection.'; _publishedLoading = false; });
    } on UnauthorizedException catch (_) {
      setState(() { _publishedError = 'Session expired.'; _publishedLoading = false; });
    } on NotFoundException catch (_) {
      setState(() { _publishedPosts = []; _publishedLoading = false; });
    } on AppException catch (e) {
      setState(() { _publishedError = e.message; _publishedLoading = false; });
    } catch (_) {
      setState(() { _publishedError = 'Something went wrong.'; _publishedLoading = false; });
    }
  }

  // ── Delete Draft ─────────────────────────
  Future<void> _deleteDraft(String id) async {
    try {
      await _api.delete('/api/posts/draft/$id');
      _fetchDrafts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Draft delete ho gaya',
              style: GoogleFonts.sora(fontSize: 13)),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ));
      }
    } on NetworkException catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('No internet connection',
              style: GoogleFonts.sora(fontSize: 13)),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Delete failed, dobara try karo',
              style: GoogleFonts.sora(fontSize: 13)),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ));
      }
    }
  }

  // ── Delete Confirm Dialog ─────────────────
  void _showDeleteConfirm(Map<String, dynamic> post) {
    final id = (post['id'] ?? post['_id'] ?? '').toString();
    final preview = (post['content'] as String? ?? '').trim();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                shape: BoxShape.circle),
            child: const Icon(Icons.delete_rounded,
                color: AppColors.error, size: 18),
          ),
          const SizedBox(width: 10),
          Text('Delete Draft?',
              style: GoogleFonts.sora(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
        ]),
        content: Text(
          preview.isNotEmpty
              ? 'Kya aap yeh draft delete karna chahte hain?\n\n"${preview.length > 60 ? '${preview.substring(0, 60)}…' : preview}"'
              : 'Kya aap yeh draft delete karna chahte hain?',
          style: GoogleFonts.sora(
              fontSize: 12, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.sora(
                    fontSize: 13, color: AppColors.textSecondary)),
          ),
          GestureDetector(
            onTap: () {
              Navigator.pop(ctx);
              _deleteDraft(id);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(8)),
              child: Text('Delete',
                  style: GoogleFonts.sora(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white)),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  // ── Open Edit Draft Sheet ─────────────────
  void _openEditDraft(Map<String, dynamic> post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditDraftSheet(
        draft: post,
        onUpdated: _fetchDrafts,
      ),
    );
  }

  // ── Shared list builder ───────────────────
  Widget _buildList({
    required bool loading,
    required String? error,
    required List<Map<String, dynamic>> posts,
    required VoidCallback onRetry,
    required _TabType type,
  }) {
    if (loading) {
      return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, __) => const _PostCardSkeleton(),
      );
    }
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  shape: BoxShape.circle),
              child: const Icon(Icons.error_outline_rounded,
                  color: AppColors.error, size: 28),
            ),
            const SizedBox(height: 16),
            Text(error,
                textAlign: TextAlign.center,
                style: GoogleFonts.sora(
                    fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 10),
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
    if (posts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                  color: type.color.withOpacity(0.1),
                  shape: BoxShape.circle),
              child: Icon(type.icon, color: type.color, size: 30),
            ),
            const SizedBox(height: 16),
            Text(type.emptyTitle,
                style: GoogleFonts.sora(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            Text(type.emptySubtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.sora(
                    fontSize: 12, color: AppColors.textSecondary)),
          ]),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.smmColor,
      backgroundColor: AppColors.surface,
      onRefresh: () async {
        if (type == _TabType.queue) await _fetchQueue();
        if (type == _TabType.drafts) await _fetchDrafts();
        if (type == _TabType.published) await _fetchPublished();
      },
      child: type == _TabType.published
          ? _buildPublishedList(posts)
          : _buildSimpleList(posts, type),
    );
  }

  // ── Queue / Drafts simple list ────────────
  Widget _buildSimpleList(
      List<Map<String, dynamic>> posts, _TabType type) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: posts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final p = posts[i];
        final content = (p['content'] as String? ?? '').trim();
        final rawPlatforms = p['platforms'];
        final platforms = rawPlatforms is List
            ? rawPlatforms.map((e) => e.toString()).toList()
            : <String>[];
        // Extract first media URL
        String? mediaUrl;
        final rawMedia = p['media'];
        if (rawMedia is List && rawMedia.isNotEmpty) {
          final first = rawMedia.first;
          if (first is Map) {
            mediaUrl = first['url']?.toString();
          } else if (first is String) {
            mediaUrl = first;
          }
        }
        final hasMedia = mediaUrl != null && mediaUrl.isNotEmpty;

        DateTime createdAt = DateTime.now();
        try {
          createdAt = DateTime.parse(
              (p['createdAt'] ?? p['created_at'] ?? '').toString());
        } catch (_) {}

        return _SimplePostCard(
          content: content,
          platforms: platforms,
          hasMedia: hasMedia,
          mediaUrl: mediaUrl,
          createdAt: createdAt,
          accentColor: type.color,
          label: type.label,
          platformColors: _platformColors,
          platformIcons: _platformIcons,
          isDraft: type == _TabType.drafts,
          onEdit: type == _TabType.drafts ? () => _openEditDraft(p) : null,
          onDelete: type == _TabType.drafts ? () => _showDeleteConfirm(p) : null,
        );
      },
    );
  }

  // ── Published rich list ───────────────────
  Widget _buildPublishedList(List<Map<String, dynamic>> posts) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: posts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _PublishedPostCard(
        post: posts[i],
        platformColors: _platformColors,
        platformIcons: _platformIcons,
      ),
    );
  }

  // ── Build ─────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: AppColors.textSecondary),
          onPressed: () => Navigator.pop(context),
        ),
        title: ShaderMask(
          shaderCallback: (b) => const LinearGradient(
              colors: [Color(0xFF00D4AA), Color(0xFF6C63FF)])
              .createShader(b),
          child: Text('Posts',
              style: GoogleFonts.sora(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(49),
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12)),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                      gradient: const LinearGradient(colors: [
                        Color(0xFF00D4AA),
                        Color(0xFF6C63FF)
                      ]),
                      borderRadius: BorderRadius.circular(10)),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelStyle: GoogleFonts.sora(
                      fontSize: 11, fontWeight: FontWeight.w600),
                  unselectedLabelStyle:
                  GoogleFonts.sora(fontSize: 11),
                  labelColor: Colors.white,
                  unselectedLabelColor: AppColors.textSecondary,
                  tabs: [
                    Tab(
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.queue_rounded, size: 13),
                            const SizedBox(width: 4),
                            Text('Queue (${_queuePosts.length})'),
                          ]),
                    ),
                    Tab(
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.drafts_rounded, size: 13),
                            const SizedBox(width: 4),
                            Text('Drafts (${_draftPosts.length})'),
                          ]),
                    ),
                    Tab(
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle_outline_rounded,
                                size: 13),
                            const SizedBox(width: 4),
                            Text(
                                'Published (${_publishedPosts.length})'),
                          ]),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Divider(color: AppColors.border, height: 1),
          ]),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildList(
              loading: _queueLoading,
              error: _queueError,
              posts: _queuePosts,
              onRetry: _fetchQueue,
              type: _TabType.queue),
          _buildList(
              loading: _draftsLoading,
              error: _draftsError,
              posts: _draftPosts,
              onRetry: _fetchDrafts,
              type: _TabType.drafts),
          _buildList(
              loading: _publishedLoading,
              error: _publishedError,
              posts: _publishedPosts,
              onRetry: _fetchPublished,
              type: _TabType.published),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// TAB TYPE ENUM
// ─────────────────────────────────────────
enum _TabType { queue, drafts, published }

extension _TabTypeX on _TabType {
  Color get color {
    switch (this) {
      case _TabType.queue:     return const Color(0xFF00D4AA);
      case _TabType.drafts:    return const Color(0xFF6C63FF);
      case _TabType.published: return const Color(0xFF4CAF50);
    }
  }

  IconData get icon {
    switch (this) {
      case _TabType.queue:     return Icons.queue_rounded;
      case _TabType.drafts:    return Icons.drafts_rounded;
      case _TabType.published: return Icons.check_circle_outline_rounded;
    }
  }

  String get label {
    switch (this) {
      case _TabType.queue:     return 'Queued';
      case _TabType.drafts:    return 'Draft';
      case _TabType.published: return 'Published';
    }
  }

  String get emptyTitle {
    switch (this) {
      case _TabType.queue:     return 'Queue is empty';
      case _TabType.drafts:    return 'No drafts yet';
      case _TabType.published: return 'No published posts';
    }
  }

  String get emptySubtitle {
    switch (this) {
      case _TabType.queue:
        return 'Create a post and it will appear here';
      case _TabType.drafts:
        return 'Save a post as draft and it will appear here';
      case _TabType.published:
        return 'Published posts will appear here';
    }
  }
}

// ─────────────────────────────────────────
// SIMPLE POST CARD  (Queue / Drafts)
// ─────────────────────────────────────────
class _SimplePostCard extends StatelessWidget {
  final String content;
  final List<String> platforms;
  final bool hasMedia;
  final String? mediaUrl;
  final DateTime createdAt;
  final Color accentColor;
  final String label;
  final Map<String, Color> platformColors;
  final Map<String, IconData> platformIcons;
  final bool isDraft;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _SimplePostCard({
    required this.content,
    required this.platforms,
    required this.hasMedia,
    this.mediaUrl,
    required this.createdAt,
    required this.accentColor,
    required this.label,
    required this.platformColors,
    required this.platformIcons,
    this.isDraft = false,
    this.onEdit,
    this.onDelete,
  });

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final display = content.isNotEmpty ? content : '(No content)';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Media thumbnail or icon
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: (hasMedia && mediaUrl != null && mediaUrl!.isNotEmpty)
                        ? CachedNetworkImage(
                      imageUrl: mediaUrl!,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        width: 56, height: 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [
                            accentColor,
                            accentColor.withOpacity(0.6),
                          ]),
                        ),
                        child: const Icon(Icons.image_rounded,
                            color: Colors.white, size: 18),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        width: 56, height: 56,
                        color: AppColors.surfaceLight,
                        child: const Icon(Icons.broken_image_rounded,
                            color: AppColors.textMuted, size: 18),
                      ),
                    )
                        : Container(
                      width: 56, height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          accentColor,
                          accentColor.withOpacity(0.6),
                        ]),
                      ),
                      child: const Icon(Icons.text_fields_rounded,
                          color: Colors.white, size: 18),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            display.length > 60
                                ? '${display.substring(0, 60)}…'
                                : display,
                            style: GoogleFonts.sora(
                                fontSize: 12,
                                color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 4),
                          Text(_timeAgo(createdAt),
                              style: GoogleFonts.sora(
                                  fontSize: 10,
                                  color: AppColors.textMuted)),
                        ]),
                  ),
                  // Draft badge + action icons
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6)),
                        child: Text(label,
                            style: GoogleFonts.sora(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: accentColor)),
                      ),
                      if (isDraft) ...[
                        const SizedBox(height: 8),
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          // Edit icon
                          GestureDetector(
                            onTap: onEdit,
                            child: Container(
                              width: 30, height: 30,
                              decoration: BoxDecoration(
                                  color: const Color(0xFF6C63FF).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8)),
                              child: const Icon(Icons.edit_rounded,
                                  color: Color(0xFF6C63FF), size: 15),
                            ),
                          ),
                          const SizedBox(width: 6),
                          // Delete icon
                          GestureDetector(
                            onTap: onDelete,
                            child: Container(
                              width: 30, height: 30,
                              decoration: BoxDecoration(
                                  color: AppColors.error.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8)),
                              child: const Icon(Icons.delete_rounded,
                                  color: AppColors.error, size: 15),
                            ),
                          ),
                        ]),
                      ],
                    ],
                  ),
                ]),
            if (platforms.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 5, runSpacing: 5,
                children: platforms.map((pid) {
                  final col =
                      platformColors[pid] ?? AppColors.textMuted;
                  final ico =
                      platformIcons[pid] ?? Icons.public_rounded;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: col.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6)),
                    child: Row(mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(ico, color: col, size: 11),
                          const SizedBox(width: 4),
                          Text(
                              pid[0].toUpperCase() +
                                  pid.substring(1),
                              style: GoogleFonts.sora(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: col)),
                        ]),
                  );
                }).toList(),
              ),
            ],
          ]),
    );
  }
}

// ─────────────────────────────────────────
// PUBLISHED POST CARD  (rich — from API)
// ─────────────────────────────────────────
class _PublishedPostCard extends StatelessWidget {
  final Map<String, dynamic> post;
  final Map<String, Color> platformColors;
  final Map<String, IconData> platformIcons;

  const _PublishedPostCard({
    required this.post,
    required this.platformColors,
    required this.platformIcons,
  });

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
    // ── Parse fields ───────────────────────
    final content = (post['content'] as String? ?? '').trim();
    final rawPlatforms = post['platforms'];
    final platforms = rawPlatforms is List
        ? rawPlatforms.map((e) => e.toString()).toList()
        : <String>[];

    // media array
    final rawMedia = post['media'];
    final mediaList = rawMedia is List
        ? rawMedia.cast<Map<String, dynamic>>()
        : <Map<String, dynamic>>[];
    final firstImageUrl = mediaList
        .where((m) => m['type'] == 'image')
        .map((m) => m['url']?.toString())
        .where((u) => u != null && u.isNotEmpty)
        .firstOrNull;

    // tags
    final rawTags = post['tags'];
    final tags = rawTags is List
        ? rawTags.map((e) => e.toString()).where((t) => t.isNotEmpty).toList()
        : <String>[];

    // stats
    final likes    = post['likes']    as int? ?? 0;
    final comments = post['comments'] as int? ?? 0;
    final shares   = post['shares']   as int? ?? 0;
    final views    = post['views']    as int? ?? 0;

    // dates
    DateTime publishedAt = DateTime.now();
    try {
      publishedAt = DateTime.parse(
          (post['publishedAt'] ?? post['createdAt'] ?? '').toString())
          .toLocal();
    } catch (_) {}

    // results
    final rawResults = post['results'];
    final results = rawResults is List
        ? rawResults.cast<Map<String, dynamic>>()
        : <Map<String, dynamic>>[];

    final accentColor = platforms.isNotEmpty
        ? (platformColors[platforms.first] ?? AppColors.success)
        : AppColors.success;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image (if any) ─────────────────
            if (firstImageUrl != null)
              ClipRRect(
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(15)),
                child: CachedNetworkImage(
                  imageUrl: firstImageUrl,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    height: 180,
                    color: AppColors.surface,
                    child: const Center(
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.smmColor)),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    height: 180,
                    color: AppColors.surface,
                    child: const Icon(Icons.broken_image_rounded,
                        color: AppColors.textMuted, size: 40),
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header row ───────────────
                    Row(children: [
                      Expanded(
                        child: Text(
                          content.isNotEmpty ? content : '(No content)',
                          style: GoogleFonts.sora(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color:
                                AppColors.success.withOpacity(0.3))),
                        child: Row(mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_circle_rounded,
                                  color: AppColors.success, size: 11),
                              const SizedBox(width: 4),
                              Text('Published',
                                  style: GoogleFonts.sora(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.success)),
                            ]),
                      ),
                    ]),
                    const SizedBox(height: 4),
                    Text(_timeAgo(publishedAt),
                        style: GoogleFonts.sora(
                            fontSize: 11, color: AppColors.textMuted)),

                    // ── Platforms ────────────────
                    if (platforms.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 5, runSpacing: 5,
                        children: platforms.map((pid) {
                          final col =
                              platformColors[pid] ?? AppColors.textMuted;
                          final ico =
                              platformIcons[pid] ?? Icons.public_rounded;
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                                color: col.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6)),
                            child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(ico, color: col, size: 11),
                                  const SizedBox(width: 4),
                                  Text(
                                      pid[0].toUpperCase() +
                                          pid.substring(1),
                                      style: GoogleFonts.sora(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: col)),
                                ]),
                          );
                        }).toList(),
                      ),
                    ],

                    // ── Stats row ────────────────
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 14),
                      decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border:
                          Border.all(color: AppColors.border)),
                      child: Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: [
                            _stat(Icons.favorite_rounded,
                                _formatNum(likes), const Color(0xFFE91E63)),
                            _statDivider(),
                            _stat(Icons.chat_bubble_rounded,
                                _formatNum(comments),
                                const Color(0xFF2196F3)),
                            _statDivider(),
                            _stat(Icons.share_rounded,
                                _formatNum(shares),
                                const Color(0xFF9C27B0)),
                            _statDivider(),
                            _stat(Icons.visibility_rounded,
                                _formatNum(views), AppColors.smmColor),
                          ]),
                    ),

                    // ── Tags ─────────────────────
                    if (tags.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 5, runSpacing: 5,
                        children: tags
                            .map((t) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                              color: AppColors.smmColor
                                  .withOpacity(0.08),
                              borderRadius:
                              BorderRadius.circular(6)),
                          child: Text('#$t',
                              style: GoogleFonts.sora(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.smmColor)),
                        ))
                            .toList(),
                      ),
                    ],

                    // ── Results row ──────────────
                    if (results.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      ...results.map((r) {
                        final platform = r['platform']?.toString() ?? '';
                        final status = r['status']?.toString() ?? '';
                        final isSuccess = status == 'success';
                        final col =
                            platformColors[platform] ?? AppColors.textMuted;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(children: [
                            Icon(
                                platformIcons[platform] ??
                                    Icons.public_rounded,
                                color: col, size: 12),
                            const SizedBox(width: 5),
                            Text(
                                platform.isNotEmpty
                                    ? platform[0].toUpperCase() +
                                    platform.substring(1)
                                    : '',
                                style: GoogleFonts.sora(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: col)),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                  color: isSuccess
                                      ? AppColors.success.withOpacity(0.12)
                                      : AppColors.error.withOpacity(0.12),
                                  borderRadius:
                                  BorderRadius.circular(5)),
                              child: Text(
                                  isSuccess ? '✓ Success' : '✗ Failed',
                                  style: GoogleFonts.sora(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: isSuccess
                                          ? AppColors.success
                                          : AppColors.error)),
                            ),
                          ]),
                        );
                      }),
                    ],
                  ]),
            ),
          ]),
    );
  }

  Widget _stat(IconData icon, String val, Color color) =>
      Column(children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(height: 3),
        Text(val,
            style: GoogleFonts.sora(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
      ]);

  Widget _statDivider() => Container(
      width: 1, height: 28, color: AppColors.border);

  String _formatNum(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}

// ─────────────────────────────────────────
// SKELETON CARD
// ─────────────────────────────────────────
class _PostCardSkeleton extends StatelessWidget {
  const _PostCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              _box(40, 40, radius: 10),
              const SizedBox(width: 10),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _box(double.infinity, 11, radius: 6),
                        const SizedBox(height: 6),
                        _box(80, 9, radius: 6),
                      ])),
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

  Widget _box(double w, double h, {required double radius}) =>
      Container(
        width: w, height: h,
        decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(radius)),
      );
}