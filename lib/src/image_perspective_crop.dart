import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'image_perspective_crop_builders.dart';
import 'image_perspective_crop_controller.dart';
import 'image_perspective_crop_models.dart';
import 'image_perspective_crop_style.dart';
import 'perspective_crop_math.dart';
import 'perspective_crop_processor.dart';

class ImagePerspectiveCrop extends StatefulWidget {
  const ImagePerspectiveCrop({
    super.key,
    required this.image,
    required this.onCompleted,
    this.controller,
    this.style = const ImagePerspectiveCropStyle(),
    this.builders = const ImagePerspectiveCropBuilders(),
    this.onCloseRequested,
    this.onSelectionChanged,
  });

  final Uint8List image;
  final ValueChanged<PerspectiveCropResult> onCompleted;
  final ImagePerspectiveCropController? controller;
  final ImagePerspectiveCropStyle style;
  final ImagePerspectiveCropBuilders builders;
  final VoidCallback? onCloseRequested;
  final ValueChanged<PerspectiveQuad>? onSelectionChanged;

  @override
  State<ImagePerspectiveCrop> createState() => _ImagePerspectiveCropState();
}

class _ImagePerspectiveCropState extends State<ImagePerspectiveCrop> {
  ui.Image? _decodedImage;
  bool _isCropping = false;
  bool _hasTriedAutoDetect = false;
  bool _isInitializingSelection = false;
  PerspectiveOctagon? _octagon;
  PerspectiveOctagon? _lastCustomOctagon;
  Rect? _imageRect;
  int? _activeHandleIndex;
  Offset? _activeFocalPoint;
  static const double _handleHitSlop = 28;
  static const int _chunkSize = 64 * 1024;

  @override
  void initState() {
    super.initState();
    widget.controller?.bind(
      onClose: _handleClose,
      onSwitch: _handleSwitch,
      onComplete: _handleComplete,
    );
    _decodeImage();
  }

