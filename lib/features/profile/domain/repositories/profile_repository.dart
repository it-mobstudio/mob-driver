import 'dart:typed_data';

import 'package:m_o_b_demand_side/core/errors/app_failure.dart';
import 'package:m_o_b_demand_side/features/profile/domain/entities/profile_entity.dart';

abstract interface class ProfileRepository {
  Future<(ProfileEntity?, AppFailure?)> getProfile();
  Future<(bool, AppFailure?)> updateProfile(Map<String, dynamic> data);
  Future<(ReferralSummaryEntity?, AppFailure?)> getReferralSummary();
  Future<(WalletHistoryEntity?, AppFailure?)> getWalletHistory();
  Future<(MobstarEntity?, AppFailure?)> getMobstar();
  Future<(ProjectListEntity?, AppFailure?)> getProjects({int page = 1});

  /// Exactly one of [siteDeliveryAddressId]/[newAddress] should be set:
  /// the former picks an existing saved address, the latter creates one
  /// inline (mirrors the web app's create_project contract).
  Future<(bool, AppFailure?)> createProject({
    required String projectName,
    required String city,
    int? siteDeliveryAddressId,
    Map<String, dynamic>? newAddress,
    Uint8List? imageBytes,
    String? imageFilename,
  });

  /// [address] must be a full address object (including `id`/`address_tag`)
  /// — updates never support picking a different saved address.
  Future<(bool, AppFailure?)> updateProject({
    required String projectId,
    required String projectName,
    required String city,
    required Map<String, dynamic> address,
    Uint8List? imageBytes,
    String? imageFilename,
  });

  Future<(bool, AppFailure?)> requestAccountDeletion();
}
