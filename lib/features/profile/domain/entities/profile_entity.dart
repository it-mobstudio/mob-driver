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
    return ProfileEntity(
      name:
          (map['name'] ?? map['full_name'] ?? map['username'] ?? '').toString(),
      phone: (map['phone'] ?? map['phone_number'] ?? map['mobile'] ?? '')
          .toString(),
      email: (map['email'] ?? '').toString(),
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
