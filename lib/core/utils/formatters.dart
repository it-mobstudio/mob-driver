import 'package:intl/intl.dart';

/// `₹1,11,620.00`-style money. INR gets the rupee sign and Indian digit
/// grouping; any other currency code is shown as a prefix.
String formatMoney(double? amount, {String currency = 'INR'}) {
  if (amount == null) return '—';
  if (currency == 'INR') {
    return NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 2,
    ).format(amount);
  }
  return '$currency ${amount.toStringAsFixed(2)}';
}

/// Like [formatMoney], but a whole amount drops its paise: `₹420`, `₹111.62`.
/// For the big headline figures, where `.00` is noise.
String formatMoneyShort(double? amount, {String currency = 'INR'}) =>
    formatMoney(amount, currency: currency).replaceFirst(RegExp(r'\.00$'), '');

/// `850 m` under a kilometre, `6.6 km` above.
String formatDistance(int? meters) {
  if (meters == null) return '—';
  if (meters < 1000) return '$meters m';
  return '${(meters / 1000).toStringAsFixed(1)} km';
}

/// `<1 min`, `16 min`, `1 h 5 min`.
String formatDuration(int? seconds) {
  if (seconds == null) return '—';
  final minutes = (seconds / 60).round();
  if (minutes < 1) return '<1 min';
  if (minutes < 60) return '$minutes min';
  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  return rest == 0 ? '$hours h' : '$hours h $rest min';
}

/// `3:07 PM`.
String formatClock(DateTime? time) =>
    time == null ? '—' : DateFormat('h:mm a').format(time);

/// `20 Sep, 3:07 PM`.
String formatDateTime(DateTime? time) =>
    time == null ? '—' : DateFormat('d MMM, h:mm a').format(time);

/// `+91 98888 00002` for an Indian number; anything else is left alone.
String formatPhone(String? raw) {
  final phone = raw?.trim() ?? '';
  final match = RegExp(r'^\+91(\d{5})(\d{5})$').firstMatch(phone);
  return match == null ? phone : '+91 ${match.group(1)} ${match.group(2)}';
}

/// `2026-09-20` — the wire format for a calendar date.
String formatIsoDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

/// `20 Sep 2026`.
String formatDate(DateTime? date) =>
    date == null ? '—' : DateFormat('d MMM yyyy').format(date);

/// `Today`, `Yesterday`, `Mon, 21 Sep` — how a statement groups its days.
String formatDayHeading(DateTime day, {DateTime? now}) {
  final today = now ?? DateTime.now();
  final a = DateTime(day.year, day.month, day.day);
  final b = DateTime(today.year, today.month, today.day);
  final gap = b.difference(a).inDays;
  if (gap == 0) return 'Today';
  if (gap == 1) return 'Yesterday';
  return DateFormat('EEE, d MMM').format(a);
}

/// `₹850`, `₹1.2k`, `₹1.5L` — money short enough to label a chart bar.
String formatCompactMoney(double amount) {
  final value = amount.abs();
  final sign = amount < 0 ? '-' : '';
  String trim(double v) =>
      v.toStringAsFixed(1).replaceFirst(RegExp(r'\.0$'), '');
  if (value >= 100000) return '$sign₹${trim(value / 100000)}L';
  if (value >= 1000) return '$sign₹${trim(value / 1000)}k';
  return '$sign₹${value.round()}';
}

/// `+₹68.00` for money in, `−₹150.00` for money out.
String formatSignedMoney(double amount, {String currency = 'INR'}) {
  final text = formatMoney(amount.abs(), currency: currency);
  return amount < 0 ? '−$text' : '+$text';
}
