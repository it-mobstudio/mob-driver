import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:mob_driver/features/driver/domain/entities/captured_photo.dart';

/// How small an uploaded photo should be. Drivers are on mobile data, often
/// with weak signal: a proof photo has to go up in a second or two, and still
/// show the parcel, the plate or the licence text clearly.
class PhotoUploadPolicy {
  const PhotoUploadPolicy({
    this.maxBytes = 50 * 1024,
    this.shorterSide = 900,
    this.quality = 70,
    this.retryShorterSide = 720,
    this.retryQuality = 55,
  });

  /// The budget for one photo.
  final int maxBytes;

  /// The picture's shorter side and WebP quality for the one encode that
  /// usually fits (a 4:3 shot at 900 is 1200×900).
  final int shorterSide;
  final int quality;

  /// The single retry when that came out over budget (a very detailed scene).
  final int retryShorterSide;
  final int retryQuality;
}

/// Turns a photo into a WebP within [PhotoUploadPolicy.maxBytes]. Encoded by
/// the phone's own image codec (native, off the UI thread), once — at most
/// twice — so even an older phone is done in well under a second. WebP is
/// ~30% smaller than JPEG at the same quality.
class PhotoCompressor {
  const PhotoCompressor({this.policy = const PhotoUploadPolicy()});

  final PhotoUploadPolicy policy;

  Future<CapturedPhoto> compress(CapturedPhoto photo) async {
    try {
      var bytes = await _webp(photo.bytes, policy.shorterSide, policy.quality);
      if (bytes.length > policy.maxBytes) {
        bytes = await _webp(
            photo.bytes, policy.retryShorterSide, policy.retryQuality);
      }
      return bytes.length < photo.bytes.length ? _asWebp(photo, bytes) : photo;
    } catch (e) {
      // No WebP encoder here (the web build): send the photo as it is.
      if (kDebugMode) debugPrint('Photo not compressed: $e');
      return photo;
    }
  }

  static Future<Uint8List> _webp(
          Uint8List source, int shorterSide, int quality) =>
      FlutterImageCompress.compressWithList(
        source,
        minWidth: shorterSide,
        minHeight: shorterSide,
        quality: quality,
        format: CompressFormat.webp,
      );

  static CapturedPhoto _asWebp(CapturedPhoto photo, Uint8List bytes) {
    final dot = photo.filename.lastIndexOf('.');
    final base = dot > 0 ? photo.filename.substring(0, dot) : photo.filename;
    return CapturedPhoto(bytes: bytes, filename: '$base.webp');
  }
}
