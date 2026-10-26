import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Shows a website inside the app, with a refresh button.
class WebViewTab extends StatefulWidget {
  const WebViewTab({super.key, required this.url});

  final String url;

  @override
  State<WebViewTab> createState() => _WebViewTabState();
}

class _WebViewTabState extends State<WebViewTab> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController();
    if (!kIsWeb) {
      _controller
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.white) // a failed load shows white, not black
        ..setNavigationDelegate(
          NavigationDelegate(
            // Problems are printed in the terminal with this prefix
            onWebResourceError: (e) => debugPrint('WEBVIEW ERROR: ${e.description}'),
          ),
        );
    }
    _controller.loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand, // make the webview fill the whole tab
      children: [
        WebViewWidget(controller: _controller),
        Positioned(
          right: 12,
          bottom: 12,
          child: FloatingActionButton.small(
            onPressed: () => _controller.reload(),
            child: const Icon(Icons.refresh),
          ),
        ),
      ],
    );
  }
}
