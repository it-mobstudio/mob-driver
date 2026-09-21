import 'package:equatable/equatable.dart';
import 'package:m_o_b_demand_side/core/utils/json_readers.dart';
import 'package:m_o_b_demand_side/core/utils/polyline_codec.dart';

/// `GET driver/trips/{id}/payment/qr` — the code the customer scans to pay a
/// COD trip's fare.
///
/// In production it is **Razorpay's**: a single-use, fixed-amount UPI QR made
/// for this trip alone, shown as the image Razorpay hosts ([imageUrl]). Razorpay
/// itself reports the payment, so the server marks the trip paid without the
/// driver having to say so. The local-development stand-in has no image: it
/// hands over a UPI link ([payload]) to draw as a QR, and nothing confirms it.
class PaymentQr extends Equatable {
  const PaymentQr({
    required this.amount,
    required this.currency,
    this.payload,
    this.imageUrl,
    this.provider = 'upi_static',
    this.reference,
    this.expiresAt,
  });

  factory PaymentQr.fromJson(Map<String, dynamic> json) => PaymentQr(
        payload: readString(json['qr_payload']),
        imageUrl: readString(json['image_url']),
        provider: readString(json['provider']) ?? 'upi_static',
        reference: readString(json['reference']),
        amount: readDouble(json['amount']) ?? 0,
        currency: readString(json['currency']) ?? 'INR',
        expiresAt: readDateTime(json['expires_at']),
      );

  /// A `upi://pay?...` deep link to draw as a QR (local stand-in only).
  final String? payload;

  /// A ready-made QR image (Razorpay) — display it as-is.
  final String? imageUrl;

  /// `razorpay`, or `upi_static` for the local stand-in.
  final String provider;
  final String? reference;
  final double amount;
  final String currency;

  /// When the code stops working; null when it never does.
  final DateTime? expiresAt;

  /// The server can tell when this code has been paid, so the driver never has
  /// to take the customer's word for it — or their own.
  bool get paymentIsVerified => provider == 'razorpay';

  bool get hasImage => (imageUrl ?? '').isNotEmpty;

  bool isExpiredAt(DateTime now) =>
      expiresAt != null && !expiresAt!.isAfter(now);

  @override
  List<Object?> get props =>
      [payload, imageUrl, provider, reference, amount, currency, expiresAt];
}

/// `GET driver/trips/{id}/navigation` — the leg from the driver's current
/// position to the trip's next stop.
class NavRoute extends Equatable {
  const NavRoute({
    required this.target,
    required this.points,
    this.distanceMeters,
    this.durationSeconds,
  });

  factory NavRoute.fromJson(Map<String, dynamic> json) => NavRoute(
        target: readString(json['target']) ?? 'pickup',
        points: decodePolyline(
          readString(json['polyline']),
          precision: readInt(json['polyline_precision']) ?? 6,
        ),
        distanceMeters: readInt(json['distance_meters']),
        durationSeconds: readInt(json['duration_seconds']),
      );

  /// `pickup` or `drop`.
  final String target;
  final List<PolylinePoint> points;
  final int? distanceMeters;
  final int? durationSeconds;

  @override
  List<Object?> get props => [target, points.length, distanceMeters];
}

/// Result of collecting a COD payment or re-sending the delivery OTP.
class DeliveryOtpSent extends Equatable {
  const DeliveryOtpSent({required this.message, this.debugOtp});

  factory DeliveryOtpSent.fromJson(Map<String, dynamic> json) =>
      DeliveryOtpSent(
        message: readString(json['message']) ?? 'OTP sent.',
        debugOtp: readString(json['otp']),
      );

  final String message;

  /// Only present when the backend runs with `DRIVER_OTP_DEBUG_RESPONSE`
  /// (non-production) — real deployments never reveal it to the driver,
  /// since it's the customer's proof of delivery.
  final String? debugOtp;

  @override
  List<Object?> get props => [message, debugOtp];
}

/// A page of a paginated list (`{count, next, previous, results}`).
class Paged<T> extends Equatable {
  const Paged(
      {required this.items, required this.count, required this.hasNext});

  final List<T> items;
  final int count;
  final bool hasNext;

  @override
  List<Object?> get props => [items, count, hasNext];
}
