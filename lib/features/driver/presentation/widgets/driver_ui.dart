import 'package:flutter/material.dart';
import 'package:m_o_b_demand_side/shared/widgets/skeleton_shimmer.dart';

/// The driver app's palette — MOB's brand: navy #001533 and blue #0454A3,
/// with the logo's green dots as the accent. Green otherwise means done /
/// pickup, red drop / problem, orange attention.
abstract final class DriverColors {
  static const ink = Color(0xFF0B1B33);
  static const navy = Color(0xFF001533);
  static const blue = Color(0xFF0454A3);
  static const blueBright = Color(0xFF2F7FD6);
  static const blueSoft = Color(0xFFE8F1FB);
  static const mint = Color(0xFF00DE9D);
  static const green = Color(0xFF12A15E);
  static const muted = Color(0xFF6A778A);
  static const surface = Color(0xFFF4F6FB);
  static const orange = Color(0xFFD9820F);
  static const red = Color(0xFFE0444F);
  static const line = Color(0xFFE6EAF0);

  /// The navy → blue sweep behind headers and hero cards.
  static const brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [navy, Color(0xFF02336E), blue],
    stops: [0, .55, 1],
  );
}

class DriverCard extends StatelessWidget {
  const DriverCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  static final _decoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: const Color(0xFFEDF0F5)),
    boxShadow: const [
      BoxShadow(color: Color(0x0A001533), blurRadius: 22, offset: Offset(0, 8)),
      BoxShadow(color: Color(0x05001533), blurRadius: 3, offset: Offset(0, 1)),
    ],
  );

  @override
  Widget build(BuildContext context) {
    if (onTap == null) {
      return Container(padding: padding, decoration: _decoration, child: child);
    }
    // Ink (not a decorated Container) so the tap ripple paints *above* the
    // white card instead of being hidden beneath it.
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: _decoration,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.trailing});
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(
          child: Text(title,
              style: const TextStyle(
                  color: DriverColors.ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w800)),
        ),
        if (trailing != null) trailing!,
      ]);
}

/// Presses in slightly while a finger is down, so a tap answers instantly —
/// before any network round-trip — the way native controls do. Listens to raw
/// pointers, so it never competes with the button's own tap handling.
class PressScale extends StatefulWidget {
  const PressScale({super.key, required this.child, this.enabled = true});

  final Widget child;
  final bool enabled;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _down = false;

  void _set(bool value) {
    if (widget.enabled && _down != value) setState(() => _down = value);
  }

  @override
  Widget build(BuildContext context) => Listener(
        onPointerDown: (_) => _set(true),
        onPointerUp: (_) => _set(false),
        onPointerCancel: (_) => _set(false),
        child: AnimatedScale(
          scale: _down ? 0.97 : 1,
          duration: const Duration(milliseconds: 90),
          curve: Curves.easeOut,
          child: widget.child,
        ),
      );
}

/// Fades a section in while sliding it up a few pixels — once, when it first
/// appears. Staggering [delay] across a screen's sections makes it settle into
/// place rather than pop in. Holds still under the OS "reduce motion" setting.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 380),
    this.offset = 14,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final double offset;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final Duration _total = widget.delay + widget.duration;
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: _total);
  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    // The delay is just the leading part of one controller run — no timers.
    curve: Interval(
      _total.inMicroseconds == 0
          ? 0
          : widget.delay.inMicroseconds / _total.inMicroseconds,
      1,
      curve: Curves.easeOutCubic,
    ),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else if (_controller.status == AnimationStatus.dismissed) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _curve,
        child: widget.child,
        builder: (context, child) => Opacity(
          opacity: _curve.value,
          child: Transform.translate(
            offset: Offset(0, (1 - _curve.value) * widget.offset),
            child: child,
          ),
        ),
      );
}

/// A screen-sized placeholder: a header-less stack of card-shaped blocks.
class DriverListSkeleton extends StatelessWidget {
  const DriverListSkeleton(
      {super.key, this.itemCount = 4, this.itemHeight = 96});

  final int itemCount;
  final double itemHeight;

  @override
  Widget build(BuildContext context) => SkeletonShimmer(
        child: ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
          itemCount: itemCount,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, __) => SkeletonBlock(height: itemHeight, radius: 18),
        ),
      );
}

/// Card-shaped placeholders that lay out in place (no scrolling of their own),
/// for the loading state of a list that lives inside a bigger scrolling page.
class DriverListSkeletonInline extends StatelessWidget {
  const DriverListSkeletonInline(
      {super.key, this.itemCount = 3, this.itemHeight = 64});

  final int itemCount;
  final double itemHeight;

