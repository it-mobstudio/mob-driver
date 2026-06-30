import 'package:flutter/material.dart';
import 'package:m_o_b_demand_side/core/app_runtime/uploaded_file.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/features/magic_quote/presentation/pages/magic_quote_widgets.dart';

class PickedMagicQuoteFile {
  const PickedMagicQuoteFile({
    required this.name,
    required this.size,
    required this.file,
  });

  final String name;
  final int size;
  final FFUploadedFile file;
}

const _imageExtensions = ['avif', 'gif', 'jpg', 'jpeg', 'png', 'svg', 'webp'];

bool isMagicQuoteImageFile(String name) {
  final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
  return _imageExtensions.contains(ext);
}

/// Thumbnail tile for a picked file — shows the image (tappable to preview)
/// or the file extension, the file name overlay, and an optional remove
/// button. Reused by both the upload form and the post-submit "Your
/// uploads" viewer, mirroring how the web shares file-tile markup between
/// UploadScreen.jsx and UploadsViewer.jsx.
class MagicQuoteFileTile extends StatelessWidget {
  const MagicQuoteFileTile({
    super.key,
    required this.file,
    this.removable = true,
    this.onRemove,
    this.onPreview,
  });

  final PickedMagicQuoteFile file;
  final bool removable;
  final VoidCallback? onRemove;
  final VoidCallback? onPreview;

  @override
  Widget build(BuildContext context) {
    final bytes = file.file.bytes;
    final isImage =
        isMagicQuoteImageFile(file.name) && bytes != null && bytes.isNotEmpty;
    const tileSize = 84.0;
    return SizedBox(
      width: tileSize,
      height: tileSize,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: tileSize,
              height: tileSize,
              color: const Color(0xFFF7F9FC),
              child: InkWell(
                onTap: isImage ? onPreview : null,
                child: isImage
                    ? Image.memory(
                        bytes,
                        width: tileSize,
                        height: tileSize,
                        fit: BoxFit.cover,
                      )
                    : Center(
                        child: Text(
                          (file.name.contains('.')
                                  ? file.name.split('.').last
                                  : file.name)
                              .toUpperCase(),
                          style: GoogleFonts.inter(
                            color: MagicQuoteColors.navy,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x00000000), Color(0xCC000000)],
                ),
              ),
              child: Text(
                file.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          if (removable && onRemove != null)
            Positioned(
              top: -6,
              right: -6,
              child: GestureDetector(
                onTap: onRemove,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    color: Color(0xFF687482),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
