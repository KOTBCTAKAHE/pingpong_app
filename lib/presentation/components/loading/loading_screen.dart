import 'dart:async';
import 'package:flutter/material.dart';

import 'loading_screen_controller.dart';

class LoadingScreen {
  LoadingScreen._sharedInstance();
  static final LoadingScreen _shared = LoadingScreen._sharedInstance();
  factory LoadingScreen.instance() => _shared;

  LoadingScreenController? controller;

  void show({
    required GlobalKey<NavigatorState> navigatorKey,
    required String text,
  }) {
    if (controller?.update(text) ?? false) {
      return;
    } else {
      controller = showOverlay(
        navigatorKey: navigatorKey,
        text: text,
      );
    }
  }

  void hide() {
    controller?.close();
    controller = null;
  }

  LoadingScreenController showOverlay({
    required GlobalKey<NavigatorState> navigatorKey,
    required String text,
  }) {
    final controller = StreamController<String>();
    controller.add(text);

    final OverlayState? state = navigatorKey.currentState!.overlay;
    BuildContext context = navigatorKey.currentContext!;

    final size = MediaQuery.of(context).size;

    final overlay = OverlayEntry(
      builder: (context) {
        return Material(
          color: Colors.black.withAlpha(150),
          child: Center(
            child: _LoadingWidget(size: size, controller: controller),
          ),
        );
      },
    );

    state?.insert(overlay);

    return LoadingScreenController(
      close: () {
        controller.close();
        overlay.remove();
        return true;
      },
      update: (text) {
        controller.add(text);
        return true;
      },
    );
  }
}

class _LoadingWidget extends StatelessWidget {
  const _LoadingWidget({
    Key? key,
    required this.size,
    required this.controller,
  }) : super(key: key);

  final Size size;
  final StreamController<String> controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size.width * 0.8,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 5,
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 10),
            CircularProgressIndicator(
              color: Theme.of(context).primaryColor,
              strokeWidth: 6.0,
            ),
            const SizedBox(height: 20),
            StreamBuilder<String>(
              stream: controller.stream,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Text(
                    snapshot.data!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }
}
