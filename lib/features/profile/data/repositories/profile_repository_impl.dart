import 'package:dio/dio.dart';
import 'package:m_o_b_demand_side/core/auth/auth_session.dart';
import 'package:m_o_b_demand_side/core/errors/app_failure.dart';
import 'package:m_o_b_demand_side/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:m_o_b_demand_side/features/profile/domain/entities/profile_entity.dart';
import 'package:m_o_b_demand_side/features/profile/domain/repositories/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl(this._datasource);

  final ProfileRemoteDatasource _datasource;

  @override
  Future<(ProfileEntity?, AppFailure?)> getProfile() async {
    try {
      final body = await _datasource.getProfile();
      final responseData = body['data'] is Map
          ? Map<String, dynamic>.from(body['data'] as Map)
          : body;
      final data = <String, dynamic>{};
      final sessionData = AuthSession.instance.userDetails;
      if (sessionData != null) {
        data.addAll(_flattenProfileData(sessionData));
      }
      data.addAll(_flattenProfileData(responseData));
      return (ProfileEntity.fromMap(data), null);
    } on DioException catch (e) {
      return (null, e.toAppFailure());
    } catch (e) {
      return (null, UnknownFailure(e.toString()));
    }
  }

  Map<String, dynamic> _flattenProfileData(Map<String, dynamic> source) {
    final flattened = <String, dynamic>{};
    for (final key in const [
      'user_details',
      'user_data',
      'user',
      'profile',
      'account',
    ]) {
      final nested = source[key];
      if (nested is Map) {
        flattened.addAll(
          Map<String, dynamic>.from(nested),
        );
      }
    }
    flattened.addAll(source);
    return flattened;
  }

  @override
  Future<(bool, AppFailure?)> updateProfile(Map<String, dynamic> data) async {
    try {
      final body = await _datasource.updateProfile(data);
      if (body['status'] == false) {
        final msg = body['message']?.toString() ?? 'Update failed.';
        return (false, BusinessFailure(msg));
      }
      return (true, null);
    } on DioException catch (e) {
      return (false, e.toAppFailure());
    } catch (e) {
      return (false, UnknownFailure(e.toString()));
    }
  }
}
