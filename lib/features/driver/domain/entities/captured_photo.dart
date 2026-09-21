import 'dart:typed_data';

import 'package:equatable/equatable.dart';

/// A picture the driver just took (or picked): the bytes plus a file name the
/// backend can read the type from. Kept in memory — these are small,
/// compressed shots, and holding bytes (not a path) means the same code works
/// on the web build and survives the camera plugin's temp file being cleaned up.
class CapturedPhoto extends Equatable {
  const CapturedPhoto({required this.bytes, this.filename = 'photo.jpg'});

  final Uint8List bytes;
  final String filename;

  /// `image/png` for a `.png`, `image/jpeg` for everything else the picker
  /// hands back.
  String get mimeType {
    final name = filename.toLowerCase();
    if (name.endsWith('.png')) return 'image/png';
    if (name.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  @override
  List<Object?> get props => [bytes.length, filename];
}
