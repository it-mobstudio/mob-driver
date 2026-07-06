const _knownDeadImageUrls = <String>{
  'https://mob-demand-side.netlify.app/Image-coming-soon.png',
};

/// Normalizes a product/category image URL coming from the API. Known dead
/// placeholder URLs (e.g. the backend's own Image-coming-soon.png, which has
/// no CORS header and always fails to load on web) are treated as "no image"
/// so callers skip the network fetch entirely instead of hitting a request
/// that's guaranteed to fail.
String sanitizeImageUrl(String? url) {
  final trimmed = url?.trim() ?? '';
  if (trimmed.isEmpty || _knownDeadImageUrls.contains(trimmed)) return '';
  return trimmed;
}
