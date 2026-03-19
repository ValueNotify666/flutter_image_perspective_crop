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
  State<PerspectiveCropExampleApp> createState() => _PerspectiveCropExampleAppState();
}

class _PerspectiveCropExampleAppState extends State<PerspectiveCropExampleApp> {
  final ImagePerspectiveCropController _controller = ImagePerspectiveCropController();
  Uint8List? _imageBytes;

  @override
  void initState() {
    super.initState();
    _loadSample();
  }

  Future<void> _loadSample() async {
    // A tiny 1x1 white PNG, base64 encoded, to avoid extra assets.
    const String base64Image =
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAusB9YtX1rkAAAAASUVORK5CYII=';
    final Uint8List bytes = base64.decode(base64Image);
    setState(() => _imageBytes = bytes);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Perspective Crop Example')),
        body: _imageBytes == null
            ? const Center(child: CircularProgressIndicator())
            : ImagePerspectiveCrop(
                image: _imageBytes!,
                controller: _controller,
                onCompleted: (Uint8List data) {
                  debugPrint('Cropped bytes length: ${data.length}');
                },
              ),
      ),
    );
  }
}
