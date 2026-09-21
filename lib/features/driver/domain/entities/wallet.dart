import 'package:equatable/equatable.dart';
import 'package:m_o_b_demand_side/core/utils/json_readers.dart';

/// Earnings over one stretch of time (`today`, `week`, ...).
class WalletPeriod extends Equatable {
  const WalletPeriod({this.earnings = 0, this.trips = 0});

  factory WalletPeriod.fromJson(Map<String, dynamic> json) => WalletPeriod(
        earnings: readDouble(json['earnings']) ?? 0,
        trips: readInt(json['trips']) ?? 0,
      );

  final double earnings;
  final int trips;

  @override
  List<Object?> get props => [earnings, trips];
}

/// One day of the last-seven-days chart.
class DayEarning extends Equatable {
  const DayEarning({
    required this.date,
    this.earnings = 0,
    this.trips = 0,
  });

  factory DayEarning.fromJson(Map<String, dynamic> json) => DayEarning(
        date: DateTime.tryParse(readString(json['date']) ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        earnings: readDouble(json['earnings']) ?? 0,
        trips: readInt(json['trips']) ?? 0,
      );

  /// The driver's local calendar day (the backend already bucketed it by their
  /// UTC offset), so only the date part is meaningful.
  final DateTime date;
  final double earnings;
  final int trips;

  @override
  List<Object?> get props => [date, earnings, trips];
}

/// `GET driver/wallet` — everything the wallet screen's header and chart show.
class WalletSummary extends Equatable {
  const WalletSummary({
    this.balance = 0,
    this.currency = 'INR',
    this.today = const WalletPeriod(),
    this.week = const WalletPeriod(),
    this.month = const WalletPeriod(),
    this.lifetime = const WalletPeriod(),
    this.lifetimePayouts = 0,
    this.last7Days = const [],
  });

  factory WalletSummary.fromJson(Map<String, dynamic> json) {
    final lifetime = asMap(json['lifetime']);
    return WalletSummary(
      balance: readDouble(json['balance']) ?? 0,
      currency: readString(json['currency']) ?? 'INR',
      today: WalletPeriod.fromJson(asMap(json['today'])),
      week: WalletPeriod.fromJson(asMap(json['week'])),
      month: WalletPeriod.fromJson(asMap(json['month'])),
      lifetime: WalletPeriod.fromJson(lifetime),
      lifetimePayouts: readDouble(lifetime['payouts']) ?? 0,
      last7Days:
          asMapList(json['last_7_days']).map(DayEarning.fromJson).toList(),
    );
  }

  /// What the company owes the driver right now.
  final double balance;
  final String currency;
  final WalletPeriod today;
  final WalletPeriod week;
  final WalletPeriod month;
  final WalletPeriod lifetime;

  /// Total the company has paid out so far.
  final double lifetimePayouts;
  final List<DayEarning> last7Days;

  @override
  List<Object?> get props => [
        balance,
        currency,
        today,
        week,
        month,
        lifetime,
        lifetimePayouts,
        last7Days,
      ];
}

/// Mirrors the backend's `WalletTransactionKind`.
enum WalletKind {
  tripEarning('trip_earning', 'Trip earning'),
  bonus('bonus', 'Bonus'),
  penalty('penalty', 'Penalty'),
  payout('payout', 'Payout'),
  adjustment('adjustment', 'Adjustment'),
  unknown('unknown', 'Transaction');

  const WalletKind(this.wire, this.label);
  final String wire;
  final String label;

  static WalletKind parse(String? value) => WalletKind.values.firstWhere(
        (kind) => kind.wire == value,
        orElse: () => WalletKind.unknown,
      );
}

/// One row of the wallet statement.
class WalletEntry extends Equatable {
  const WalletEntry({
    required this.id,
    required this.kind,
    required this.amount,
    required this.balanceAfter,
    this.description,
    this.reference,
    this.tripId,
    this.createdAt,
  });

  factory WalletEntry.fromJson(Map<String, dynamic> json) => WalletEntry(
        id: readString(json['id']) ?? '',
        kind: WalletKind.parse(readString(json['kind'])),
        amount: readDouble(json['amount']) ?? 0,
        balanceAfter: readDouble(json['balance_after']) ?? 0,
        description: readString(json['description']),
        reference: readString(json['reference']),
        tripId: readString(json['trip_id']),
        createdAt: readDateTime(json['created_at']),
      );

  final String id;
  final WalletKind kind;

  /// Signed: money in is positive, payouts and penalties negative.
  final double amount;
  final double balanceAfter;
  final String? description;

  /// A payout's bank/UPI reference, for matching it to a bank statement.
  final String? reference;
  final String? tripId;
  final DateTime? createdAt;

  bool get isCredit => amount > 0;

  @override
  List<Object?> get props => [
        id,
        kind,
        amount,
        balanceAfter,
        description,
        reference,
        tripId,
        createdAt,
      ];
}
