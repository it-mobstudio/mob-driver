import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:m_o_b_demand_side/core/app_runtime/push_notification_service.dart';
import 'package:m_o_b_demand_side/core/location/location_permission_helper.dart';
import 'package:m_o_b_demand_side/core/di/injection.dart';
import 'package:m_o_b_demand_side/core/auth/auth_session.dart';
import 'package:m_o_b_demand_side/core/config/app_config.dart';
import 'package:m_o_b_demand_side/features/driver/data/datasources/driver_remote_datasource.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:m_o_b_demand_side/shared/pull_to_refresh.dart';
import 'package:m_o_b_demand_side/shared/nav_visibility.dart';
import 'package:m_o_b_demand_side/shared/widgets/top_snack_bar.dart';

const _ink = Color(0xFF102A43);
const _blue = Color(0xFF176BFF);
const _green = Color(0xFF16A36A);
const _muted = Color(0xFF66788A);
const _surface = Color(0xFFF4F7FB);

class DriverDashboardPage extends StatefulWidget {
  const DriverDashboardPage({super.key});
  static const routeName = 'DriverDashboard';
  static const routePath = '/driver';

  @override
  State<DriverDashboardPage> createState() => _DriverDashboardPageState();
}

class _DriverDashboardPageState extends State<DriverDashboardPage> {
  bool online = false;
  bool paused = false;
  bool changingDuty = false;
  Map<String, dynamic>? dashboardData;
  bool dashboardLoading = true;
  String? dashboardError;

  @override
  void initState() {
    super.initState();
    refreshDriverDashboard = _refreshFromNavigation;
    _loadDashboard();
  }

  @override
  void dispose() {
    if (refreshDriverDashboard == _refreshFromNavigation) {
      refreshDriverDashboard = null;
    }
    super.dispose();
  }

  void _refreshFromNavigation() {
    if (!mounted) return;
    _refreshDashboard(showMessage: false);
  }

  Future<void> _refreshDashboard({required bool showMessage}) async {
    final success = await _loadDashboard();
    if (!mounted || !showMessage) return;
    TopSnackBar.show(context,
        message: success
            ? 'Dashboard updated successfully'
            : 'Could not refresh dashboard. Please try again.',
        type: success ? TopSnackBarType.success : TopSnackBarType.error);
  }

  Future<bool> _loadDashboard() async {
    try {
      final data = await sl<DriverRemoteDatasource>().dashboard();
      if (!mounted) return false;
      final tracking = data['live_tracking'] is Map
          ? Map<String, dynamic>.from(data['live_tracking'] as Map)
          : <String, dynamic>{};
      setState(() {
        dashboardData = data;
        online = tracking['enabled'] == true;
        dashboardLoading = false;
        dashboardError = null;
      });
      return true;
    } catch (_) {
      if (!mounted) return false;
      setState(() {
        dashboardLoading = false;
        dashboardError = 'Unable to load driver dashboard';
      });
      return false;
    }
  }

  Future<void> _changeDuty(bool goOnline) async {
    if (changingDuty) return;
    if (!goOnline) {
      try {
        await sl<DriverRemoteDatasource>().toggleTracking(false);
      } catch (_) {
        if (mounted) _toast(context, 'Unable to stop tracking. Try again.');
        return;
      }
      setState(() {
        online = false;
        paused = false;
      });
      await PushNotificationService.instance.hideOngoingTrip();
      return;
    }

    final proceed = await showAdaptiveDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog.adaptive(
        title: const Text('Start duty and live tracking?'),
        content: const Text(
          'MOB Driver uses your location during duty to show your vehicle to operations, calculate kilometres and detect route or stationary issues. You can pause tracking during breaks.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Not now')),
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Continue')),
        ],
      ),
    );
    if (proceed != true || !mounted) return;

    setState(() => changingDuty = true);
    final locationAllowed = await ensureLocationPermission(context);
    if (!mounted) return;
    if (!locationAllowed) {
      setState(() => changingDuty = false);
      return;
    }
    await PushNotificationService.instance.requestNotificationPermission();
    if (!mounted) return;
    try {
      await sl<DriverRemoteDatasource>().toggleTracking(true);
    } catch (_) {
      if (mounted) {
        setState(() => changingDuty = false);
        _toast(context, 'Unable to start tracking. Try again.');
      }
      return;
    }
    setState(() {
      online = true;
      changingDuty = false;
    });
    await PushNotificationService.instance.showOngoingTrip(
        tripId: _activeTripData?['trip_id']?.toString() ?? 'Active trip',
        destination: _activeDropName,
        eta: '24 min');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      body: SafeArea(
        bottom: false,
        child: PullToRefresh(
          playSound: true,
          showSpinner: true,
          spinnerTopOffset: 18,
          onRefresh: () => _refreshDashboard(showMessage: true),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _header()),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 110),
                sliver: SliverList.list(children: [
                  _trackingCard(),
                  const SizedBox(height: 16),
                  if (dashboardLoading)
                    const _DashboardLoadingCard()
                  else if (dashboardData == null)
                    _DashboardErrorCard(
                        message: dashboardError ?? 'Dashboard unavailable',
                        onRetry: () {
                          setState(() => dashboardLoading = true);
                          _loadDashboard();
                        })
                  else ...[
                    _TodayProgressCard(
                        progress: dashboardData?['today_progress'] is Map
                            ? Map<String, dynamic>.from(
                                dashboardData!['today_progress'] as Map)
                            : const {},
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                                builder: (_) => const DriverReportPage()))),
                    const SizedBox(height: 16),
                    _activeTrip(),
                    const SizedBox(height: 16),
                    const _AlertCard(),
                    const SizedBox(height: 16),
                    _quickActions(context),
                  ],
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() => Container(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
                color: Color(0x12000000), blurRadius: 16, offset: Offset(0, 5))
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            _driverAvatar(),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(
                      dashboardData?['greeting']?.toString() ?? 'Welcome back,',
                      style: const TextStyle(color: _muted, fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(_driverName,
                      style: const TextStyle(
                          color: _ink,
                          fontSize: 19,
                          fontWeight: FontWeight.w700)),
                ])),
            Stack(children: [
              _iconButton(Icons.notifications_none_rounded,
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                          builder: (_) => const DriverNotificationsPage()))),
              Positioned(
                  right: 9,
                  top: 8,
                  child: Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                          color: Color(0xFFFFB547), shape: BoxShape.circle))),
            ]),
          ]),
          const SizedBox(height: 20),
          Row(children: [
            const Icon(Icons.verified_rounded,
                color: Color(0xFF58D6A5), size: 17),
            const SizedBox(width: 6),
            const Text('Verified driver',
                style: TextStyle(
                    color: _green, fontSize: 12, fontWeight: FontWeight.w600)),
            const Spacer(),
            Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                    color: const Color(0xFFF1F4F8),
                    borderRadius: BorderRadius.circular(20)),
                child: Row(children: [
                  const Icon(Icons.local_shipping_outlined,
                      color: _muted, size: 14),
                  const SizedBox(width: 6),
                  Text(
                      _activeTripData?['vehicle_number']?.toString() ??
                          _nextPlannedTripData?['vehicle_number']?.toString() ??
                          'No vehicle',
                      style: const TextStyle(
                          color: _ink,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: .4))
                ])),
          ]),
        ]),
      );

  String get _driverName {
    final driver = dashboardData?['driver'];
    return driver is Map && driver['name'] != null
        ? driver['name'].toString()
        : AuthSession.instance.userDetails?['name']?.toString() ?? 'Driver';
  }

  String get _driverPhotoUrl {
    final driver = dashboardData?['driver'];
    final raw = driver is Map ? driver['photo']?.toString() : null;
    return AppConfig.resolveMediaUrl(raw);
  }

  Widget _driverAvatar() {
    final photoUrl = _driverPhotoUrl;
    Widget fallback() => Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
            color: const Color(0xFFEAF2FF),
            borderRadius: BorderRadius.circular(14)),
        child: Text(
            _driverName.trim().isEmpty
                ? 'D'
                : _driverName.trim().substring(0, 1).toUpperCase(),
            style: const TextStyle(
                color: _blue, fontSize: 17, fontWeight: FontWeight.w800)));
    if (photoUrl.isEmpty) return fallback();
    return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: CachedNetworkImage(
            imageUrl: photoUrl,
            width: 44,
            height: 44,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(
                width: 44,
                height: 44,
                color: const Color(0xFFF1F4F8),
                alignment: Alignment.center,
                child: const SizedBox(
                    width: 17,
                    height: 17,
                    child: CircularProgressIndicator(strokeWidth: 2))),
            errorWidget: (_, __, ___) => fallback()));
  }

  Map<String, dynamic>? get _activeTripData =>
      dashboardData?['active_trip'] is Map
          ? Map<String, dynamic>.from(dashboardData!['active_trip'] as Map)
          : null;
  Map<String, dynamic>? get _nextPlannedTripData =>
      dashboardData?['next_planned_trip'] is Map
          ? Map<String, dynamic>.from(
              dashboardData!['next_planned_trip'] as Map)
          : null;

  String _dashboardTime(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
    if (date == null) return 'Time not available';
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    return '$hour:${date.minute.toString().padLeft(2, '0')} ${date.hour >= 12 ? 'PM' : 'AM'}';
  }

  String get _activeDropName {
    final drop = _activeTripData?['drop'];
    return drop is Map
        ? drop['location_name']?.toString() ?? 'Delivery location'
        : 'Delivery location';
  }

  Widget _trackingCard() => _Card(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Row(children: [
            Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                    color: (online ? _green : _muted).withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(14)),
                child: Icon(Icons.sensors_rounded,
                    color: online ? _green : _muted)),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(
                      online
                          ? (paused
                              ? 'Tracking paused'
                              : 'Live tracking active')
                          : 'You are offline',
                      style: const TextStyle(
                          color: _ink,
                          fontSize: 16,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text(
                      paused
                          ? 'Lunch break · 18 min'
                          : 'Updated just now · GPS strong',
                      style: const TextStyle(color: _muted, fontSize: 12)),
                ])),
            if (changingDuty)
              const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 2.5))
            else
              Switch.adaptive(
                  value: online,
                  activeThumbColor: _green,
                  onChanged: _changeDuty),
          ]),
          if (online) ...[
            const Divider(height: 25),
            InkWell(
                onTap: () {
                  setState(() => paused = !paused);
                  PushNotificationService.instance.showOngoingTrip(
                      tripId: _activeTripData?['trip_id']?.toString() ??
                          'Active trip',
                      destination: _activeDropName,
                      eta: paused ? 'Tracking paused' : '24 min');
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: paused
                            ? const Color(0xFFEAF8F2)
                            : const Color(0xFFFFF7E8),
                        borderRadius: BorderRadius.circular(12)),
                    child: Row(children: [
                      Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10)),
                          child: Icon(
                              paused
                                  ? Icons.play_arrow_rounded
                                  : Icons.restaurant_rounded,
                              color: paused ? _green : const Color(0xFFD88212),
                              size: 19)),
                      const SizedBox(width: 10),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(paused ? 'Resume duty' : 'Take a break',
                                style: const TextStyle(
                                    color: _ink,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(height: 2),
                            Text(
                                paused
                                    ? 'Paused for 18 minutes'
                                    : 'Lunch, charging or personal break',
                                style: const TextStyle(
                                    color: _muted, fontSize: 10))
                          ])),
                      Icon(Icons.chevron_right_rounded,
                          color: paused ? _green : const Color(0xFFD88212))
                    ]))),
          ] else ...[
            const Divider(height: 25),
            SizedBox(
                width: double.infinity,
                child: _primaryButton('Start duty', Icons.play_arrow_rounded,
                    () => _changeDuty(true)))
          ]
        ]),
      );

  Widget _activeTrip() {
    final trip = _activeTripData;
    if (trip == null) {
      final plannedTrip = _nextPlannedTripData;
      if (plannedTrip != null) return _plannedTripCard(plannedTrip);
      return const _Card(
          child: Row(children: [
        Icon(Icons.event_available_outlined, color: _muted),
        SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('No active trip',
              style: TextStyle(color: _ink, fontWeight: FontWeight.w700)),
          SizedBox(height: 3),
          Text('New assignments will appear here.',
              style: TextStyle(color: _muted, fontSize: 11))
        ]))
      ]));
    }
    final pickup = trip['pickup'] is Map
        ? Map<String, dynamic>.from(trip['pickup'] as Map)
        : <String, dynamic>{};
    final drop = trip['drop'] is Map
        ? Map<String, dynamic>.from(trip['drop'] as Map)
        : <String, dynamic>{};
    final tripPk = int.tryParse(trip['id']?.toString() ?? '') ?? 0;
    return _Card(
      padding: EdgeInsets.zero,
      child: Column(children: [
        Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
                color: Color(0xFFEAF2FF),
                borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
            child: Row(children: [
              const _StatusDot(color: _blue),
              const SizedBox(width: 8),
              const Text('ACTIVE TRIP',
                  style: TextStyle(
                      color: _blue,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: .7)),
              const Spacer(),
              Text(trip['trip_id']?.toString() ?? '',
                  style: const TextStyle(
                      color: _ink, fontWeight: FontWeight.w700, fontSize: 12)),
            ])),
        Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              _RoutePoint(
                  color: _green,
                  title: pickup['location_name']?.toString() ?? 'Pickup',
                  subtitle: pickup['status']?.toString() ?? 'Pickup'),
              Container(
                  margin: const EdgeInsets.only(left: 6),
                  height: 22,
                  alignment: Alignment.centerLeft,
                  child: Container(width: 2, color: const Color(0xFFDCE3EA))),
              _RoutePoint(
                  color: _blue,
                  title: drop['location_name']?.toString() ?? 'Delivery',
                  subtitle:
                      '${drop['remaining_km'] ?? '--'} km away · ETA ${drop['eta_minutes'] ?? '--'} min'),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                    child: _primaryButton(
                        'Open trip',
                        Icons.arrow_forward_rounded,
                        () => Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => TripDetailPage(tripId: tripPk))))),
                const SizedBox(width: 10),
                SizedBox(
                    width: 48,
                    height: 48,
                    child: OutlinedButton(
                        onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                                builder: (_) =>
                                    TripDetailPage(tripId: tripPk))),
                        style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            side: const BorderSide(color: Color(0xFFD7E0E8)),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(13))),
                        child: const Icon(Icons.navigation_rounded,
                            color: _blue))),
              ])
            ]))
      ]),
    );
  }

  Widget _plannedTripCard(Map<String, dynamic> trip) {
    final from = trip['from'] is Map
        ? Map<String, dynamic>.from(trip['from'] as Map)
        : <String, dynamic>{};
    final to = trip['to'] is Map
        ? Map<String, dynamic>.from(trip['to'] as Map)
        : <String, dynamic>{};
    final tripPk = int.tryParse(trip['id']?.toString() ?? '');
    final canStart = trip['can_start'] == true;
    final pickupProofUploaded = trip['pickup_proof_uploaded'] == true;
    final plannedTrips = dashboardData?['planned_trips'];
    final remainingCount = plannedTrips is List ? plannedTrips.length : 1;

    return _Card(
      padding: EdgeInsets.zero,
      child: Column(children: [
        Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
                color: Color(0xFFF1EDFF),
                borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
            child: Row(children: [
              const _StatusDot(color: Color(0xFF7C5CFC)),
              const SizedBox(width: 8),
              const Text('NEXT PLANNED TRIP',
                  style: TextStyle(
                      color: Color(0xFF6D4FE0),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: .7)),
              const Spacer(),
              Text(trip['trip_id']?.toString() ?? '',
                  style: const TextStyle(
                      color: _ink, fontWeight: FontWeight.w700, fontSize: 12)),
            ])),
        Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              _RoutePoint(
                  color: _green,
                  title: from['location_text']?.toString() ?? 'Pickup',
                  subtitle: 'Pickup · ${_dashboardTime(from['time'])}'),
              Container(
                  margin: const EdgeInsets.only(left: 6),
                  height: 22,
                  alignment: Alignment.centerLeft,
                  child: Container(width: 2, color: const Color(0xFFDCE3EA))),
              _RoutePoint(
                  color: const Color(0xFF7C5CFC),
                  title: to['location_text']?.toString() ?? 'Delivery',
                  subtitle: 'Expected · ${_dashboardTime(to['time'])}'),
              const SizedBox(height: 14),
              Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                      color: canStart
                          ? const Color(0xFFEAF8F2)
                          : const Color(0xFFFFF7E8),
                      borderRadius: BorderRadius.circular(12)),
                  child: Row(children: [
                    Icon(
                        canStart
                            ? Icons.check_circle_outline_rounded
                            : Icons.camera_alt_outlined,
                        color: canStart ? _green : const Color(0xFFD88212),
                        size: 19),
                    const SizedBox(width: 9),
                    Expanded(
                        child: Text(
                            canStart
                                ? 'Trip is ready to start'
                                : pickupProofUploaded
                                    ? 'Complete remaining requirements to start'
                                    : 'Upload pickup proof before starting',
                            style: TextStyle(
                                color:
                                    canStart ? _green : const Color(0xFF9B6413),
                                fontSize: 11,
                                fontWeight: FontWeight.w700))),
                    if (remainingCount > 1)
                      Text('+$remainingCount planned',
                          style: const TextStyle(
                              color: _muted,
                              fontSize: 10,
                              fontWeight: FontWeight.w700))
                  ])),
              const SizedBox(height: 14),
              SizedBox(
                  width: double.infinity,
                  child: _primaryButton(
                      pickupProofUploaded ? 'View trip' : 'Add pickup proof',
                      pickupProofUploaded
                          ? Icons.arrow_forward_rounded
                          : Icons.camera_alt_outlined,
                      tripPk == null
                          ? () {}
                          : () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                  builder: (_) =>
                                      TripDetailPage(tripId: tripPk)))))
            ]))
      ]),
    );
  }

  Widget _quickActions(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const _SectionTitle(title: 'Quick actions'),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
              child: _QuickAction(
                  icon: Icons.report_problem_outlined,
                  color: const Color(0xFFFF8A3D),
                  label: 'Report issue',
                  onTap: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => const IssueSheet()))),
          const SizedBox(width: 10),
          Expanded(
              child: _QuickAction(
                  icon: Icons.support_agent_rounded,
                  color: _blue,
                  label: 'Emergency',
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                          builder: (_) => const DriverEmergencyPage())))),
          const SizedBox(width: 10),
          Expanded(
              child: _QuickAction(
                  icon: Icons.flag_outlined,
                  color: _green,
                  label: 'End day',
                  onTap: () => _showEndDay(context))),
        ])
      ]);
}

