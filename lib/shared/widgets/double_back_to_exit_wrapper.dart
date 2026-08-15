import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

/// Wraps the app so a single back-button press never closes the app.
///
/// - If there is a screen to go back to (go_router can pop), it pops normally.
/// - If we're already at the root/home screen, the first back press shows a
///   "Press back again to exit" snackbar with an EXIT action. Tapping EXIT
///   closes the app immediately, or pressing back again within 2 seconds
///   also exits the app.
///
/// NOTE: This widget sits in MaterialApp.router's `builder`, which is OUTSIDE
/// the internal Router widget — so GoRouter.of(context)/BackButtonListener
/// don't work here (no Router ancestor). Instead we use WidgetsBindingObserver's
/// didPopRoute(), which intercepts the Android back button at the engine level
/// regardless of where the widget sits in the tree, and we take the GoRouter
/// instance directly instead of looking it up from context.
class DoubleBackToExitWrapper extends StatefulWidget {
  final Widget child;
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey;
  final GoRouter router;

  const DoubleBackToExitWrapper({
    super.key,
    required this.child,
    required this.scaffoldMessengerKey,
    required this.router,
  });

  @override
  State<DoubleBackToExitWrapper> createState() =>
      _DoubleBackToExitWrapperState();
}

class _DoubleBackToExitWrapperState extends State<DoubleBackToExitWrapper>
    with WidgetsBindingObserver {
  DateTime? _lastBackPressTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Future<bool> didPopRoute() async {
    if (widget.router.canPop()) {
      widget.router.pop();
      return true;
    }

    final now = DateTime.now();
    if (_lastBackPressTime == null ||
        now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
      _lastBackPressTime = now;
      widget.scaffoldMessengerKey.currentState
        ?..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: const Text('Press back again to exit'),
            duration: const Duration(seconds: 2),
            action: SnackBarAction(
              label: 'EXIT',
              textColor: Colors.black,
              onPressed: () {
                SystemNavigator.pop();
              },
            ),
          ),
        );
      return true; //
    }

    SystemNavigator.pop();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}