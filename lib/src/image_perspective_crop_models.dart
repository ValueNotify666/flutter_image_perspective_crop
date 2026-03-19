import 'dart:ui';

enum PerspectiveControlPointType {
  corner,
  edge,
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
