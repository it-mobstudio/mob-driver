import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mob_driver/core/theme/app_colors.dart';

/// The app's [ThemeData]. Screens style themselves with [AppColors] and the
/// shared widgets; this sets the defaults underneath them.
abstract final class AppTheme {
  static const fontFamily = 'Inter';

  /// The theme for [palette] (light or dark).
  static ThemeData of(AppPalette palette) => ThemeData(
        brightness: palette.brightness,
        fontFamily: fontFamily,
        useMaterial3: false,
        primaryColor: palette.button,
        scaffoldBackgroundColor: palette.surface,
        canvasColor: palette.card,
        cardColor: palette.card,
        dividerColor: palette.line,
        colorScheme: ColorScheme.fromSeed(
          seedColor: palette.button,
          brightness: palette.brightness,
          primary: palette.button,
          surface: palette.card,
          onSurface: palette.ink,
          error: palette.red,
        ),
        textTheme: Typography.material2018().black.apply(
              fontFamily: fontFamily,
              bodyColor: palette.ink,
              displayColor: palette.ink,
            ),
        iconTheme: IconThemeData(color: palette.ink),
        appBarTheme: AppBarTheme(
          backgroundColor: palette.card,
          foregroundColor: palette.ink,
          elevation: 0,
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: palette.card,
          titleTextStyle: TextStyle(
              fontFamily: fontFamily,
              color: palette.ink,
              fontSize: 19,
              fontWeight: FontWeight.w800),
          contentTextStyle: TextStyle(
              fontFamily: fontFamily,
              color: palette.muted,
              fontSize: 14.5,
              height: 1.4),
        ),
        bottomSheetTheme: BottomSheetThemeData(
          backgroundColor: palette.card,
          modalBarrierColor: const Color(0x99000000),
        ),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            // The stock Cupertino builder is the one that provides the iOS
            // left-edge swipe-to-go-back gesture; a custom one would drop it.
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.android: _FadeSlidePageTransition(),
          },
        ),
      );

  /// Wraps every screen: keeps text scaling within what the dense driver
  /// screens can lay out, and on tablets/web shows the app in a phone-width
  /// column instead of stretching it.
  static Widget viewport(BuildContext context, Widget? child) {
    if (child == null) return const SizedBox.shrink();
    final scaled = MediaQuery.withClampedTextScaling(
      minScaleFactor: 0.9,
      maxScaleFactor: 1.2,
      child: child,
    );
    if (!kIsWeb && MediaQuery.sizeOf(context).width <= _maxPhoneWidth) {
      return scaled;
    }
    return ColoredBox(
      color: kIsWeb ? const Color(0xFF1A1A2E) : AppColors.surface,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _phoneColumnWidth),
          child: ClipRect(child: scaled),
        ),
      ),
    );
  }

  static const _maxPhoneWidth = 480.0;
  static const _phoneColumnWidth = 430.0;
}

/// Android page transition: the new page fades in while sliding a little
/// from the right.
class _FadeSlidePageTransition extends PageTransitionsBuilder {
  const _FadeSlidePageTransition();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final slide =
        CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
    final fade = CurvedAnimation(
      parent: animation,
      curve: const Interval(0, .8, curve: Curves.easeOut),
    );
    return FadeTransition(
      opacity: fade,
      child: SlideTransition(
        position:
            Tween(begin: const Offset(.08, 0), end: Offset.zero).animate(slide),
        child: child,
      ),
    );
  }
}
