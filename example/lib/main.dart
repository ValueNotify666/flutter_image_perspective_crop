import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_image_perspective_crop/flutter_image_perspective_crop.dart';

void main() {
  runApp(const PerspectiveCropExampleApp());
}

class PerspectiveCropExampleApp extends StatefulWidget {
  const PerspectiveCropExampleApp({super.key});

  @override
  State<PerspectiveCropExampleApp> createState() =>
      _PerspectiveCropExampleAppState();
}

class _PerspectiveCropExampleAppState extends State<PerspectiveCropExampleApp> {
  Uint8List? _imageBytes;
  final ImagePerspectiveCropController _controller = ImagePerspectiveCropController();
  final List<int> _defaultSinkBytes = <int>[];
  final List<int> _controllerSinkBytes = <int>[];
  String _defaultStatus = 'idle';
  String _controllerStatus = 'idle';

  @override
  void initState() {
    super.initState();
    _loadSample();
    _controller.onCompleted(_handleControllerCompleted);
  }

  Future<void> _loadSample() async {
    const String base64Image =
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAusB9YtX1rkAAAAASUVORK5CYII=';
    final Uint8List bytes = base64.decode(base64Image);
    setState(() => _imageBytes = bytes);
  }

  Future<void> _handleDefaultCompleted(PerspectiveCropResult event) async {
    final String nextStatus = event.status.name;
    switch (event.status) {
      case PerspectiveCropStatus.processing:
        break;
      case PerspectiveCropStatus.startSend:
        _defaultSinkBytes.clear();
        break;
      case PerspectiveCropStatus.sending:
        if (event.chunk != null) {
          _defaultSinkBytes.addAll(event.chunk!);
        }
        break;
      case PerspectiveCropStatus.complete:
        debugPrint('Default flow bytes length: ${_defaultSinkBytes.length}');
        break;
      case PerspectiveCropStatus.error:
        debugPrint('Default flow error: ${event.errorMessage}');
        break;
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _defaultStatus = nextStatus;
    });
  }

  Future<void> _handleControllerCompleted(PerspectiveCropResult event) async {
    final String nextStatus = event.status.name;
    switch (event.status) {
      case PerspectiveCropStatus.processing:
        break;
      case PerspectiveCropStatus.startSend:
        _controllerSinkBytes.clear();
        break;
      case PerspectiveCropStatus.sending:
        if (event.chunk != null) {
          _controllerSinkBytes.addAll(event.chunk!);
        }
        break;
      case PerspectiveCropStatus.complete:
        debugPrint('Controller flow bytes length: ${_controllerSinkBytes.length}');
        break;
      case PerspectiveCropStatus.error:
        debugPrint('Controller flow error: ${event.errorMessage}');
        break;
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _controllerStatus = nextStatus;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Perspective Crop Example')),
        body: _imageBytes == null
            ? const Center(child: CircularProgressIndicator())
            : DefaultTabController(
                length: 2,
                child: Column(
                  children: <Widget>[
                    const TabBar(
                      tabs: <Widget>[
                        Tab(text: 'Simple'),
                        Tab(text: 'Controller'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: <Widget>[
                          Column(
                            children: <Widget>[
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text('Simple status: $_defaultStatus'),
                              ),
                              Expanded(
                                child: ImagePerspectiveCrop(
                                  image: _imageBytes!,
                                  onCloseRequested: () {
                                    debugPrint('Simple close requested');
                                  },
                                  onCompleted: _handleDefaultCompleted,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            children: <Widget>[
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text('Controller status: $_controllerStatus'),
                              ),
                              Expanded(
                                child: ImagePerspectiveCrop(
                                  image: _imageBytes!,
                                  controller: _controller,
                                  style: const ImagePerspectiveCropStyle(),
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
                                  onCompleted: (_) async {},
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
