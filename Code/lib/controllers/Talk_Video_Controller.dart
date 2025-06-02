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

class _TalkVideoEmbedState extends State<TalkVideoEmbed>
    with AutomaticKeepAliveClientMixin<TalkVideoEmbed> {
  late final PlatformWebViewControllerCreationParams _params;
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    // 1) Parametri di base
    if (Platform.isAndroid) {
      _params = AndroidWebViewControllerCreationParams();
    } else {
      _params = const PlatformWebViewControllerCreationParams();
    }

    _controller = WebViewController.fromPlatformCreationParams(_params)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) => setState(() => _isLoading = true),
          onPageFinished: (url) => setState(() => _isLoading = false),
          onWebResourceError: (_) => setState(() => _isLoading = false),
        ),
      )
      ..loadRequest(Uri.parse(widget.url));

    // 2) Disabilitiamo l’autoplay (richiede gesto utente su Android)
    if (_controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      (_controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // serve per AutomaticKeepAliveClientMixin

    return Stack(
      children: [
        AbsorbPointer(
          absorbing: _isLoading,
          child: WebViewWidget(controller: _controller),
        ),
        if (_isLoading)
          const Center(child: CircularProgressIndicator()),
      ],
    );
  }

  @override
  bool get wantKeepAlive => true;
}
