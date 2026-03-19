import 'package:flutter/material.dart';

import 'image_perspective_crop_controller.dart';
import 'image_perspective_crop_models.dart';

typedef PerspectiveActionButtonBuilder = Widget Function(
  BuildContext context,
  VoidCallback onPressed,
);

typedef PerspectiveHandleBuilder = Widget Function(
  BuildContext context,
  PerspectiveControlPointData data,
);

typedef PerspectiveOverlayBuilder = Widget Function(
  BuildContext context,
  Widget child,
);

typedef PerspectiveMagnifierBuilder = Widget Function(
  BuildContext context,
  Widget child,
);

typedef PerspectiveBottomBarBuilder = Widget Function(
  BuildContext context,
  Widget closeButton,
  Widget switchButton,
  Widget completeButton,
);

typedef PerspectiveBottomBarWithControllerBuilder = Widget Function(
  BuildContext context,
  ImagePerspectiveCropController controller,
  Widget closeButton,
  Widget switchButton,
  Widget completeButton,
);

@immutable
class ImagePerspectiveCropBuilders {
  const ImagePerspectiveCropBuilders({
    this.closeButtonBuilder,
    this.switchButtonBuilder,
    this.completeButtonBuilder,
    this.handleBuilder,
    this.gridOverlayBuilder,
    this.lineOverlayBuilder,
    this.magnifierBuilder,
    this.bottomBarBuilder,
    this.bottomBarWithControllerBuilder,
  });

  final PerspectiveActionButtonBuilder? closeButtonBuilder;
  final PerspectiveActionButtonBuilder? switchButtonBuilder;
  final PerspectiveActionButtonBuilder? completeButtonBuilder;
  final PerspectiveHandleBuilder? handleBuilder;
  final PerspectiveOverlayBuilder? gridOverlayBuilder;
  final PerspectiveOverlayBuilder? lineOverlayBuilder;
  final PerspectiveMagnifierBuilder? magnifierBuilder;
  final PerspectiveBottomBarBuilder? bottomBarBuilder;
  final PerspectiveBottomBarWithControllerBuilder? bottomBarWithControllerBuilder;
}