class DriverTripsPage extends StatefulWidget {
  const DriverTripsPage({super.key});
  static const routePath = '/driver/trips';

  @override
  State<DriverTripsPage> createState() => _DriverTripsPageState();
}

class _DriverTripsPageState extends State<DriverTripsPage> {
  List<Map<String, dynamic>> trips = const [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await sl<DriverRemoteDatasource>().trips();
      if (!mounted) return;
      setState(() {
        trips = data;
        loading = false;
        error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = 'Unable to load trips';
      });
    }
  }

  String _value(dynamic value, [String fallback = '—']) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty || text == 'null' ? fallback : text;
  }

  String _time(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
    if (date == null) return 'Schedule unavailable';
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    return '$hour:${date.minute.toString().padLeft(2, '0')} ${date.hour >= 12 ? 'PM' : 'AM'}';
  }

  Color _statusColor(String status) => switch (status) {
        'completed' => _green,
        'in_progress' => _blue,
        'cancelled' => const Color(0xFFD94D3D),
        _ => const Color(0xFF7C5CFC),
      };

  @override
  Widget build(BuildContext context) {
    final completed = trips.where((t) => t['status'] == 'completed').length;
    final active = trips.where((t) => t['status'] == 'in_progress').length;
    return Scaffold(
        backgroundColor: _surface,
        appBar: _appBar('My trips'),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : error != null
                ? _DriverLoadError(message: error!, onRetry: _load)
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(18, 16, 18, 110),
                        physics: const AlwaysScrollableScrollPhysics(),
                        cacheExtent: 500,
                        itemCount: trips.isEmpty ? 1 : trips.length + 1,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _SummaryStrip(
                                      trips: trips.length,
                                      delivered: completed,
                                      active: active),
                                  const SizedBox(height: 18),
                                  _SectionTitle(
                                      title:
                                          'Assigned trips · ${trips.length}'),
                                  const SizedBox(height: 10),
                                  if (trips.isEmpty)
                                    const _DriverEmptyState(
                                        icon: Icons.route_outlined,
                                        title: 'No trips assigned',
                                        subtitle:
                                            'New assignments will appear here automatically')
                                ]);
                          }
                          final trip = trips[index - 1];
                          final tripPk = int.tryParse('${trip['id']}');
                          return RepaintBoundary(
                              key: ValueKey(trip['id'] ?? trip['trip_id']),
                              child: _TripTile(
                                  status: _value(trip['status'])
                                      .replaceAll('_', ' '),
                                  id: _value(trip['trip_id']),
                                  route:
                                      '${_value(trip['pickup_address'], 'Pickup')} → ${_value(trip['delivery_address'], 'Delivery')}',
                                  time: _time(trip['expected_start_at'] ??
                                      trip['started_at']),
                                  color: _statusColor(
                                      _value(trip['status'], 'planned')),
                                  onTap: tripPk == null
                                      ? null
                                      : () => Navigator.of(context).push(
                                          MaterialPageRoute<void>(
                                              builder: (_) => TripDetailPage(
                                                  tripId: tripPk)))));
                        })));
  }
}

class DriverVehiclePage extends StatefulWidget {
  const DriverVehiclePage({super.key});
  static const routePath = '/driver/vehicle';

  @override
  State<DriverVehiclePage> createState() => _DriverVehiclePageState();
}

