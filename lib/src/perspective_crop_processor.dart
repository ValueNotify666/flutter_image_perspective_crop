import 'dart:isolate';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_opencv_ffi/flutter_opencv_ffi.dart' as opencv;
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
  static Future<PerspectiveOctagon> detectDocumentOctagon({
    required Uint8List imageBytes,
  }) async {
    final _PerspectiveDetectResponse response = await Isolate.run<_PerspectiveDetectResponse>(
      () => _processDetect(imageBytes),
    );
    return response.octagon;
  }

  static Future<PerspectiveOctagon> detectDocumentOctagonRgba({
    required Uint8List rgba,
    required int width,
    required int height,
  }) async {
    final _PerspectiveDetectRgbaRequest request = _PerspectiveDetectRgbaRequest(
      rgba: rgba,
      width: width,
      height: height,
    );
    final _PerspectiveDetectResponse response = await Isolate.run<_PerspectiveDetectResponse>(
      () => _processDetectRgba(request),
    );
    return response.octagon;
  }

  static Future<PerspectiveCropProcessingOutput> cropEnhanceToPng({
    required Uint8List imageBytes,
    required PerspectiveOctagon imageOctagon,
  }) async {
    final _PerspectiveCropEnhanceRequest request = _PerspectiveCropEnhanceRequest(
      imageBytes: imageBytes,
      imageOctagon: imageOctagon,
    );
    final _PerspectiveCropResponse response = await Isolate.run<_PerspectiveCropResponse>(
      () => _processCropEnhance(request),
    );
    return PerspectiveCropProcessingOutput(
      bytes: response.bytes,
      imageWidth: response.imageWidth,
      imageHeight: response.imageHeight,
    );
  }

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

  static _PerspectiveDetectResponse _processDetect(Uint8List imageBytes) {
    final img.Image? source = img.decodeImage(imageBytes);
    if (source == null) {
      throw StateError('Unable to decode image bytes for document detection.');
    }

    final Uint8List rgba = source.getBytes(order: img.ChannelOrder.rgba);
    final Float32List points = opencv.detectDocument8PointsRgba(
      rgba,
      source.width,
      source.height,
    );

    return _PerspectiveDetectResponse(
      octagon: _octagonFromFloat32List(points),
    );
  }

  static _PerspectiveDetectResponse _processDetectRgba(_PerspectiveDetectRgbaRequest request) {
    final Float32List points = opencv.detectDocument8PointsRgba(
      request.rgba,
      request.width,
      request.height,
    );

    return _PerspectiveDetectResponse(
      octagon: _octagonFromFloat32List(points),
    );
  }

  static _PerspectiveCropResponse _processCropEnhance(_PerspectiveCropEnhanceRequest request) {
    final img.Image? source = img.decodeImage(request.imageBytes);
    if (source == null) {
      throw StateError('Unable to decode image bytes for OpenCV crop enhance.');
    }

    final Uint8List rgba = source.getBytes(order: img.ChannelOrder.rgba);
    final opencv.OpenCvImageResult result = opencv.cropEnhanceDocument8PointsRgba(
      rgba,
      source.width,
      source.height,
      _octagonToFloat32List(request.imageOctagon),
    );
    final img.Image output = img.Image.fromBytes(
      width: result.width,
      height: result.height,
      bytes: result.rgba.buffer,
      order: img.ChannelOrder.rgba,
      numChannels: 4,
    );

    return _PerspectiveCropResponse(
      bytes: Uint8List.fromList(img.encodePng(output)),
      imageWidth: result.width,
      imageHeight: result.height,
    );
  }

  static Offset _mapFromUnitSquare(PerspectiveQuad quad, double u, double v) {
    final Offset top = Offset.lerp(quad.topLeft, quad.topRight, u)!;
    final Offset bottom = Offset.lerp(quad.bottomLeft, quad.bottomRight, u)!;
    return Offset.lerp(top, bottom, v)!;
  }

  static PerspectiveOctagon _octagonFromFloat32List(Float32List points) {
    Offset point(int index) {
      return Offset(points[index * 2], points[index * 2 + 1]);
    }

    return PerspectiveOctagon(
      topLeft: point(0),
      topCenter: point(1),
      topRight: point(2),
      rightCenter: point(3),
      bottomRight: point(4),
      bottomCenter: point(5),
      bottomLeft: point(6),
      leftCenter: point(7),
    );
  }

  static Float32List _octagonToFloat32List(PerspectiveOctagon octagon) {
    return Float32List.fromList(
      octagon.toList().expand((Offset point) => <double>[point.dx, point.dy]).toList(),
    );
  }
}

class _PerspectiveDetectResponse {
  const _PerspectiveDetectResponse({
    required this.octagon,
  });

  final PerspectiveOctagon octagon;
}

class _PerspectiveDetectRgbaRequest {
  const _PerspectiveDetectRgbaRequest({
    required this.rgba,
    required this.width,
    required this.height,
  });

  final Uint8List rgba;
  final int width;
  final int height;
}

class _PerspectiveCropEnhanceRequest {
  const _PerspectiveCropEnhanceRequest({
    required this.imageBytes,
    required this.imageOctagon,
  });

  final Uint8List imageBytes;
  final PerspectiveOctagon imageOctagon;
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
