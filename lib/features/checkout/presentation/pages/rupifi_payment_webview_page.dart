import 'package:flutter/material.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
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
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
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
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
