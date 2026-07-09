import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// WebView screen that listens for the OAuth redirect callback.
class OAuthWebviewScreen extends StatefulWidget {
  final String authUrl;
  final String redirectUrl;

  const OAuthWebviewScreen({
    super.key,
    required this.authUrl,
    required this.redirectUrl,
  });

  @override
  State<OAuthWebviewScreen> createState() => _OAuthWebviewScreenState();
}

class _OAuthWebviewScreenState extends State<OAuthWebviewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _isLoading = true),
          onPageFinished: (_) => setState(() => _isLoading = false),
          onNavigationRequest: _handleNavigationRequest,
          onWebResourceError: (error) {
            setState(() {
              _errorMessage = 'WebView error: ${error.description}';
              _isLoading = false;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.authUrl));
  }

  NavigationDecision _handleNavigationRequest(NavigationRequest request) {
    final uri = Uri.tryParse(request.url);
    if (uri != null && _isRedirectUri(uri)) {
      _handleRedirectUri(uri);
      return NavigationDecision.prevent;
    }
    return NavigationDecision.navigate;
  }

  bool _isRedirectUri(Uri uri) {
    final redirect = Uri.parse(widget.redirectUrl);
    return uri.scheme == redirect.scheme && uri.host == redirect.host && uri.path == redirect.path;
  }

  void _handleRedirectUri(Uri uri) {
    final code = uri.queryParameters['code'];
    final state = uri.queryParameters['state'];

    if (code != null && state != null) {
      Navigator.of(context).pop({'code': code, 'state': state});
      return;
    }

    setState(() {
      _errorMessage = 'Authorization failed. Missing code or state from callback.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          Navigator.of(context).pop(null);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Authorize Account'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(null),
          ),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 1,
        ),
        body: Column(
          children: [
            if (_isLoading) const LinearProgressIndicator(),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            Expanded(
              child: WebViewWidget(controller: _controller),
            ),
          ],
        ),
      ),
    );
  }
}
