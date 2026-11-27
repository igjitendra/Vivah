import 'dart:io';
import 'package:flutter/material.dart';

/// Shared full-screen interactive pinch-to-zoom image viewer.
class FullScreenImageViewer extends StatelessWidget {
  final String imagePath;
  final String? title;

  const FullScreenImageViewer({
    super.key,
    required this.imagePath,
    this.title,
  });

  static void show(BuildContext context, String imagePath, {String? title}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullScreenImageViewer(imagePath: imagePath, title: title),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final file = File(imagePath);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: title != null
            ? Text(
                title!,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              )
            : null,
      ),
      body: Center(
        child: file.existsSync()
            ? InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.file(file),
              )
            : const Icon(
                Icons.broken_image_outlined,
                color: Colors.white54,
                size: 56,
              ),
      ),
    );
  }
}