  @override
  Widget build(BuildContext context) => SkeletonShimmer(
        child: Column(children: [
          for (var i = 0; i < itemCount; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            SkeletonBlock(height: itemHeight, radius: 16),
          ],
        ]),
      );
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.color = DriverColors.blue,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    // The brand button gets a soft blue-to-navy sheen and a glow; any other
    // colour (green "Done", red "End duty"…) stays flat in that colour.
    final brand = color == DriverColors.blue;
    return PressScale(
      enabled: enabled,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: onPressed == null && !loading ? .5 : 1,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            gradient: brand
                ? const LinearGradient(colors: [DriverColors.blueBright, DriverColors.blue, Color(0xFF033E7C)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight)
                : null,
            color: brand ? null : color,
            boxShadow: [
              if (enabled)
                BoxShadow(color: color.withValues(alpha: .28), blurRadius: 16, offset: const Offset(0, 6)),
            ],
          ),
          child: SizedBox(
            height: 52,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: loading ? null : onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.transparent,
                disabledForegroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                textStyle: const TextStyle(
                    fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 15.5, letterSpacing: .1),
              ),
              child: loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                  : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      if (icon != null) ...[
                        Icon(icon, size: 19),
                        const SizedBox(width: 8),
                      ],
                      Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
                    ]),
            ),
          ),
        ),
      ),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color = DriverColors.ink,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color color;

  @override
  Widget build(BuildContext context) => PressScale(
        enabled: onPressed != null,
        child: SizedBox(
          height: 46,
          child: OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: color,
              side: BorderSide(color: color.withValues(alpha: .25)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13)),
              textStyle:
                  const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 14),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              if (icon != null) ...[
                Icon(icon, size: 18),
                const SizedBox(width: 7)
              ],
              Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
            ]),
          ),
        ),
      );
}

class StatusPill extends StatelessWidget {
  const StatusPill(this.label, {super.key, required this.color, this.icon});
  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
          ],
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 11, fontWeight: FontWeight.w800)),
        ]),
      );
}

class InfoBanner extends StatelessWidget {
  const InfoBanner({
    super.key,
    required this.text,
    this.icon = Icons.info_outline_rounded,
    this.color = DriverColors.orange,
    this.action,
    this.solid = false,
  });

  final String text;
  final IconData icon;
  final Color color;
  final Widget? action;

  /// Paint the tint over white, for banners that sit on a dark header.
  final bool solid;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: solid ? Color.alphaBlend(color.withValues(alpha: .1), Colors.white) : color.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: color, size: 19),
          const SizedBox(width: 9),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    color: color,
                    fontSize: 12,
                    height: 1.4,
                    fontWeight: FontWeight.w600)),
          ),
          if (action != null) action!,
        ]),
      );
}

class DriverAvatar extends StatelessWidget {
  const DriverAvatar(this.name, {super.key, this.size = 44, this.photoUrl});
  final String name;
  final double size;

  /// The driver's own photo, when they've added one; the initial otherwise (and
  /// if the picture can't be loaded).
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final trimmed = name.trim();
    final radius = BorderRadius.circular(size * .32);
    final initial = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration:
          BoxDecoration(color: DriverColors.blueSoft, borderRadius: radius),
      child: Text(trimmed.isEmpty ? 'D' : trimmed.substring(0, 1).toUpperCase(),
          style: TextStyle(
              color: DriverColors.blue,
              fontSize: size * .4,
              fontWeight: FontWeight.w800)),
    );
    final url = photoUrl;
    if (url == null || url.isEmpty) return initial;
    return ClipRRect(
      borderRadius: radius,
      child: Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => initial,
      ),
    );
  }
}

class CenteredMessage extends StatelessWidget {
  const CenteredMessage({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 42, color: DriverColors.muted),
            const SizedBox(height: 12),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: DriverColors.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w800)),
            if (message != null) ...[
              const SizedBox(height: 6),
              Text(message!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: DriverColors.muted, fontSize: 13, height: 1.4)),
            ],
            if (actionLabel != null) ...[
              const SizedBox(height: 16),
              SizedBox(
                  width: 180,
                  child:
                      PrimaryButton(label: actionLabel!, onPressed: onAction)),
            ],
          ]),
        ),
      );
}

/// One `label ...... value` line.
class InfoRow extends StatelessWidget {
  const InfoRow(this.label, this.value,
      {super.key, this.valueColor, this.bold = false});
  final String label;
  final String value;
  final Color? valueColor;
  final bool bold;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: const TextStyle(color: DriverColors.muted, fontSize: 13)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(value,
                textAlign: TextAlign.right,
                style: TextStyle(
                    color: valueColor ?? DriverColors.ink,
                    fontSize: 13,
                    fontWeight: bold ? FontWeight.w800 : FontWeight.w600)),
          ),
        ]),
      );
}
