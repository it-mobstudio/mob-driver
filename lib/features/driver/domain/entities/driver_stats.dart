import 'package:equatable/equatable.dart';
import 'package:m_o_b_demand_side/core/utils/json_readers.dart';

class PeriodStats extends Equatable {
  const PeriodStats({
    this.tripsCompleted = 0,
    this.tripsCancelled = 0,
    this.totalFare = 0,
    this.earnings = 0,
    this.codCollected = 0,
    this.distanceMeters = 0,
  });

  factory PeriodStats.fromJson(Map<String, dynamic> json) => PeriodStats(
        tripsCompleted: readInt(json['trips_completed']) ?? 0,
        tripsCancelled: readInt(json['trips_cancelled']) ?? 0,
        totalFare: readDouble(json['total_fare']) ?? 0,
        earnings: readDouble(json['earnings']) ?? 0,
        codCollected: readDouble(json['cod_collected']) ?? 0,
        distanceMeters: readInt(json['distance_meters']) ?? 0,
      );

  final int tripsCompleted;
  final int tripsCancelled;

  /// Fare value of the completed trips — what the customers were charged.
  final double totalFare;

  /// What the driver personally made from them (their wallet credits).
  final double earnings;
  final double codCollected;
  final int distanceMeters;

  @override
  List<Object?> get props => [
        tripsCompleted,
        tripsCancelled,
        totalFare,
        earnings,
        codCollected,
        distanceMeters
      ];
}

class DriverStats extends Equatable {
  const DriverStats({
    this.today = const PeriodStats(),
    this.allTime = const PeriodStats(),
  });

  factory DriverStats.fromJson(Map<String, dynamic> json) => DriverStats(
        today: PeriodStats.fromJson(asMap(json['today'])),
        allTime: PeriodStats.fromJson(asMap(json['all_time'])),
      );

  final PeriodStats today;
  final PeriodStats allTime;

  @override
  List<Object?> get props => [today, allTime];
}
