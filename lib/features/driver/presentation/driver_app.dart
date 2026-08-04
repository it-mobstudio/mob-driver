/// Backwards-compatible driver presentation entry point.
///
/// New code should import `presentation/pages/pages.dart`. Keeping this export
/// avoids coupling the router and existing consumers to the physical page
/// layout while the driver feature follows the same structure as other
/// features in the application.
export 'pages/driver_app.dart';
