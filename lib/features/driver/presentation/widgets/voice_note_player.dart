import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/driver_ui.dart';

/// The dispatcher's spoken note (≤ 30 s): a play/pause button with a
/// progress bar. The audio is only fetched on the first tap, so a screen
/// showing it costs nothing until the driver wants to listen.
class VoiceNotePlayer extends StatefulWidget {
  const VoiceNotePlayer({
    super.key,
    required this.url,
    this.seconds,
    this.compact = false,
  });

  final String url;

  /// Length as the server knows it, shown before the audio is loaded.
  final int? seconds;

  /// A slimmer pill for the trip panel.
  final bool compact;

  @override
  State<VoiceNotePlayer> createState() => _VoiceNotePlayerState();
}

class _VoiceNotePlayerState extends State<VoiceNotePlayer> {
  AudioPlayer? _player;
  final List<StreamSubscription<dynamic>> _subs = [];
  Duration _position = Duration.zero;
  Duration? _duration;
  bool _playing = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _player?.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_playing) {
      await _player?.pause();
      return;
    }
    setState(() {
      _error = null;
      _loading = _player == null;
    });
    try {
      var player = _player;
      if (player == null) {
        player = _player = AudioPlayer();
        _subs
          ..add(player.positionStream.listen((p) => mounted ? setState(() => _position = p) : null))
          ..add(player.durationStream.listen((d) => mounted ? setState(() => _duration = d) : null))
          ..add(player.playerStateStream.listen((s) {
            if (!mounted) return;
            final done = s.processingState == ProcessingState.completed;
            setState(() => _playing = s.playing && !done);
            if (done) {
              player!.pause();
              player.seek(Duration.zero);
            }
          }));
        await player.setUrl(widget.url);
      }
      if (mounted) setState(() => _loading = false);
      unawaited(player.play());
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Couldn’t play the voice note.';
        });
      }
    }
  }

  String _clock(Duration d) => '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final total = _duration ?? (widget.seconds != null ? Duration(seconds: widget.seconds!) : null);
    final progress = total == null || total.inMilliseconds == 0
        ? 0.0
        : (_position.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0);
    final size = widget.compact ? 36.0 : 44.0;

    return Container(
      key: const Key('voice_note'),
      padding: EdgeInsets.all(widget.compact ? 8 : 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F6FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD6E4FF)),
      ),
      child: Row(children: [
        Material(
          color: DriverColors.blue,
          shape: const CircleBorder(),
          child: InkWell(
            key: const Key('voice_note_play'),
            customBorder: const CircleBorder(),
            onTap: _loading ? null : _toggle,
            child: SizedBox.square(
              dimension: size,
              child: _loading
                  ? const Padding(
                      padding: EdgeInsets.all(11),
                      child: CircularProgressIndicator(
                          strokeWidth: 2.2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                  : Icon(_playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: Colors.white, size: size * .6),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.graphic_eq_rounded, size: 16, color: DriverColors.blue),
              const SizedBox(width: 6),
              Expanded(
                child: Text(_error ?? 'Voice note from dispatcher',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: _error != null ? DriverColors.red : DriverColors.ink,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
              ),
              Text(
                  _playing || _position > Duration.zero
                      ? '${_clock(_position)} / ${total == null ? '–' : _clock(total)}'
                      : total == null
                          ? ''
                          : _clock(total),
                  style: const TextStyle(
                      color: DriverColors.muted,
                      fontSize: 12,
                      fontFeatures: [FontFeature.tabularFigures()])),
            ]),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                backgroundColor: const Color(0xFFD6E4FF),
                valueColor: const AlwaysStoppedAnimation(DriverColors.blue),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}
