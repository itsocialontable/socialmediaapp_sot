import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/social_provider.dart';
import '../../../../core/services/social_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../model/social_platform_model.dart';
import '../../../../shared/widgets/common_widgets.dart';
import 'channels/oauth_webview_screen.dart';

// ─────────────────────────────────────────
// CONNECTED ACCOUNTS PAGE
// Lists every client from /api/smm/clients, each with its platform list.
// Tapping a platform under a client kicks off the same OAuth connect /
// disconnect flow as before, scoped to that client's id + key.
// ─────────────────────────────────────────
class ConnectedAccountsPage extends StatefulWidget {
  const ConnectedAccountsPage({super.key});

  @override
  State<ConnectedAccountsPage> createState() => _ConnectedAccountsPageState();
}

class _ConnectedAccountsPageState extends State<ConnectedAccountsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<SocialProvider>().loadClients();
    });
  }

  Future<void> _startConnect(SmmClientModel client, SocialPlatformModel platform) async {
    final navigator = Navigator.of(context);
    final provider = context.read<SocialProvider>();
    final authUrl = await provider.prepareAuthUrl(
      clientId: client.id,
      platform: platform.platform,
      key: client.key,
    );

    if (authUrl == null) {
      _showSnackbar(provider.errorMessage ?? 'Unable to start authentication flow.');
      return;
    }

    final callbackData = await navigator.push<Map<String, String?>>(MaterialPageRoute(
      builder: (_) => OAuthWebviewScreen(
        authUrl: authUrl,
        redirectUrl: AppConstants.redirectUri,
      ),
    ));

    if (!mounted || callbackData == null) {
      return;
    }

    final code = callbackData['code'];
    final state = callbackData['state'];

    if (code == null || state == null) {
      _showSnackbar('Authorization callback did not return required credentials.');
      return;
    }

    final success = await provider.completeSocialConnect(
      clientId: client.id,
      platform: platform.platform,
      code: code,
      state: state,
      key: client.key,
    );

    if (success) {
      _showSnackbar('${platform.name} connected successfully.');
    } else {
      _showSnackbar(provider.errorMessage ?? 'Failed to connect ${platform.name}.');
    }
  }

  Future<void> _disconnect(SmmClientModel client, SocialPlatformModel platform) async {
    final provider = context.read<SocialProvider>();

    if (platform.accountId == null) {
      _showSnackbar('Unable to find the account identifier for ${platform.name}.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Disconnect account'),
          content: Text('Disconnect ${platform.name} for ${client.name}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Disconnect'),
            ),
          ],
        );
      },
    ) ??
        false;

    if (!mounted || !confirmed) return;

    final success = await provider.disconnectAccount(
      clientId: client.id,
      accountId: platform.accountId!,
      platform: platform.platform,
      key: client.key,
    );

    if (success) {
      _showSnackbar('${platform.name} disconnected.');
    } else {
      _showSnackbar(provider.errorMessage ?? 'Failed to disconnect ${platform.name}.');
    }
  }

  void _showSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SocialProvider>();

    final totalConnected = provider.clients
        .fold<int>(0, (sum, c) => sum + c.platforms.where((p) => p.connected).length);

    return Scaffold(
      backgroundColor: AppColors.surface,

      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            color: AppColors.textSecondary,
          ),
          onPressed: () => Navigator.pop(context),
        ),

        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShaderMask(
              shaderCallback: (bounds) =>
                  AppColors.smmGradient.createShader(bounds),
              child: Text(
                'Connected Accounts',
                style: GoogleFonts.sora(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            Text(
              '$totalConnected connected across ${provider.clients.length} clients',
              style: GoogleFonts.sora(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),

        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(
            color: AppColors.border,
            height: 1,
          ),
        ),
      ),

      body: RefreshIndicator(
        onRefresh: provider.loadClients,

        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [

            if (provider.isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(child: CircularProgressIndicator()),
              ),

            if (!provider.isLoading && provider.errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
                    const SizedBox(height: 16),
                    Text(
                      provider.errorMessage!,
                      style: GoogleFonts.sora(fontSize: 13, color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: provider.loadClients,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),

            if (!provider.isLoading && provider.errorMessage == null && provider.clients.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    const Icon(Icons.people_outline_rounded, size: 60, color: AppColors.textMuted),
                    const SizedBox(height: 16),
                    Text(
                      'No clients found.',
                      style: GoogleFonts.sora(fontSize: 13, color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

            if (!provider.isLoading && provider.errorMessage == null)
              ...provider.clients.map((client) => _ClientSection(
                client: client,
                isPlatformLoading: (platform) => provider.isPlatformLoading(client.id, platform),
                onTapPlatform: (platform) {
                  if (platform.connected) {
                    _disconnect(client, platform);
                  } else {
                    _startConnect(client, platform);
                  }
                },
              )),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// A single client block: header + connected-accounts list + platform
// chips to connect more — mirrors the "card per client" reference layout.
// ─────────────────────────────────────────
class _ClientSection extends StatelessWidget {
  final SmmClientModel client;
  final bool Function(String platform) isPlatformLoading;
  final void Function(SocialPlatformModel platform) onTapPlatform;

  const _ClientSection({
    required this.client,
    required this.isPlatformLoading,
    required this.onTapPlatform,
  });

  @override
  Widget build(BuildContext context) {
    final connected = client.platforms.where((p) => p.connected).toList();
    final connectedCount = connected.length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: CommonCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header: avatar, name/email, status badge ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.smmColor.withOpacity(0.15),
                  child: Text(
                    client.name.isNotEmpty ? client.name[0].toUpperCase() : '?',
                    style: GoogleFonts.sora(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.smmColor),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        client.name,
                        style: GoogleFonts.sora(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                      if (client.email != null && client.email!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          client.email!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.sora(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _StatusBadge(connectedCount: connectedCount),
              ],
            ),

            // ── Connected accounts list ──
            if (connectedCount > 0) ...[
              const SizedBox(height: 16),
              Text(
                'CONNECTED ACCOUNTS',
                style: GoogleFonts.sora(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted, letterSpacing: 0.6),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.background.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    for (int i = 0; i < connected.length; i++) ...[
                      _ConnectedAccountRow(
                        platform: connected[i],
                        loading: isPlatformLoading(connected[i].platform),
                        onDisconnect: () => onTapPlatform(connected[i]),
                      ),
                      if (i != connected.length - 1)
                        Container(height: 1, color: AppColors.border.withOpacity(0.5), margin: const EdgeInsets.symmetric(horizontal: 14)),
                    ],
                  ],
                ),
              ),
            ],

            // ── Connect-platform chips (all platforms; connected ones
            // shown checked-off and disabled) ──
            const SizedBox(height: 16),
            Text(
              'CONNECT PLATFORM',
              style: GoogleFonts.sora(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted, letterSpacing: 0.6),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: client.platforms.map((platform) {
                return _PlatformChip(
                  platform: platform,
                  loading: isPlatformLoading(platform.platform),
                  onTap: platform.connected ? null : () => onTapPlatform(platform),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// Top-right status badge: "No channels" (muted) or "N connected" (green).
// ─────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final int connectedCount;
  const _StatusBadge({required this.connectedCount});

  @override
  Widget build(BuildContext context) {
    final bool hasAny = connectedCount > 0;
    final color = hasAny ? AppColors.success : AppColors.textMuted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        hasAny ? '$connectedCount connected' : 'No channels',
        style: GoogleFonts.sora(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

// ─────────────────────────────────────────
// Row for an already-connected platform: icon, name/handle, connected
// check, and a tappable "Disconnect" action (or a spinner while busy).
// ─────────────────────────────────────────
class _ConnectedAccountRow extends StatelessWidget {
  final SocialPlatformModel platform;
  final bool loading;
  final VoidCallback onDisconnect;

  const _ConnectedAccountRow({
    required this.platform,
    required this.loading,
    required this.onDisconnect,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: platform.color.withOpacity(0.15), shape: BoxShape.circle),
            child: Icon(platform.icon, size: 17, color: platform.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  platform.name,
                  style: GoogleFonts.sora(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
                if (platform.connectedAs != null && platform.connectedAs!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    '@${platform.connectedAs}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.sora(fontSize: 11.5, color: AppColors.textSecondary),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (loading)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(AppColors.error)),
            )
          else
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_rounded, size: 14, color: AppColors.success),
                const SizedBox(width: 4),
                Text('Connected', style: GoogleFonts.sora(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.success)),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: onDisconnect,
                  child: Text(
                    'Disconnect',
                    style: GoogleFonts.sora(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.error),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// Small pill chip in the "Connect Platform" row. Unconnected platforms
// are tappable and open the OAuth flow; connected ones render checked-off
// and disabled, since they're already listed above.
// ─────────────────────────────────────────
class _PlatformChip extends StatelessWidget {
  final SocialPlatformModel platform;
  final bool loading;
  final VoidCallback? onTap;

  const _PlatformChip({
    required this.platform,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDone = platform.connected;

    return Opacity(
      opacity: isDone ? 0.5 : 1,
      child: GestureDetector(
        onTap: loading ? null : onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: isDone ? AppColors.surfaceLight : platform.color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDone ? AppColors.border : platform.color.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (loading)
                SizedBox(
                  width: 13,
                  height: 13,
                  child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(platform.color)),
                )
              else
                Icon(isDone ? Icons.check_rounded : platform.icon, size: 15, color: isDone ? AppColors.textMuted : platform.color),
              const SizedBox(width: 6),
              Text(
                platform.name,
                style: GoogleFonts.sora(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: isDone ? AppColors.textMuted : platform.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}