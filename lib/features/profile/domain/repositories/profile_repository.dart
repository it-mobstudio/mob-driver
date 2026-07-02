import 'package:m_o_b_demand_side/core/errors/app_failure.dart';
import 'package:m_o_b_demand_side/features/profile/domain/entities/profile_entity.dart';

abstract interface class ProfileRepository {
  Future<(ProfileEntity?, AppFailure?)> getProfile();
  Future<(bool, AppFailure?)> updateProfile(Map<String, dynamic> data);
  Future<(ReferralSummaryEntity?, AppFailure?)> getReferralSummary();
  Future<(WalletHistoryEntity?, AppFailure?)> getWalletHistory();
  Future<(MobstarEntity?, AppFailure?)> getMobstar();
  Future<(ProjectListEntity?, AppFailure?)> getProjects({int page = 1});
}