class _DriverVehiclePageState extends State<DriverVehiclePage> {
  Map<String, dynamic>? vehicle;
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await sl<DriverRemoteDatasource>().vehicle();
      if (!mounted) return;
      setState(() {
        vehicle = data['vehicle'] is Map
            ? Map<String, dynamic>.from(data['vehicle'] as Map)
            : null;
        loading = false;
        error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = 'Unable to load assigned vehicle';
      });
    }
  }

  String _value(dynamic value, [String fallback = '—']) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty || text == 'null' ? fallback : text;
  }

  @override
  Widget build(BuildContext context) {
    final insurance = vehicle?['insurance'] is Map
        ? Map<String, dynamic>.from(vehicle!['insurance'] as Map)
        : <String, dynamic>{};
    final picture = AppConfig.resolveMediaUrl(vehicle?['picture']?.toString());
    final active = vehicle?['active'] == true;
    return Scaffold(
        backgroundColor: _surface,
        appBar: _appBar('Vehicle'),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : error != null
                ? _DriverLoadError(message: error!, onRetry: _load)
                : vehicle == null
                    ? RefreshIndicator(
                        onRefresh: _load,
                        child: ListView(children: const [
                          SizedBox(height: 160),
                          _DriverEmptyState(
                              icon: Icons.no_transfer_outlined,
                              title: 'No vehicle assigned',
                              subtitle:
                                  'Your assigned vehicle will appear here')
                        ]))
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView(
                            padding: const EdgeInsets.fromLTRB(18, 16, 18, 110),
                            children: [
                              _Card(
                                  child: Column(children: [
                                Container(
                                    height: 150,
                                    decoration: BoxDecoration(
                                        color: const Color(0xFFE8EEF5),
                                        borderRadius:
                                            BorderRadius.circular(14)),
                                    clipBehavior: Clip.antiAlias,
                                    child: picture.isEmpty
                                        ? const Center(
                                            child: Icon(
                                                Icons.local_shipping_rounded,
                                                color: _ink,
                                                size: 84))
                                        : CachedNetworkImage(
                                            imageUrl: picture,
                                            fit: BoxFit.cover,
                                            errorWidget: (_, __, ___) =>
                                                const Center(
                                                    child: Icon(
                                                        Icons
                                                            .local_shipping_rounded,
                                                        color: _ink,
                                                        size: 84)))),
                                const SizedBox(height: 15),
                                Row(children: [
                                  Expanded(
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                        Text(
                                            _value(vehicle?[
                                                'registration_number']),
                                            style: const TextStyle(
                                                color: _ink,
                                                fontSize: 20,
                                                fontWeight: FontWeight.w800)),
                                        const SizedBox(height: 4),
                                        Text(
                                            _value(vehicle?['type'],
                                                'Vehicle type unavailable'),
                                            style: const TextStyle(
                                                color: _muted, fontSize: 13))
                                      ])),
                                  _Pill(
                                      text: active ? 'ACTIVE' : 'INACTIVE',
                                      color: active
                                          ? _green
                                          : const Color(0xFFD94D3D))
                                ]),
                              ])),
                              const SizedBox(height: 14),
                              Row(children: [
                                Expanded(
                                    child: _MetricCard(
                                        icon: Icons.speed_rounded,
                                        value: _value(
                                            vehicle?['total_running_km'], '0'),
                                        unit: 'km',
                                        label: 'Total running')),
                                const SizedBox(width: 10),
                                Expanded(
                                    child: _FuelStatusCard(
                                        onTap: () => _showFuelUpdate(context)))
                              ]),
                              const SizedBox(height: 18),
                              const _SectionTitle(title: 'Vehicle details'),
                              const SizedBox(height: 10),
                              _Card(
                                  child: Column(children: [
                                _InfoRow(
                                    icon: Icons.inventory_2_outlined,
                                    label: 'Capacity',
                                    value:
                                        '${_value(vehicle?['capacity_kg'])} kg'),
                                const _Divider(),
                                _InfoRow(
                                    icon: Icons.category_outlined,
                                    label: 'Type',
                                    value: _value(vehicle?['type'])),
                                const _Divider(),
                                _InfoRow(
                                    icon: Icons.view_in_ar_outlined,
                                    label: 'Volume capacity',
                                    value:
                                        '${_value(vehicle?['capacity_volume_cft'])} cft'),
                                const _Divider(),
                                _InfoRow(
                                    icon: Icons.event_outlined,
                                    label: 'Insurance valid',
                                    value: _value(insurance['expiry_date'],
                                        'Not available'),
                                    valueColor: insurance['valid'] == true
                                        ? _green
                                        : const Color(0xFFD94D3D))
                              ])),
                              const SizedBox(height: 14),
                              _Card(
                                  child: ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      leading: const CircleAvatar(
                                          backgroundColor: Color(0xFFFFECE8),
                                          child: Icon(Icons.delete_outline,
                                              color: Color(0xFFD94D3D))),
                                      title: const Text('Vehicle unavailable?',
                                          style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              color: _ink)),
                                      subtitle: const Text(
                                          'Report breakdown or request a change',
                                          style: TextStyle(
                                              color: _muted, fontSize: 12)),
                                      trailing: const Icon(Icons.chevron_right),
                                      onTap: () => showModalBottomSheet(
                                          context: context,
                                          isScrollControlled: true,
                                          builder: (_) => const IssueSheet())))
                            ])));
  }
}

class DriverProfilePage extends StatefulWidget {
  const DriverProfilePage({super.key});
  static const routePath = '/driver/profile';

  @override
  State<DriverProfilePage> createState() => _DriverProfilePageState();
}

class _DriverProfilePageState extends State<DriverProfilePage> {
  Map<String, dynamic>? data;
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final response = await sl<DriverRemoteDatasource>().profile();
      if (!mounted) return;
      setState(() {
        data = response;
        loading = false;
        error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = 'Unable to load driver profile';
      });
    }
  }

  Map<String, dynamic> _map(dynamic value) =>
      value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

  String _value(dynamic value, [String fallback = 'Not available']) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty || text == 'null' ? fallback : text;
  }

  String _hours(dynamic value) {
    final hours = double.tryParse('$value');
    if (hours == null) return 'Not available';
    final whole = hours.floor();
    final minutes = ((hours - whole) * 60).round();
    return '${whole}h ${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    final driver = _map(data?['driver']);
    final licence = _map(driver['driving_licence']);
    final police = _map(driver['police_verification']);
    final work = _map(data?['work_and_safety']);
    final verified = driver['verified'] == true;
    final imageUrl = AppConfig.resolveMediaUrl(
        (driver['image'] ?? driver['photo'])?.toString());
    final name = _value(driver['name'],
        AuthSession.instance.userDetails?['name']?.toString() ?? 'Driver');
    return Scaffold(
        backgroundColor: _surface,
        appBar: _appBar('Driver profile'),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : error != null
                ? _DriverLoadError(message: error!, onRetry: _load)
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(18, 16, 18, 110),
                        children: [
                          _Card(
                              child: Row(children: [
                            Container(
                                width: 62,
                                height: 62,
                                clipBehavior: Clip.antiAlias,
                                decoration: const BoxDecoration(
                                    color: Color(0xFFE7EFFF),
                                    shape: BoxShape.circle),
                                child: imageUrl.isEmpty
                                    ? const Icon(Icons.person_rounded,
                                        color: _blue, size: 34)
                                    : CachedNetworkImage(
                                        imageUrl: imageUrl,
                                        fit: BoxFit.cover,
                                        placeholder: (_, __) => const Center(
                                            child: SizedBox.square(
                                                dimension: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                        strokeWidth: 2))),
                                        errorWidget: (_, __, ___) => const Icon(
                                            Icons.person_rounded,
                                            color: _blue,
                                            size: 34))),
                            const SizedBox(width: 14),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Text(name,
                                      style: const TextStyle(
                                          color: _ink,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800)),
                                  const SizedBox(height: 5),
                                  Row(children: [
                                    Icon(
                                        verified
                                            ? Icons.verified_rounded
                                            : Icons.pending_outlined,
                                        color: verified
                                            ? _green
                                            : const Color(0xFFD88212),
                                        size: 16),
                                    const SizedBox(width: 5),
                                    Text(
                                        verified
                                            ? 'Driver verified'
                                            : 'Verification pending',
                                        style: TextStyle(
                                            color: verified
                                                ? _green
                                                : const Color(0xFFD88212),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700))
                                  ])
                                ])),
                            const Icon(Icons.chevron_right_rounded,
                                color: _muted)
                          ])),
                          const SizedBox(height: 18),
                          const _SectionTitle(title: 'Verification documents'),
                          const SizedBox(height: 10),
                          _DocumentTile(
                              icon: Icons.badge_outlined,
                              title: 'Aadhaar card',
                              detail: _value(driver['masked_aadhaar_number']),
                              verified: verified),
                          _DocumentTile(
                              icon: Icons.credit_card_rounded,
                              title: 'Driving licence',
                              detail: licence['valid_until'] == null
                                  ? _value(licence['number'])
                                  : '${_value(licence['number'])} · Valid until ${licence['valid_until']}',
                              verified: licence['valid'] == true),
                          _DocumentTile(
                              icon: Icons.local_police_outlined,
                              title: 'Police verification',
                              detail: police['verified_at'] == null
                                  ? 'Verification pending'
                                  : 'Verified ${police['verified_at'].toString().split('T').first}',
                              verified: police['verified'] == true),
                          const SizedBox(height: 18),
                          const _SectionTitle(title: 'Work & safety'),
                          const SizedBox(height: 10),
                          _Card(
                              child: Column(children: [
                            _InfoRow(
                                icon: Icons.timelapse_rounded,
                                label: 'Hours this week',
                                value: _hours(work['hours_this_week'])),
                            const _Divider(),
                            _InfoRow(
                                icon: Icons.route_outlined,
                                label: 'Distance this week',
                                value:
                                    '${_value(work['distance_this_week_km'], '0')} km'),
                            const _Divider(),
                            _InfoRow(
                                icon: Icons.health_and_safety_outlined,
                                label: 'Safety score',
                                value:
                                    '${_value(work['safety_score'], '0')} / ${_value(work['score_out_of'], '100')}',
                                valueColor: _green)
                          ])),
                          const SizedBox(height: 14),
                          _Card(
                              child: Column(children: [
                            _MenuRow(
                                icon: Icons.help_outline_rounded,
                                text: 'Help & support',
                                onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute<void>(
                                        builder: (_) =>
                                            const DriverEmergencyPage()))),
                            const _Divider(),
                            _MenuRow(
                                icon: Icons.emergency_outlined,
                                text: 'Emergency contacts',
                                onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute<void>(
                                        builder: (_) =>
                                            const DriverEmergencyPage()))),
                            const _Divider(),
                            _MenuRow(
                                icon: Icons.logout_rounded,
                                text: 'Sign out',
                                danger: true,
                                onTap: () => showDialog<void>(
                                    context: context,
                                    builder: (dialogContext) => AlertDialog(
                                            title: const Text('Sign out?'),
                                            content: const Text(
                                                'Live tracking will stop after you sign out.'),
                                            actions: [
                                              TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                          dialogContext),
                                                  child: const Text('Cancel')),
                                              TextButton(
                                                  onPressed: () {
                                                    Navigator.pop(
                                                        dialogContext);
                                                    _toast(context,
                                                        'Sign out will connect to the auth API');
                                                  },
                                                  child: const Text('Sign out'))
                                            ])))
                          ])),
                        ])));
  }
}

class TripDetailPage extends StatefulWidget {
  const TripDetailPage({super.key, this.tripId = 45});
  final int tripId;
  @override
  State<TripDetailPage> createState() => _TripDetailPageState();
}

class _TripDetailPageState extends State<TripDetailPage> {
  bool beforeLoadingUploaded = true;
  bool loadedVehicleUploaded = true;
  bool deliveryUploaded = false;
  bool challanUploaded = false;
  bool recipientVerified = false;
  bool proofUploading = false;
  bool tripCompleting = false;
  Map<String, dynamic>? tripData;
  bool tripLoading = true;
  String? tripError;
  String? fetchedRoutePolyline;
  BitmapDescriptor? driverMarkerIcon;
  BitmapDescriptor? pickupMarkerIcon;
  BitmapDescriptor? deliveryMarkerIcon;

  @override
  void initState() {
    super.initState();
    _loadTrip();
    _loadMapMarkers();
  }

  Future<void> _loadMapMarkers() async {
    final pickup = await _buildMapPin(_green, label: 'P');
    final delivery = await _buildMapPin(const Color(0xFFD94D3D), label: 'D');
    final driverFallback = await _buildMapPin(_blue, label: 'D');
    if (!mounted) return;
    setState(() {
      pickupMarkerIcon = pickup;
      deliveryMarkerIcon = delivery;
      driverMarkerIcon = driverFallback;
    });
    try {
      final profile = await sl<DriverRemoteDatasource>().profile();
      final driver = profile['driver'] is Map
          ? Map<String, dynamic>.from(profile['driver'] as Map)
          : <String, dynamic>{};
      final imageUrl = AppConfig.resolveMediaUrl(
          (driver['image'] ?? driver['photo'])?.toString());
      if (imageUrl.isEmpty) return;
      final image = await _resolveMarkerImage(imageUrl);
      final marker = await _buildMapPin(_blue, image: image);
      if (!mounted) return;
      setState(() => driverMarkerIcon = marker);
    } catch (_) {
      // Keep the generated blue driver pin if the photo cannot be decoded.
    }
  }

