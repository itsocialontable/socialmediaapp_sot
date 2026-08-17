// lib/model/posts_analytics_overview_model.dart
//
// Models for GET /api/posts/overviewAnalytics
// Used by: SMM / Admin "Posts Overview + Analytics" screen.
// Query param: clientId (optional) — scope to one client.

class PostsOverviewAnalytics {
  final ClientRef? client;
  final PostsOverviewCounts posts;
  final PostsAnalyticsSummary analytics;

  const PostsOverviewAnalytics({
    required this.client,
    required this.posts,
    required this.analytics,
  });

  factory PostsOverviewAnalytics.fromJson(Map<String, dynamic> json) {
    final rawClient = json['client'];
    return PostsOverviewAnalytics(
      client: (rawClient is Map<String, dynamic>)
          ? ClientRef.fromJson(rawClient)
          : null,
      posts: PostsOverviewCounts.fromJson(
        (json['posts'] as Map<String, dynamic>?) ?? const {},
      ),
      analytics: PostsAnalyticsSummary.fromJson(
        (json['analytics'] as Map<String, dynamic>?) ?? const {},
      ),
    );
  }

  /// Empty/zeroed state — handy as a default before the first successful
  /// fetch, or to fall back to on error without crashing the UI.
  factory PostsOverviewAnalytics.empty() => PostsOverviewAnalytics(
        client: null,
        posts: PostsOverviewCounts.empty(),
        analytics: PostsAnalyticsSummary.empty(),
      );
}

/// Minimal client reference echoed back by the API when `clientId` is passed.
/// Kept loose (all nullable) since the backend may only send an id/name.
class ClientRef {
  final String? id;
  final String? name;

  const ClientRef({this.id, this.name});

  factory ClientRef.fromJson(Map<String, dynamic> json) => ClientRef(
        id: (json['_id'] ?? json['id'])?.toString(),
        name: (json['name'] ?? json['clientName'] ?? json['businessName'])
            ?.toString(),
      );
}

class PostsOverviewCounts {
  final int totalPosts;
  final int draftPosts;
  final int queuedPosts;
  final int scheduledPosts;
  final int publishedPosts;

  const PostsOverviewCounts({
    required this.totalPosts,
    required this.draftPosts,
    required this.queuedPosts,
    required this.scheduledPosts,
    required this.publishedPosts,
  });

  factory PostsOverviewCounts.fromJson(Map<String, dynamic> json) {
    return PostsOverviewCounts(
      totalPosts: _toInt(json['totalPosts']),
      draftPosts: _toInt(json['draftPosts']),
      queuedPosts: _toInt(json['queuedPosts']),
      scheduledPosts: _toInt(json['scheduledPosts']),
      publishedPosts: _toInt(json['publishedPosts']),
    );
  }

  factory PostsOverviewCounts.empty() => const PostsOverviewCounts(
        totalPosts: 0,
        draftPosts: 0,
        queuedPosts: 0,
        scheduledPosts: 0,
        publishedPosts: 0,
      );
}

class PostsAnalyticsSummary {
  final int totalLikes;
  final int totalComments;
  final int totalShares;
  final int totalViews;
  final int totalReach;
  final int totalImpressions;
  final int totalEngagement;
  final int totalProfileViews;
  final List<PlatformAnalytics> byPlatform;
  final List<PlatformProfileViews> profileViewsByPlatform;

  const PostsAnalyticsSummary({
    required this.totalLikes,
    required this.totalComments,
    required this.totalShares,
    required this.totalViews,
    required this.totalReach,
    required this.totalImpressions,
    required this.totalEngagement,
    required this.totalProfileViews,
    required this.byPlatform,
    required this.profileViewsByPlatform,
  });

  factory PostsAnalyticsSummary.fromJson(Map<String, dynamic> json) {
    final rawByPlatform = json['byPlatform'];
    final rawProfileViews = json['profileViewsByPlatform'];

    return PostsAnalyticsSummary(
      totalLikes: _toInt(json['totalLikes']),
      totalComments: _toInt(json['totalComments']),
      totalShares: _toInt(json['totalShares']),
      totalViews: _toInt(json['totalViews']),
      totalReach: _toInt(json['totalReach']),
      totalImpressions: _toInt(json['totalImpressions']),
      totalEngagement: _toInt(json['totalEngagement']),
      totalProfileViews: _toInt(json['totalProfileViews']),
      byPlatform: (rawByPlatform is List)
          ? rawByPlatform
              .whereType<Map<String, dynamic>>()
              .map(PlatformAnalytics.fromJson)
              .toList()
          : const [],
      profileViewsByPlatform: (rawProfileViews is List)
          ? rawProfileViews
              .whereType<Map<String, dynamic>>()
              .map(PlatformProfileViews.fromJson)
              .toList()
          : const [],
    );
  }

  factory PostsAnalyticsSummary.empty() => const PostsAnalyticsSummary(
        totalLikes: 0,
        totalComments: 0,
        totalShares: 0,
        totalViews: 0,
        totalReach: 0,
        totalImpressions: 0,
        totalEngagement: 0,
        totalProfileViews: 0,
        byPlatform: [],
        profileViewsByPlatform: [],
      );
}

class PlatformAnalytics {
  final String platform;
  final int likes;
  final int comments;
  final int shares;
  final int views;
  final int reach;
  final int impressions;
  final int posts;

  const PlatformAnalytics({
    required this.platform,
    required this.likes,
    required this.comments,
    required this.shares,
    required this.views,
    required this.reach,
    required this.impressions,
    required this.posts,
  });

  factory PlatformAnalytics.fromJson(Map<String, dynamic> json) {
    return PlatformAnalytics(
      platform: json['platform']?.toString() ?? '',
      likes: _toInt(json['likes']),
      comments: _toInt(json['comments']),
      shares: _toInt(json['shares']),
      views: _toInt(json['views']),
      reach: _toInt(json['reach']),
      impressions: _toInt(json['impressions']),
      posts: _toInt(json['posts']),
    );
  }
}

class PlatformProfileViews {
  final String platform;
  final int profileViews;
  final int reach;

  const PlatformProfileViews({
    required this.platform,
    required this.profileViews,
    required this.reach,
  });

  factory PlatformProfileViews.fromJson(Map<String, dynamic> json) {
    return PlatformProfileViews(
      platform: json['platform']?.toString() ?? '',
      profileViews: _toInt(json['profileViews']),
      reach: _toInt(json['reach']),
    );
  }
}

/// Safe int coercion — API may send ints, doubles, numeric strings, or null.
int _toInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is double) return value.round();
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}
