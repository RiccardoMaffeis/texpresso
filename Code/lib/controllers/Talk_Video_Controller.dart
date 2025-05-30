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
  bool _isLoading = true; // ← stato di caricamento

  @override
  void initState() {
    super.initState();

    // 1) parametri come prima
    if (Platform.isAndroid) {
      _params = AndroidWebViewControllerCreationParams();
    } else {
      _params = const PlatformWebViewControllerCreationParams();
    }
    _controller = WebViewController.fromPlatformCreationParams(_params)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      // 2) installiamo il NavigationDelegate per tracciare inizio/fine caricamento
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() => _isLoading = true);
          },
          onPageFinished: (url) {
            setState(() => _isLoading = false);
          },
          onWebResourceError: (err) {
            // opzionale: gestisci gli errori di caricamento
            setState(() => _isLoading = false);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));

    // 3) debug & autoplay come prima
    if (_controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      (_controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Blocca i tocchi se stiamo ancora caricando
        AbsorbPointer(
          absorbing: _isLoading,
          child: WebViewWidget(controller: _controller),
        ),
        if (_isLoading)
          // indicatore al centro
          const Center(
            child: CircularProgressIndicator(),
          ),
      ],
    );
  }
}
