class ReferralInviteEntity {
  const ReferralInviteEntity({
    required this.inviteId,
    required this.inviteeName,
    required this.inviteePhone,
    required this.ordered,
    required this.rewarded,
    required this.inviterRewardAmount,
    this.firstOrderNumber = '',
    this.createdAt = '',
  });

  final int inviteId;
  final String inviteeName;
  final String inviteePhone;
  final bool ordered;
  final bool rewarded;
  final double inviterRewardAmount;
  final String firstOrderNumber;
  final String createdAt;

  factory ReferralInviteEntity.fromMap(Map<String, dynamic> map) {
    final inviteeRaw = map['invitee'];
    final inviteeMap = inviteeRaw is Map
        ? Map<String, dynamic>.from(inviteeRaw)
        : <String, dynamic>{};
    return ReferralInviteEntity(
      inviteId: int.tryParse((map['invite_id'] ?? map['id'] ?? '0').toString()) ?? 0,
      inviteeName: (inviteeMap['name'] ??
              inviteeMap['full_name'] ??
              map['invitee_name'] ??
              map['name'] ??
              '')
          .toString(),
      inviteePhone: (inviteeMap['phone'] ??
              inviteeMap['phone_number'] ??
              map['invitee_phone'] ??
              map['phone'] ??
              '')
          .toString(),
      ordered: map['ordered'] == true,
      rewarded: map['rewarded'] == true,
      inviterRewardAmount: double.tryParse(
            (map['inviter_reward_amount'] ?? '0').toString(),
          ) ??
          0,
      firstOrderNumber: (map['first_order_number'] ?? '').toString(),
      createdAt: (map['created_at'] ?? '').toString(),
    );
  }
}

class ReferralSummaryEntity {
  const ReferralSummaryEntity({
    required this.referralCode,
    required this.referralLink,
    required this.invitedCount,
    required this.orderedCount,
    required this.notOrderedCount,
    required this.rewardedCount,
    required this.walletCreditedAmount,
    required this.walletBalance,
    required this.invites,
  });

  final String referralCode;
  final String referralLink;
  final int invitedCount;
  final int orderedCount;
  final int notOrderedCount;
  final int rewardedCount;
  final double walletCreditedAmount;
  final double walletBalance;
  final List<ReferralInviteEntity> invites;

  factory ReferralSummaryEntity.fromMap(Map<String, dynamic> map) {
    final invitesRaw = map['invites'] is List ? map['invites'] as List : <dynamic>[];
    return ReferralSummaryEntity(
      referralCode: (map['referral_code'] ?? '').toString(),
      referralLink: (map['referral_link'] ?? '').toString(),
      invitedCount: int.tryParse((map['invited_count'] ?? '0').toString()) ?? 0,
      orderedCount: int.tryParse((map['ordered_count'] ?? '0').toString()) ?? 0,
      notOrderedCount:
          int.tryParse((map['not_ordered_count'] ?? '0').toString()) ?? 0,
      rewardedCount: int.tryParse((map['rewarded_count'] ?? '0').toString()) ?? 0,
      walletCreditedAmount: double.tryParse(
            (map['wallet_credited_amount'] ?? '0').toString(),
          ) ??
          0,
      walletBalance: double.tryParse(
            (map['wallet_balance'] ?? '0').toString(),
          ) ??
          0,
      invites: invitesRaw
          .whereType<Map>()
          .map((e) => ReferralInviteEntity.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }

  static const empty = ReferralSummaryEntity(
    referralCode: '',
    referralLink: '',
    invitedCount: 0,
    orderedCount: 0,
    notOrderedCount: 0,
    rewardedCount: 0,
    walletCreditedAmount: 0,
    walletBalance: 0,
    invites: [],
  );
}

class ProfileEntity {
  const ProfileEntity({
    required this.name,
    required this.phone,
    required this.email,
    required this.gstin,
    required this.businessName,
    required this.rewardPoints,
    this.referralCode = '',
  });

  final String name;
  final String phone;
  final String email;
  final String gstin;
  final String businessName;
  final int rewardPoints;
  final String referralCode;

  factory ProfileEntity.fromMap(Map<String, dynamic> map) {
    final emailOrPhone = (map['email_or_phone'] ?? '').toString().trim();
    final phoneFallback = emailOrPhone.contains('@') ? '' : emailOrPhone;
    final emailFallback = emailOrPhone.contains('@') ? emailOrPhone : '';

    return ProfileEntity(
      name: (map['name'] ??
              map['full_name'] ??
              map['display_name'] ??
              map['username'] ??
              '')
          .toString(),
      phone: (map['phone'] ??
              map['phone_number'] ??
              map['mobile'] ??
              map['business_mobile'] ??
              map['contact_number'] ??
              phoneFallback)
          .toString(),
      email: (map['email'] ?? map['email_id'] ?? emailFallback).toString(),
      gstin:
          (map['gstin'] ?? map['gst_number'] ?? map['gst_no'] ?? '').toString(),
      businessName:
          (map['business_name'] ?? map['company_name'] ?? '').toString(),
      rewardPoints: int.tryParse(
            (map['reward_points'] ?? map['mobstar_points'] ?? '0').toString(),
          ) ??
          0,
      referralCode:
          (map['referral_code'] ?? map['referralCode'] ?? '').toString(),
    );
  }

  static const empty = ProfileEntity(
    name: '',
    phone: '',
    email: '',
    gstin: '',
    businessName: '',
    rewardPoints: 0,
    referralCode: '',
  );
}
