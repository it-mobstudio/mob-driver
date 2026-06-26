class BusinessSegmentEntity {
  const BusinessSegmentEntity({
    required this.id,
    required this.category,
    required this.categoryName,
    required this.lineOfCreditInterest,
    required this.interestAfter,
    required this.termsAndConditions,
    required this.mobPartnerFees,
  });

  final int id;
  final String category;
  final String categoryName;
  final String lineOfCreditInterest;
  final int interestAfter;
  final String termsAndConditions;
  final String mobPartnerFees;

  factory BusinessSegmentEntity.fromMap(Map<String, dynamic> map) {
    return BusinessSegmentEntity(
      id: (map['id'] as num?)?.toInt() ?? 0,
      category: map['category']?.toString() ?? '',
      categoryName: map['category_name']?.toString() ?? '',
      lineOfCreditInterest: map['line_of_credit_interest']?.toString() ?? '',
      interestAfter: (map['interest_after'] as num?)?.toInt() ?? 0,
      termsAndConditions: map['terms_and_conditions']?.toString() ?? '',
      mobPartnerFees: map['mob_partner_fees']?.toString() ?? '',
    );
  }
}
