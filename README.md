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
- Returns cropped result as `Uint8List`
- 裁剪结果返回 `Uint8List`

## Getting started
## 快速开始

Add the dependency in your `pubspec.yaml`:
在 `pubspec.yaml` 中添加依赖：

```yaml
dependencies:
  flutter_image_perspective_crop: ^0.0.1
```

Then import it:
然后在代码中引入：

```dart
import 'package:flutter_image_perspective_crop/flutter_image_perspective_crop.dart';
```

## Usage
## 使用方法

### Basic usage
### 最简单用法

```dart
final ImagePerspectiveCropController _cropController = ImagePerspectiveCropController();

ImagePerspectiveCrop(
  image: state.imageBytes,
  controller: _cropController,
  onCloseRequested: () {
  },
  onCompleted: (Uint8List data) {
    MyLogs.debug('ImageEditor cropped image bytes: $data');
  },
)
```

### Trigger complete from your own button
### 在自定义按钮中手动触发完成

If you do not replace the whole bottom bar, but you want your own custom button logic, you can call `controller.complete()` directly.
如果你不替换整个底部栏，但想用自定义按钮逻辑，可以直接调用 `controller.complete()`。

```dart
final ImagePerspectiveCropController _cropController = ImagePerspectiveCropController();

Future<void> _onTapComplete() async {
  final Uint8List? data = await _cropController.complete();
  if (data == null) {
    return;
  }
  MyLogs.debug('ImageEditor cropped image bytes: $data');
}
```

`controller.complete()` returns the cropped `Uint8List?`.
`controller.complete()` 会返回裁剪得到的 `Uint8List?`。

At the same time, `ImagePerspectiveCrop.onCompleted` will still be called after crop succeeds.
同时，裁剪成功后仍会触发 `ImagePerspectiveCrop.onCompleted`。

### Custom bottom bar
### 自定义底部栏

If you want to fully customize the bottom action bar, use `bottomBarWithControllerBuilder`.
如果需要完全自定义底部操作栏，请使用 `bottomBarWithControllerBuilder`。

```dart
final ImagePerspectiveCropController _cropController = ImagePerspectiveCropController();

ImagePerspectiveCrop(
  image: state.imageBytes,
  controller: _cropController,
  onCompleted: (Uint8List data) {
    MyLogs.debug('ImageEditor cropped image bytes: $data');
  },
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
          IconButton(
            onPressed: controller.close,
            icon: const Icon(Icons.close),
          ),
          IconButton(
            onPressed: controller.switchSelection,
            icon: const Icon(Icons.crop_free),
          ),
          IconButton(
            onPressed: () async {
              final Uint8List? data = await controller.complete();
              if (data == null) {
                return;
              }
              print('ImageEditor cropped image bytes: $data');
            },
            icon: const Icon(Icons.check),
          ),
        ],
      );
    },
  ),
)
```

### Notes about `controller.complete()` and `onCompleted`
### 关于 `controller.complete()` 与 `onCompleted` 的说明

`controller.complete()` and `onCompleted` are both valid result channels:
`controller.complete()` 和 `onCompleted` 都是有效的结果通道：

- `await controller.complete()` lets your custom button get the crop result directly
- `await controller.complete()` 让自定义按钮直接获取裁剪结果
- `onCompleted(Uint8List data)` is the widget-level completion callback
- `onCompleted(Uint8List data)` 是组件级完成回调

If you use both, your business code may receive the same crop result twice. Choose one main consumption path based on your architecture.
如果同时使用，两边都会收到结果，请按业务架构选择一个主要的处理路径，避免重复处理。

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
