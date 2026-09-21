import 'package:equatable/equatable.dart';
import 'package:m_o_b_demand_side/core/utils/formatters.dart';
import 'package:m_o_b_demand_side/core/utils/json_readers.dart';
import 'package:m_o_b_demand_side/features/driver/domain/entities/driver_vehicle.dart';

/// Mirrors the backend's `VerificationStatus`.
enum KycStatus {
  pending,
  verified,
  rejected;

  static KycStatus parse(String? value) => KycStatus.values.firstWhere(
        (status) => status.name == value,
        orElse: () => KycStatus.pending,
      );
}

/// Where a driver is in getting approved — the backend derives it
/// (`Driver.onboarding_status`); the app just steers by it.
enum OnboardingStatus {
  profileIncomplete('profile_incomplete'),
  documentsRequired('documents_required'),
  underReview('under_review'),
  actionRequired('action_required'),
  approved('approved');

  const OnboardingStatus(this.wire);
  final String wire;

  static OnboardingStatus? tryParse(String? value) {
    for (final status in values) {
      if (status.wire == value) return status;
    }
    return null;
  }

  /// The sign-up flow is forced on the driver only while it's *their* turn.
  /// After that they're waiting on (or fixing something for) the company and
  /// can use the app.
  bool get needsSetup => this == profileIncomplete || this == documentsRequired;
}

/// One verifiable document (Aadhaar, licence, police certificate): the
/// company's verdict plus what the driver submitted for it.
class KycItem extends Equatable {
  const KycItem(
    this.status, {
    this.rejectionNote,
    this.submitted = false,
    this.frontUrl,
    this.backUrl,
    this.reference,
  });

  final KycStatus status;
  final String? rejectionNote;

  /// The driver has uploaded something for this document.
  final bool submitted;
  final String? frontUrl;
  final String? backUrl;

  /// What identifies it on screen: `•••• 0123` for Aadhaar (only the last four
  /// digits are ever stored), the number for a licence.
  final String? reference;

  /// Nothing to show for review yet, or the company sent it back.
  bool get needsUpload =>
      status == KycStatus.rejected ||
      (!submitted && status != KycStatus.verified);

  @override
  List<Object?> get props =>
      [status, rejectionNote, submitted, frontUrl, backUrl, reference];
}

/// Where the company sends this driver's payouts. The account number never
/// comes back in full — only enough to recognise the account.
class PayoutDetails extends Equatable {
  const PayoutDetails({
    this.upiId,
    this.bankAccountHolder,
    this.bankAccountLast4,
    this.bankIfsc,
    this.isSet = false,
  });

  factory PayoutDetails.fromJson(Map<String, dynamic> json) => PayoutDetails(
        upiId: readString(json['upi_id']),
        bankAccountHolder: readString(json['bank_account_holder']),
        bankAccountLast4: readString(json['bank_account_last4']),
        bankIfsc: readString(json['bank_ifsc']),
        isSet: readBool(json['is_set']),
      );

  final String? upiId;
  final String? bankAccountHolder;
  final String? bankAccountLast4;
  final String? bankIfsc;
  final bool isSet;

  /// `ravi@okhdfc`, or `HDFC0001234 · ••••9012`.
  String? get summary {
    if (upiId != null) return upiId;
    if (bankAccountLast4 != null) {
      return '${bankIfsc ?? 'Bank'} · ••••$bankAccountLast4';
    }
    return null;
  }

  @override
  List<Object?> get props =>
      [upiId, bankAccountHolder, bankAccountLast4, bankIfsc, isSet];
}

/// The fields of `PATCH driver/me`. A null field isn't sent; an empty string
/// clears it (where the backend allows that).
class ProfileUpdate extends Equatable {
  const ProfileUpdate({
    this.fullName,
    this.dateOfBirth,
    this.email,
    this.addressLine,
    this.city,
    this.pincode,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.payoutUpiId,
    this.bankAccountHolder,
    this.bankAccountNumber,
    this.bankIfsc,
  });

  final String? fullName;
  final DateTime? dateOfBirth;
  final String? email;
  final String? addressLine;
  final String? city;
  final String? pincode;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? payoutUpiId;
  final String? bankAccountHolder;
  final String? bankAccountNumber;
  final String? bankIfsc;

