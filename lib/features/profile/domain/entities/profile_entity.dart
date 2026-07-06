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
      inviteId:
          int.tryParse((map['invite_id'] ?? map['id'] ?? '0').toString()) ?? 0,
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
    final invitesRaw =
        map['invites'] is List ? map['invites'] as List : <dynamic>[];
    return ReferralSummaryEntity(
      referralCode: (map['referral_code'] ?? '').toString(),
      referralLink: (map['referral_link'] ?? '').toString(),
      invitedCount: int.tryParse((map['invited_count'] ?? '0').toString()) ?? 0,
      orderedCount: int.tryParse((map['ordered_count'] ?? '0').toString()) ?? 0,
      notOrderedCount:
          int.tryParse((map['not_ordered_count'] ?? '0').toString()) ?? 0,
      rewardedCount:
          int.tryParse((map['rewarded_count'] ?? '0').toString()) ?? 0,
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
          .map(
              (e) => ReferralInviteEntity.fromMap(Map<String, dynamic>.from(e)))
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

class WalletTransactionEntity {
  const WalletTransactionEntity({
    required this.id,
    required this.amount,
    required this.remarks,
    required this.transactionType,
    required this.createdAt,
    required this.orderNumber,
  });

  final int id;
  final double amount;
  final String remarks;
  final String transactionType;
  final DateTime? createdAt;
  final String orderNumber;

  bool get isDebit => transactionType.toUpperCase() == 'DEBIT' || amount < 0;

  factory WalletTransactionEntity.fromMap(Map<String, dynamic> map) {
    final details = map['details'] is Map
        ? Map<String, dynamic>.from(map['details'] as Map)
        : <String, dynamic>{};
    return WalletTransactionEntity(
      id: int.tryParse((map['id'] ?? '0').toString()) ?? 0,
      amount: double.tryParse((map['amount'] ?? '0').toString()) ?? 0,
      remarks: (map['remarks'] ?? '').toString(),
      transactionType: (map['transaction_type'] ?? '').toString(),
      createdAt: DateTime.tryParse((map['created_at'] ?? '').toString()),
      orderNumber: (details['order_id'] ??
              (map['metadata'] is Map
                  ? (map['metadata'] as Map)['order_number']
                  : null) ??
              '')
          .toString(),
    );
  }
}

class WalletHistoryEntity {
  const WalletHistoryEntity(
      {required this.balance, required this.transactions});

  final double balance;
  final List<WalletTransactionEntity> transactions;

  factory WalletHistoryEntity.fromMap(Map<String, dynamic> map) {
    final results =
        map['results'] is List ? map['results'] as List : const <dynamic>[];
    return WalletHistoryEntity(
      balance: double.tryParse(
            (map['wallet'] ??
                    map['wallet_balance'] ??
                    map['mob_wallet_balance'] ??
                    '0')
                .toString(),
          ) ??
          0,
      transactions: results
          .whereType<Map>()
          .map((item) => WalletTransactionEntity.fromMap(
                Map<String, dynamic>.from(item),
              ))
          .toList(),
    );
  }
}

class MobstarEntity {
  const MobstarEntity({
    required this.points,
    required this.actualMoney,
    required this.levelName,
    required this.percentage,
    required this.freeDelivery,
    required this.nextLevelName,
    required this.purchaseLimit,
    required this.transactions,
  });

  final int points;
  final double actualMoney;
  final String levelName;
  final double percentage;
  final int freeDelivery;
  final String nextLevelName;
  final double purchaseLimit;
  final List<MobstarTransactionEntity> transactions;

  String get membership {
    final match = RegExp(r'\(([^)]+)\)').firstMatch(levelName);
    return match?.group(1) ?? (levelName.isEmpty ? 'Bronze' : levelName);
  }

  String get nextMembership {
    final match = RegExp(r'\(([^)]+)\)').firstMatch(nextLevelName);
    return match?.group(1) ??
        (nextLevelName.isEmpty ? 'Silver' : nextLevelName);
  }

  factory MobstarEntity.fromMap(Map<String, dynamic> map) {
    final source = map['data'] is Map
        ? Map<String, dynamic>.from(map['data'] as Map)
        : map;
    final program = source['program_details'] is Map
        ? Map<String, dynamic>.from(source['program_details'] as Map)
        : <String, dynamic>{};
    final results = source['results'] is List
        ? source['results'] as List
        : const <dynamic>[];
    final first = results.whereType<Map>().isNotEmpty
        ? Map<String, dynamic>.from(results.whereType<Map>().first)
        : <String, dynamic>{};
    final pointsMap = first['mobStarPoints'] is Map
        ? Map<String, dynamic>.from(first['mobStarPoints'] as Map)
        : <String, dynamic>{};
    final points = int.tryParse(
          (program['current_points'] ?? pointsMap['points'] ?? '0').toString(),
        ) ??
        0;
    final moneyFromApi =
        double.tryParse((pointsMap['actual_money'] ?? '').toString());

    return MobstarEntity(
      points: points,
      actualMoney: moneyFromApi ?? points / 4,
      levelName: (program['current_loyalty_program'] ??
              pointsMap['name'] ??
              'Level 01 (Bronze)')
          .toString(),
      percentage:
          double.tryParse((pointsMap['percentage'] ?? '0').toString()) ?? 0,
      freeDelivery:
          int.tryParse((pointsMap['free_delivery'] ?? '0').toString()) ?? 0,
      nextLevelName:
          (program['next_loyalty_program'] ?? 'Level 02 (Silver)').toString(),
      purchaseLimit:
          double.tryParse((program['purchase_limit'] ?? '0').toString()) ?? 0,
      transactions: results
          .whereType<Map>()
          .map((item) => MobstarTransactionEntity.fromMap(
                Map<String, dynamic>.from(item),
              ))
          .toList(),
    );
  }

  static const empty = MobstarEntity(
    points: 0,
    actualMoney: 0,
    levelName: 'Level 01 (Bronze)',
    percentage: 0,
    freeDelivery: 0,
    nextLevelName: 'Level 02 (Silver)',
    purchaseLimit: 250000,
    transactions: [],
  );
}

class MobstarTransactionEntity {
  const MobstarTransactionEntity({
    required this.points,
    required this.currentBalance,
    required this.txType,
    required this.status,
    required this.createdAt,
    required this.validTill,
    required this.notes,
    required this.orderId,
    required this.amount,
  });

  final int points;
  final int currentBalance;
  final String txType;
  final String status;
  final DateTime? createdAt;
  final String validTill;
  final String notes;
  final String orderId;
  final double amount;

  bool get credited => txType.toUpperCase() == 'EARN' || points > 0;

  factory MobstarTransactionEntity.fromMap(Map<String, dynamic> map) {
    final details = map['details'] is Map
        ? Map<String, dynamic>.from(map['details'] as Map)
        : <String, dynamic>{};
    return MobstarTransactionEntity(
      points: int.tryParse((map['points'] ?? '0').toString()) ?? 0,
      currentBalance:
          int.tryParse((map['current_balance'] ?? '0').toString()) ?? 0,
      txType: (map['tx_type'] ?? '').toString(),
      status: (map['status'] ?? '').toString(),
      createdAt: DateTime.tryParse((map['created_at'] ?? '').toString()),
      validTill: (map['valid_till'] ?? map['expires_on'] ?? '').toString(),
      notes: (map['notes'] ?? '').toString(),
      orderId: (details['order_id'] ?? details['id'] ?? '').toString(),
      amount: double.tryParse((details['amount'] ?? '0').toString()) ?? 0,
    );
  }
}

class ProjectEntity {
  const ProjectEntity({
    required this.id,
    required this.projectId,
    required this.name,
    required this.address,
    required this.city,
    required this.sitePersonName,
    required this.phone,
    required this.rfqCount,
    required this.orderCount,
    required this.imageUrl,
  });

  final int id;
  final String projectId;
  final String name;
  final String address;
  final String city;
  final String sitePersonName;
  final String phone;
  final int rfqCount;
  final int orderCount;
  final String imageUrl;

  String get initials {
    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
    if (words.isEmpty) return 'PR';
    if (words.length == 1) return words.first.substring(0, 1).toUpperCase();
    return '${words.first[0]}${words[1][0]}'.toUpperCase();
  }

  bool matches(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return true;
    return name.toLowerCase().contains(normalized) ||
        projectId.toLowerCase().contains(normalized) ||
        address.toLowerCase().contains(normalized) ||
        city.toLowerCase().contains(normalized);
  }

  factory ProjectEntity.fromMap(Map<String, dynamic> map) {
    final project = _asMap(map['project']);
    final addressMap = _asMap(
      map['delivery_address'] ??
          map['address'] ??
          map['project_address'] ??
          project['address'],
    );
    final manager = _asMap(
      map['site_person'] ??
          map['site_manager'] ??
          map['project_manager'] ??
          addressMap['site_person'],
    );

    final id = _asInt(map['id'] ?? project['id']);
    final projectCode = _firstString([
      map['project_id'],
      map['projectId'],
      map['project_code'],
      map['code'],
      project['project_id'],
      project['project_code'],
      id == 0 ? null : id,
    ]);
    final name = _firstString([
      map['project_name'],
      map['name'],
      map['title'],
      project['project_name'],
      project['name'],
      'Project',
    ]);

    return ProjectEntity(
      id: id,
      projectId: projectCode,
      name: name,
      address: _addressFrom(addressMap, map),
      city: _firstString([
        map['city'],
        addressMap['city'],
        addressMap['district'],
        addressMap['state'],
      ]),
      sitePersonName: _firstString([
        map['site_person_name'],
        map['site_manager_name'],
        map['project_manager_name'],
        manager['name'],
        addressMap['name'],
        addressMap['contact_person'],
      ]),
      phone: _firstString([
        map['phone'],
        map['phone_number'],
        map['site_person_phone'],
        map['site_manager_phone'],
        manager['phone'],
        manager['phone_number'],
        addressMap['phone'],
        addressMap['phone_number'],
      ]),
      rfqCount: _countFrom(map, const [
        'rfq_count',
        'rfqs_count',
        'rfqCount',
        'rfq',
        'rfqs',
      ]),
      orderCount: _countFrom(map, const [
        'order_count',
        'orders_count',
        'orderCount',
        'orders',
      ]),
      imageUrl: _firstString([
        map['image'],
        map['image_url'],
        map['project_image'],
        map['thumbnail'],
        project['image'],
        project['image_url'],
      ]),
    );
  }

  static Map<String, dynamic> _asMap(dynamic value) =>
      value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

  static int _asInt(dynamic value) =>
      int.tryParse((value ?? '0').toString()) ?? 0;

  static int _countFrom(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value is List) return value.length;
      if (value != null) return _asInt(value);
    }
    return 0;
  }

  static String _firstString(List<dynamic> values) {
    for (final value in values) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty && text != 'null') return text;
    }
    return '';
  }

  static String _addressFrom(
    Map<String, dynamic> addressMap,
    Map<String, dynamic> fallback,
  ) {
    final direct = _firstString([
      fallback['delivery_address'],
      fallback['full_address'],
      fallback['address'],
      fallback['project_address'],
      addressMap['full_address'],
      addressMap['address'],
      addressMap['formatted_address'],
    ]);
    if (direct.isNotEmpty && !direct.startsWith('{')) return direct;

    return [
      addressMap['address_line1'],
      addressMap['address_line2'],
      addressMap['landmark'],
      addressMap['city'],
      addressMap['state'],
      addressMap['pincode'] ?? addressMap['postal_code'],
    ]
        .map((part) => part?.toString().trim() ?? '')
        .where((part) => part.isNotEmpty && part != 'null')
        .join(', ');
  }
}

