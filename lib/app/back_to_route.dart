import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Sends the system back gesture/button (Android) to [route] instead of
/// leaving the app — for screens whose way back isn't the previous page
/// (e.g. tabs opened from the profile menu go back to the profile).
class BackToRoute extends StatelessWidget {
  const BackToRoute({super.key, required this.route, required this.child});

  final String route;
  final Widget child;

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) context.go(route);
        },
        child: child,
      );
}
