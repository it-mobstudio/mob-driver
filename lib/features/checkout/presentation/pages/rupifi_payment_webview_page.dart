import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

class RupifiPaymentResult {
  const RupifiPaymentResult({
    required this.status,
    this.merchantPaymentRefId,
    this.paymentId,
  });

  final String status;
  final String? merchantPaymentRefId;
  final String? paymentId;

  bool get isCompleted =>
      status == 'AUTH_PENDING' || status == 'SUCCESS' || status == 'CAPTURED';
  bool get isCancelled => status == 'CANCELLED';
}

class RupifiPaymentWebviewPage extends StatefulWidget {
  const RupifiPaymentWebviewPage({super.key, required this.paymentUrl});

  final String paymentUrl;

  @override
  State<RupifiPaymentWebviewPage> createState() =>
      _RupifiPaymentWebviewPageState();
}

class _RupifiPaymentWebviewPageState extends State<RupifiPaymentWebviewPage> {
  WebViewController? _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _isLoading = false;
      return;
    }
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _isLoading = true),
          onPageFinished: (_) => setState(() => _isLoading = false),
          onWebResourceError: (_) => setState(() => _isLoading = false),
          onNavigationRequest: _onNavigationRequest,
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  NavigationDecision _onNavigationRequest(NavigationRequest request) {
    final uri = Uri.tryParse(request.url);
    if (uri == null) return NavigationDecision.navigate;

    // Per Rupifi's UPI Intent flow (developers.rupifi.com/documentation/
    // UPI-Intent-Android-iOS), the hosted payment page redirects to a UPI
    // app deep link (upi://, tez://, phonepe://, paytmmp://, intent://, ...)
    // once the user picks an app. A WebView can't load these schemes itself
    // — it just fails (blank page / ERR_UNKNOWN_URL_SCHEME). Hand off to the
    // OS so the actual UPI app opens, same as the native intent flow would.
    if (uri.scheme != 'http' && uri.scheme != 'https') {
      _launchExternally(uri);
      return NavigationDecision.prevent;
    }

    // Intercept when Rupifi redirects back to our backend webhook
    final isRedirect = uri.path.contains('rupifi') ||
        uri.path.contains('payment_history') ||
        (uri.host.contains('madoverbuilding.com') &&
            uri.path.contains('/api/'));

    if (isRedirect) {
      final result = RupifiPaymentResult(
        status: uri.queryParameters['status'] ?? 'AUTH_PENDING',
        merchantPaymentRefId: uri.queryParameters['merchantPaymentRefId'],
        paymentId: uri.queryParameters['paymentId'],
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop(result);
      });
      return NavigationDecision.prevent;
    }
    return NavigationDecision.navigate;
  }

  Future<void> _launchExternally(Uri uri) async {
    try {
      final fallbackUri = _intentFallbackUri(uri);
      final launched = await launchUrl(
        fallbackUri ?? uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No UPI app found to complete this payment. '
              'Please install GPay, PhonePe, or Paytm and try again.',
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to open the UPI app. Please try again.'),
          ),
        );
      }
    }
  }

  Uri? _intentFallbackUri(Uri uri) {
    if (uri.scheme != 'intent') return null;
    final raw = uri.toString();
    final fallbackMatch =
        RegExp(r'S\.browser_fallback_url=([^;]+)').firstMatch(raw);
    final encodedFallback = fallbackMatch?.group(1);
    if (encodedFallback == null || encodedFallback.isEmpty) return null;
    return Uri.tryParse(Uri.decodeComponent(encodedFallback));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'mobCREDIT Payment',
          style: GoogleFonts.inter(
            color: const Color(0xFF0A243F),
            fontSize: 15,
            fontWeight: FontWeight.w600,
            height: 22 / 15,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF0A243F)),
          onPressed: () => Navigator.of(context).pop(
            const RupifiPaymentResult(status: 'CANCELLED'),
          ),
        ),
      ),
      body: Stack(
        children: [
          if (kIsWeb)
            _WebUnsupportedPaymentView(
              paymentUrl: widget.paymentUrl,
              onCancel: () => Navigator.of(context).pop(
                const RupifiPaymentResult(status: 'CANCELLED'),
              ),
            )
          else
            WebViewWidget(controller: _controller!),
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}

class _WebUnsupportedPaymentView extends StatelessWidget {
  const _WebUnsupportedPaymentView({
    required this.paymentUrl,
    required this.onCancel,
  });

  final String paymentUrl;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'mobCREDIT payment opens outside the web preview.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: const Color(0xFF0A243F),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                final uri = Uri.tryParse(paymentUrl);
                if (uri != null) {
                  launchUrl(
                    uri,
                    mode: LaunchMode.externalApplication,
                    webOnlyWindowName: '_blank',
                  );
                }
              },
              child: const Text('Open payment'),
            ),
            TextButton(
              onPressed: onCancel,
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}
