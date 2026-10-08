import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:mob_driver/features/driver/data/realtime/driver_realtime.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// One scripted server connection: what the app sent, and buttons for what
/// the server does next.
class FakeSocket implements WebSocketChannel {
  final _incoming = StreamController<dynamic>();
  final List<Map<String, dynamic>> sent = [];
  bool closedByApp = false;
  int? _closeCode;

  late final WebSocketSink _sink = _FakeSink(this);

  void serverSends(Map<String, Object?> message) =>
      _incoming.add(jsonEncode(message));

  Future<void> serverCloses([int? code]) async {
    _closeCode = code;
    await _incoming.close();
  }

  Iterable<Map<String, dynamic>> sentOfType(String type) =>
      sent.where((m) => m['type'] == type);

  @override
  Future<void> get ready => Future.value();

  @override
  Stream<dynamic> get stream => _incoming.stream;

  @override
  WebSocketSink get sink => _sink;

  @override
  int? get closeCode => _closeCode;

  @override
  String? get closeReason => null;

  @override
  String? get protocol => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeSink implements WebSocketSink {
  _FakeSink(this._socket);
  final FakeSocket _socket;

  @override
  void add(dynamic data) => _socket.sent
      .add(Map<String, dynamic>.from(jsonDecode(data as String) as Map));

  @override
  Future<void> close([int? closeCode, String? closeReason]) async {
    _socket.closedByApp = true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A [DriverRealtime] whose every (re)connect opens a fresh [FakeSocket],
/// with timings shrunk so tests don't wait real seconds.
class RealtimeRig {
  RealtimeRig({
    Duration heartbeat = const Duration(hours: 1),
    Duration pongTimeout = const Duration(milliseconds: 30),
  }) {
    realtime = DriverRealtime(
      url: Uri.parse('ws://test/ws/driver/'),
      accessToken: () => token,
      refreshToken: () async {
        refreshes++;
        token = refreshedToken;
        return token;
      },
      connect: (_) {
        final socket = FakeSocket();
        sockets.add(socket);
        return socket;
      },
      heartbeat: heartbeat,
      pongTimeout: pongTimeout,
      maxBackoff: const Duration(milliseconds: 20),
      random: math.Random(1),
    );
  }

  late final DriverRealtime realtime;
  final List<FakeSocket> sockets = [];
  String? token = 'token-1';
  String? refreshedToken = 'token-2';
  int refreshes = 0;

  FakeSocket get socket => sockets.last;

  /// Starts and completes the auth handshake on the first socket.
  Future<FakeSocket> goLive() async {
    realtime.start();
    await settle();
    socket.serverSends({'type': 'ready'});
    await settle();
    return socket;
  }

  static Future<void> settle([int ms = 10]) =>
      Future<void>.delayed(Duration(milliseconds: ms));
}
