import 'package:flutter/foundation.dart';

import 'image_perspective_crop_models.dart';

class ImagePerspectiveCropController extends ChangeNotifier {
  VoidCallback? _onClose;
  VoidCallback? _onSwitch;
  Future<PerspectiveCropResult?> Function()? _onComplete;

  void bind({
    VoidCallback? onClose,
    VoidCallback? onSwitch,
    Future<PerspectiveCropResult?> Function()? onComplete,
  }) {
    _onClose = onClose;
    _onSwitch = onSwitch;
    _onComplete = onComplete;
  }

  void unbind() {
    _onClose = null;
    _onSwitch = null;
    _onComplete = null;
  }

  void close() {
    _onClose?.call();
  }

  void switchSelection() {
    _onSwitch?.call();
  }

  Future<PerspectiveCropResult?> complete() async {
    return _onComplete?.call();
  }
}
