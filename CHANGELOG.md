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

## 0.0.3

- Move perspective crop processing (decode -> crop -> encode) to a background isolate to avoid UI freeze on large images.
- Add streaming completion events with 5 statuses: processing, startSend, sending, complete, error; `onCompleted` now receives multiple events and chunks instead of a single final bytes payload.
- Example updated to show basic usage and controller customization under the new streaming API.
- 将透视裁剪的解码/裁剪/编码迁移到后台 isolate，避免大图时阻塞 UI。
- 新增 5 个状态的流式完成事件：processing、startSend、sending、complete、error；`onCompleted` 会多次回调并携带分片，而不是单次返回完整字节。
- 示例更新，展示默认用法和带 controller 的自定义用法，适配新的流式 API。
