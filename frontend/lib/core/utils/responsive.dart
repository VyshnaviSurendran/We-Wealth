import 'package:flutter/widgets.dart';

/// Single breakpoint the whole app uses to switch from a compact (phone)
/// layout to a wide (tablet/desktop/web) layout — e.g. bottom nav vs. side
/// rail, single-column vs. multi-column dashboard.
const double wideLayoutBreakpoint = 840.0;

bool isWideScreen(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= wideLayoutBreakpoint;
