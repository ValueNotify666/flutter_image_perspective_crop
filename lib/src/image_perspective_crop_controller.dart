import 'package:flutter/foundation.dart';

import 'image_perspective_crop_models.dart';

typedef PerspectiveCropListener = Future<void> Function(PerspectiveCropResult event);

class ImagePerspectiveCropController extends ChangeNotifier {
  VoidCallback? _onClose;
  VoidCallback? _onSwitch;
  Future<void> Function()? _onComplete;
  PerspectiveCropListener? _onCompleted;

  void bind({
    VoidCallback? onClose,
    VoidCallback? onSwitch,
    Future<void> Function()? onComplete,
  }) {
    _onClose = onClose;
    _onSwitch = onSwitch;
    _onComplete = onComplete;
  }

  void unbind() {
    _onClose = null;
    _onSwitch = null;
    _onComplete = null;
    _onCompleted = null;
  }

  void close() {
    _onClose?.call();
  }

  void switchSelection() {
    _onSwitch?.call();
  }

  void onCompleted(PerspectiveCropListener listener) {
    _onCompleted = listener;
  }

  Future<void> dispatchCompleted(PerspectiveCropResult event) async {
    await _onCompleted?.call(event);
  }

  Future<void> complete() async {
    await _onComplete?.call();
  }
}
