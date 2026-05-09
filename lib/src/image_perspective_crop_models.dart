import 'dart:typed_data';
import 'dart:ui';

enum PerspectiveControlPointType {
  corner,
  edge,
}

enum PerspectiveCropStatus {
  processing,
  startSend,
  sending,
  complete,
  error,
}

enum PerspectiveControlPointPosition {
  topLeft,
  topCenter,
  topRight,
  rightCenter,
  bottomRight,
  bottomCenter,
  bottomLeft,
  leftCenter,
}

class PerspectiveQuad {
  const PerspectiveQuad({
    required this.topLeft,
    required this.topRight,
    required this.bottomRight,
    required this.bottomLeft,
  });

  final Offset topLeft;
  final Offset topRight;
  final Offset bottomRight;
  final Offset bottomLeft;

  List<Offset> toList() {
    return <Offset>[topLeft, topRight, bottomRight, bottomLeft];
  }

  PerspectiveQuad copyWith({
    Offset? topLeft,
    Offset? topRight,
    Offset? bottomRight,
    Offset? bottomLeft,
  }) {
    return PerspectiveQuad(
      topLeft: topLeft ?? this.topLeft,
      topRight: topRight ?? this.topRight,
      bottomRight: bottomRight ?? this.bottomRight,
      bottomLeft: bottomLeft ?? this.bottomLeft,
    );
  }

  static PerspectiveQuad fromRect(Rect rect) {
    return PerspectiveQuad(
      topLeft: rect.topLeft,
      topRight: rect.topRight,
      bottomRight: rect.bottomRight,
      bottomLeft: rect.bottomLeft,
    );
  }
}

class PerspectiveOctagon {
  const PerspectiveOctagon({
    required this.topLeft,
    required this.topCenter,
    required this.topRight,
    required this.rightCenter,
    required this.bottomRight,
    required this.bottomCenter,
    required this.bottomLeft,
    required this.leftCenter,
  });

  final Offset topLeft;
  final Offset topCenter;
  final Offset topRight;
  final Offset rightCenter;
  final Offset bottomRight;
  final Offset bottomCenter;
  final Offset bottomLeft;
  final Offset leftCenter;

  List<Offset> toList() {
    return <Offset>[
      topLeft,
      topCenter,
      topRight,
      rightCenter,
      bottomRight,
      bottomCenter,
      bottomLeft,
      leftCenter,
    ];
  }

  PerspectiveQuad toQuad() {
    return PerspectiveQuad(
      topLeft: topLeft,
      topRight: topRight,
      bottomRight: bottomRight,
      bottomLeft: bottomLeft,
    );
  }

  PerspectiveOctagon copyWith({
    Offset? topLeft,
    Offset? topCenter,
    Offset? topRight,
    Offset? rightCenter,
    Offset? bottomRight,
    Offset? bottomCenter,
    Offset? bottomLeft,
    Offset? leftCenter,
  }) {
    return PerspectiveOctagon(
      topLeft: topLeft ?? this.topLeft,
      topCenter: topCenter ?? this.topCenter,
      topRight: topRight ?? this.topRight,
      rightCenter: rightCenter ?? this.rightCenter,
      bottomRight: bottomRight ?? this.bottomRight,
      bottomCenter: bottomCenter ?? this.bottomCenter,
      bottomLeft: bottomLeft ?? this.bottomLeft,
      leftCenter: leftCenter ?? this.leftCenter,
    );
  }

  static PerspectiveOctagon fromRect(Rect rect) {
    return PerspectiveOctagon(
      topLeft: rect.topLeft,
      topCenter: Offset(rect.center.dx, rect.top),
      topRight: rect.topRight,
      rightCenter: Offset(rect.right, rect.center.dy),
      bottomRight: rect.bottomRight,
      bottomCenter: Offset(rect.center.dx, rect.bottom),
      bottomLeft: rect.bottomLeft,
      leftCenter: Offset(rect.left, rect.center.dy),
    );
  }
}

class PerspectiveControlPointData {
  const PerspectiveControlPointData({
    required this.index,
    required this.position,
    required this.offset,
    required this.type,
    required this.isActive,
  });

  final int index;
  final PerspectiveControlPointPosition position;
  final Offset offset;
  final PerspectiveControlPointType type;
  final bool isActive;
}

class PerspectiveCropResult {
  const PerspectiveCropResult({
    required this.status,
    this.bytes,
    this.chunk,
    this.imageWidth,
    this.imageHeight,
    this.sentBytes,
    this.totalBytes,
    this.errorMessage,
  });

  final PerspectiveCropStatus status;
  final Uint8List? bytes;
  final Uint8List? chunk;
  final int? imageWidth;
  final int? imageHeight;
  final int? sentBytes;
  final int? totalBytes;
  final String? errorMessage;
}
