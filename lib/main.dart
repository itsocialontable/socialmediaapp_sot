import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:smm_app/shared/widgets/update_dialog.dart';
import 'package:smm_app/shared/widgets/double_back_to_exit_wrapper.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/client_calendar_provider.dart';
import 'core/providers/client_design_project_provider.dart';
import 'core/providers/gd_project_provider.dart';
import 'core/providers/social_provider.dart';
import 'core/providers/smm_design_project_provider.dart';
import 'core/providers/posts_analytics_provider.dart';
import 'core/router/app_router.dart';
import 'core/services/oauth_deep_link_service.dart';
import 'core/services/update_service.dart';
import 'core/theme/app_theme.dart';
import 'features/dashboard/smm/smm_dashboard_screen.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Listens for the smmapp://oauth-callback deep link that the browser
  // sends back after a Google (or other platform) OAuth sign-in.
  OAuthDeepLinkService.instance.init();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0A0E1A),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const MyApp());

  // Handles the case where Android killed the app process while the user
  // was signing in with Google/etc. (common on the FIRST connect attempt,
  // since the consent screen has extra steps). The deep link then cold-
  // starts the app instead of resuming it, so the in-memory OAuth state
  // from before is gone. OAuthDeepLinkService persisted the callback to
  // disk in that case — pick it up here and finish the connect.
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    final ctx = rootNavigatorKey.currentContext;
    if (ctx == null) return;
    final social = Provider.of<SocialProvider>(ctx, listen: false);
    final resumed = await social.resumePendingConnectIfAny();
    if (resumed) {
      rootScaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('Account connected successfully.')),
      );
    }
  });

  // App render hone ke baad update check — Navigator ready hoga tab tak
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    await Future.delayed(const Duration(seconds: 4));
    final info = await UpdateService.checkForUpdate();
    if (info == null) return;
    final ctx = rootNavigatorKey.currentContext;
    if (ctx == null) return;
    showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => UpdateDialog(info: info),
    );
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PostsProvider()),
        ChangeNotifierProvider(create: (_) => GdProjectProvider()),
        ChangeNotifierProvider(create: (_) => SocialProvider()),
        ChangeNotifierProvider(create: (_) => ClientDesignProjectProvider()),
        ChangeNotifierProvider(create: (_) => ClientCalendarProvider()),
        ChangeNotifierProvider(create: (_) => SmmDesignProjectProvider()),
        ChangeNotifierProvider(create: (_) => PostsAnalyticsProvider()),
      ],
      child: Builder(
        builder: (context) {
          final router = AppRouter.createRouter(context);
          return MaterialApp.router(
            title: 'SOT SMM',
            scaffoldMessengerKey: rootScaffoldMessengerKey,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.darkTheme,
            routerConfig: router,
            builder: (context, child) {
              if (child == null) return const SizedBox.shrink();
              return DoubleBackToExitWrapper(
                scaffoldMessengerKey: rootScaffoldMessengerKey,
                router: router,
                child: child,
              );
            },
          );
        },
      ),
    );
  }
}