class ProjectListEntity {
  const ProjectListEntity({
    required this.projects,
    required this.page,
    required this.totalCount,
  });

  final List<ProjectEntity> projects;
  final int page;
  final int totalCount;

  factory ProjectListEntity.fromMap(Map<String, dynamic> map, {int page = 1}) {
    final data = map['data'];
    final dataMap = data is Map ? Map<String, dynamic>.from(data) : map;
    final raw = dataMap['results'] ??
        dataMap['projects'] ??
        dataMap['data'] ??
        map['results'] ??
        const <dynamic>[];
    final list = raw is List ? raw : const <dynamic>[];
    return ProjectListEntity(
      projects: list
          .whereType<Map>()
          .map((item) => ProjectEntity.fromMap(Map<String, dynamic>.from(item)))
          .toList(),
      page: page,
      totalCount: ProjectEntity._asInt(
        dataMap['count'] ?? dataMap['total'] ?? dataMap['total_count'],
      ),
    );
  }

  static const empty = ProjectListEntity(
    projects: [],
    page: 1,
    totalCount: 0,
  );

  ProjectListEntity copyWith({
    List<ProjectEntity>? projects,
    int? page,
    int? totalCount,
  }) {
    return ProjectListEntity(
      projects: projects ?? this.projects,
      page: page ?? this.page,
      totalCount: totalCount ?? this.totalCount,
    );
  }
}
