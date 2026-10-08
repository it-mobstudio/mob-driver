import 'package:flutter/material.dart';

/// Cross-fades from the splash into the app once startup work is done, rather
/// than cutting between them.
///
/// This sits ABOVE both `MaterialApp`s (the splash is one, the real app is the
/// other), so there is no `Directionality` — or anything else inherited — in
/// scope. Anything here that resolves text direction (a `Stack` left on its
/// default `AlignmentDirectional` alignment, for one) throws
/// "No Directionality widget found" on every frame.
class SplashCrossFade extends StatelessWidget {
  const SplashCrossFade({
    super.key,
    required this.ready,
    required this.splash,
    required this.app,
  });

  final bool ready;
  final Widget splash;
  final Widget app;

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        layoutBuilder: (current, previous) => Stack(
          // Deliberately NOT the default (AlignmentDirectional.topStart).
          alignment: Alignment.topLeft,
          fit: StackFit.expand,
          children: [...previous, if (current != null) current],
        ),
        child: ready
            ? KeyedSubtree(key: const ValueKey('app'), child: app)
            : KeyedSubtree(key: const ValueKey('splash'), child: splash),
      );
}
