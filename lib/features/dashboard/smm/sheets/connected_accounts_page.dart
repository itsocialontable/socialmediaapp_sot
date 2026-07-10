import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/social_provider.dart';
import '../../../../core/services/social_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../model/social_platform_model.dart';
import '../../../../shared/widgets/social_platform_card.dart';
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
// A single client block: name + its platform list.
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
    final connectedCount = client.platforms.where((p) => p.connected).length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.smmColor.withOpacity(0.12),
                child: Text(
                  client.name.isNotEmpty ? client.name[0].toUpperCase() : '?',
                  style: GoogleFonts.sora(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.smmColor),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      client.name,
                      style: GoogleFonts.sora(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                    Text(
                      '$connectedCount of ${client.platforms.length} connected',
                      style: GoogleFonts.sora(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...client.platforms.map((platform) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SocialPlatformCard(
              platform: platform,
              loading: isPlatformLoading(platform.platform),
              onActionPressed: () => onTapPlatform(platform),
            ),
          )),
        ],
      ),
    );
  }
}