  Map<String, dynamic> toJson() => {
        if (fullName != null) 'full_name': fullName,
        if (dateOfBirth != null) 'date_of_birth': formatIsoDate(dateOfBirth!),
        if (email != null) 'email': email,
        if (addressLine != null) 'address_line': addressLine,
        if (city != null) 'city': city,
        if (pincode != null) 'pincode': pincode,
        if (emergencyContactName != null)
          'emergency_contact_name': emergencyContactName,
        if (emergencyContactPhone != null)
          'emergency_contact_phone': emergencyContactPhone,
        if (payoutUpiId != null) 'payout_upi_id': payoutUpiId,
        if (bankAccountHolder != null) 'bank_account_holder': bankAccountHolder,
        if (bankAccountNumber != null) 'bank_account_number': bankAccountNumber,
        if (bankIfsc != null) 'bank_ifsc': bankIfsc,
      };

  @override
  List<Object?> get props => [toJson()];
}

class DriverProfile extends Equatable {
  const DriverProfile({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    required this.isOnline,
    required this.isEligible,
    required this.aadhar,
    required this.drivingLicence,
    required this.police,
    this.accountStatus = 'active',
    this.onboardingStatus = OnboardingStatus.approved,
    this.isProfileComplete = true,
    this.licenceExpiry,
    this.allowedCategories = const [],
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.email,
    this.dateOfBirth,
    this.addressLine,
    this.city,
    this.pincode,
    this.photoUrl,
    this.payout = const PayoutDetails(),
    this.currentVehicle,
  });

  /// Parses `DriverMeSerializer`, which is also embedded in the OTP-verify
  /// response as `driver`.
  factory DriverProfile.fromJson(Map<String, dynamic> json) {
    final vehicle = json['current_vehicle'];
    final kyc = asMap(json['kyc']);
    final aadhar = asMap(kyc['aadhar']);
    final licence = asMap(kyc['dl']);
    final police = asMap(kyc['police']);
    final isEligible = readBool(json['is_eligible_for_assignment']);
    final last4 = readString(aadhar['number_last4']);

    return DriverProfile(
      id: readString(json['id']) ?? '',
      fullName: readString(json['full_name']) ?? '',
      phoneNumber: readString(json['phone_number']) ?? '',
      accountStatus: readString(json['account_status']) ?? 'active',
      // A backend (or a stored snapshot) from before onboarding existed has no
      // status: an eligible driver is approved, anyone else is being reviewed.
      onboardingStatus:
          OnboardingStatus.tryParse(readString(json['onboarding_status'])) ??
              (isEligible
                  ? OnboardingStatus.approved
                  : OnboardingStatus.underReview),
      isProfileComplete: readBool(json['is_profile_complete'], fallback: true),
      isOnline: readBool(json['is_online']),
      isEligible: isEligible,
      aadhar: KycItem(
        KycStatus.parse(readString(json['aadhar_status'])),
        rejectionNote: readString(json['aadhar_rejection_note']),
        submitted: readBool(aadhar['submitted']),
        frontUrl: readString(aadhar['front_url']),
        backUrl: readString(aadhar['back_url']),
        reference: last4 == null ? null : '•••• $last4',
      ),
      drivingLicence: KycItem(
        KycStatus.parse(readString(json['dl_status'])),
        rejectionNote: readString(json['dl_rejection_note']),
        submitted: readBool(licence['submitted']),
        frontUrl: readString(licence['front_url']),
        backUrl: readString(licence['back_url']),
        reference: readString(licence['number']),
      ),
      police: KycItem(
        KycStatus.parse(readString(json['police_status'])),
        rejectionNote: readString(json['police_rejection_note']),
        submitted: readBool(police['submitted']),
        frontUrl: readString(police['document_url']),
      ),
      licenceExpiry:
          DateTime.tryParse(readString(json['dl_expiry_date']) ?? ''),
      allowedCategories: json['dl_allowed_categories'] is List
          ? (json['dl_allowed_categories'] as List)
              .map((e) => e.toString())
              .toList()
          : const [],
      emergencyContactName: readString(json['emergency_contact_name']),
      emergencyContactPhone: readString(json['emergency_contact_phone']),
      email: readString(json['email']),
      dateOfBirth: DateTime.tryParse(readString(json['date_of_birth']) ?? ''),
      addressLine: readString(json['address_line']),
      city: readString(json['city']),
      pincode: readString(json['pincode']),
      photoUrl: readString(json['profile_photo_url']),
      payout: PayoutDetails.fromJson(asMap(json['payout'])),
      currentVehicle: vehicle is Map
          ? DriverVehicle.fromJson(Map<String, dynamic>.from(vehicle))
          : null,
    );
  }

