import 'package:m_o_b_demand_side/core/errors/app_failure.dart';
import 'package:m_o_b_demand_side/features/home/domain/entities/home_entity.dart';

abstract interface class HomeRepository {
  Future<(HomeEntity?, AppFailure?)> getHomeData();
}