  Future<ui.Image> _resolveMarkerImage(String imageUrl) {
    final completer = Completer<ui.Image>();
    final stream =
        CachedNetworkImageProvider(imageUrl).resolve(ImageConfiguration.empty);
    late ImageStreamListener listener;
    listener = ImageStreamListener((info, _) {
      stream.removeListener(listener);
      if (!completer.isCompleted) completer.complete(info.image);
    }, onError: (Object error, StackTrace? stackTrace) {
      stream.removeListener(listener);
      if (!completer.isCompleted) completer.completeError(error, stackTrace);
    });
    stream.addListener(listener);
    return completer.future.timeout(const Duration(seconds: 8));
  }

  Future<BitmapDescriptor> _buildMapPin(Color color,
      {String? label, ui.Image? image}) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const size = Size(88, 104);
    final tip = Path()
      ..moveTo(32, 70)
      ..lineTo(44, 101)
      ..lineTo(56, 70)
      ..close();
    canvas.drawShadow(tip, Colors.black, 5, true);
    canvas.drawPath(tip, Paint()..color = color);
    canvas.drawCircle(const Offset(44, 42), 39, Paint()..color = Colors.white);
    canvas.drawCircle(const Offset(44, 42), 35, Paint()..color = color);
    if (image != null) {
      canvas.save();
      canvas.clipPath(Path()
        ..addOval(Rect.fromCircle(center: const Offset(44, 42), radius: 30)));
      canvas.drawImageRect(
          image,
          Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
          const Rect.fromLTWH(14, 12, 60, 60),
          Paint()..filterQuality = FilterQuality.high);
      canvas.restore();
    } else {
      final painter = TextPainter(
          text: TextSpan(
              text: label ?? '',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w800)),
          textDirection: TextDirection.ltr)
        ..layout();
      painter.paint(
          canvas, Offset(44 - painter.width / 2, 42 - painter.height / 2));
    }
    final rendered = await recorder
        .endRecording()
        .toImage(size.width.toInt(), size.height.toInt());
    final png = await rendered.toByteData(format: ui.ImageByteFormat.png);
    if (png == null) return BitmapDescriptor.defaultMarker;
    return BitmapDescriptor.bytes(png.buffer.asUint8List(), imagePixelRatio: 2);
  }

  Future<void> _loadTrip() async {
    try {
      final data = await sl<DriverRemoteDatasource>().tripDetail(widget.tripId);
      if (!mounted) return;
      final proofs = data['proofs'] is Map
          ? Map<String, dynamic>.from(data['proofs'] as Map)
          : <String, dynamic>{};
      setState(() {
        tripData = data;
        tripLoading = false;
        tripError = null;
        beforeLoadingUploaded = proofs['before_loading_uploaded'] == true;
        loadedVehicleUploaded = proofs['loaded_vehicle_uploaded'] == true;
        deliveryUploaded = proofs['goods_after_delivery_uploaded'] == true;
        challanUploaded = proofs['signed_challan_uploaded'] == true;
      });
      _loadRoadRoute(data);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        tripLoading = false;
        tripError = 'Unable to load trip details';
      });
    }
  }

  Future<void> _loadRoadRoute(Map<String, dynamic> data) async {
    final route = _map(data['route']);
    final backendPolyline = _routePolylineValue(route);
    final pickup = _coordinate(_map(route['pickup']));
    final delivery = _coordinate(_map(route['delivery']));
    if (pickup == null || delivery == null) return;
    // A route is accepted only when it contains road geometry and its decoded
    // endpoints match this trip's pickup and delivery coordinates.
    if (_validatedRoutePolyline(backendPolyline, pickup, delivery).isNotEmpty) {
      return;
    }
    try {
      final encoded = await sl<DriverRemoteDatasource>().drivingRoutePolyline(
        originLatitude: pickup.latitude,
        originLongitude: pickup.longitude,
        destinationLatitude: delivery.latitude,
        destinationLongitude: delivery.longitude,
        apiKey: AppConfig.googleMapsApiKey,
      );
      if (!mounted || encoded == null) return;
      setState(() => fetchedRoutePolyline = encoded);
    } catch (_) {
      // Markers and external Google Maps navigation remain available if the
      // Routes API is disabled or restricted for the configured key.
    }
  }

  Map<String, dynamic> _map(dynamic value) =>
      value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

  List<Map<String, dynamic>> get _items => tripData?['items'] is List
      ? (tripData!['items'] as List)
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList()
      : <Map<String, dynamic>>[];

  String _text(dynamic value, [String fallback = '—']) {
    final result = value?.toString().trim() ?? '';
    return result.isEmpty || result == 'null' ? fallback : result;
  }

  String _number(dynamic value) {
    final number = double.tryParse(value?.toString() ?? '');
    if (number == null) return _text(value);
    return number == number.roundToDouble()
        ? number.toInt().toString()
        : number
            .toStringAsFixed(2)
            .replaceFirst(RegExp(r'0+$'), '')
            .replaceFirst(RegExp(r'\.$'), '');
  }

  String _dateTime(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
    if (date == null) return 'Time not available';
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute ${date.hour >= 12 ? 'PM' : 'AM'}';
  }

  LatLng? _coordinate(Map<String, dynamic> point) {
    final latitude = double.tryParse(point['latitude']?.toString() ?? '');
    final longitude = double.tryParse(point['longitude']?.toString() ?? '');
    if (latitude == null || longitude == null) return null;
    if (latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180) {
      return null;
    }
    return LatLng(latitude, longitude);
  }

  Future<void> _frameRoute(
      GoogleMapController controller, List<LatLng> points) async {
    if (points.length < 2) return;
    var south = points.first.latitude;
    var north = points.first.latitude;
    var west = points.first.longitude;
    var east = points.first.longitude;
    for (final point in points.skip(1)) {
      if (point.latitude < south) south = point.latitude;
      if (point.latitude > north) north = point.latitude;
      if (point.longitude < west) west = point.longitude;
      if (point.longitude > east) east = point.longitude;
    }
    await controller.animateCamera(CameraUpdate.newLatLngBounds(
        LatLngBounds(
            southwest: LatLng(south, west), northeast: LatLng(north, east)),
        46));
  }

  List<LatLng> _decodePolyline(dynamic rawValue, {int precision = 5}) {
    final encoded = rawValue?.toString().trim() ?? '';
    if (encoded.isEmpty || encoded == 'null') return const <LatLng>[];
    final points = <LatLng>[];
    var index = 0;
    var latitude = 0;
    var longitude = 0;
    while (index < encoded.length) {
      var result = 0;
      var shift = 0;
      int byte;
      do {
        if (index >= encoded.length) return const <LatLng>[];
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1f) << shift;
        shift += 5;
      } while (byte >= 0x20);
      latitude += (result & 1) != 0 ? ~(result >> 1) : result >> 1;

      result = 0;
      shift = 0;
      do {
        if (index >= encoded.length) return const <LatLng>[];
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1f) << shift;
        shift += 5;
      } while (byte >= 0x20);
      longitude += (result & 1) != 0 ? ~(result >> 1) : result >> 1;
      final divisor = precision == 6 ? 1e6 : 1e5;
      final point = LatLng(latitude / divisor, longitude / divisor);
      if (point.latitude < -90 ||
          point.latitude > 90 ||
          point.longitude < -180 ||
          point.longitude > 180) {
        return const <LatLng>[];
      }
      points.add(point);
    }
    return points;
  }

  List<LatLng> _validatedRoutePolyline(
      dynamic rawValue, LatLng? origin, LatLng? destination) {
    if (origin == null || destination == null) return const <LatLng>[];
    if (rawValue is List) {
      for (final geoJsonOrder in const [false, true]) {
        final points = rawValue
            .map<LatLng?>((value) {
              if (value is Map) {
                return _coordinate(Map<String, dynamic>.from(value));
              }
              if (value is List && value.length >= 2) {
                final first = double.tryParse('${value[0]}');
                final second = double.tryParse('${value[1]}');
                if (first == null || second == null) return null;
                return geoJsonOrder
                    ? LatLng(second, first)
                    : LatLng(first, second);
              }
              return null;
            })
            .whereType<LatLng>()
            .toList();
        if (points.length > 2) {
          final forward = _coordinateDistance(points.first, origin) +
              _coordinateDistance(points.last, destination);
          final reverse = _coordinateDistance(points.first, destination) +
              _coordinateDistance(points.last, origin);
          if ((forward < reverse ? forward : reverse) < .25) {
            return reverse < forward ? points.reversed.toList() : points;
          }
        }
      }
      return const <LatLng>[];
    }
    List<LatLng> best = const <LatLng>[];
    var bestScore = double.infinity;
    for (final precision in const [5, 6]) {
      final points = _decodePolyline(rawValue, precision: precision);
      if (points.length <= 2) continue;
      final forward = _coordinateDistance(points.first, origin) +
          _coordinateDistance(points.last, destination);
      final reverse = _coordinateDistance(points.first, destination) +
          _coordinateDistance(points.last, origin);
      final score = forward < reverse ? forward : reverse;
      // Encoded road geometry must terminate close to this trip's endpoints.
      // This also prevents a precision mismatch from drawing across the map.
      if (score < bestScore && score < .25) {
        bestScore = score;
        best = reverse < forward ? points.reversed.toList() : points;
      }
    }
    return best;
  }

  dynamic _routePolylineValue(Map<String, dynamic> route) {
    final routes = route['routes'];
    if (routes is List && routes.isNotEmpty && routes.first is Map) {
      final firstRoute = Map<String, dynamic>.from(routes.first as Map);
      final nested = _routePolylineValue(firstRoute);
      if (nested != null) return nested;
    }
    final overview = route['overview_polyline'];
    if (overview is String) return overview;
    if (overview is Map) {
      final value = overview['points'] ?? overview['encodedPolyline'];
      if (value != null) return value;
    }
    final geometry = route['route_geometry'] ?? route['geometry'];
    if (geometry is String || geometry is List) return geometry;
    if (geometry is Map && geometry['coordinates'] is List) {
      return geometry['coordinates'];
    }
    if (route['route_coordinates'] is List) return route['route_coordinates'];
    if (route['coordinates'] is List) return route['coordinates'];
    if (route['encoded_polyline'] != null) return route['encoded_polyline'];
    if (route['encodedPolyline'] != null) return route['encodedPolyline'];
    final routePolyline = route['route_polyline'];
    if (routePolyline is String || routePolyline is List) return routePolyline;
    if (routePolyline is Map) {
      return routePolyline['encoded_polyline'] ??
          routePolyline['encodedPolyline'] ??
          routePolyline['points'];
    }
    final polyline = route['polyline'];
    if (polyline is String || polyline is List) return polyline;
    if (polyline is Map) {
      return polyline['encoded_polyline'] ??
          polyline['encodedPolyline'] ??
          polyline['points'];
    }
    return null;
  }

  double _coordinateDistance(LatLng a, LatLng b) {
    final latitude = a.latitude - b.latitude;
    final longitude = a.longitude - b.longitude;
    return latitude * latitude + longitude * longitude;
  }

  Future<void> _pick(String proofType) async {
    if (proofUploading) return;
    final file = await ImagePicker()
        .pickImage(source: ImageSource.camera, imageQuality: 75);
    if (file != null && mounted) {
      setState(() => proofUploading = true);
      final apiType = switch (proofType) {
        'beforeLoading' => 'before_loading',
        'loadedVehicle' => 'loaded_vehicle',
        'delivery' => 'goods_after_delivery',
        'challan' => 'signed_challan',
        _ => 'other',
      };
      try {
        final imageBytes = await file.readAsBytes();
        await sl<DriverRemoteDatasource>().uploadTripProof(
          tripId: widget.tripId,
          imageBytes: imageBytes,
          fileName: file.name.isEmpty ? 'trip-proof.jpg' : file.name,
          imageType: apiType,
          caption: switch (proofType) {
            'beforeLoading' => 'Goods before loading',
            'loadedVehicle' => 'Loaded vehicle and secured goods',
            'delivery' => 'Goods after delivery',
            'challan' => 'Signed delivery challan',
            _ => 'Trip proof',
          },
        );
        if (!mounted) return;
        setState(() {
          switch (proofType) {
            case 'beforeLoading':
              beforeLoadingUploaded = true;
            case 'loadedVehicle':
              loadedVehicleUploaded = true;
            case 'delivery':
              deliveryUploaded = true;
            case 'challan':
              challanUploaded = true;
          }
          proofUploading = false;
        });
        _toast(context, 'Proof uploaded successfully');
      } catch (_) {
        if (!mounted) return;
        setState(() => proofUploading = false);
        _toast(context, 'Proof upload failed. Please retry.');
      }
    }
  }

  String? _documentUrl(String key) {
    final documents = tripData?['documents'];
    if (documents is! Map) return null;
    final value = documents[key]?.toString().trim();
    return value == null || value.isEmpty || value == 'null' ? null : value;
  }

  Future<void> _openDocument(String title, String key) async {
    final raw = _documentUrl(key);
    if (raw == null) {
      _toast(context, '$title is not available yet');
      return;
    }
    final uri = Uri.tryParse(raw);
    if (uri == null ||
        !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) _toast(context, 'Unable to open $title');
    }
  }

  @override
  Widget build(BuildContext context) {
    final route = _map(tripData?['route']);
    final pickup = _map(route['pickup']);
    final delivery = _map(route['delivery']);
    final payment = _map(tripData?['payment']);
    final itemCount = _items.length;
    final totalLoad = _number(tripData?['total_load_kg']);
    final paymentRequired = payment['required'] == true;
    final amount = _number(payment['amount_to_collect']);
    final pickupCoordinate = _coordinate(pickup);
    final deliveryCoordinate = _coordinate(delivery);
    final latestCoordinate = _coordinate(_map(route['latest_location']));
    final routePoints = <LatLng>[
      if (pickupCoordinate != null) pickupCoordinate,
      if (latestCoordinate != null) latestCoordinate,
      if (deliveryCoordinate != null) deliveryCoordinate,
    ];
    final backendRoutePoints = _validatedRoutePolyline(
        _routePolylineValue(route), pickupCoordinate, deliveryCoordinate);
    final fetchedRoutePoints = _validatedRoutePolyline(
        fetchedRoutePolyline, pickupCoordinate, deliveryCoordinate);
    final roadRoutePoints = backendRoutePoints.isNotEmpty
        ? backendRoutePoints
        : fetchedRoutePoints.isNotEmpty
            ? fetchedRoutePoints
            : const <LatLng>[];
    final cameraPoints =
        roadRoutePoints.isNotEmpty ? roadRoutePoints : routePoints;
    final initialCoordinate = latestCoordinate ??
        pickupCoordinate ??
        deliveryCoordinate ??
        const LatLng(20.5937, 78.9629);

    return Scaffold(
        backgroundColor: _surface,
        appBar: _appBar(
            'Trip ${tripData?['trip_id']?.toString() ?? widget.tripId}',
            back: true),
        body: tripLoading
            ? const Center(child: CircularProgressIndicator())
            : tripError != null
                ? Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.cloud_off_rounded,
                        color: _muted, size: 42),
                    const SizedBox(height: 12),
                    Text(tripError!, style: const TextStyle(color: _muted)),
                    const SizedBox(height: 8),
                    TextButton(
                        onPressed: () {
                          setState(() {
                            tripLoading = true;
                            tripError = null;
                          });
                          _loadTrip();
                        },
                        child: const Text('Retry'))
                  ]))
                : RefreshIndicator(
                    onRefresh: _loadTrip,
                    child: ListView(
                        padding: const EdgeInsets.fromLTRB(18, 16, 18, 120),
                        children: [
                          Container(
                              height: 210,
                              clipBehavior: Clip.antiAlias,
                              decoration: BoxDecoration(
                                  color: const Color(0xFFDDE9E6),
                                  borderRadius: BorderRadius.circular(20)),
                              child: Stack(children: [
                                Positioned.fill(
                                    child: routePoints.isEmpty
                                        ? const _TripMapUnavailable()
                                        : GoogleMap(
                                            initialCameraPosition:
                                                CameraPosition(
                                                    target: initialCoordinate,
                                                    zoom: 12.5),
                                            onMapCreated: (controller) =>
                                                _frameRoute(
                                                    controller, cameraPoints),
                                            markers: {
                                              if (pickupCoordinate != null)
                                                Marker(
                                                    markerId: const MarkerId(
                                                        'pickup'),
                                                    position: pickupCoordinate,
                                                    infoWindow: InfoWindow(
                                                        title: 'Pickup',
                                                        snippet: _text(
                                                            pickup['location'],
                                                            'Pickup location')),
                                                    icon: pickupMarkerIcon ??
                                                        BitmapDescriptor
                                                            .defaultMarker),
                                              if (deliveryCoordinate != null)
                                                Marker(
                                                    markerId: const MarkerId(
                                                        'delivery'),
                                                    position:
                                                        deliveryCoordinate,
                                                    infoWindow: InfoWindow(
                                                        title: 'Delivery',
                                                        snippet: _text(
                                                            delivery[
                                                                'location'],
                                                            'Delivery location')),
                                                    icon: deliveryMarkerIcon ??
                                                        BitmapDescriptor
                                                            .defaultMarker),
                                              if (latestCoordinate != null)
                                                Marker(
                                                    markerId: const MarkerId(
                                                        'driver'),
                                                    position: latestCoordinate,
                                                    infoWindow: const InfoWindow(
                                                        title: 'Driver',
                                                        snippet:
                                                            'Current location'),
                                                    icon: driverMarkerIcon ??
                                                        BitmapDescriptor
                                                            .defaultMarker),
                                            },
                                            polylines: roadRoutePoints.length >
                                                    1
                                                ? {
                                                    Polyline(
                                                        polylineId:
                                                            const PolylineId(
                                                                'trip_route'),
                                                        points: roadRoutePoints,
                                                        color: _blue,
                                                        width: 5)
                                                  }
                                                : const <Polyline>{},
                                            zoomControlsEnabled: false,
                                            mapToolbarEnabled: false,
                                            myLocationButtonEnabled: false,
                                            compassEnabled: false,
                                            buildingsEnabled: false,
                                          )),
                                Positioned(
                                    left: 16,
                                    right: 16,
                                    bottom: 12,
                                    child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 9),
                                        decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            boxShadow: const [
                                              BoxShadow(
                                                  color: Color(0x22000000),
                                                  blurRadius: 12)
                                            ]),
                                        child: Row(children: [
                                          const Icon(Icons.navigation_rounded,
                                              color: _blue, size: 18),
                                          const SizedBox(width: 8),
                                          Expanded(
                                              child: Text(
                                                  _text(route['distance_text'],
                                                      'Open route in Google Maps'),
                                                  style: const TextStyle(
                                                      color: _ink,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      fontSize: 12))),
                                          if (_text(
                                                  route['google_maps_url'], '')
                                              .isNotEmpty)
                                            TextButton(
                                                onPressed: () => launchUrl(
                                                    Uri.parse(
                                                        route['google_maps_url']
                                                            .toString()),
                                                    mode: LaunchMode
                                                        .externalApplication),
                                                child: const Text('Navigate'))
                                        ]))),
                              ])),
                          const SizedBox(height: 14),
                          _Card(
                              child: Column(children: [
                            _RoutePoint(
                                color: _green,
                                title: _text(
                                    pickup['location'], 'Pickup location'),
                                subtitle:
                                    'Pickup · ${_dateTime(pickup['time'])}'),
                            const SizedBox(height: 20),
                            _RoutePoint(
                                color: _blue,
                                title: _text(
                                    delivery['location'], 'Delivery location'),
                                subtitle:
                                    'Expected · ${_dateTime(delivery['time'])}')
                          ])),
                          const SizedBox(height: 14),
                          _Card(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Row(children: [
                                  Expanded(
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                        Text(
                                            'Order ${tripData?['order_number']?.toString() ?? '—'}',
                                            style: const TextStyle(
                                                color: _ink,
                                                fontWeight: FontWeight.w800,
                                                fontSize: 16)),
                                        const SizedBox(height: 4),
                                        Text(
                                            'Delivery challan ${tripData?['delivery_challan_number']?.toString() ?? '—'}',
                                            style: const TextStyle(
                                                color: _muted, fontSize: 11))
                                      ])),
                                  _Pill(
                                      text: paymentRequired
                                          ? 'PAYMENT DUE'
                                          : 'PREPAID',
                                      color: paymentRequired
                                          ? const Color(0xFFF59E0B)
                                          : _green)
                                ]),
                                const SizedBox(height: 15),
                                if (_items.isEmpty)
                                  const Padding(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 8),
                                      child: Text('No order items available',
                                          style: TextStyle(
                                              color: _muted, fontSize: 12)))
                                else
                                  for (var index = 0;
                                      index < _items.length;
                                      index++) ...[
                                    _OrderItem(
                                        name: _text(_items[index]['name'],
                                            'Order item'),
                                        quantity:
                                            '${_number(_items[index]['quantity'])} ${_text(_items[index]['unit'], '')}'
                                                .trim(),
                                        detail:
                                            '${_number(_items[index]['total_weight_kg'])} kg',
                                        imageUrl: AppConfig.resolveMediaUrl(
                                            _items[index]['product_image']
                                                ?.toString())),
                                    if (index != _items.length - 1)
                                      const _Divider(),
                                  ],
                                const _Divider(),
                                _InfoRow(
                                    icon: Icons.scale_outlined,
                                    label: 'Total load',
                                    value: '$totalLoad kg'),
                                const _Divider(),
                                _InfoRow(
                                    icon: Icons.notes_rounded,
                                    label: 'Delivery instruction',
                                    value: _text(
                                        tripData?['delivery_instructions'],
                                        'No special instructions')),
                              ])),
                          const SizedBox(height: 14),
                          _Card(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                const Text('Order documents',
                                    style: TextStyle(
                                        color: _ink,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16)),
                                const SizedBox(height: 5),
                                const Text(
                                    'Keep documents available for warehouse and site checks.',
                                    style:
                                        TextStyle(color: _muted, fontSize: 12)),
                                const SizedBox(height: 12),
                                _DownloadRow(
                                    icon: Icons.description_outlined,
                                    title: 'Delivery challan',
                                    detail:
                                        '${tripData?['delivery_challan_number']?.toString() ?? 'Not available'} · PDF',
                                    onTap: () => _openDocument(
                                        'Delivery challan',
                                        'delivery_challan_pdf')),
                                const _Divider(),
                                _DownloadRow(
                                    icon: Icons.receipt_long_outlined,
                                    title: 'Order invoice',
                                    detail:
                                        '${tripData?['order_number']?.toString() ?? 'Not available'} · PDF',
                                    onTap: () => _openDocument(
                                        'Order invoice', 'order_invoice')),
                                const _Divider(),
                                _DownloadRow(
                                    icon: Icons.inventory_2_outlined,
                                    title: 'Material list',
                                    detail:
                                        '$itemCount ${itemCount == 1 ? 'item' : 'items'} · $totalLoad kg',
                                    onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute<void>(
                                            builder: (_) => DriverDocumentPage(
                                                title: 'Material list',
                                                number:
                                                    '$itemCount ${itemCount == 1 ? 'item' : 'items'} · $totalLoad kg')))),
                              ])),
                          const SizedBox(height: 14),
                          _Card(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                const Text('Loading & delivery proof',
                                    style: TextStyle(
                                        color: _ink,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16)),
                                const SizedBox(height: 5),
                                const Text(
                                    'Timestamp and location will be attached to every photo.',
                                    style:
                                        TextStyle(color: _muted, fontSize: 12)),
                                const SizedBox(height: 14),
                                _ProofRow(
                                    title: 'Goods before loading',
                                    subtitle: 'Mandatory before loading starts',
                                    uploaded: beforeLoadingUploaded,
                                    onTap: () => _pick('beforeLoading')),
                                const _Divider(),
                                _ProofRow(
                                    title: 'Loaded vehicle & secured goods',
                                    subtitle: 'Mandatory before trip starts',
                                    uploaded: loadedVehicleUploaded,
                                    onTap: () => _pick('loadedVehicle')),
                                const _Divider(),
                                _ProofRow(
                                    title: 'Goods after delivery',
                                    subtitle:
                                        'Show unloaded goods at delivery point',
                                    uploaded: deliveryUploaded,
                                    onTap: () => _pick('delivery')),
                                const _Divider(),
                                _ProofRow(
                                    title: 'Signed / stamped challan',
                                    subtitle: 'Upload signed DC when available',
                                    uploaded: challanUploaded,
                                    onTap: () => _pick('challan')),
                              ])),
                          const SizedBox(height: 14),
                          _Card(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                const Text('Proof of delivery',
                                    style: TextStyle(
                                        color: _ink,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16)),
                                const SizedBox(height: 12),
                                _InfoRow(
                                    icon: Icons.person_outline_rounded,
                                    label: 'Recipient',
                                    value: _text(
                                        tripData?['proof_of_delivery_name'],
                                        'To be confirmed')),
                                const _Divider(),
                                Row(children: [
                                  const Icon(Icons.pin_outlined,
                                      color: _muted, size: 20),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                      child: Text('Delivery OTP',
                                          style: TextStyle(
                                              color: _muted, fontSize: 13))),
                                  if (recipientVerified)
                                    const _Pill(text: 'VERIFIED', color: _green)
                                  else
                                    TextButton(
                                        onPressed: () async {
                                          final verified = await Navigator.push<
                                                  bool>(
                                              context,
                                              MaterialPageRoute<bool>(
                                                  builder: (_) =>
                                                      const DeliveryOtpPage()));
                                          if (verified == true && mounted)
                                            setState(
                                                () => recipientVerified = true);
                                        },
                                        child: const Text('Verify OTP'))
                                ]),
                                const _Divider(),
                                _InfoRow(
                                    icon: Icons.payments_outlined,
                                    label: 'Amount to collect',
                                    value: paymentRequired
                                        ? '₹$amount'
                                        : '₹0 · Prepaid',
                                    valueColor: paymentRequired
                                        ? const Color(0xFFF59E0B)
                                        : _green),
                              ])),
                          const SizedBox(height: 16),
                          _tripActionButtons(),
                        ])));
  }

  Widget _tripActionButtons() => SafeArea(
      top: false,
      child: Row(children: [
        Expanded(
            child: _tripActionButton(
                label: 'Report issue',
                icon: Icons.report_problem_outlined,
                backgroundColor: const Color(0xFFD94D3D),
                onPressed: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => IssueSheet(tripId: widget.tripId)))),
        const SizedBox(width: 10),
        Expanded(
            child: _tripActionButton(
                label: deliveryUploaded && recipientVerified
                    ? 'Complete trip'
                    : 'Finish proof',
                icon: deliveryUploaded && recipientVerified
                    ? Icons.check_rounded
                    : Icons.camera_alt_outlined,
                backgroundColor: _blue,
                onPressed: () async {
                  if (tripCompleting) return;
                  if (!deliveryUploaded) {
                    await _pick('delivery');
                  } else if (!recipientVerified) {
                    _toast(context, 'Verify recipient OTP to complete');
                  } else {
                    setState(() => tripCompleting = true);
                    try {
                      await sl<DriverRemoteDatasource>().endTrip(widget.tripId);
                      if (mounted) _done(context);
                    } catch (_) {
                      if (mounted) {
                        setState(() => tripCompleting = false);
                        _toast(context,
                            'Unable to complete trip. Check required proofs.');
                      }
                    }
                  }
                }))
      ]));

  Widget _tripActionButton({
    required String label,
    required IconData icon,
    required Color backgroundColor,
    required VoidCallback onPressed,
  }) =>
      SizedBox(
          height: 48,
          child: ElevatedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 18),
              label: Text(label, maxLines: 1, overflow: TextOverflow.fade),
              style: ButtonStyle(
                elevation: const WidgetStatePropertyAll(0),
                backgroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.pressed)) {
                    return Color.alphaBlend(
                        Colors.black.withValues(alpha: .12), backgroundColor);
                  }
                  return backgroundColor;
                }),
                foregroundColor: const WidgetStatePropertyAll(Colors.white),
                overlayColor: const WidgetStatePropertyAll(Color(0x18FFFFFF)),
                padding: const WidgetStatePropertyAll(
                    EdgeInsets.symmetric(horizontal: 12)),
                minimumSize: const WidgetStatePropertyAll(Size(0, 48)),
                maximumSize:
                    const WidgetStatePropertyAll(Size(double.infinity, 48)),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: WidgetStatePropertyAll(RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13))),
                textStyle: const WidgetStatePropertyAll(TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w700)),
              )));
}

