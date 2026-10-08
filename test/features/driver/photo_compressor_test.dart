import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mob_driver/features/driver/data/media/photo_compressor.dart';
import 'package:mob_driver/features/driver/domain/entities/captured_photo.dart';

void main() {
  test('the default budget is 50 KB, with one smaller retry', () {
    const policy = PhotoUploadPolicy();
    expect(policy.maxBytes, 50 * 1024);
    expect(policy.retryQuality, lessThan(policy.quality));
    expect(policy.retryShorterSide, lessThan(policy.shorterSide));
  });

  test('with no native encoder (tests, the web) the photo goes up unchanged',
      () async {
    final photo = CapturedPhoto(bytes: Uint8List(10), filename: 'shot.jpg');
    expect(await const PhotoCompressor().compress(photo), photo);
  });

  test('a compressed photo is named .webp so the backend reads its type', () {
    expect(CapturedPhoto(bytes: Uint8List(1), filename: 'a.webp').mimeType,
        'image/webp');
  });
}
