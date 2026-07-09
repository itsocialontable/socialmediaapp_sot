import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/social_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../model/social_platform_model.dart';
import '../../../../shared/widgets/social_platform_card.dart';
import 'channels/oauth_webview_screen.dart';

// ─────────────────────────────────────────
// ACCOUNT INFO MODEL
// ─────────────────────────────────────────
class AccountInfo {
  final String id, name, subtitle;
  final Color color;
  final IconData icon;
  const AccountInfo(this.id, this.name, this.color, this.icon, this.subtitle);
}

// ─────────────────────────────────────────
// CONNECTED ACCOUNTS PAGE
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
      context.read<SocialProvider>().loadPlatforms();
    });
  }

  Future<void> _startConnect(SocialPlatformModel platform) async {
    final navigator = Navigator.of(context);
    final provider = context.read<SocialProvider>();
    final authUrl = await provider.prepareAuthUrl(platform.platform);

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
      platform: platform.platform,
      code: code,
      state: state,
    );

    if (success) {
      _showSnackbar('${platform.name} connected successfully.');
    } else {
      _showSnackbar(provider.errorMessage ?? 'Failed to connect ${platform.name}.');
    }
  }

  Future<void> _disconnect(SocialPlatformModel platform) async {
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
          content: Text('Disconnect ${platform.name}?'),
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
      accountId: platform.accountId!,
      platform: platform.platform,
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

    final connectedCount = provider.platforms
        .where((e) => e.connected)
        .length;

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

            /// TITLE
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

            /// SUBTITLE
            Text(
              '$connectedCount of ${provider.platforms.length} connected',
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
        onRefresh: provider.loadPlatforms,

        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [

            if (provider.isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),

            if (!provider.isLoading &&
                provider.errorMessage != null)
              Padding(
                padding:
                const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [

                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red.shade400,
                    ),

                    const SizedBox(height: 16),

                    Text(
                      provider.errorMessage!,
                      style: GoogleFonts.sora(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 20),

                    ElevatedButton(
                      onPressed: provider.loadPlatforms,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),

            if (!provider.isLoading &&
                provider.errorMessage == null &&
                provider.platforms.isEmpty)
              Padding(
                padding:
                const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [

                    const Icon(
                      Icons.link_off,
                      size: 60,
                      color: AppColors.textMuted,
                    ),

                    const SizedBox(height: 16),

                    Text(
                      'No social channels available.',
                      style: GoogleFonts.sora(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

            if (!provider.isLoading &&
                provider.errorMessage == null)
              ...provider.platforms.map(
                    (platform) {
                  return Padding(
                    padding:
                    const EdgeInsets.only(bottom: 10),

                    child: SocialPlatformCard(
                      platform: platform,

                      loading:
                      provider.isPlatformLoading(
                        platform.platform,
                      ),

                      onActionPressed: () {
                        if (platform.connected) {
                          _disconnect(platform);
                        } else {
                          _startConnect(platform);
                        }
                      },
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