class DeliveryOtpPage extends StatefulWidget {
  const DeliveryOtpPage({super.key});
  @override
  State<DeliveryOtpPage> createState() => _DeliveryOtpPageState();
}

class _DeliveryOtpPageState extends State<DeliveryOtpPage> {
  final controller = TextEditingController();
  bool invalid = false;
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.white,
        appBar: _appBar('Verify delivery', back: true),
        body: SafeArea(
            child: Padding(
          padding: const EdgeInsets.all(20),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                    color: const Color(0xFFEAF2FF),
                    borderRadius: BorderRadius.circular(16)),
                child: const Icon(Icons.verified_user_outlined,
                    color: _blue, size: 27)),
            const SizedBox(height: 22),
            const Text('Enter recipient OTP',
                style: TextStyle(
                    color: _ink, fontSize: 24, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            const Text(
                'Ask Rakesh Verma for the 4-digit code sent to +91 98••• 2041.',
                style: TextStyle(color: _muted, fontSize: 13, height: 1.45)),
            const SizedBox(height: 24),
            TextField(
                controller: controller,
                autofocus: true,
                keyboardType: TextInputType.number,
                maxLength: 4,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 14),
                decoration: InputDecoration(
                    counterText: '',
                    hintText: '••••',
                    errorText: invalid ? 'Enter the 4-digit OTP' : null,
                    filled: true,
                    fillColor: _surface,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none))),
            const SizedBox(height: 12),
            Row(children: [
              const Icon(Icons.info_outline, size: 16, color: _muted),
              const SizedBox(width: 7),
              const Expanded(
                  child: Text(
                      'OTP confirms that the correct person received the order.',
                      style: TextStyle(color: _muted, fontSize: 11))),
              TextButton(
                  onPressed: () => _toast(context, 'OTP resent'),
                  child: const Text('Resend'))
            ]),
            const Spacer(),
            SizedBox(
                width: double.infinity,
                child: _primaryButton(
                    'Verify & confirm delivery', Icons.arrow_forward_rounded,
                    () {
                  if (controller.text.length != 4) {
                    setState(() => invalid = true);
                  } else {
                    Navigator.pop(context, true);
                  }
                })),
          ]),
        )),
      );
}

