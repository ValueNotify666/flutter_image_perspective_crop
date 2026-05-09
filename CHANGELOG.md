## 0.0.4

- Integrated flutter_opencv_ffi for initial document detection and crop enhancement.
- Changed local dependency to remote GitHub dependency: flutter_opencv_ffi from https://github.com/ValueNotify666/flutter_opencv_ffi.
- Initial detection now waits for OpenCV auto-detection to complete before showing crop UI, avoiding default crop box display.
- Added loading indicator during initial detection phase.
- Optimized detection input by using ui.Image rawRgba bytes directly, avoiding duplicate image decoding.
- Initial detection algorithm improved: downscales to max side 960px, uses grayscale text cluster detection, selects densest text region, outputs 8-point rotated rectangle with minimal expansion.
- Crop enhancement changed from adaptive threshold to CLAHE + sharpening to preserve content (e.g., colored labels) while enhancing text.
- Platform support: Currently only HarmonyOS (OHOS) due to flutter_opencv_ffi native dependency limitation.
- 集成 flutter_opencv_ffi 进行首次文档检测和裁剪增强。
- 将本地依赖改为远程 GitHub 依赖：flutter_opencv_ffi 来自 https://github.com/ValueNotify666/flutter_opencv_ffi。
- 首次定位现在等待 OpenCV 自动检测完成后再显示裁剪 UI，避免默认裁剪框提前显示。
- 首次检测阶段添加加载指示器。
- 优化检测输入，直接使用 ui.Image 的 rawRgba 字节，避免重复解码图片。
- 首次检测算法改进：降采样到最大边 960px，使用灰度文字簇检测，选择最密集文字区域，输出 8 点旋转矩形并做最小扩展。
- 裁剪增强从自适应阈值改为 CLAHE + 锐化，保留内容（如彩色标签）同时增强文字。
- 平台支持：目前仅支持鸿蒙（OHOS），因为 flutter_opencv_ffi 原生依赖目前仅支持鸿蒙原生平台。

## 0.0.3

- Move perspective crop processing (decode -> crop -> encode) to a background isolate to avoid UI freeze on large images.
- Add streaming completion events with 5 statuses: processing, startSend, sending, complete, error; `onCompleted` now receives multiple events and chunks instead of a single final bytes payload.
- Example updated to show basic usage and controller customization under the new streaming API.
- 将透视裁剪的解码/裁剪/编码迁移到后台 isolate，避免大图时阻塞 UI。
- 新增 5 个状态的流式完成事件：processing、startSend、sending、complete、error；`onCompleted` 会多次回调并携带分片，而不是单次返回完整字节。
- 示例更新，展示默认用法和带 controller 的自定义用法，适配新的流式 API。


## 0.0.2

- onCompleted/controller.complete now return `PerspectiveCropResult` (bytes + imageWidth + imageHeight).
- README and examples updated to new result model.
- onCompleted/controller.complete 现在返回 `PerspectiveCropResult`（包含 bytes、imageWidth、imageHeight）。
- README 和示例已同步新返回模型。

## 0.0.1

- Initial release.
- 初始发布。
- Perspective crop editor with 4 corners + 4 edge handles.
- 透视裁剪编辑器，包含 4 个角点 + 4 个边中点控制手柄。
- Fixed reference grid, magnifier on drag.
- 固定参考网格，拖拽时显示放大镜。
- External controller: close / switchSelection / complete (returns Uint8List?).
- 外部控制器：close / switchSelection / complete（返回 Uint8List?）。
- Builders to customize handles, overlays, buttons, bottom bar (with controller).
- 提供 builders 自定义控制点、叠加层、按钮、底部栏（含 controller 版本）。

