class AddressEntity {
  const AddressEntity({
    this.id = '',
    required this.latitude,
    required this.longitude,
    required this.formattedAddress,
    required this.city,
    required this.state,
    required this.pincode,
    required this.sublocality,
    required this.locationName,
    required this.name,
    required this.email,
    required this.addressLine1,
    required this.addressLine2,
    required this.sitePerson,
    required this.sitePersonMobile,
    required this.addressTag,
    required this.phoneNumber,
    this.googleMapLink = '',
    this.isLocationServiceable = true,
    this.projectName = '',
    this.mobCredit = false,
    this.gstNumber = '',
  });

  final String id;
  final double latitude;
  final double longitude;
  final String googleMapLink;
  final String formattedAddress;
  final String city;
  final String state;
  final String pincode;
  final String sublocality;
  final String locationName;
  final bool isLocationServiceable;
  final String name;
  final String email;
  final String addressLine1;
  final String addressLine2;
  final String sitePerson;
  final String sitePersonMobile;
  final String addressTag;
  final String phoneNumber;
  final String projectName;
  /// Marks this saved address as the user's designated mobCREDIT/billing
  /// address (mirrors web's `address?.mob_credit`, used to auto-pick a
  /// billing address at checkout).
  final bool mobCredit;
  final String gstNumber;

  String get displayAddress => [
        addressLine1,
        addressLine2,
        formattedAddress,
      ].where((part) => part.trim().isNotEmpty).join(', ');

  factory AddressEntity.fromMap(Map<String, dynamic> map) {
    return AddressEntity(
      id: _stringValue(map, const ['id', 'pk', 'address_id']),
      latitude: _toDouble(
        _firstValue(map, const ['latitude', 'lat', 'map_latitude']),
      ),
      longitude: _toDouble(
        _firstValue(map, const ['longitude', 'lng', 'lon', 'map_longitude']),
      ),
      googleMapLink:
          _stringValue(map, const ['google_map_link', 'googleMapLink']),
      formattedAddress: _stringValue(
        map,
        const ['formatted_address', 'formattedAddress', 'full_address'],
      ),
      city: _stringValue(map, const ['city', 'locality']),
      state: _stringValue(
        map,
        const ['state', 'administrative_area', 'administrativeArea'],
      ),
      pincode: _pincodeValue(map),
      sublocality: _stringValue(
        map,
        const ['sublocality', 'sub_locality', 'subLocality'],
      ),
      locationName: _stringValue(
        map,
        const ['locationName', 'location_name', 'place_name'],
      ),
      isLocationServiceable: _toBool(
        _firstValue(
          map,
          const ['isLocationServiceable', 'is_location_serviceable'],
        ),
      ),
      name: _stringValue(map, const ['name', 'full_name']),
      email: _stringValue(map, const ['email']),
      addressLine1: _stringValue(map, const ['address_line_1', 'address1']),
      addressLine2: _stringValue(map, const ['address_line_2', 'address2']),
      sitePerson: _stringValue(map, const ['site_person', 'delivery_person']),
      sitePersonMobile: _stringValue(
        map,
        const ['site_person_mobile', 'delivery_phone'],
      ),
      addressTag:
          _stringValue(map, const ['address_tag', 'tag', 'address_type']),
      phoneNumber: _stringValue(map, const ['phone_number', 'phone', 'mobile']),
      projectName: _projectNameValue(map),
      mobCredit: map['mob_credit'] == true ||
          map['mob_credit']?.toString().toLowerCase() == 'true',
      gstNumber: _stringValue(map, const ['gst_number', 'gstin', 'gst_no']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'google_map_link': googleMapLink,
      'formatted_address': formattedAddress,
      'city': city,
      'state': state,
      'pincode': pincode,
      'sublocality': sublocality,
      'locationName': locationName,
      'isLocationServiceable': isLocationServiceable,
      'name': name,
      'email': email,
      'address_line_1': addressLine1,
      'address_line_2': addressLine2,
      'site_person': sitePerson,
      'site_person_mobile': sitePersonMobile,
      'address_tag': addressTag,
      'phone_number': phoneNumber,
      'project_name': projectName,
      'mob_credit': mobCredit,
      'gst_number': gstNumber,
    };
  }

  Map<String, dynamic> toCreatePayload() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'google_map_link': googleMapLink.isNotEmpty
          ? googleMapLink
          : 'https://www.google.com/maps?q=$latitude,$longitude',
      'formatted_address': formattedAddress,
      'city': city,
      'state': state,
      'pincode': pincode,
      'sublocality': sublocality,
      'locationName': locationName,
      'isLocationServiceable': isLocationServiceable,
      'name': name,
      'email': email,
      'address_line_1': addressLine1,
      'site_person': sitePerson,
      'site_person_mobile': sitePersonMobile,
      'address_tag': addressTag,
      'phone_number': phoneNumber,
      'address_line_2': addressLine2,
      'gst_number': gstNumber,
    };
  }

  static dynamic _firstValue(
    Map<String, dynamic> map,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = map[key];
      if (value != null && value.toString().trim().isNotEmpty) return value;
    }
    return null;
  }

  static String _stringValue(
    Map<String, dynamic> map,
    List<String> keys,
  ) {
    return _firstValue(map, keys)?.toString().trim() ?? '';
  }

  static bool _toBool(dynamic value) {
    if (value == null) return true;
    if (value is bool) return value;
    final normalized = value.toString().trim().toLowerCase();
    return normalized != 'false' && normalized != '0' && normalized != 'no';
  }

  /// 'project_name' and 'project' can each hold either a plain string or the
  /// full project object ({project_id, project_name, city, project_image})
  /// depending on the endpoint — always unwrap to just the name, never dump
  /// the object's toString().
  static String _projectNameValue(Map<String, dynamic> map) {
    for (final key in const ['project_name', 'project']) {
      final value = map[key];
      if (value == null) continue;
      if (value is Map) {
        final nested = _stringValue(
          value.cast<String, dynamic>(),
          const ['project_name', 'name'],
        );
        if (nested.isNotEmpty) return nested;
        continue;
      }
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return '';
  }

  static String _pincodeValue(Map<String, dynamic> map) {
    final direct = _stringValue(
      map,
      const ['pincode', 'postal_code', 'postalCode', 'zip'],
    );
    if (direct.isNotEmpty) return direct;
    final address = _stringValue(
      map,
      const ['formatted_address', 'formattedAddress', 'full_address'],
    );
    return RegExp(r'\b[1-9][0-9]{5}\b').firstMatch(address)?.group(0) ?? '';
  }

  static double _toDouble(dynamic value) {
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class AddressLocationEntity {
  const AddressLocationEntity({
    required this.latitude,
    required this.longitude,
    required this.formattedAddress,
    required this.city,
    required this.state,
    required this.pincode,
    required this.sublocality,
    required this.locationName,
  });

  final double latitude;
  final double longitude;
  final String formattedAddress;
  final String city;
  final String state;
  final String pincode;
  final String sublocality;
  final String locationName;
}

class AddressSuggestionEntity {
  const AddressSuggestionEntity({
    required this.placeId,
    required this.primaryText,
    required this.secondaryText,
  });

  final String placeId;
  final String primaryText;
  final String secondaryText;
}

class UserAddressEntity {
  const UserAddressEntity({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.tag,
    this.pincode = '',
    this.project = '',
    this.gstNumber = '',
  });

  final String id;
  final String name;
  final String address;
  final String phone;
  final String tag;
  final String pincode;
  final String project;
  final String gstNumber;

  bool get hasAddress => address.trim().isNotEmpty;
}