  final String id;
  final String fullName;
  final String phoneNumber;
  final String accountStatus;
  final OnboardingStatus onboardingStatus;
  final bool isProfileComplete;
  final bool isOnline;

  /// KYC complete + account active + licence in date — the backend's gate on
  /// going on duty (`DRIVER_NOT_ELIGIBLE` otherwise).
  final bool isEligible;
  final KycItem aadhar;
  final KycItem drivingLicence;
  final KycItem police;
  final DateTime? licenceExpiry;
  final List<String> allowedCategories;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? email;
  final DateTime? dateOfBirth;
  final String? addressLine;
  final String? city;
  final String? pincode;
  final String? photoUrl;
  final PayoutDetails payout;
  final DriverVehicle? currentVehicle;

  /// The name and date of birth are what the verified ID says; the backend
  /// refuses to change them once the Aadhaar is verified.
  bool get identityLocked => aadhar.status == KycStatus.verified;

  /// Days until the licence lapses, when it's close enough to warn about.
  int? get licenceDaysLeft {
    final expiry = licenceExpiry;
    if (expiry == null) return null;
    final today = DateTime.now();
    return DateTime(expiry.year, expiry.month, expiry.day)
        .difference(DateTime(today.year, today.month, today.day))
        .inDays;
  }

  /// Documents the company rejected, in words, for the "fix these" prompt.
  List<(String, KycItem)> get rejectedDocuments => [
        ('Aadhaar', aadhar),
        ('Driving licence', drivingLicence),
        ('Police verification', police),
      ].where((d) => d.$2.status == KycStatus.rejected).toList();

  /// Everything still blocking the driver from going on duty, in words.
  List<String> get blockers {
    final reasons = <String>[];
    void check(String name, KycItem item) {
      switch (item.status) {
        case KycStatus.pending:
          reasons.add('$name verification is pending.');
        case KycStatus.rejected:
          final note = item.rejectionNote;
          reasons.add('$name was rejected${note == null ? '.' : ': $note'}');
        case KycStatus.verified:
          break;
      }
    }

    check('Aadhaar', aadhar);
    check('Driving licence', drivingLicence);
    check('Police', police);
    if (accountStatus == 'locked_dl_expired') {
      reasons.add('Your account is locked because your licence expired.');
    } else if (accountStatus == 'disabled') {
      reasons.add('Your account has been disabled.');
    }
    return reasons;
  }

  DriverProfile copyWith({bool? isOnline, DriverVehicle? currentVehicle}) =>
      DriverProfile(
        id: id,
        fullName: fullName,
        phoneNumber: phoneNumber,
        accountStatus: accountStatus,
        onboardingStatus: onboardingStatus,
        isProfileComplete: isProfileComplete,
        isOnline: isOnline ?? this.isOnline,
        isEligible: isEligible,
        aadhar: aadhar,
        drivingLicence: drivingLicence,
        police: police,
        licenceExpiry: licenceExpiry,
        allowedCategories: allowedCategories,
        emergencyContactName: emergencyContactName,
        emergencyContactPhone: emergencyContactPhone,
        email: email,
        dateOfBirth: dateOfBirth,
        addressLine: addressLine,
        city: city,
        pincode: pincode,
        photoUrl: photoUrl,
        payout: payout,
        currentVehicle: currentVehicle ?? this.currentVehicle,
      );

  @override
  List<Object?> get props => [
        id,
        fullName,
        phoneNumber,
        accountStatus,
        onboardingStatus,
        isProfileComplete,
        isOnline,
        isEligible,
        aadhar,
        drivingLicence,
        police,
        licenceExpiry,
        allowedCategories,
        emergencyContactName,
        emergencyContactPhone,
        email,
        dateOfBirth,
        addressLine,
        city,
        pincode,
        photoUrl,
        payout,
        currentVehicle,
      ];
}
