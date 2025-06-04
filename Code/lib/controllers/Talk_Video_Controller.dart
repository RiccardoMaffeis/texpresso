// lib/controllers/Talk_Video_Controller.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

class TalkVideoEmbed extends StatefulWidget {
  final String url;
  /// Se vuoi usare un’immagine di anteprima, passala qui.
  /// Altrimenti, se è null, il video verrà caricato subito.
  final String? thumbnailUrl;

  const TalkVideoEmbed({
    required this.url,
    this.thumbnailUrl,
    Key? key,
  }) : super(key: key);

  @override
  State<TalkVideoEmbed> createState() => _TalkVideoEmbedState();
}

class _TalkVideoEmbedState extends State<TalkVideoEmbed>
    with AutomaticKeepAliveClientMixin<TalkVideoEmbed> {
  /// Parametri di creazione del WebView (usati da WebViewController)
  late final PlatformWebViewControllerCreationParams _params;

  /// Il controller viene inizializzato soltanto quando serve (o subito se non c'è thumbnail)
  WebViewController? _controller;

  bool _isLoading = false;
  bool _hasStarted = false; // true quando dobbiamo mostrare il WebView

  @override
  void initState() {
    super.initState();

    // 1) Prepara i parametri di base (ma non creiamo ancora il controller)
    if (Platform.isAndroid) {
      _params = AndroidWebViewControllerCreationParams();
    } else {
      _params = const PlatformWebViewControllerCreationParams();
    }

    // 2) Se non è stata passata alcuna thumbnailUrl, avviamo subito il caricamento del video
    if (widget.thumbnailUrl == null) {
      _hasStarted = true;
      _isLoading = true;
      _initAndLoadWebView();
    }
  }

  /// Crea il WebViewController e carica l’URL video
  void _initAndLoadWebView() {
    _controller = WebViewController.fromPlatformCreationParams(_params)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() => _isLoading = true);
          },
          onPageFinished: (url) {
            setState(() => _isLoading = false);
          },
          onWebResourceError: (_) {
            setState(() => _isLoading = false);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));

    // Disabilitiamo l’autoplay su Android (richiede gesto utente)
    if (_controller!.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      (_controller!.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // per AutomaticKeepAliveClientMixin

    // Se non abbiamo ancora iniziato (e c’è thumbnail), mostriamo il placeholder
    if (!_hasStarted) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: GestureDetector(
          onTap: () {
            setState(() {
              _hasStarted = true;
              _isLoading = true;
            });
            _initAndLoadWebView();
          },
          child: Stack(
            fit: StackFit.expand,
            alignment: Alignment.center,
            children: [
              // Se hai thumbnailUrl, la mostriamo, altrimenti sfondo nero
              if (widget.thumbnailUrl != null)
                Image.network(
                  widget.thumbnailUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) {
                    return Container(color: Colors.black);
                  },
                )
              else
                Container(color: Colors.black),
              const Icon(
                Icons.play_circle_fill,
                size: 64,
                color: Colors.white70,
              ),
            ],
          ),
        ),
      );
    }

    // Altrimenti (_hasStarted == true): mostriamo subito il WebView + spinner se sta caricando
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        fit: StackFit.expand,
        children: [
          WebViewWidget(controller: _controller!),
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
