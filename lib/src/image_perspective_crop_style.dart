import 'package:flutter/material.dart';

@immutable
class PerspectiveGridStyle {
  const PerspectiveGridStyle({
    this.color = const Color(0x66FFFFFF),
    this.strokeWidth = 1,
    this.horizontalDivisions = 2,
    this.verticalDivisions = 2,
    this.visible = true,
  });

  final Color color;
  final double strokeWidth;
  final int horizontalDivisions;
  final int verticalDivisions;
  final bool visible;
}

@immutable
class PerspectiveLineStyle {
  const PerspectiveLineStyle({
    this.color = const Color(0xFFFFC84A),
    this.strokeWidth = 2,
  });

  final Color color;
  final double strokeWidth;
}

@immutable
class PerspectiveHandleStyle {
  const PerspectiveHandleStyle({
    this.size = 28,
    this.fillColor = const Color(0xFF8FFBFF),
    this.borderColor = Colors.white,
    this.borderWidth = 2,
  });

  final double size;
  final Color fillColor;
  final Color borderColor;
  final double borderWidth;
}

@immutable
class PerspectiveMagnifierStyle {
  const PerspectiveMagnifierStyle({
    this.size = 92,
    this.scale = 2.4,
    this.borderColor = Colors.white,
    this.borderWidth = 2,
    this.backgroundColor = Colors.black,
  });

  final double size;
  final double scale;
  final Color borderColor;
  final double borderWidth;
  final Color backgroundColor;
}

@immutable
class PerspectiveActionBarStyle {
  const PerspectiveActionBarStyle({
    this.padding = const EdgeInsets.fromLTRB(32, 16, 32, 32),
    this.iconColor = Colors.white,
    this.iconSize = 34,
    this.backgroundColor = Colors.black,
  });

  final EdgeInsets padding;
  final Color iconColor;
  final double iconSize;
  final Color backgroundColor;
}

@immutable
class ImagePerspectiveCropStyle {
  const ImagePerspectiveCropStyle({
    this.backgroundColor = Colors.black,
    this.overlayColor = const Color(0x88000000),
    this.gridStyle = const PerspectiveGridStyle(),
    this.lineStyle = const PerspectiveLineStyle(),
    this.handleStyle = const PerspectiveHandleStyle(),
    this.magnifierStyle = const PerspectiveMagnifierStyle(),
    this.actionBarStyle = const PerspectiveActionBarStyle(),
  });

  final Color backgroundColor;
  final Color overlayColor;
  final PerspectiveGridStyle gridStyle;
  final PerspectiveLineStyle lineStyle;
  final PerspectiveHandleStyle handleStyle;
  final PerspectiveMagnifierStyle magnifierStyle;
  final PerspectiveActionBarStyle actionBarStyle;
}