class DriverReportPage extends StatelessWidget {
  const DriverReportPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: _surface,
      appBar: _appBar('Daily work report', back: true),
      body: ListView(padding: const EdgeInsets.all(18), children: [
        const _SummaryStrip(),
        const SizedBox(height: 14),
        const Row(children: [
          Expanded(
              child: _MetricCard(
                  icon: Icons.route_outlined,
                  value: '86.4',
                  unit: 'km',
                  label: 'Distance')),
          SizedBox(width: 10),
          Expanded(
              child: _MetricCard(
                  icon: Icons.schedule_outlined,
                  value: '6h 18m',
                  unit: '',
                  label: 'Active time'))
        ]),
        const SizedBox(height: 14),
        const _Card(
            child: Column(children: [
          _InfoRow(
              icon: Icons.play_circle_outline,
              label: 'Day started',
              value: '6:42 AM'),
          _Divider(),
          _InfoRow(
              icon: Icons.pause_circle_outline,
              label: 'Paused time',
              value: '32 min'),
          _Divider(),
          _InfoRow(
              icon: Icons.hourglass_bottom_rounded,
              label: 'Stationary time',
              value: '48 min'),
          _Divider(),
          _InfoRow(
              icon: Icons.speed_outlined,
              label: 'Average speed',
              value: '31 km/h')
        ])),
        const SizedBox(height: 18),
        const _SectionTitle(title: 'Trip activity'),
        const SizedBox(height: 10),
        const _TripTile(
            status: 'Delivered',
            id: 'TRP-2043',
            route: 'Alambagh → Hazratganj',
            time: '8:50 AM · 24.2 km',
            color: _green),
        const _TripTile(
            status: 'Delivered',
            id: 'TRP-2039',
            route: 'Transport Nagar → Indira Nagar',
            time: '7:15 AM · 31.6 km',
            color: _green),
      ]));
}

class DriverDocumentPage extends StatelessWidget {
  const DriverDocumentPage(
      {super.key, required this.title, required this.number});
  final String title, number;
  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: _surface,
      appBar: _appBar(title, back: true),
      body: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(children: [
            Expanded(
                child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE0E3E7))),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            SvgPicture.asset('assets/images/moblogo-orders.svg',
                                width: 42),
                            const Spacer(),
                            Text(number,
                                style: const TextStyle(
                                    color: _ink, fontWeight: FontWeight.w700))
                          ]),
                          const Divider(height: 34),
                          Text(title.toUpperCase(),
                              style: const TextStyle(
                                  color: _ink,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800)),
                          const SizedBox(height: 18),
                          _InfoRow(
                              icon: Icons.inventory_2_outlined,
                              label: 'Order',
                              value: number),
                          const _Divider(),
                          const _InfoRow(
                              icon: Icons.local_shipping_outlined,
                              label: 'Vehicle',
                              value: 'Assigned vehicle'),
                          const _Divider(),
                          const _InfoRow(
                              icon: Icons.location_on_outlined,
                              label: 'Destination',
                              value: 'Gomti Nagar'),
                          const Spacer(),
                          const Center(
                              child: Text(
                                  'Sample document preview\nAPI PDF will render here',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: _muted, height: 1.5)))
                        ]))),
            const SizedBox(height: 12),
            SizedBox(
                width: double.infinity,
                child: _primaryButton('Download PDF', Icons.download_rounded,
                    () => _toast(context, '$title downloaded')))
          ])));
}

class DriverNotificationsPage extends StatelessWidget {
  const DriverNotificationsPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: _surface,
      appBar: _appBar('Notifications', back: true),
      body: ListView(padding: const EdgeInsets.all(18), children: const [
        _NotificationTile(
            icon: Icons.route_outlined,
            title: 'Route updated',
            detail: 'Delivery location changed by operations.',
            time: '2 min'),
        _NotificationTile(
            icon: Icons.local_shipping_outlined,
            title: 'Next trip assigned',
            detail: 'TRP-2054 is expected to start at 12:40 PM.',
            time: '18 min'),
        _NotificationTile(
            icon: Icons.warning_amber_rounded,
            title: 'Stationary alert cleared',
            detail: 'Movement resumed after 12 minutes.',
            time: '1 hr'),
      ]));
}

