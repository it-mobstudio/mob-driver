import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show ValueListenable, ValueNotifier;
import 'package:mob_driver/features/driver/domain/entities/demand_hint.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Whether the server can reach this phone right now.
enum RealtimeStatus {
  /// Not started, or stopped (signed out).
  off,

  /// Connecting, authenticating, or waiting to retry.
  connecting,

  /// Authenticated: pushes arrive as they happen.
  live,
}

/// Something the server pushed. A push is a nudge to re-read over REST,
/// never the data itself (see the backend's realtime/publish.py).
sealed class RealtimePush {
  const RealtimePush();
}

/// A trip of this driver's changed — assigned, cancelled, paid, moved to
/// another driver… [event] is the backend's event name (`trip.assigned`).
final class TripChanged extends RealtimePush {
  const TripChanged({required this.tripId, required this.event});
  final String tripId;
  final String event;
}

/// The driver's own profile changed on the company's side (documents
/// verified or sent back, account locked).
final class ProfileChanged extends RealtimePush {
  const ProfileChanged();
}

/// Where the orders are — sent by the company or its demand forecasting.
final class HintReceived extends RealtimePush {
  const HintReceived(this.hint);
  final DemandHint hint;
}

typedef SocketConnector = WebSocketChannel Function(Uri url);

/// The driver app's one live connection to the backend (`/ws/driver/`),
/// replacing polling: instead of every phone asking "anything new?" every
/// few seconds, the server says so when there is. Also carries location
/// updates while it's up — one open socket instead of an HTTP request (and
/// a token check) per ping.
///
/// Keeps itself connected: reconnects with jittered exponential backoff
/// (so a server restart isn't met by every driver at the same instant),
/// detects a dead connection with an app-level ping, and on an auth refusal
/// refreshes the token once before trying again.
class DriverRealtime {
  DriverRealtime({
    required this.url,
    required this.accessToken,
    required this.refreshToken,
    SocketConnector? connect,
    this.heartbeat = const Duration(seconds: 25),
    this.pongTimeout = const Duration(seconds: 10),
    this.maxBackoff = const Duration(seconds: 30),
    math.Random? random,
  })  : _connector = connect ?? WebSocketChannel.connect,
        _random = random ?? math.Random();

  final Uri url;

  /// The current access token (null when signed out).
  final String? Function() accessToken;

  /// Gets a fresh access token after the server refused this one; null when
  /// there's none to be had. May throw on a network error.
  final Future<String?> Function() refreshToken;

  final Duration heartbeat;
  final Duration pongTimeout;
  final Duration maxBackoff;

  final SocketConnector _connector;
  final math.Random _random;

  /// Close code the server uses for a missing, bad or expired token.
  static const closeUnauthorized = 4401;

  final _status = ValueNotifier<RealtimeStatus>(RealtimeStatus.off);
  ValueListenable<RealtimeStatus> get status => _status;
  bool get isLive => _status.value == RealtimeStatus.live;

  final _pushes = StreamController<RealtimePush>.broadcast();
  Stream<RealtimePush> get pushes => _pushes.stream;

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _sub;
  Timer? _retryTimer;
  Timer? _pingTimer;
  Timer? _pongTimer;
  int _failures = 0;
  bool _running = false;
  bool _refreshedForThisFailure = false;

  /// Bumped on every (re)connect and on stop, so callbacks from an old
  /// socket can't act on the new one.
  int _generation = 0;

  /// Connects (if not already) and stays connected until [stop].
  void start() {
    if (_running) return;
    _running = true;
    _failures = 0;
    unawaited(_connect());
  }

  void stop() {
    _running = false;
    _generation++;
    _teardown();
    _retryTimer?.cancel();
    _retryTimer = null;
    _status.value = RealtimeStatus.off;
  }

  /// Reconnects now rather than at the next backoff step — e.g. the app came
  /// back to the foreground, where the OS may have silently cut the socket.
  void reconnectNow() {
    if (!_running || isLive) return;
    _retryTimer?.cancel();
    _failures = 0;
    unawaited(_connect());
  }

  /// Sends one location fix if connected. False if not — the caller falls
  /// back to the REST endpoint.
  bool sendLocation(double latitude, double longitude) =>
      _send({'type': 'location', 'lat': latitude, 'lng': longitude});

