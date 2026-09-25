import 'package:m_o_b_demand_side/core/errors/app_failure.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/captured_photo.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/driver_profile.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/driver_stats.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/driver_vehicle.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/my_vehicle.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/trip.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/trip_extras.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/wallet.dart';

/// Every call returns `(value, failure)`: exactly one is non-null (except
/// [activeTrip], whose value is legitimately null when there's no trip — check
/// the failure first).
abstract interface class DriverRepository {
  /// What the backend last told us about this driver, from local storage — for
  /// painting the dashboard before the network answers. Never throws; either
  /// part is null when nothing usable is stored.
  Future<({DriverProfile? profile, DriverStats? stats})> cachedSnapshot();

  /// Forgets the stored snapshot (on sign-out).
  Future<void> clearCache();

  Future<(DriverProfile?, AppFailure?)> profile();
  Future<(List<DriverVehicle>?, AppFailure?)> availableVehicles();

  // -- the driver's own vehicles ------------------------------------------------
  Future<(List<VehicleTypeOption>?, AppFailure?)> vehicleTypes();
  Future<(List<MyVehicle>?, AppFailure?)> myVehicles();
  Future<(MyVehicle?, AppFailure?)> addVehicle({
    required String vehicleTypeId,
    required String registrationNumber,
    double? capacityKg,
    List<CapturedPhoto> photos = const [],
  });
  Future<(MyVehicle?, AppFailure?)> updateVehicle(
    String id, {
    String? vehicleTypeId,
    String? registrationNumber,
    double? capacityKg,
  });
  Future<(MyVehicle?, AppFailure?)> addVehiclePhoto(
      String id, CapturedPhoto photo);
  Future<(MyVehicle?, AppFailure?)> removeVehiclePhoto(
      String id, String photoId);
  Future<AppFailure?> removeVehicle(String id);
  Future<(DriverStats?, AppFailure?)> stats();

  // -- onboarding: the driver's own details and documents. Each returns the
  // refreshed profile so the app updates from one round trip. ------------------
  Future<(DriverProfile?, AppFailure?)> updateProfile(ProfileUpdate update);
  Future<(DriverProfile?, AppFailure?)> uploadPhoto(CapturedPhoto photo);
  Future<(DriverProfile?, AppFailure?)> submitAadhar({
    required String number,
    required CapturedPhoto front,
    required CapturedPhoto back,
  });
  Future<(DriverProfile?, AppFailure?)> submitLicence({
    required String number,
    required DateTime expiry,
    required CapturedPhoto front,
    CapturedPhoto? back,
  });
  Future<(DriverProfile?, AppFailure?)> submitPolice(CapturedPhoto document);

  /// Closes the account. Null on success.
  Future<AppFailure?> deleteAccount();

  // -- wallet ----------------------------------------------------------------
  Future<(WalletSummary?, AppFailure?)> wallet();
  Future<(Paged<WalletEntry>?, AppFailure?)> walletEntries({
    int page = 1,
    List<WalletKind> kinds = const [],
  });

  Future<(DriverProfile?, AppFailure?)> startDuty({
    required String vehicleId,
    double? latitude,
    double? longitude,
  });
  Future<(DriverProfile?, AppFailure?)> endDuty();
  Future<AppFailure?> sendLocation({
    required double latitude,
    required double longitude,
  });

  /// `(null, null)` means "no active trip".
  Future<(Trip?, AppFailure?)> activeTrip();
  Future<(Paged<Trip>?, AppFailure?)> trips({
    int page = 1,
    List<TripStatus> statuses = const [],
  });
  Future<(Trip?, AppFailure?)> trip(String id);
  Future<(NavRoute?, AppFailure?)> navigation(
    String id, {
    required double latitude,
    required double longitude,
  });

  Future<(Trip?, AppFailure?)> arrive(String id);
  Future<(Trip?, AppFailure?)> start(String id);
  Future<(PaymentQr?, AppFailure?)> paymentQr(String id);
  Future<(DeliveryOtpSent?, AppFailure?)> collectPayment(String id);
  Future<(DeliveryOtpSent?, AppFailure?)> resendDeliveryOtp(String id);
  Future<(Trip?, AppFailure?)> complete(String id, {String? otp});
  Future<(Trip?, AppFailure?)> cancel(String id, {required String reason});

  /// The driver's answer for one item at the drop; returns the whole trip.
  Future<(Trip?, AppFailure?)> verifyItem(
    String tripId,
    String itemId, {
    required ItemStatus status,
    String? note,
    CapturedPhoto? photo,
  });

  /// A camera photo at the pickup or the drop (of the order, or of item
  /// [itemId]); returns the whole trip.
  Future<(Trip?, AppFailure?)> addTripPhoto(
    String tripId, {
    required PhotoStage stage,
    required CapturedPhoto photo,
    String? itemId,
  });

  /// Takes an item back to pending.
  Future<(Trip?, AppFailure?)> resetItem(String tripId, String itemId);
}
