import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mob_driver/core/l10n/tr.dart';
import 'package:mob_driver/features/driver/data/media/geo_stamp.dart';
import 'package:mob_driver/features/driver/data/media/photo_compressor.dart';
import 'package:mob_driver/features/driver/domain/entities/captured_photo.dart';

/// The camera couldn't be used (permission off, no camera, ...). [message] is
/// fit to show the driver as-is.
class PhotoCaptureException implements Exception {
  const PhotoCaptureException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Where pictures come from. An interface so screens can be tested without a
/// camera, and so proof photos (camera only — a picture taken *there*, not one
/// found in the gallery) and document scans (camera or gallery) share one door.
abstract interface class PhotoCapture {
  /// Opens the camera. Null when the driver backs out.
  Future<CapturedPhoto?> takePhoto();

  /// Opens the gallery. Null when the driver backs out.
  Future<CapturedPhoto?> pickFromGallery();

  /// Burns [stamp] (location, time, what it shows, the address if known)
  /// into [photo] — for proof photos.
  Future<CapturedPhoto> geoStamp(CapturedPhoto photo, GeoStamp stamp);

  /// The street address at a spot, for the stamp; null when it can't be had
  /// quickly. Asked for while the camera is open, so it's usually ready.
  Future<String?> addressAt(double latitude, double longitude);

  /// The last step before upload: a small WebP (see [PhotoCompressor]).
  /// Done once, at the end, so a stamped photo isn't compressed twice.
  Future<CapturedPhoto> optimizeForUpload(CapturedPhoto photo);
}

class DevicePhotoCapture implements PhotoCapture {
  const DevicePhotoCapture({this.compressor = const PhotoCompressor()});

  final PhotoCompressor compressor;

  @override
  Future<CapturedPhoto> optimizeForUpload(CapturedPhoto photo) =>
      compressor.compress(photo);

  @override
  Future<String?> addressAt(double latitude, double longitude) =>
      lookUpAddress(latitude, longitude);

  static final ImagePicker _picker = ImagePicker();

  @override
  Future<CapturedPhoto?> takePhoto() => _pick(ImageSource.camera);

  @override
  Future<CapturedPhoto?> pickFromGallery() => _pick(ImageSource.gallery);

  @override
  Future<CapturedPhoto> geoStamp(CapturedPhoto photo, GeoStamp stamp) async {
    try {
      return await renderGeoStamp(photo, stamp);
    } catch (_) {
      // A photo that can't be decoded here is still a photo; the server
      // checks it's an image.
      return photo;
    }
  }

  Future<CapturedPhoto?> _pick(ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        // Scaled down by the camera itself (native, instant): a 12 MP
        // original is several MB, while 1280 px is plenty to read a licence
        // or see a parcel, and every later step has a fraction of the pixels
        // to handle. Also turns an iPhone's HEIC into a JPEG.
        imageQuality: 85,
        maxWidth: 1280,
        maxHeight: 1280,
        preferredCameraDevice: CameraDevice.rear,
      );
      if (file == null) return null;
      return CapturedPhoto(
        bytes: await file.readAsBytes(),
        filename: _fileName(file.name),
      );
    } on PlatformException catch (e) {
      final denied = e.code.contains('denied') || e.code.contains('access');
      throw PhotoCaptureException(
        denied
            ? tr(
                'Camera or photo access is off. Allow it in Settings to add pictures.')
            : tr('Couldn’t open the camera. Please try again.'),
      );
    }
  }

  /// The backend reads the type from the extension; some pickers (the web
  /// build, some Android galleries) hand back a name without one.
  static String _fileName(String name) {
    final lower = name.toLowerCase();
    final ok = ['.jpg', '.jpeg', '.png', '.webp'].any(lower.endsWith);
    return ok ? name : 'photo-${DateTime.now().millisecondsSinceEpoch}.jpg';
  }
}
