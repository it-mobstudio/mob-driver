import 'package:m_o_b_demand_side/features/address/data/local/selected_address_store.dart';

Future<Map<String, dynamic>> selectedCityQueryParameter() async {
  final address =
      SelectedAddressStore.cached ?? await SelectedAddressStore.read();
  final city = address?.city.trim() ?? '';
  if (city.isEmpty) return const <String, dynamic>{};
  return <String, dynamic>{'city': city};
}
