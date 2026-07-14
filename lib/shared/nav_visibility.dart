import 'package:flutter/foundation.dart';

/// Global notifier that controls bottom nav bar visibility.
/// Set to false when user scrolls up (content scrolling), true when scrolling back down.
final ValueNotifier<bool> navBarVisible = ValueNotifier(true);

/// Registered by the active Home page so a second tap on the selected Home
/// tab can return its preserved scroll view to the top.
VoidCallback? scrollHomeToTop;

/// Bottom nav bar's own content height, excluding the device safe-area
/// inset (add `MediaQuery.paddingOf(context).bottom` separately). Shared
/// so anything positioning itself relative to the nav bar — e.g. the
/// floating ViewCartBar — can't drift out of sync with the nav bar's own
/// layout.
const double kBottomNavBarHeight = 64.0;

/// ViewCartBar pill's own height, and the gap it keeps from whatever is
/// below it (the nav bar while visible, or the screen edge once it slides
/// away). Shared so scrollable content can reserve exactly the right
/// amount of trailing space — see [kScrollBottomClearance].
const double kViewCartBarHeight = 56.0;
const double kViewCartBarGap = 16.0;

/// Bottom padding scrollable content needs so its last item clears the
/// floating ViewCartBar pill. Deliberately does *not* also reserve room
/// for the bottom nav bar — that would keep this tight in the common case
/// (scrolled to the end, nav bar hidden) at the cost of a brief overlap
/// with the last line of content in the rarer case where the nav bar
/// reappears while still scrolled all the way down. Excludes the device
/// safe-area inset — add `MediaQuery.paddingOf(context).bottom` on top.
const double kScrollBottomClearance = kViewCartBarHeight + kViewCartBarGap + 8;
