import 'dart:math' as math;
import 'dart:ui';

import 'image_perspective_crop_models.dart';

class PerspectiveCropMath {
  static double distance(Offset a, Offset b) {
    return (a - b).distance;
  }

  static Offset midpoint(Offset a, Offset b) {
    return Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);
  }

  static PerspectiveQuad clampQuad(PerspectiveQuad quad, Rect bounds) {
    Offset clamp(Offset value) {
      return Offset(
        value.dx.clamp(bounds.left, bounds.right).toDouble(),
        value.dy.clamp(bounds.top, bounds.bottom).toDouble(),
      );
    }

    return PerspectiveQuad(
      topLeft: clamp(quad.topLeft),
      topRight: clamp(quad.topRight),
      bottomRight: clamp(quad.bottomRight),
      bottomLeft: clamp(quad.bottomLeft),
    );
  }

  static Size estimateOutputSize(PerspectiveQuad quad) {
    final double topWidth = distance(quad.topLeft, quad.topRight);
    final double bottomWidth = distance(quad.bottomLeft, quad.bottomRight);
    final double leftHeight = distance(quad.topLeft, quad.bottomLeft);
    final double rightHeight = distance(quad.topRight, quad.bottomRight);
    return Size(
      math.max(1, ((topWidth + bottomWidth) / 2).round()).toDouble(),
      math.max(1, ((leftHeight + rightHeight) / 2).round()).toDouble(),
    );
  }

  static PerspectiveQuad mapDisplayQuadToImage({
    required PerspectiveQuad displayQuad,
    required Rect imageRect,
    required int imageWidth,
    required int imageHeight,
  }) {
    Offset convert(Offset point) {
      final double normalizedX = ((point.dx - imageRect.left) / imageRect.width).clamp(0, 1);
      final double normalizedY = ((point.dy - imageRect.top) / imageRect.height).clamp(0, 1);
      return Offset(
        normalizedX * (imageWidth - 1),
        normalizedY * (imageHeight - 1),
      );
    }

    return PerspectiveQuad(
      topLeft: convert(displayQuad.topLeft),
      topRight: convert(displayQuad.topRight),
      bottomRight: convert(displayQuad.bottomRight),
      bottomLeft: convert(displayQuad.bottomLeft),
    );
  }
}
