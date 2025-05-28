// lib/controllers/Talk_Video_Controller.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

class TalkVideoEmbed extends StatefulWidget {
  final String url;
  const TalkVideoEmbed({required this.url, Key? key}) : super(key: key);

  @override
  State<TalkVideoEmbed> createState() => _TalkVideoEmbedState();
}

class _TalkVideoEmbedState extends State<TalkVideoEmbed> {
  late final PlatformWebViewControllerCreationParams _params;
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();

    if (Platform.isAndroid) {
      _params = AndroidWebViewControllerCreationParams();
    } else {
      _params = const PlatformWebViewControllerCreationParams();
    }

    _controller = WebViewController.fromPlatformCreationParams(_params)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(widget.url));

    if (_controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      (_controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: _controller);
  }
}
