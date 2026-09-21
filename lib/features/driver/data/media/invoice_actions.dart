import 'dart:io' show File;
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// What the driver can do with an order's invoice. Each returns null on
/// success or a sentence to show the driver — so screens stay free of
/// platform details and can be tested with a fake.
abstract interface class InvoiceActions {
  /// Opens it where the phone can view and save it (the browser / PDF viewer).
  Future<String?> download(String url);

  /// Fetches the file and offers it through the system share sheet, where
  /// WhatsApp (or anything else) can take it as an attachment.
  Future<String?> shareFile(
    String url, {
    required String fileName,
    String? message,
  });

  /// Opens a WhatsApp chat with [phone] (or lets the driver pick a chat when
  /// it's null) with [message] typed in. WhatsApp can't be handed a file this
  /// way, so the message carries the invoice link.
  Future<String?> whatsApp({String? phone, required String message});
}

class DeviceInvoiceActions implements InvoiceActions {
  const DeviceInvoiceActions();

  static const _maxBytes = 20 * 1024 * 1024;

  @override
  Future<String?> download(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) return 'This invoice link isn’t valid.';
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      return opened ? null : 'Couldn’t open the invoice on this phone.';
    } catch (_) {
      return 'Couldn’t open the invoice on this phone.';
    }
  }

  @override
  Future<String?> shareFile(
    String url, {
    required String fileName,
    String? message,
  }) async {
    try {
      // A plain Dio, deliberately: the invoice lives on the company's own
      // server or storage, and the app's authenticated client would attach the
      // driver's access token to a request for someone else's host.
      final response = await Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 40),
        responseType: ResponseType.bytes,
      )).get<List<int>>(url);
      final data = response.data;
      if (data == null || data.isEmpty) return 'The invoice file is empty.';
      if (data.length > _maxBytes) return 'This invoice is too large to share.';

      final bytes = Uint8List.fromList(data);
      final mime = _mimeFor(fileName);
      final XFile file;
      if (kIsWeb) {
        file = XFile.fromData(bytes, mimeType: mime, name: fileName);
      } else {
        final dir = await getTemporaryDirectory();
        final path = '${dir.path}/$fileName';
        await File(path).writeAsBytes(bytes, flush: true);
        file = XFile(path, mimeType: mime, name: fileName);
      }
      await SharePlus.instance.share(ShareParams(
        files: [file],
        text: message,
        subject: fileName,
      ));
      return null;
    } on DioException {
      return 'Couldn’t download the invoice. Check your connection and try again.';
    } catch (_) {
      return 'Couldn’t share the invoice. Please try again.';
    }
  }

  @override
  Future<String?> whatsApp({String? phone, required String message}) async {
    final uri = whatsAppUri(phone: phone, message: message);
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      return opened ? null : 'WhatsApp isn’t available on this phone.';
    } catch (_) {
      return 'WhatsApp isn’t available on this phone.';
    }
  }

  static String _mimeFor(String fileName) {
    final name = fileName.toLowerCase();
    if (name.endsWith('.png')) return 'image/png';
    if (name.endsWith('.jpg') || name.endsWith('.jpeg')) return 'image/jpeg';
    if (name.endsWith('.webp')) return 'image/webp';
    return 'application/pdf';
  }
}

/// `https://wa.me/919888800002?text=…` — WhatsApp's own deep link, handled by
/// the app when it's installed and by WhatsApp Web otherwise. The number goes
/// in as digits only (country code included, no `+`).
Uri whatsAppUri({String? phone, required String message}) {
  final digits = (phone ?? '').replaceAll(RegExp(r'\D'), '');
  return Uri.https(
      'wa.me', digits.isEmpty ? '/' : '/$digits', {'text': message});
}

/// A file name for sharing: the company's own name for it when the link has
/// one, otherwise `Invoice-<number>` with the right extension.
String invoiceFileName(String url, {String? invoiceNumber}) {
  final last = Uri.tryParse(url)?.pathSegments.lastWhere(
        (s) => s.isNotEmpty,
        orElse: () => '',
      );
  final hasExtension = last != null &&
      RegExp(r'\.(pdf|png|jpe?g|webp)$', caseSensitive: false).hasMatch(last);
  if (hasExtension) return last;
  final base = (invoiceNumber ?? '').trim().isEmpty
      ? 'Invoice'
      : 'Invoice-${invoiceNumber!.trim().replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_')}';
  return '$base.pdf';
}
