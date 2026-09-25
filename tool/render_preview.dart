// Renders the current Flutter interface into a deterministic website asset.
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:quota_bubble/desktop_app.dart';
import 'package:quota_bubble/presentation/quota_window.dart';

import 'preview.dart' show PreviewController;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = PreviewController()..windowVisible = false;
  final boundaryKey = GlobalKey();
  final output = Platform.environment['QUOTA_BUBBLE_PREVIEW_OUTPUT'];
  if (output == null || output.isEmpty) {
    stderr.writeln('QUOTA_BUBBLE_PREVIEW_OUTPUT must name the output PNG.');
    exitCode = 64;
    return;
  }

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Material(
        color: const Color(0xff111817),
        child: Center(
          child: RepaintBoundary(
            key: boundaryKey,
            child: Container(
              width: 330,
              height: QuotaWindow.heightFor(controller),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: const Color(0xff071f25),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xff294248), width: .5),
              ),
              child: QuotaWindow(
                controller: controller,
                onClose: () {},
                version: appVersion,
              ),
            ),
          ),
        ),
      ),
    ),
  );

  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(_capture(boundaryKey, output, controller));
  });
}

Future<void> _capture(
  GlobalKey boundaryKey,
  String output,
  PreviewController controller,
) async {
  await Future<void>.delayed(const Duration(milliseconds: 400));
  final boundary =
      boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
  if (boundary == null) {
    stderr.writeln('Preview boundary was not rendered.');
    exit(1);
  }
  final image = await boundary.toImage(pixelRatio: 2);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  if (data == null) {
    stderr.writeln('Preview image could not be encoded.');
    exit(1);
  }
  final file = File(output);
  await file.parent.create(recursive: true);
  await file.writeAsBytes(data.buffer.asUint8List(), flush: true);
  controller.dispose();
  exit(0);
}
