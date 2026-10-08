import 'package:flutter/material.dart';

/// How many pixels wide to decode a picture shown [logicalWidth] wide:
/// decoding at display size, not the file's, is what keeps a screen of
/// photos from costing tens of megabytes on a low-memory phone.
int thumbPixels(BuildContext context, double logicalWidth) =>
    (logicalWidth * MediaQuery.devicePixelRatioOf(context)).ceil();
