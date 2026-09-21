import 'package:flutter_test/flutter_test.dart';
import 'package:m_o_b_demand_side/core/utils/formatters.dart';

void main() {
  group('formatMoney', () {
    test('rupees with Indian digit grouping', () {
      expect(formatMoney(111.62), '₹111.62');
      expect(formatMoney(85), '₹85.00');
      expect(formatMoney(123456.5), '₹1,23,456.50');
    });
    test('null shows a dash; other currencies keep their code', () {
      expect(formatMoney(null), '—');
      expect(formatMoney(10, currency: 'USD'), 'USD 10.00');
    });
  });

  group('formatDistance', () {
    test('metres under a km, one-decimal km above', () {
      expect(formatDistance(850), '850 m');
      expect(formatDistance(6582), '6.6 km');
      expect(formatDistance(null), '—');
    });
  });

  group('formatDuration', () {
    test('minutes, hours, and the sub-minute case', () {
      expect(formatDuration(20), '<1 min');
      expect(formatDuration(947), '16 min');
      expect(formatDuration(3600), '1 h');
      expect(formatDuration(3900), '1 h 5 min');
      expect(formatDuration(null), '—');
    });
  });

  test('formatPhone groups an Indian number and leaves others alone', () {
    expect(formatPhone('+919888800002'), '+91 98888 00002');
    expect(formatPhone('+14155550123'), '+14155550123');
    expect(formatPhone(null), '');
  });
}
