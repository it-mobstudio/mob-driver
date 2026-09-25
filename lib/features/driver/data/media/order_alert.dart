import 'dart:async';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:just_audio/just_audio.dart';
import 'package:vibration/vibration.dart';

/// The "an order has arrived" alarm: a chime on loop and strong, repeating
/// vibration bursts, until the driver answers the offer. An interface so the
/// offer screen can be tested without a speaker or a vibration motor.
abstract interface class OrderAlert {
  Future<void> start();
  Future<void> stop();
}

class DeviceOrderAlert implements OrderAlert {
  DeviceOrderAlert();

  // Long-short-long at full strength, then a breath — hard to miss in a
  // pocket or a phone mount, repeated for as long as the offer stands.
  static const _pattern = [0, 700, 250, 700, 250, 1000, 900];
  static const _intensities = [0, 255, 0, 255, 0, 255, 0];

  AudioPlayer? _player;
  Timer? _hapticFallback;
  bool _running = false;

  @override
  Future<void> start() async {
    if (_running) return;
    _running = true;
    await Future.wait([_startSound(), _startVibration()]);
  }

  Future<void> _startSound() async {
    try {
      final player = _player = AudioPlayer();
      await player.setAsset('assets/audios/new_order.m4a');
      await player.setLoopMode(LoopMode.one);
      await player.setVolume(1);
      if (_running) unawaited(player.play());
    } catch (e) {
      // No sound (web autoplay rules, no audio device) — the vibration and
      // the screen itself still announce the order.
      debugPrint('Order alert sound unavailable: $e');
    }
  }

  Future<void> _startVibration() async {
    try {
      if (await Vibration.hasVibrator()) {
        final strong = await Vibration.hasAmplitudeControl();
        await Vibration.vibrate(
          pattern: _pattern,
          intensities: strong ? _intensities : const [],
          repeat: 0,
        );
        return;
      }
    } catch (_) {
      // Fall through to the haptic engine below.
    }
    // No vibrator plugin (web, some iPhones' rules): heavy haptic taps.
    _hapticFallback = Timer.periodic(const Duration(milliseconds: 900), (_) {
      if (_running) HapticFeedback.heavyImpact();
    });
  }

  @override
  Future<void> stop() async {
    if (!_running) return;
    _running = false;
    _hapticFallback?.cancel();
    final player = _player;
    _player = null;
    try {
      await Vibration.cancel();
    } catch (_) {}
    try {
      await player?.stop();
      await player?.dispose();
    } catch (_) {}
  }
}
