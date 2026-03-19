import 'dart:typed_data';
import 'dart:ui';

import 'package:image/image.dart' as img;

import 'image_perspective_crop_models.dart';
import 'perspective_crop_math.dart';

class PerspectiveCropProcessor {
  static Future<Uint8List> cropToJpg({
    required Uint8List imageBytes,
    required PerspectiveQuad imageQuad,
    int quality = 90,
  }) async {
    final img.Image? source = img.decodeImage(imageBytes);
    if (source == null) {
      throw StateError('Unable to decode image bytes for perspective crop.');
    }

    final Size outputSize = PerspectiveCropMath.estimateOutputSize(imageQuad);
    final int targetWidth = outputSize.width.round();
    final int targetHeight = outputSize.height.round();
    final img.Image destination = img.Image(width: targetWidth, height: targetHeight);

    for (int y = 0; y < targetHeight; y++) {
      final double v = targetHeight == 1 ? 0 : y / (targetHeight - 1);
      for (int x = 0; x < targetWidth; x++) {
        final double u = targetWidth == 1 ? 0 : x / (targetWidth - 1);
        final Offset sourcePoint = _mapFromUnitSquare(imageQuad, u, v);
        final int sx = sourcePoint.dx.clamp(0, source.width - 1).round();
        final int sy = sourcePoint.dy.clamp(0, source.height - 1).round();
        destination.setPixel(x, y, source.getPixel(sx, sy));
      }
    }

    return Uint8List.fromList(img.encodeJpg(destination, quality: quality));
  }

  static Offset _mapFromUnitSquare(PerspectiveQuad quad, double u, double v) {
    final Offset top = Offset.lerp(quad.topLeft, quad.topRight, u)!;
    final Offset bottom = Offset.lerp(quad.bottomLeft, quad.bottomRight, u)!;
    return Offset.lerp(top, bottom, v)!;
  }
}