  @override
  void didUpdateWidget(covariant ImagePerspectiveCrop oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.unbind();
      widget.controller?.bind(
        onClose: _handleClose,
        onSwitch: _handleSwitch,
        onComplete: _handleComplete,
      );
    }
    if (oldWidget.image != widget.image) {
      _decodedImage = null;
      _hasTriedAutoDetect = false;
      _isInitializingSelection = false;
      _octagon = null;
      _lastCustomOctagon = null;
      _imageRect = null;
      _decodeImage();
    }
  }

  @override
  void dispose() {
    widget.controller?.unbind();
    super.dispose();
  }

  Future<void> _decodeImage() async {
    final ui.Codec codec = await ui.instantiateImageCodec(widget.image);
    final ui.FrameInfo frameInfo = await codec.getNextFrame();
    if (!mounted) {
      return;
    }
    setState(() {
      _decodedImage = frameInfo.image;
    });
  }

  void _initializeOctagonIfNeeded(Rect imageRect) {
    if (_octagon != null && _imageRect == imageRect) {
      return;
    }
    _imageRect = imageRect;
    if (!_hasTriedAutoDetect) {
      _hasTriedAutoDetect = true;
      _isInitializingSelection = true;
      _detectInitialOctagon(imageRect);
    }
  }

  Future<void> _detectInitialOctagon(Rect imageRect) async {
    final ui.Image? image = _decodedImage;
    if (image == null) {
      return;
    }
    try {
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (byteData == null) {
        throw StateError('Unable to read raw RGBA bytes for document detection.');
      }
      final PerspectiveOctagon imageOctagon = await PerspectiveCropProcessor.detectDocumentOctagonRgba(
        rgba: byteData.buffer.asUint8List(),
        width: image.width,
        height: image.height,
      );
      if (!mounted || _imageRect != imageRect) {
        return;
      }
      final PerspectiveOctagon displayOctagon = PerspectiveCropMath.mapImageOctagonToDisplay(
        imageOctagon: imageOctagon,
        imageRect: imageRect,
        imageWidth: image.width,
        imageHeight: image.height,
      );
      final PerspectiveOctagon clamped = PerspectiveCropMath.clampOctagon(displayOctagon, imageRect);
      setState(() {
        _octagon = clamped;
        _lastCustomOctagon = clamped;
      });
      widget.onSelectionChanged?.call(clamped.toQuad());
    } catch (_) {
      if (!mounted || _imageRect != imageRect) {
        return;
      }
      final PerspectiveOctagon fallback = PerspectiveOctagon.fromRect(imageRect.deflate(24));
      setState(() {
        _octagon = fallback;
        _lastCustomOctagon = fallback;
      });
      widget.onSelectionChanged?.call(fallback.toQuad());
    } finally {
      if (mounted && _imageRect == imageRect) {
        setState(() {
          _isInitializingSelection = false;
        });
      }
    }
  }

  void _handleClose() {
    if (widget.onCloseRequested != null) {
      widget.onCloseRequested!.call();
      return;
    }
    Navigator.of(context).maybePop();
  }

  void _handleSwitch() {
    final Rect? imageRect = _imageRect;
    final PerspectiveOctagon? octagon = _octagon;
    if (imageRect == null || octagon == null) {
      return;
    }
    final PerspectiveOctagon full = PerspectiveOctagon.fromRect(imageRect);
    final bool isFull = _isAlmostFullSelection(octagon.toQuad(), full.toQuad());
    setState(() {
      if (isFull && _lastCustomOctagon != null) {
        _octagon = _lastCustomOctagon;
      } else {
        _lastCustomOctagon = octagon;
        _octagon = full;
      }
    });
    if (_octagon != null) {
      widget.onSelectionChanged?.call(_octagon!.toQuad());
    }
  }

  bool _isAlmostFullSelection(PerspectiveQuad current, PerspectiveQuad full) {
    const double tolerance = 2;
    return (current.topLeft - full.topLeft).distance <= tolerance &&
        (current.topRight - full.topRight).distance <= tolerance &&
        (current.bottomRight - full.bottomRight).distance <= tolerance &&
        (current.bottomLeft - full.bottomLeft).distance <= tolerance;
  }

  Future<void> _emitCompleted(PerspectiveCropResult event) async {
    widget.onCompleted(event);
    await widget.controller?.dispatchCompleted(event);
  }

  Future<void> _sendChunkedResult(PerspectiveCropProcessingOutput output) async {
    await _emitCompleted(
      PerspectiveCropResult(
        status: PerspectiveCropStatus.startSend,
        imageWidth: output.imageWidth,
        imageHeight: output.imageHeight,
        totalBytes: output.bytes.length,
      ),
    );

    int sentBytes = 0;
    while (sentBytes < output.bytes.length) {
      final int end = (sentBytes + _chunkSize).clamp(0, output.bytes.length);
      final Uint8List chunk = Uint8List.sublistView(output.bytes, sentBytes, end);
      sentBytes = end;
      await _emitCompleted(
        PerspectiveCropResult(
          status: PerspectiveCropStatus.sending,
          chunk: chunk,
          sentBytes: sentBytes,
          totalBytes: output.bytes.length,
          imageWidth: output.imageWidth,
          imageHeight: output.imageHeight,
        ),
      );
    }

    await _emitCompleted(
      PerspectiveCropResult(
        status: PerspectiveCropStatus.complete,
        imageWidth: output.imageWidth,
        imageHeight: output.imageHeight,
        totalBytes: output.bytes.length,
      ),
    );
  }

  Future<void> _handleComplete() async {
    final PerspectiveOctagon? octagon = _octagon;
    final Rect? imageRect = _imageRect;
    final ui.Image? image = _decodedImage;
    if (_isCropping || octagon == null || imageRect == null || image == null) {
      return;
    }
    setState(() {
      _isCropping = true;
    });
    try {
      await _emitCompleted(
        PerspectiveCropResult(
          status: PerspectiveCropStatus.processing,
          imageWidth: image.width,
          imageHeight: image.height,
        ),
      );
      final PerspectiveOctagon imageOctagon = PerspectiveCropMath.mapDisplayOctagonToImage(
        displayOctagon: octagon,
        imageRect: imageRect,
        imageWidth: image.width,
        imageHeight: image.height,
      );
      final PerspectiveCropProcessingOutput output = await PerspectiveCropProcessor.cropEnhanceToPng(
        imageBytes: widget.image,
        imageOctagon: imageOctagon,
      );
      await _sendChunkedResult(output);
    } catch (error) {
      await _emitCompleted(
        PerspectiveCropResult(
          status: PerspectiveCropStatus.error,
          imageWidth: image.width,
          imageHeight: image.height,
          errorMessage: error.toString(),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCropping = false;
        });
      }
    }
  }

  List<PerspectiveControlPointData> _buildHandleData(PerspectiveOctagon octagon) {
    return <PerspectiveControlPointData>[
      PerspectiveControlPointData(index: 0, position: PerspectiveControlPointPosition.topLeft, offset: octagon.topLeft, type: PerspectiveControlPointType.corner, isActive: _activeHandleIndex == 0),
      PerspectiveControlPointData(index: 1, position: PerspectiveControlPointPosition.topCenter, offset: octagon.topCenter, type: PerspectiveControlPointType.edge, isActive: _activeHandleIndex == 1),
      PerspectiveControlPointData(index: 2, position: PerspectiveControlPointPosition.topRight, offset: octagon.topRight, type: PerspectiveControlPointType.corner, isActive: _activeHandleIndex == 2),
      PerspectiveControlPointData(index: 3, position: PerspectiveControlPointPosition.rightCenter, offset: octagon.rightCenter, type: PerspectiveControlPointType.edge, isActive: _activeHandleIndex == 3),
      PerspectiveControlPointData(index: 4, position: PerspectiveControlPointPosition.bottomRight, offset: octagon.bottomRight, type: PerspectiveControlPointType.corner, isActive: _activeHandleIndex == 4),
      PerspectiveControlPointData(index: 5, position: PerspectiveControlPointPosition.bottomCenter, offset: octagon.bottomCenter, type: PerspectiveControlPointType.edge, isActive: _activeHandleIndex == 5),
      PerspectiveControlPointData(index: 6, position: PerspectiveControlPointPosition.bottomLeft, offset: octagon.bottomLeft, type: PerspectiveControlPointType.corner, isActive: _activeHandleIndex == 6),
      PerspectiveControlPointData(index: 7, position: PerspectiveControlPointPosition.leftCenter, offset: octagon.leftCenter, type: PerspectiveControlPointType.edge, isActive: _activeHandleIndex == 7),
    ];
  }

  int? _findHandleIndex(Offset localPosition, List<PerspectiveControlPointData> handles) {
    int? closestIndex;
    double closestDistance = double.infinity;
    final double maxDistance = (widget.style.handleStyle.size / 2) + _handleHitSlop;

    for (final PerspectiveControlPointData handle in handles) {
      final double distance = (handle.offset - localPosition).distance;
      if (distance <= maxDistance && distance < closestDistance) {
        closestIndex = handle.index;
        closestDistance = distance;
      }
    }

    return closestIndex;
  }

  Offset _handleFocalPoint(PerspectiveOctagon octagon, int index) {
    return _buildHandleData(octagon).firstWhere((PerspectiveControlPointData data) => data.index == index).offset;
  }

  bool _isValidQuad(PerspectiveQuad quad) {
    final List<Offset> points = quad.toList();
    final double signedArea = points.asMap().entries.fold(0, (double sum, MapEntry<int, Offset> entry) {
      final Offset current = entry.value;
      final Offset next = points[(entry.key + 1) % points.length];
      return sum + ((current.dx * next.dy) - (next.dx * current.dy));
    });

    if (signedArea.abs() < 1) {
      return false;
    }

    return !_segmentsIntersect(quad.topLeft, quad.topRight, quad.bottomRight, quad.bottomLeft) &&
        !_segmentsIntersect(quad.topRight, quad.bottomRight, quad.bottomLeft, quad.topLeft);
  }

  bool _segmentsIntersect(Offset a1, Offset a2, Offset b1, Offset b2) {
    double cross(Offset a, Offset b, Offset c) {
      return (b.dx - a.dx) * (c.dy - a.dy) - (b.dy - a.dy) * (c.dx - a.dx);
    }

    bool hasOverlap(double a, double b, double c, double d) {
      final double min1 = a < b ? a : b;
      final double max1 = a > b ? a : b;
      final double min2 = c < d ? c : d;
      final double max2 = c > d ? c : d;
      return min1 <= max2 && min2 <= max1;
    }

    final double d1 = cross(a1, a2, b1);
    final double d2 = cross(a1, a2, b2);
    final double d3 = cross(b1, b2, a1);
    final double d4 = cross(b1, b2, a2);

    if (((d1 > 0 && d2 < 0) || (d1 < 0 && d2 > 0)) && ((d3 > 0 && d4 < 0) || (d3 < 0 && d4 > 0))) {
      return true;
    }

    if (d1 == 0 && hasOverlap(a1.dx, a2.dx, b1.dx, b1.dx) && hasOverlap(a1.dy, a2.dy, b1.dy, b1.dy)) {
      return true;
    }
    if (d2 == 0 && hasOverlap(a1.dx, a2.dx, b2.dx, b2.dx) && hasOverlap(a1.dy, a2.dy, b2.dy, b2.dy)) {
      return true;
    }
    if (d3 == 0 && hasOverlap(b1.dx, b2.dx, a1.dx, a1.dx) && hasOverlap(b1.dy, b2.dy, a1.dy, a1.dy)) {
      return true;
    }
    if (d4 == 0 && hasOverlap(b1.dx, b2.dx, a2.dx, a2.dx) && hasOverlap(b1.dy, b2.dy, a2.dy, a2.dy)) {
      return true;
    }

    return false;
  }

  PerspectiveOctagon _moveHandle(PerspectiveOctagon octagon, int index, Offset delta, Rect bounds) {
    PerspectiveOctagon next = octagon;
    switch (index) {
      case 0:
        next = octagon.copyWith(topLeft: octagon.topLeft + delta);
        break;
      case 1:
        next = octagon.copyWith(topCenter: octagon.topCenter + delta);
        break;
      case 2:
        next = octagon.copyWith(topRight: octagon.topRight + delta);
        break;
      case 3:
        next = octagon.copyWith(rightCenter: octagon.rightCenter + delta);
        break;
      case 4:
        next = octagon.copyWith(bottomRight: octagon.bottomRight + delta);
        break;
      case 5:
        next = octagon.copyWith(bottomCenter: octagon.bottomCenter + delta);
        break;
      case 6:
        next = octagon.copyWith(bottomLeft: octagon.bottomLeft + delta);
        break;
      case 7:
        next = octagon.copyWith(leftCenter: octagon.leftCenter + delta);
        break;
    }
    final PerspectiveOctagon clamped = PerspectiveCropMath.clampOctagon(next, bounds);
    if (!_isValidQuad(clamped.toQuad())) {
      return octagon;
    }
    return clamped;
  }

  void _handlePanStart(Offset localPosition, List<PerspectiveControlPointData> handles) {
    final int? handleIndex = _findHandleIndex(localPosition, handles);
    if (handleIndex == null) {
      return;
    }

    setState(() {
      _activeHandleIndex = handleIndex;
      _activeFocalPoint = _handleFocalPoint(_octagon!, handleIndex);
    });
  }

  void _handlePanUpdate(Offset delta, Rect imageRect) {
    final int? activeHandleIndex = _activeHandleIndex;
    final PerspectiveOctagon? octagon = _octagon;
    if (activeHandleIndex == null || octagon == null) {
      return;
    }

    final PerspectiveOctagon nextOctagon = _moveHandle(octagon, activeHandleIndex, delta, imageRect);
    final Offset nextFocalPoint = _handleFocalPoint(nextOctagon, activeHandleIndex);

    setState(() {
      _octagon = nextOctagon;
      _lastCustomOctagon = nextOctagon;
      _activeFocalPoint = nextFocalPoint;
    });

    widget.onSelectionChanged?.call(nextOctagon.toQuad());
  }

  void _handlePanEnd() {
    setState(() {
      _activeHandleIndex = null;
      _activeFocalPoint = null;
    });
  }

  Widget _buildDefaultHandle(BuildContext context, PerspectiveControlPointData data) {
    final PerspectiveHandleStyle style = widget.style.handleStyle;
    return IgnorePointer(
      child: Container(
        width: style.size,
        height: style.size,
        decoration: BoxDecoration(
          color: style.fillColor,
          shape: BoxShape.circle,
          border: Border.all(color: style.borderColor, width: style.borderWidth),
        ),
      ),
    );
  }

  Widget _buildDefaultActionButton(IconData icon, VoidCallback onPressed) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(
        icon,
        color: widget.style.actionBarStyle.iconColor,
        size: widget.style.actionBarStyle.iconSize,
      ),
    );
  }

  Rect _computeImageRect(Size layoutSize, ui.Image image) {
    final FittedSizes fitted = applyBoxFit(
      BoxFit.contain,
      Size(image.width.toDouble(), image.height.toDouble()),
      layoutSize,
    );
    final Size destination = fitted.destination;
    final Offset offset = Offset(
      (layoutSize.width - destination.width) / 2,
      (layoutSize.height - destination.height) / 2,
    );
    return offset & destination;
  }

  @override
  Widget build(BuildContext context) {
    if (_decodedImage == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final Size layoutSize = Size(constraints.maxWidth, constraints.maxHeight);
        final Rect imageRect = _computeImageRect(layoutSize, _decodedImage!);
        _initializeOctagonIfNeeded(imageRect);
        if (_octagon == null || _isInitializingSelection) {
          return Container(
            color: widget.style.backgroundColor,
            alignment: Alignment.center,
            child: const CircularProgressIndicator(),
          );
        }
        final PerspectiveOctagon octagon = _octagon!;
        final List<PerspectiveControlPointData> handles = _buildHandleData(octagon);

        final Widget closeButton = widget.builders.closeButtonBuilder?.call(context, _handleClose) ?? _buildDefaultActionButton(Icons.close, _handleClose);
        final Widget switchButton = widget.builders.switchButtonBuilder?.call(context, _handleSwitch) ?? _buildDefaultActionButton(Icons.crop_free, _handleSwitch);
        final Widget completeButton = widget.builders.completeButtonBuilder?.call(context, _handleComplete) ?? _buildDefaultActionButton(Icons.check, _handleComplete);

        Widget content = Container(
          color: widget.style.backgroundColor,
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: RawImage(
                  image: _decodedImage,
                  fit: BoxFit.contain,
                ),
              ),
              Positioned.fill(
                child: CustomPaint(
                  painter: _PerspectiveCropPainter(
                    imageRect: imageRect,
                    octagon: octagon,
                    style: widget.style,
                  ),
                ),
              ),
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onPanStart: (DragStartDetails details) {
                    _handlePanStart(details.localPosition, handles);
                  },
                  onPanUpdate: (DragUpdateDetails details) {
                    _handlePanUpdate(details.delta, imageRect);
                  },
                  onPanEnd: (_) {
                    _handlePanEnd();
                  },
                  onPanCancel: _handlePanEnd,
                ),
              ),
              ...handles.map((PerspectiveControlPointData data) {
                final Widget handle = widget.builders.handleBuilder?.call(context, data) ?? _buildDefaultHandle(context, data);
                return Positioned(
                  left: data.offset.dx - widget.style.handleStyle.size / 2,
                  top: data.offset.dy - widget.style.handleStyle.size / 2,
                  child: IgnorePointer(child: handle),
                );
              }),
              if (_activeFocalPoint != null)
                Positioned(
                  left: 16,
                  top: MediaQuery.paddingOf(context).top + 16,
                  child: IgnorePointer(
                    child: _PerspectiveMagnifier(
                      image: _decodedImage!,
                      imageRect: imageRect,
                      focalPoint: _activeFocalPoint!,
                      style: widget.style,
                      builder: widget.builders.magnifierBuilder,
                    ),
                  ),
                ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  color: widget.style.actionBarStyle.backgroundColor,
                  padding: widget.style.actionBarStyle.padding,
                  child: (widget.controller != null ? widget.builders.bottomBarWithControllerBuilder?.call(context, widget.controller!, closeButton, switchButton, completeButton) : null) ??
                      widget.builders.bottomBarBuilder?.call(context, closeButton, switchButton, completeButton) ??
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[closeButton, switchButton, completeButton],
                      ),
                ),
              ),
              if (_isCropping)
                const Positioned.fill(
                  child: ColoredBox(
                    color: Color(0x66000000),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
            ],
          ),
        );

        if (widget.builders.gridOverlayBuilder != null) {
          content = widget.builders.gridOverlayBuilder!(context, content);
        }
        if (widget.builders.lineOverlayBuilder != null) {
          content = widget.builders.lineOverlayBuilder!(context, content);
        }
        return content;
      },
    );
  }
}

