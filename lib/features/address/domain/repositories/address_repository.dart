import 'package:m_o_b_demand_side/core/errors/app_failure.dart';
import 'package:m_o_b_demand_side/features/address/domain/entities/address_entity.dart';

abstract interface class AddressRepository {
  Future<(List<AddressEntity>?, AppFailure?)> getAddresses();

  Future<(AddressEntity?, AppFailure?)> createAddress(AddressEntity address);

  Future<(List<AddressSuggestionEntity>?, AppFailure?)> searchLocations(
    String query,
  );

  Future<(AddressLocationEntity?, AppFailure?)> getLocationDetails(
    String placeId,
  );
}
