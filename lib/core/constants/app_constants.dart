// lib/core/constants/app_constants.dart

class AppConstants {
  // Base URL
  static const String baseUrl =
      'https://smm-backend1-stkn.onrender.com';

  // ── Admin ──────────────────────────────────────────────────────────────
  static const String adminDashboard = '/api/admin/dashboard';
  static const String adminLogin = '/api/agency/login';

  // ── Auth ───────────────────────────────────────────────────────────────
  static const String userLogin = '/api/user/login';
  static const String createUser = '/api/user/create';
  static const String editUser = '/api/user/edit';

  // ── Admin User Management ──────────────────────────────────────────────
  static const String adminClients          = '/api/admin/users/clients';
  static const String adminSmm              = '/api/admin/users/smm';
  static const String adminGraphicDesigners = '/api/admin/users/graphic-designers';
  static const String adminDeleteUser       = '/api/admin/users'; // DELETE /api/admin/users/:id
  static const String adminUserDetail       = '/api/admin/users'; // GET /api/admin/users/:id

  // ── SMM ────────────────────────────────────────────────────────────────
  static const String smmDashboard        = '/api/smm/dashboard';
  static const String createDesignProject = '/api/smm/design-projects';
  static const String createPost          = '/api/posts/create';
  static const String saveDraftPost       = '/api/posts/draft';
  static const String queuedPosts         = '/api/posts/queued';
  static const String draftPosts          = '/api/posts/drafts';
  static const String smmClients          = '/api/smm/clients';
  static const String smmGraphicDesigners = '/api/smm/graphic-designers';
  // ── Client ─────────────────────────────────────────────────────────────
  /// GET  /api/client/design-projects
  static const String clientDesignProjects = '/api/client/design-projects';

  /// GET  /api/client/design-projects/:id
  /// Usage: '${AppConstants.clientDesignProjects}/$id'

  /// PATCH /api/client/design-projects/:id/review  { action, feedback }
  /// Usage: '${AppConstants.clientDesignProjects}/$id/review'

  // ── Graphic Designer ───────────────────────────────────────────────────
  static const String gdProjects    = '/api/gd/projects';            // GET
  static const String gdProjectFiles = '/api/gd/projects';           // POST /api/gd/projects/:id/files
  // Usage: '${AppConstants.gdProjectFiles}/$projectId/files'

  // ── Misc ───────────────────────────────────────────────────────────────
  static const String notifications = '/api/notifications';
  static const String socialAccount =
      "/api/social/accounts";

  static const String socialAuth = "/api/social/auth";
  static const String socialConnect = "/api/social/connect";
  static const String socialDisconnect = "/api/social/disconnect";
  static const String redirectUri =
      "https://smm-backend1-stkn.onrender.com/auth/callback";
  static const String publishedPosts = '/api/posts/published';

  // ── Secure Storage Keys ────────────────────────────────────────────────
  static const String tokenKey       = 'token';
  static const String userRoleKey    = 'user_role';
  static const String accountTypeKey = 'account_type';
  static const String userEmailKey   = 'user_email';
  static const String userNameKey    = 'user_name';
  static const String profileImageKey = 'profile_image';

  // ── Timeouts ───────────────────────────────────────────────────────────
  static const int connectTimeout = 30000;
  static const int receiveTimeout = 30000;
  static const int sendTimeout    = 30000;
}