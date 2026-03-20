# flutter_image_perspective_crop
# 一个支持透视裁剪的 Flutter 组件

A Flutter package for perspective crop editing with draggable corner and edge handles, fixed reference guides, magnifier preview, external controller support, and pure Dart perspective crop output.
一个 Flutter 包，提供可拖拽的角点/边中点、固定参考辅助线、拖拽放大镜、外部控制器，以及纯 Dart 实现的透视裁剪输出。

## Features
## 功能特性

- Perspective crop editor based on `Uint8List`
- 基于 `Uint8List` 的透视裁剪编辑器
- 4 corner handles and 4 edge-center handles
- 4 个角点 + 4 个边中点控制手柄
- Fixed reference guide lines inside the displayed image area
- 显示区域内的固定参考辅助线
- Magnifier preview while dragging
- 拖拽时显示放大镜预览
- External control via `ImagePerspectiveCropController`
- 通过 `ImagePerspectiveCropController` 支持外部控制
- Customizable handles, overlays, action buttons, and bottom bar
- 控制点、叠加层、动作按钮、底部栏均可自定义
- Streaming completion events (processing/startSend/sending/complete/error) to avoid UI freeze on large images
- 支持流式完成事件（processing/startSend/sending/complete/error），大图时避免 UI 卡顿

## Getting started
## 快速开始

Add the dependency in your `pubspec.yaml`:
在 `pubspec.yaml` 中添加依赖：

```yaml
dependencies:
  flutter_image_perspective_crop: ^0.0.3
```

Then import it:
然后在代码中引入：

```dart
import 'package:flutter_image_perspective_crop/flutter_image_perspective_crop.dart';
```

## Usage
## 使用方法

### Basic usage (streaming events)
### 最简单用法（流式事件）

```dart
final List<int> sinkBytes = <int>[];

ImagePerspectiveCrop(
  image: state.imageBytes, // 必传 only required
  onCloseRequested: () {},
  onCompleted: (PerspectiveCropResult event) async {
    switch (event.status) {
      case PerspectiveCropStatus.processing:
        // show loading
        break;
      case PerspectiveCropStatus.startSend:
        sinkBytes.clear();
        break;
      case PerspectiveCropStatus.sending:
        if (event.chunk != null) sinkBytes.addAll(event.chunk!);
        break;
      case PerspectiveCropStatus.complete:
        final Uint8List bytes = Uint8List.fromList(sinkBytes);
        debugPrint('final bytes: ${bytes.length}, src: ${event.imageWidth}x${event.imageHeight}');
        break;
      case PerspectiveCropStatus.error:
        debugPrint('error: ${event.errorMessage}');
        break;
    }
  },
)
```

### Controller + custom button
### 使用 controller + 自定义按钮

```dart
final ImagePerspectiveCropController _controller = ImagePerspectiveCropController();
final List<int> sinkBytes = <int>[];

@override
void initState() {
  super.initState();
  _controller.onCompleted((PerspectiveCropResult event) async {
    switch (event.status) {
      case PerspectiveCropStatus.processing:
        break;
      case PerspectiveCropStatus.startSend:
        sinkBytes.clear();
        break;
      case PerspectiveCropStatus.sending:
        if (event.chunk != null) sinkBytes.addAll(event.chunk!);
        break;
      case PerspectiveCropStatus.complete:
        final Uint8List bytes = Uint8List.fromList(sinkBytes);
        debugPrint('controller bytes: ${bytes.length}');
        break;
      case PerspectiveCropStatus.error:
        debugPrint('error: ${event.errorMessage}');
        break;
    }
  });
}

// In your button
await _controller.complete();

// Widget
ImagePerspectiveCrop(
  image: state.imageBytes,
  controller: _controller,
  builders: ImagePerspectiveCropBuilders(
    bottomBarWithControllerBuilder: (
      BuildContext context,
      ImagePerspectiveCropController controller,
      Widget closeButton,
      Widget switchButton,
      Widget completeButton,
    ) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          closeButton,
          switchButton,
          ElevatedButton(
            onPressed: () async {
              await controller.complete();
            },
            child: const Text('Done'),
          ),
        ],
      );
    },
  ),
  onCompleted: (_) async {}, // 可留空，主监听用 controller
)
```

## Customization
## 自定义能力

`ImagePerspectiveCropBuilders` currently supports customizing:
`ImagePerspectiveCropBuilders` 目前支持自定义：

- Close button
- 关闭按钮
- Switch button
- 切换按钮
- Complete button
- 完成按钮
- Handle widgets
- 控制点样式
- Grid overlay wrapper
- 网格叠加包装
- Line overlay wrapper
- 边框线叠加包装
- Magnifier wrapper
- 放大镜包装
- Bottom bar
- 底部栏
- Bottom bar with controller
- 带 controller 的底部栏

`ImagePerspectiveCropStyle` can be used to customize colors, handle size, line style, grid style, magnifier style, and action bar style.
`ImagePerspectiveCropStyle` 可用于自定义颜色、控制点尺寸、边框线样式、网格样式、放大镜样式、底部栏样式。



## License
## 许可证

MIT
