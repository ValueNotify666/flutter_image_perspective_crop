import 'dart:typed_data';

import 'package:flutter/foundation.dart';

class ImagePerspectiveCropController extends ChangeNotifier {
  VoidCallback? _onClose;
  VoidCallback? _onSwitch;
  Future<Uint8List?> Function()? _onComplete;

  void bind({
    VoidCallback? onClose,
    VoidCallback? onSwitch,
    Future<Uint8List?> Function()? onComplete,
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

  Future<Uint8List?> complete() async {
    return _onComplete?.call();
  }
}
