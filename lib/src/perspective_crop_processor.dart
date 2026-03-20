import 'dart:isolate';
import 'dart:typed_data';
import 'dart:ui';

import 'package:image/image.dart' as img;

import 'image_perspective_crop_models.dart';
import 'perspective_crop_math.dart';

class PerspectiveCropProcessingOutput {
  const PerspectiveCropProcessingOutput({
    required this.bytes,
    required this.imageWidth,
    required this.imageHeight,
  });

  final Uint8List bytes;
  final int imageWidth;
  final int imageHeight;
}

class PerspectiveCropProcessor {
  static Future<PerspectiveCropProcessingOutput> cropToJpg({
    required Uint8List imageBytes,
    required PerspectiveQuad imageQuad,
    int quality = 100,
  }) async {
    final _PerspectiveCropRequest request = _PerspectiveCropRequest(
      imageBytes: imageBytes,
      imageQuad: imageQuad,
      quality: quality,
    );
    final _PerspectiveCropResponse response = await Isolate.run<_PerspectiveCropResponse>(
      () => _processCrop(request),
    );
    return PerspectiveCropProcessingOutput(
      bytes: response.bytes,
      imageWidth: response.imageWidth,
      imageHeight: response.imageHeight,
    );
  }

  static _PerspectiveCropResponse _processCrop(_PerspectiveCropRequest request) {
    final img.Image? source = img.decodeImage(request.imageBytes);
    if (source == null) {
      throw StateError('Unable to decode image bytes for perspective crop.');
    }

    final Size outputSize = PerspectiveCropMath.estimateOutputSize(request.imageQuad);
    final int targetWidth = outputSize.width.round();
    final int targetHeight = outputSize.height.round();
    final img.Image destination = img.Image(width: targetWidth, height: targetHeight);

    for (int y = 0; y < targetHeight; y++) {
      final double v = targetHeight == 1 ? 0 : y / (targetHeight - 1);
      for (int x = 0; x < targetWidth; x++) {
        final double u = targetWidth == 1 ? 0 : x / (targetWidth - 1);
        final Offset sourcePoint = _mapFromUnitSquare(request.imageQuad, u, v);
        final int sx = sourcePoint.dx.clamp(0, source.width - 1).round();
        final int sy = sourcePoint.dy.clamp(0, source.height - 1).round();
        destination.setPixel(x, y, source.getPixel(sx, sy));
      }
    }

    return _PerspectiveCropResponse(
      bytes: Uint8List.fromList(img.encodeJpg(destination, quality: request.quality)),
      imageWidth: source.width,
      imageHeight: source.height,
    );
  }

  static Offset _mapFromUnitSquare(PerspectiveQuad quad, double u, double v) {
    final Offset top = Offset.lerp(quad.topLeft, quad.topRight, u)!;
    final Offset bottom = Offset.lerp(quad.bottomLeft, quad.bottomRight, u)!;
    return Offset.lerp(top, bottom, v)!;
  }
}

class _PerspectiveCropRequest {
  const _PerspectiveCropRequest({
    required this.imageBytes,
    required this.imageQuad,
    required this.quality,
  });

  final Uint8List imageBytes;
  final PerspectiveQuad imageQuad;
  final int quality;
}

class _PerspectiveCropResponse {
  const _PerspectiveCropResponse({
    required this.bytes,
    required this.imageWidth,
    required this.imageHeight,
  });

  final Uint8List bytes;
  final int imageWidth;
  final int imageHeight;
}