class _PerspectiveMagnifier extends StatelessWidget {
  const _PerspectiveMagnifier({
    required this.image,
    required this.imageRect,
    required this.focalPoint,
    required this.style,
    required this.builder,
  });

  final ui.Image image;
  final Rect imageRect;
  final Offset focalPoint;
  final ImagePerspectiveCropStyle style;
  final PerspectiveMagnifierBuilder? builder;

  @override
  Widget build(BuildContext context) {
    final double size = style.magnifierStyle.size;
    Widget child = ClipOval(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: style.magnifierStyle.backgroundColor,
          shape: BoxShape.circle,
          border: Border.all(
            color: style.magnifierStyle.borderColor,
            width: style.magnifierStyle.borderWidth,
          ),
        ),
        child: CustomPaint(
          painter: _PerspectiveMagnifierPainter(
            image: image,
            imageRect: imageRect,
            focalPoint: focalPoint,
            style: style,
          ),
        ),
      ),
    );
    if (builder != null) {
      child = builder!(context, child);
    }
    return child;
  }
}

class _PerspectiveMagnifierPainter extends CustomPainter {
  const _PerspectiveMagnifierPainter({
    required this.image,
    required this.imageRect,
    required this.focalPoint,
    required this.style,
  });

  final ui.Image image;
  final Rect imageRect;
  final Offset focalPoint;
  final ImagePerspectiveCropStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipPath(Path()..addOval(Offset.zero & size));
    final double scale = style.magnifierStyle.scale;
    final double centerX = (((focalPoint.dx - imageRect.left) / imageRect.width).clamp(0.0, 1.0) as num).toDouble() * image.width;
    final double centerY = (((focalPoint.dy - imageRect.top) / imageRect.height).clamp(0.0, 1.0) as num).toDouble() * image.height;
    final Rect srcRect = Rect.fromCenter(
      center: Offset(centerX, centerY),
      width: image.width / scale,
      height: image.height / scale,
    );
    canvas.drawImageRect(
      image,
      srcRect,
      Offset.zero & size,
      Paint(),
    );
    final Paint crosshair = Paint()
      ..color = Colors.white
      ..strokeWidth = 1;
    canvas.drawLine(Offset(size.width / 2, 0), Offset(size.width / 2, size.height), crosshair);
    canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), crosshair);
  }

  @override
  bool shouldRepaint(covariant _PerspectiveMagnifierPainter oldDelegate) {
    return oldDelegate.focalPoint != focalPoint || oldDelegate.image != image;
  }
}

 class _PerspectiveCropPainter extends CustomPainter {
  const _PerspectiveCropPainter({
    required this.imageRect,
    required this.octagon,
    required this.style,
  });

  final Rect imageRect;
  final PerspectiveOctagon octagon;
  final ImagePerspectiveCropStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    final List<Offset> points = octagon.toList();
    final Path quadPath = Path()
      ..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      quadPath.lineTo(points[i].dx, points[i].dy);
    }
    quadPath.close();
    canvas.drawPath(
      Path.combine(PathOperation.difference, Path()..addRect(Offset.zero & size), quadPath),
      Paint()..color = style.overlayColor,
    );

    if (style.gridStyle.visible) {
      final Paint gridPaint = Paint()
        ..color = style.gridStyle.color
        ..strokeWidth = style.gridStyle.strokeWidth;
      for (int i = 1; i <= style.gridStyle.verticalDivisions; i++) {
        final double t = i / (style.gridStyle.verticalDivisions + 1);
        final double dx = imageRect.left + (imageRect.width * t);
        final Offset top = Offset(dx, imageRect.top);
        final Offset bottom = Offset(dx, imageRect.bottom);
        canvas.drawLine(top, bottom, gridPaint);
      }
      for (int i = 1; i <= style.gridStyle.horizontalDivisions; i++) {
        final double t = i / (style.gridStyle.horizontalDivisions + 1);
        final double dy = imageRect.top + (imageRect.height * t);
        final Offset left = Offset(imageRect.left, dy);
        final Offset right = Offset(imageRect.right, dy);
        canvas.drawLine(left, right, gridPaint);
      }
    }

    final Paint linePaint = Paint()
      ..color = style.lineStyle.color
      ..strokeWidth = style.lineStyle.strokeWidth
      ..style = PaintingStyle.stroke;
    canvas.drawPath(quadPath, linePaint);
  }

  @override
  bool shouldRepaint(covariant _PerspectiveCropPainter oldDelegate) {
    return oldDelegate.octagon != octagon || oldDelegate.imageRect != imageRect || oldDelegate.style != style;
  }
}
