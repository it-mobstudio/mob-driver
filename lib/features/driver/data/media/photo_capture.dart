import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/captured_photo.dart';

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
}

class DevicePhotoCapture implements PhotoCapture {
  const DevicePhotoCapture();

  static final ImagePicker _picker = ImagePicker();

  @override
  Future<CapturedPhoto?> takePhoto() => _pick(ImageSource.camera);

  @override
  Future<CapturedPhoto?> pickFromGallery() => _pick(ImageSource.gallery);

  Future<CapturedPhoto?> _pick(ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        // Re-encoded on the way in: a phone camera's 12 MP original is several
        // MB (slow on mobile data, and over the backend's upload limit), while
        // a 1600 px JPEG is plenty to read a licence or see a parcel — and it
        // turns an iPhone's HEIC into a JPEG the backend accepts.
        imageQuality: 82,
        maxWidth: 1600,
        maxHeight: 1600,
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
            ? 'Camera or photo access is off. Allow it in Settings to add pictures.'
            : 'Couldn’t open the camera. Please try again.',
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
