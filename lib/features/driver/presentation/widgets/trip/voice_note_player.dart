import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mob_driver/core/config/app_config.dart';
import 'package:mob_driver/core/l10n/tr.dart';
import 'package:mob_driver/core/theme/app_colors.dart';
import 'package:path_provider/path_provider.dart';

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
  Directory? _audioDirectory;

  Future<void> _releasePlayer() async {
    final player = _player;
    final directory = _audioDirectory;
    final subscriptions = List<StreamSubscription<dynamic>>.of(_subs);
    _subs.clear();
    _player = null;
    _audioDirectory = null;
    for (final sub in subscriptions) {
      await sub.cancel();
    }
    await player?.dispose();
    if (directory != null && await directory.exists()) {
      await directory.delete(recursive: true);
    }
  }

  @override
  void dispose() {
    unawaited(_releasePlayer());
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
          ..add(player.positionStream
              .listen((p) => mounted ? setState(() => _position = p) : null))
          ..add(player.durationStream
              .listen((d) => mounted ? setState(() => _duration = d) : null))
          ..add(player.playerStateStream.listen((s) {
            if (!mounted) return;
            final done = s.processingState == ProcessingState.completed;
            setState(() => _playing = s.playing && !done);
            if (done) {
              player!.pause();
              player.seek(Duration.zero);
            }
          }));
        final url = AppConfig.ourMediaUrl(widget.url);
        if (kIsWeb) {
          await player.setUrl(url);
        } else {
          // Download these short clips first: development media servers may
          // not support the byte-range requests native audio players make.
          final response = await Dio(BaseOptions(
            receiveTimeout: const Duration(seconds: 30),
            responseType: ResponseType.bytes,
          )).get<List<int>>(url);
          final bytes = response.data;
          if (!mounted) return;
          if (bytes == null || bytes.isEmpty) {
            throw StateError('Voice note download was empty');
          }
          final root = await getTemporaryDirectory();
          final directory = await root.createTemp('voice_note_');
          if (!mounted) {
            await directory.delete(recursive: true);
            return;
          }
          _audioDirectory = directory;
          final extension = Uri.parse(url).path.split('.').last.toLowerCase();
          final suffix = const ['m4a', 'mp3', 'aac', 'wav'].contains(extension)
              ? extension
              : 'm4a';
          final file = File('${directory.path}/note.$suffix');
          await file.writeAsBytes(bytes);
          if (!mounted) return;
          await player.setFilePath(file.path);
        }
      }
      if (!mounted) return;
      setState(() => _loading = false);
      await player.play();
    } catch (e) {
      debugPrint('Voice note ${widget.url} failed: $e');
      // Throw the half-built player away, so the next tap really tries again
      // (a kept one would skip loading and fail the same way forever).
      await _releasePlayer();
      if (mounted) {
        setState(() {
          _loading = false;
          _playing = false;
          _error = tr('Couldn’t play the voice note — tap to retry.');
        });
      }
    }
  }

  String _clock(Duration d) =>
      '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final total = _duration ??
        (widget.seconds != null ? Duration(seconds: widget.seconds!) : null);
    final progress = total == null || total.inMilliseconds == 0
        ? 0.0
        : (_position.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0);
    final size = widget.compact ? 36.0 : 44.0;

    return Container(
      key: const Key('voice_note'),
      padding: EdgeInsets.all(widget.compact ? 8 : 12),
      decoration: BoxDecoration(
        color: AppColors.blueSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.blue.withValues(alpha: .25)),
      ),
      child: Row(children: [
        Material(
          color: AppColors.blue,
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
                          strokeWidth: 2.2,
                          valueColor: AlwaysStoppedAnimation(Colors.white)))
                  : Icon(
                      _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: size * .6),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.graphic_eq_rounded, size: 16, color: AppColors.blue),
              const SizedBox(width: 6),
              Expanded(
                child: Text(_error ?? tr('Voice note from dispatcher'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: _error != null ? AppColors.red : AppColors.ink,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
              ),
              Text(
                  _playing || _position > Duration.zero
                      ? '${_clock(_position)} / ${total == null ? '–' : _clock(total)}'
                      : total == null
                          ? ''
                          : _clock(total),
                  style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                      fontFeatures: const [FontFeature.tabularFigures()])),
            ]),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                backgroundColor: AppColors.blueSoft,
                valueColor: AlwaysStoppedAnimation(AppColors.blue),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}