class DriverEmergencyPage extends StatelessWidget {
  const DriverEmergencyPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: _surface,
      appBar: _appBar('Emergency help', back: true),
      body: ListView(padding: const EdgeInsets.all(18), children: [
        Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
                color: const Color(0xFFFFF0EE),
                borderRadius: BorderRadius.circular(18)),
            child: const Row(children: [
              Icon(Icons.sos_rounded, color: Color(0xFFD94D3D), size: 34),
              SizedBox(width: 14),
              Expanded(
                  child: Text(
                      'Use emergency help only when immediate support is required.',
                      style: TextStyle(
                          color: _ink,
                          fontWeight: FontWeight.w700,
                          height: 1.4)))
            ])),
        const SizedBox(height: 14),
        _EmergencyAction(
            icon: Icons.support_agent_rounded,
            title: 'Call operations',
            subtitle: '24×7 driver support',
            onTap: () => _toast(context, 'Calling operations…')),
        _EmergencyAction(
            icon: Icons.local_police_outlined,
            title: 'Police / penalty support',
            subtitle: 'Share location and incident details',
            onTap: () => showModalBottomSheet(
                context: context, builder: (_) => const IssueSheet())),
        _EmergencyAction(
            icon: Icons.car_crash_outlined,
            title: 'Accident or breakdown',
            subtitle: 'Notify fleet team immediately',
            onTap: () => showModalBottomSheet(
                context: context, builder: (_) => const IssueSheet())),
      ]));
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile(
      {required this.icon,
      required this.title,
      required this.detail,
      required this.time});
  final IconData icon;
  final String title, detail, time;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _Card(
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
                color: const Color(0xFFEAF2FF),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: _blue)),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: const TextStyle(color: _ink, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(detail,
              style: const TextStyle(color: _muted, fontSize: 11, height: 1.35))
        ])),
        Text(time, style: const TextStyle(color: _muted, fontSize: 10))
      ])));
}

class _EmergencyAction extends StatelessWidget {
  const _EmergencyAction(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.onTap});
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _Card(
          child: ListTile(
              contentPadding: EdgeInsets.zero,
              onTap: onTap,
              leading: CircleAvatar(
                  backgroundColor: const Color(0xFFEAF2FF),
                  child: Icon(icon, color: _blue)),
              title: Text(title,
                  style: const TextStyle(
                      color: _ink, fontWeight: FontWeight.w700)),
              subtitle: Text(subtitle,
                  style: const TextStyle(color: _muted, fontSize: 11)),
              trailing: const Icon(Icons.chevron_right_rounded))));
}

class IssueSheet extends StatefulWidget {
  const IssueSheet({super.key, this.tripId});
  final int? tripId;
  @override
  State<IssueSheet> createState() => _IssueSheetState();
}

class _IssueSheetState extends State<IssueSheet> {
  String selected = 'Traffic delay';
  final items = const [
    'Pickup issue',
    'Traffic delay',
    'Vehicle breakdown',
    'Unloading issue',
    'Traffic police penalty',
    'Delivery issue'
  ];
  @override
  Widget build(BuildContext context) => SafeArea(
      child: SingleChildScrollView(
          padding:
              EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
          child: Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                        width: 38,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 18),
                        decoration: BoxDecoration(
                            color: const Color(0xFFD4DCE4),
                            borderRadius: BorderRadius.circular(5))),
                    const Text('Report an issue',
                        style: TextStyle(
                            color: _ink,
                            fontWeight: FontWeight.w800,
                            fontSize: 21)),
                    const SizedBox(height: 6),
                    const Text(
                        'Your operations team will be notified immediately.',
                        style: TextStyle(color: _muted, fontSize: 13)),
                    const SizedBox(height: 16),
                    Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: items
                            .map((e) => ChoiceChip(
                                label: Text(e),
                                selected: selected == e,
                                selectedColor: const Color(0xFFE5EFFF),
                                labelStyle: TextStyle(
                                    color: selected == e ? _blue : _ink,
                                    fontWeight: FontWeight.w600),
                                onSelected: (_) =>
                                    setState(() => selected = e)))
                            .toList()),
                    const SizedBox(height: 14),
                    TextField(
                        maxLines: 3,
                        decoration: InputDecoration(
                            hintText: 'Add details for the operations team…',
                            filled: true,
                            fillColor: _surface,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(13),
                                borderSide: BorderSide.none))),
                    const SizedBox(height: 14),
                    SizedBox(
                        width: double.infinity,
                        child: _primaryButton('Send report', Icons.send_rounded,
                            () {
                          Navigator.pop(context);
                          _toast(context, 'Issue reported to operations');
                        }))
                  ]))));
}

// Reusable driver UI
class _Card extends StatelessWidget {
  const _Card({required this.child, this.padding = const EdgeInsets.all(16)});
  final Widget child;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => Container(
      padding: padding,
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE7ECF1)),
          boxShadow: const [
            BoxShadow(
                color: Color(0x080F2942), blurRadius: 18, offset: Offset(0, 5))
          ]),
      child: child);
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.action, this.onAction});
  final String title;
  final String? action;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(
            child: Text(title,
                style: const TextStyle(
                    color: _ink, fontSize: 16, fontWeight: FontWeight.w800))),
        if (action != null)
          TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  minimumSize: const Size(0, 32)),
              child: Text(action!,
                  style: const TextStyle(
                      color: _blue, fontSize: 12, fontWeight: FontWeight.w700)))
      ]);
}

class _DashboardLoadingCard extends StatelessWidget {
  const _DashboardLoadingCard();
  @override
  Widget build(BuildContext context) => const _Card(
      child: SizedBox(
          height: 110,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2.5))));
}

class _DashboardErrorCard extends StatelessWidget {
  const _DashboardErrorCard({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => _Card(
          child: Row(children: [
        const Icon(Icons.cloud_off_outlined, color: _muted),
        const SizedBox(width: 12),
        Expanded(
            child: Text(message,
                style: const TextStyle(color: _ink, fontSize: 12))),
        TextButton(onPressed: onRetry, child: const Text('Retry'))
      ]));
}

class _TodayProgressCard extends StatelessWidget {
  const _TodayProgressCard({required this.onTap, this.progress = const {}});
  final VoidCallback onTap;
  final Map<String, dynamic> progress;

  double _number(String key, double fallback) =>
      double.tryParse(progress[key]?.toString() ?? '') ?? fallback;
  String get _activeTime {
    final minutes = (_number('active_hours', 6.3) * 60).round();
    return '${minutes ~/ 60}h ${minutes % 60}m';
  }

  @override
  Widget build(BuildContext context) => _Card(
      padding: EdgeInsets.zero,
      child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Expanded(
                          child: Text("Today's progress",
                              style: TextStyle(
                                  color: _ink,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800))),
                      Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 5),
                          decoration: BoxDecoration(
                              color: const Color(0xFFEAF8F2),
                              borderRadius: BorderRadius.circular(20)),
                          child: const Row(children: [
                            Icon(Icons.trending_up_rounded,
                                color: _green, size: 14),
                            SizedBox(width: 4),
                            Text('On track',
                                style: TextStyle(
                                    color: _green,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700))
                          ]))
                    ]),
                    const SizedBox(height: 17),
                    Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text(_number('distance_km', 86.4).toStringAsFixed(1),
                          style: const TextStyle(
                              color: _ink,
                              fontSize: 30,
                              height: 1,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -.8)),
                      const SizedBox(width: 5),
                      const Padding(
                          padding: EdgeInsets.only(bottom: 3),
                          child: Text('km today',
                              style: TextStyle(
                                  color: _muted,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600))),
                      const Spacer(),
                      const Icon(Icons.chevron_right_rounded, color: _muted)
                    ]),
                    const SizedBox(height: 13),
                    ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: LinearProgressIndicator(
                            value: (_number('completion_percentage', 72) / 100)
                                .clamp(0, 1),
                            minHeight: 6,
                            backgroundColor: Color(0xFFE7ECF1),
                            valueColor:
                                const AlwaysStoppedAnimation<Color>(_blue))),
                    const SizedBox(height: 8),
                    Row(children: [
                      Text(
                          'Daily target ${_number('daily_target_km', 120).toStringAsFixed(0)} km',
                          style: const TextStyle(color: _muted, fontSize: 10)),
                      const Spacer(),
                      Text(
                          '${_number('completion_percentage', 72).toStringAsFixed(0)}%',
                          style: const TextStyle(
                              color: _blue,
                              fontSize: 10,
                              fontWeight: FontWeight.w700))
                    ]),
                    const Divider(height: 25, color: Color(0xFFE9EDF2)),
                    Row(children: [
                      Expanded(
                          child: _CompactStat(
                              icon: Icons.schedule_outlined,
                              value: _activeTime,
                              label: 'Active')),
                      const SizedBox(
                          height: 30,
                          child: VerticalDivider(color: Color(0xFFE2E8EF))),
                      Expanded(
                          child: _CompactStat(
                              icon: Icons.pause_circle_outline_rounded,
                              value:
                                  '${_number('break_minutes', 32).round()} min',
                              label: 'Breaks')),
                      const SizedBox(
                          height: 30,
                          child: VerticalDivider(color: Color(0xFFE2E8EF))),
                      Expanded(
                          child: _CompactStat(
                              icon: Icons.task_alt_rounded,
                              value:
                                  '${_number('completed_trip_count', 3).round()} of ${_number('total_trip_count', 4).round()}',
                              label: 'Trips'))
                    ])
                  ]))));
}

class _CompactStat extends StatelessWidget {
  const _CompactStat(
      {required this.icon, required this.value, required this.label});
  final IconData icon;
  final String value, label;
  @override
  Widget build(BuildContext context) => Column(children: [
        Icon(icon, color: _blue, size: 17),
        const SizedBox(height: 6),
        Text(value,
            style: const TextStyle(
                color: _ink, fontSize: 12, fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: _muted, fontSize: 9))
      ]);
}

class _MetricCard extends StatelessWidget {
  const _MetricCard(
      {required this.icon,
      required this.value,
      required this.unit,
      required this.label});
  final IconData icon;
  final String value, unit, label;
  @override
  Widget build(BuildContext context) => _Card(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: _blue, size: 21),
        const SizedBox(height: 14),
        RichText(
            text: TextSpan(style: const TextStyle(color: _ink), children: [
          TextSpan(
              text: value,
              style:
                  const TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
          TextSpan(
              text: unit.isEmpty ? '' : ' $unit',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700))
        ])),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: _muted, fontSize: 12))
      ]));
}

class _FuelStatusCard extends StatelessWidget {
  const _FuelStatusCard({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: const _Card(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.local_gas_station_outlined, color: _blue, size: 21),
        SizedBox(height: 14),
        Text('Not logged',
            style: TextStyle(
                color: _ink, fontSize: 16, fontWeight: FontWeight.w800)),
        SizedBox(height: 6),
        Text('Update fuel level',
            style: TextStyle(
                color: _blue, fontSize: 11, fontWeight: FontWeight.w700))
      ])));
}

class _RoutePoint extends StatelessWidget {
  const _RoutePoint(
      {required this.color, required this.title, required this.subtitle});
  final Color color;
  final String title, subtitle;
  @override
  Widget build(BuildContext context) =>
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
            width: 13,
            height: 13,
            margin: const EdgeInsets.only(top: 3),
            decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 4))),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: const TextStyle(
                  color: _ink, fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 3),
          Text(subtitle, style: const TextStyle(color: _muted, fontSize: 11))
        ]))
      ]);
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.color});
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle));
}

class _AlertCard extends StatelessWidget {
  const _AlertCard();
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
          color: const Color(0xFFFFF7E8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFFE4B2))),
      child: const Row(children: [
        Icon(Icons.info_outline_rounded, color: Color(0xFFD88212)),
        SizedBox(width: 11),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Smart route monitoring is on',
              style: TextStyle(
                  color: _ink, fontWeight: FontWeight.w700, fontSize: 13)),
          SizedBox(height: 3),
          Text(
              'Operations will be alerted for wrong direction or unusual stationary time.',
              style: TextStyle(color: _muted, fontSize: 11, height: 1.35))
        ]))
      ]));
}

