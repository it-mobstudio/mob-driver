import 'package:flutter/material.dart';
import 'package:m_o_b_demand_side/features/driver/data/media/photo_capture.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/captured_photo.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/driver_ui.dart';
import 'package:m_o_b_demand_side/shared/widgets/top_snack_bar.dart';

/// A picture from the network with a quiet fallback — used for item pictures,
/// proof photos and document scans, which may be missing, slow, or on a host
/// that's unreachable. Never throws into the layout.
class NetworkThumb extends StatelessWidget {
  const NetworkThumb(
    this.url, {
    super.key,
    this.size = 56,
    this.radius = 12,
    this.fallbackIcon = Icons.inventory_2_outlined,
  });

  final String? url;
  final double size;
  final double radius;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: size,
      height: size,
      color: const Color(0xFFF1F4F8),
      child: Icon(fallbackIcon, color: DriverColors.muted, size: size * .42),
    );
    final source = url;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: source == null || source.isEmpty
          ? fallback
          : Image.network(
              source,
              width: size,
              height: size,
              fit: BoxFit.cover,
              // Decode near display size: a list of full-size product photos
              // shouldn't cost megabytes each.
              cacheWidth:
                  (size * MediaQuery.devicePixelRatioOf(context)).round(),
              errorBuilder: (_, __, ___) => fallback,
              frameBuilder: (_, child, frame, sync) => AnimatedOpacity(
                opacity: sync || frame != null ? 1 : 0,
                duration: const Duration(milliseconds: 220),
                child: child,
              ),
            ),
    );
  }
}

/// A dashed-look slot for one picture: empty (tap to add), filled with what
/// was just captured, or showing what's already on the server.
class PhotoTile extends StatelessWidget {
  const PhotoTile({
    super.key,
    required this.label,
    required this.onTap,
    this.photo,
    this.networkUrl,
    this.optional = false,
    this.height = 112,
    this.enabled = true,
  });

  final String label;
  final VoidCallback onTap;
  final CapturedPhoto? photo;
  final String? networkUrl;
  final bool optional;
  final double height;
  final bool enabled;

  bool get _filled =>
      photo != null || (networkUrl != null && networkUrl!.isNotEmpty);

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: enabled ? onTap : null,
          child: Ink(
            height: height,
            decoration: BoxDecoration(
              color: const Color(0xFFF7F9FC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _filled ? DriverColors.green : DriverColors.line,
                width: _filled ? 1.6 : 1.2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: _filled ? _filledView() : _emptyView(),
            ),
          ),
        ),
      );

  Widget _emptyView() => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.add_a_photo_outlined,
              color: DriverColors.blue, size: 26),
          const SizedBox(height: 6),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: DriverColors.ink,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700)),
          if (optional)
            const Text('Optional',
                style: TextStyle(color: DriverColors.muted, fontSize: 11)),
        ]),
      );

  Widget _filledView() => Stack(fit: StackFit.expand, children: [
        if (photo != null)
          Image.memory(photo!.bytes, fit: BoxFit.cover)
        else
          Image.network(
            networkUrl!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const Center(
                child: Icon(Icons.image_not_supported_outlined,
                    color: DriverColors.muted)),
          ),
        Positioned(
          left: 8,
          bottom: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: .62),
                borderRadius: BorderRadius.circular(20)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.check_circle_rounded,
                  color: Colors.white, size: 13),
              const SizedBox(width: 4),
              Text(enabled ? '$label · Tap to change' : label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700)),
            ]),
          ),
        ),
      ]);
}

/// Takes a picture with the camera, telling the driver why if it can't.
/// Null when they back out or the camera is unavailable.
Future<CapturedPhoto?> takePhotoWithFeedback(
  BuildContext context,
  PhotoCapture capture,
) async {
  try {
    return await capture.takePhoto();
  } on PhotoCaptureException catch (e) {
    if (context.mounted) {
      TopSnackBar.show(context,
          message: e.message, type: TopSnackBarType.error);
    }
    return null;
  }
}

/// "Take a photo" or "Choose from gallery" — for document scans, which a
/// driver may well already have on the phone. Proof-of-delivery photos skip
/// this and go straight to the camera ([takePhotoWithFeedback]): they should be
/// pictures taken *at the drop*.
Future<CapturedPhoto?> chooseDocumentPhoto(
  BuildContext context,
  PhotoCapture capture,
) async {
  final source = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 14, 8, 8),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            ListTile(
              key: const Key('photo_source_camera'),
              leading: const Icon(Icons.photo_camera_outlined,
                  color: DriverColors.blue),
              title: const Text('Take a photo',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              onTap: () => Navigator.pop(ctx, true),
            ),
            ListTile(
              key: const Key('photo_source_gallery'),
              leading: const Icon(Icons.photo_library_outlined,
                  color: DriverColors.blue),
              title: const Text('Choose from gallery',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              onTap: () => Navigator.pop(ctx, false),
            ),
          ]),
        ),
      ),
    ),
  );
  if (source == null || !context.mounted) return null;
  try {
    return source ? await capture.takePhoto() : await capture.pickFromGallery();
  } on PhotoCaptureException catch (e) {
    if (context.mounted) {
      TopSnackBar.show(context,
          message: e.message, type: TopSnackBarType.error);
    }
    return null;
  }
}