  bool _send(Map<String, Object?> message) {
    final channel = _channel;
    if (!isLive || channel == null) return false;
    try {
      channel.sink.add(jsonEncode(message));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _connect() async {
    _teardown();
    final generation = ++_generation;
    final token = accessToken();
    if (token == null || token.isEmpty) {
      _scheduleRetry(generation);
      return;
    }
    _status.value = RealtimeStatus.connecting;

    final WebSocketChannel channel;
    try {
      channel = _connector(url);
      await channel.ready;
    } catch (_) {
      if (generation == _generation) _scheduleRetry(generation);
      return;
    }
    if (generation != _generation) {
      unawaited(channel.sink.close());
      return;
    }
    _channel = channel;
    _sub = channel.stream.listen(
      (raw) => _onMessage(raw, generation),
      onDone: () => _onClosed(channel.closeCode, generation),
      onError: (Object _) => _onClosed(null, generation),
      cancelOnError: true,
    );
    channel.sink.add(jsonEncode({'type': 'auth', 'token': token}));
  }

  void _onMessage(dynamic raw, int generation) {
    if (generation != _generation) return;
    // Anything at all from the server proves the connection is alive.
    _pongTimer?.cancel();
    _pongTimer = null;

    final Object? decoded;
    try {
      decoded = raw is String ? jsonDecode(raw) : null;
    } catch (_) {
      return;
    }
    if (decoded is! Map) return;

    switch (decoded['type']) {
      case 'ready':
        _failures = 0;
        _refreshedForThisFailure = false;
        _status.value = RealtimeStatus.live;
        _startHeartbeat(generation);
      case 'trip.changed':
        final tripId = decoded['trip_id'];
        if (tripId is String) {
          _pushes.add(
              TripChanged(tripId: tripId, event: '${decoded['event'] ?? ''}'));
        }
      case 'driver.changed':
        _pushes.add(const ProfileChanged());
      case 'driver.hint':
        final message = decoded['message'];
        if (message is String && message.trim().isNotEmpty) {
          _pushes.add(HintReceived(DemandHint(
            message: message.trim(),
            latitude: (decoded['lat'] as num?)?.toDouble(),
            longitude: (decoded['lng'] as num?)?.toDouble(),
          )));
        }
      // 'pong' and anything newer than this app: nothing more to do.
    }
  }

  void _startHeartbeat(int generation) {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(heartbeat, (_) {
      if (generation != _generation) return;
      if (!_send({'type': 'ping'})) return;
      // No answer in time: the connection is dead even if the OS hasn't
      // noticed (common after switching networks).
      _pongTimer ??= Timer(pongTimeout, () {
        if (generation == _generation) _onClosed(null, generation);
      });
    });
  }

  Future<void> _onClosed(int? code, int generation) async {
    if (generation != _generation) return;
    _generation++;
    _teardown();
    if (!_running) return;

    if (code == closeUnauthorized && !_refreshedForThisFailure) {
      // The token expired (or was refused): renew it once, then go again
      // straight away. A second refusal backs off like any other failure.
      _refreshedForThisFailure = true;
      _status.value = RealtimeStatus.connecting;
      try {
        await refreshToken();
      } catch (_) {
        // Offline — the retry below copes.
      }
      if (!_running) return;
      unawaited(_connect());
      return;
    }
    _scheduleRetry(_generation);
  }

  void _scheduleRetry(int generation) {
    if (!_running) return;
    _status.value = RealtimeStatus.connecting;
    _retryTimer?.cancel();
    _retryTimer = Timer(nextBackoff(_failures++), () {
      if (_running) unawaited(_connect());
    });
  }

  /// 1s, 2s, 4s… capped at [maxBackoff], each randomised to between half
  /// and all of that — "full jitter" spreads a fleet's reconnects out.
  Duration nextBackoff(int failures) {
    final cap = maxBackoff.inMilliseconds;
    final base =
        math.min(cap, 1000 * math.pow(2, math.min(failures, 16)).toInt());
    final ms = base ~/ 2 + _random.nextInt(base ~/ 2 + 1);
    return Duration(milliseconds: ms);
  }

  void _teardown() {
    _pingTimer?.cancel();
    _pongTimer?.cancel();
    _pingTimer = null;
    _pongTimer = null;
    unawaited(_sub?.cancel());
    _sub = null;
    final channel = _channel;
    _channel = null;
    if (channel != null) unawaited(channel.sink.close().catchError((_) {}));
    if (_status.value == RealtimeStatus.live) {
      _status.value = RealtimeStatus.connecting;
    }
  }

  Future<void> dispose() async {
    stop();
    await _pushes.close();
    _status.dispose();
  }
}