class _QuickAction extends StatelessWidget {
  const _QuickAction(
      {required this.icon,
      required this.color,
      required this.label,
      required this.onTap});
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: _Card(
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 8),
          child: Column(children: [
            Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                    color: color.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color, size: 21)),
            const SizedBox(height: 9),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: _ink, fontWeight: FontWeight.w700, fontSize: 11))
          ])));
}

class _TripTile extends StatelessWidget {
  const _TripTile(
      {required this.status,
      required this.id,
      required this.route,
      required this.time,
      required this.color,
      this.onTap});
  final String status, id, route, time;
  final Color color;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _Card(
          child: InkWell(
              onTap: onTap,
              child: Row(children: [
                Container(
                    width: 43,
                    height: 43,
                    decoration: BoxDecoration(
                        color: color.withValues(alpha: .1),
                        borderRadius: BorderRadius.circular(13)),
                    child: Icon(Icons.local_shipping_outlined, color: color)),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Row(children: [
                        Text(id,
                            style: const TextStyle(
                                color: _ink,
                                fontWeight: FontWeight.w800,
                                fontSize: 13)),
                        const SizedBox(width: 7),
                        _Pill(text: status.toUpperCase(), color: color)
                      ]),
                      const SizedBox(height: 6),
                      Text(route,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: _ink,
                              fontWeight: FontWeight.w600,
                              fontSize: 12)),
                      const SizedBox(height: 3),
                      Text(time,
                          style: const TextStyle(color: _muted, fontSize: 11))
                    ])),
                const Icon(Icons.chevron_right_rounded, color: _muted)
              ]))));
}

class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({this.trips = 4, this.delivered = 3, this.active = 1});
  final int trips;
  final int delivered;
  final int active;

  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(vertical: 17),
      decoration:
          BoxDecoration(color: _ink, borderRadius: BorderRadius.circular(18)),
      child: Row(children: [
        Expanded(child: _MiniStat(value: '$trips', label: 'Trips')),
        const _VLine(),
        Expanded(child: _MiniStat(value: '$delivered', label: 'Delivered')),
        const _VLine(),
        Expanded(child: _MiniStat(value: '$active', label: 'Active'))
      ]));
}

class _DriverLoadError extends StatelessWidget {
  const _DriverLoadError({required this.message, required this.onRetry});
  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.cloud_off_rounded, color: _muted, size: 42),
        const SizedBox(height: 12),
        Text(message, style: const TextStyle(color: _muted)),
        const SizedBox(height: 8),
        TextButton(onPressed: onRetry, child: const Text('Retry'))
      ]));
}

class _DriverEmptyState extends StatelessWidget {
  const _DriverEmptyState(
      {required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.all(28),
      child: Column(children: [
        Icon(icon, color: _muted, size: 44),
        const SizedBox(height: 12),
        Text(title,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: _ink, fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(height: 5),
        Text(subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _muted, fontSize: 12))
      ]));
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.value, required this.label});
  final String value, label;
  @override
  Widget build(BuildContext context) => Column(children: [
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 3),
        Text(label,
            style: const TextStyle(color: Color(0xFFB9C8D8), fontSize: 11))
      ]);
}

class _VLine extends StatelessWidget {
  const _VLine();
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 28, color: Colors.white24);
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.color});
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: color.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(20)),
      child: Text(text,
          style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: .3)));
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(
      {required this.icon,
      required this.label,
      required this.value,
      this.valueColor});
  final IconData icon;
  final String label, value;
  final Color? valueColor;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Icon(icon, color: _muted, size: 20),
        const SizedBox(width: 12),
        Expanded(
            child: Text(label,
                style: const TextStyle(color: _muted, fontSize: 13))),
        Text(value,
            style: TextStyle(
                color: valueColor ?? _ink,
                fontWeight: FontWeight.w700,
                fontSize: 12))
      ]));
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) =>
      const Divider(height: 25, color: Color(0xFFE9EDF2));
}

class _DocumentTile extends StatelessWidget {
  const _DocumentTile(
      {required this.icon,
      required this.title,
      required this.detail,
      required this.verified});
  final IconData icon;
  final String title, detail;
  final bool verified;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _Card(
          child: Row(children: [
        Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
                color: const Color(0xFFEAF2FF),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: _blue)),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: const TextStyle(
                  color: _ink, fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 4),
          Text(detail, style: const TextStyle(color: _muted, fontSize: 11))
        ])),
        Icon(verified ? Icons.check_circle_rounded : Icons.error_outline,
            color: verified ? _green : Colors.orange, size: 20)
      ])));
}

class _MenuRow extends StatelessWidget {
  const _MenuRow(
      {required this.icon,
      required this.text,
      this.danger = false,
      this.onTap});
  final IconData icon;
  final String text;
  final bool danger;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(children: [
            Icon(icon,
                color: danger ? const Color(0xFFD94D3D) : _muted, size: 20),
            const SizedBox(width: 12),
            Expanded(
                child: Text(text,
                    style: TextStyle(
                        color: danger ? const Color(0xFFD94D3D) : _ink,
                        fontWeight: FontWeight.w600,
                        fontSize: 13))),
            const Icon(Icons.chevron_right_rounded, color: _muted, size: 20)
          ])));
}

class _ProofRow extends StatelessWidget {
  const _ProofRow(
      {required this.title,
      required this.uploaded,
      required this.onTap,
      this.subtitle});
  final String title;
  final String? subtitle;
  final bool uploaded;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(uploaded ? Icons.check_circle_rounded : Icons.camera_alt_outlined,
            color: uploaded ? _green : _muted),
        const SizedBox(width: 10),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: const TextStyle(
                  color: _ink, fontWeight: FontWeight.w700, fontSize: 13)),
          if (subtitle != null) ...[
            const SizedBox(height: 3),
            Text(subtitle!, style: const TextStyle(color: _muted, fontSize: 10))
          ]
        ])),
        TextButton(
            onPressed: onTap, child: Text(uploaded ? 'Retake' : 'Upload'))
      ]);
}

class _OrderItem extends StatelessWidget {
  const _OrderItem(
      {required this.name,
      required this.quantity,
      required this.detail,
      this.imageUrl = ''});
  final String name;
  final String quantity;
  final String detail;
  final String imageUrl;
  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: const Color(0xFFEAF2FF),
                borderRadius: BorderRadius.circular(11)),
            clipBehavior: Clip.antiAlias,
            child: imageUrl.isEmpty
                ? const Icon(Icons.inventory_2_outlined, color: _blue, size: 20)
                : CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => const Center(
                        child: SizedBox.square(
                            dimension: 15,
                            child: CircularProgressIndicator(strokeWidth: 2))),
                    errorWidget: (_, __, ___) => const Icon(
                        Icons.inventory_2_outlined,
                        color: _blue,
                        size: 20))),
        const SizedBox(width: 11),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name,
              style: const TextStyle(
                  color: _ink, fontWeight: FontWeight.w700, fontSize: 12)),
          const SizedBox(height: 3),
          Text(detail, style: const TextStyle(color: _muted, fontSize: 10))
        ])),
        Text(quantity,
            style: const TextStyle(
                color: _ink, fontWeight: FontWeight.w800, fontSize: 11))
      ]);
}

class _DownloadRow extends StatelessWidget {
  const _DownloadRow(
      {required this.icon,
      required this.title,
      required this.detail,
      required this.onTap});
  final IconData icon;
  final String title;
  final String detail;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: const Color(0xFFF1F4F8),
                borderRadius: BorderRadius.circular(11)),
            child: Icon(icon, color: _ink, size: 20)),
        const SizedBox(width: 11),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: const TextStyle(
                  color: _ink, fontWeight: FontWeight.w700, fontSize: 12)),
          const SizedBox(height: 3),
          Text(detail, style: const TextStyle(color: _muted, fontSize: 10))
        ])),
        IconButton(
            tooltip: 'Download',
            onPressed: onTap,
            icon: const Icon(Icons.download_rounded, color: _blue))
      ]);
}

class _TripMapUnavailable extends StatelessWidget {
  const _TripMapUnavailable();

  @override
  Widget build(BuildContext context) => const ColoredBox(
      color: Color(0xFFDDE9E6),
      child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.map_outlined, color: _muted, size: 34),
        SizedBox(height: 8),
        Text('Route coordinates are unavailable',
            style: TextStyle(
                color: _muted, fontSize: 12, fontWeight: FontWeight.w600))
      ])));
}

PreferredSizeWidget _appBar(String title, {bool back = false}) => AppBar(
    backgroundColor: Colors.white,
    elevation: 0,
    centerTitle: false,
    automaticallyImplyLeading: back,
    iconTheme: const IconThemeData(color: _ink),
    title: Text(title,
        style: const TextStyle(
            color: _ink, fontWeight: FontWeight.w800, fontSize: 20)));
Widget _iconButton(IconData icon, {VoidCallback? onTap}) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(13),
    child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
            color: const Color(0xFFF1F4F8),
            borderRadius: BorderRadius.circular(13)),
        child: Icon(icon, color: _ink)));
Widget _primaryButton(String text, IconData icon, VoidCallback onPressed) =>
    SizedBox(
        height: 48,
        child: ElevatedButton.icon(
            onPressed: onPressed,
            icon: Icon(icon, size: 18),
            label: Text(text),
            style: ElevatedButton.styleFrom(
                backgroundColor: _blue,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13)),
                textStyle: const TextStyle(fontWeight: FontWeight.w700))));
ButtonStyle _outlineStyle() => OutlinedButton.styleFrom(
    foregroundColor: _ink,
    padding: const EdgeInsets.symmetric(vertical: 14),
    side: const BorderSide(color: Color(0xFFD5DEE7)),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)));
void _toast(BuildContext context, String text) =>
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(text), behavior: SnackBarBehavior.floating));
void _done(BuildContext context) {
  PushNotificationService.instance.hideOngoingTrip();
  _toast(context, 'Trip completed successfully');
  Navigator.pop(context);
}

void _showEndDay(BuildContext context) => showModalBottomSheet(
    context: context,
    builder: (ctx) => SafeArea(
        child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('End your day',
                      style: TextStyle(
                          color: _ink,
                          fontSize: 21,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 10),
                  const Text(
                      'Complete active trips, park at the assigned point, upload the final odometer photo, then switch tracking off.',
                      style: TextStyle(color: _muted, height: 1.45)),
                  const SizedBox(height: 18),
                  SizedBox(
                      width: double.infinity,
                      child: _primaryButton('Upload odometer & end day',
                          Icons.camera_alt_outlined, () {
                        PushNotificationService.instance.hideOngoingTrip();
                        Navigator.pop(ctx);
                      }))
                ]))));

void _showFuelUpdate(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => SafeArea(
        child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                      color: const Color(0xFFD4DCE4),
                      borderRadius: BorderRadius.circular(4))),
              const SizedBox(height: 18),
              const Row(children: [
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text('Update fuel level',
                          style: TextStyle(
                              color: _ink,
                              fontSize: 20,
                              fontWeight: FontWeight.w800)),
                      SizedBox(height: 5),
                      Text(
                          'Manual estimate until a supported vehicle fuel sensor is connected.',
                          style: TextStyle(
                              color: _muted, fontSize: 11, height: 1.4))
                    ]))
              ]),
              const SizedBox(height: 16),
              Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ['Empty', '¼ tank', '½ tank', '¾ tank', 'Full']
                      .map((level) => ActionChip(
                          backgroundColor: const Color(0xFFF1F4F8),
                          side: BorderSide.none,
                          label: Text(level),
                          onPressed: () {
                            Navigator.pop(sheetContext);
                            _toast(context, 'Fuel level saved: $level');
                          }))
                      .toList()),
              const SizedBox(height: 14),
              TextField(
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                      labelText: 'Odometer reading (km)',
                      hintText: 'e.g. 48,260',
                      filled: true,
                      fillColor: _surface,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(13),
                          borderSide: BorderSide.none))),
            ]))));
