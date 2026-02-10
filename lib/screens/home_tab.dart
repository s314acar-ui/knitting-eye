import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../services/settings_service.dart';

class HomeTab extends StatefulWidget {
  final VoidCallback onNavigateToOcr;

  const HomeTab({super.key, required this.onNavigateToOcr});

  @override
  State<HomeTab> createState() => HomeTabState();
}

class HomeTabState extends State<HomeTab> {
  final settingsService = SettingsService();
  WebViewController? _webViewController;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  Future<void> _initWebView() async {
    String homeUrl = settingsService.homeUrl;
    
    if (homeUrl.isEmpty) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      return;
    }

    setState(() {
      _hasError = false;
      _isLoading = true;
    });

    // HTTPS'i HTTP'ye çevir
    if (homeUrl.startsWith('https://')) {
      homeUrl = homeUrl.replaceFirst('https://', 'http://');
    } else if (!homeUrl.startsWith('http://') && !homeUrl.startsWith('https://')) {
      homeUrl = 'http://$homeUrl';
    }

    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF2D2D2D))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = true;
                _hasError = false;
              });
            }
          },
          onPageFinished: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
          onWebResourceError: (WebResourceError error) {
            // Hata durumunda sadece yenileme butonu göster
            if (mounted) {
              setState(() {
                _isLoading = false;
                _hasError = true;
              });
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(homeUrl));

    setState(() {});
  }

  void refreshPage() {
    _initWebView();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF2D2D2D),
      child: Stack(
        children: [
          if (_webViewController != null && !_hasError)
            WebViewWidget(controller: _webViewController!),
          
          // Hata mesajı
          if (_hasError)
            Container(
              color: const Color(0xFF2D2D2D),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.cloud_outlined,
                        color: Color(0xFFBDBDBD),
                        size: 64,
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton.icon(
                        onPressed: refreshPage,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Sayfayı Yenile'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF424242),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          
          if (_isLoading)
            Container(
              color: const Color(0xFF2D2D2D),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Yükleniyor...',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
