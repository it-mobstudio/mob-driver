class AddressEntity {
  const AddressEntity({
    this.id = '',
    required this.latitude,
    required this.longitude,
    required this.googleMapLink,
    required this.formattedAddress,
    required this.city,
    required this.state,
    required this.pincode,
    required this.sublocality,
    required this.locationName,
    required this.isLocationServiceable,
    required this.name,
    required this.email,
    required this.addressLine1,
    required this.sitePerson,
    required this.sitePersonMobile,
    required this.addressTag,
    required this.phoneNumber,
    required this.addressLine2,
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
  final String sitePerson;
  final String sitePersonMobile;
  final String addressTag;
  final String phoneNumber;
  final String addressLine2;

  String get displayAddress {
    final parts = [addressLine1, addressLine2, city, state, pincode]
        .where((value) => value.trim().isNotEmpty)
        .toList();
    return parts.isNotEmpty ? parts.join(', ') : formattedAddress;
  }

  factory AddressEntity.fromMap(Map<String, dynamic> map) {
    return AddressEntity(
      id: (map['id'] ?? map['address_id'] ?? '').toString(),
      latitude: _double(map['latitude']),
      longitude: _double(map['longitude']),
      googleMapLink: (map['google_map_link'] ?? '').toString(),
      formattedAddress: (map['formatted_address'] ?? map['address'] ?? '').toString(),
      city: (map['city'] ?? '').toString(),
      state: (map['state'] ?? '').toString(),
      pincode: (map['pincode'] ?? map['postal_code'] ?? '').toString(),
      sublocality: (map['sublocality'] ?? map['sub_locality'] ?? '').toString(),
      locationName: (map['locationName'] ?? map['location_name'] ?? '').toString(),
      isLocationServiceable:
          map['isLocationServiceable'] == true || map['is_location_serviceable'] == true,
      name: (map['name'] ?? '').toString(),
      email: (map['email'] ?? '').toString(),
      addressLine1: (map['address_line_1'] ?? '').toString(),
      sitePerson: (map['site_person'] ?? '').toString(),
      sitePersonMobile: (map['site_person_mobile'] ?? '').toString(),
      addressTag: (map['address_tag'] ?? map['tag'] ?? '').toString(),
      phoneNumber: (map['phone_number'] ?? map['phone'] ?? '').toString(),
      addressLine2: (map['address_line_2'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() => {
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
        'site_person': sitePerson,
        'site_person_mobile': sitePersonMobile,
        'address_tag': addressTag,
        'phone_number': phoneNumber,
        'address_line_2': addressLine2,
      };

  static double _double(dynamic value) =>
      value is num ? value.toDouble() : double.tryParse(value?.toString() ?? '') ?? 0;
}

class LocationSuggestion {
  const LocationSuggestion({
    required this.placeId,
    required this.description,
    required this.mainText,
    required this.secondaryText,
  });

  final String placeId;
  final String description;
  final String mainText;
  final String secondaryText;

  factory LocationSuggestion.fromMap(Map<String, dynamic> map) {
    final formatting = map['structured_formatting'] is Map
        ? Map<String, dynamic>.from(map['structured_formatting'] as Map)
        : <String, dynamic>{};
    return LocationSuggestion(
      placeId: (map['place_id'] ?? '').toString(),
      description: (map['description'] ?? '').toString(),
      mainText: (formatting['main_text'] ?? map['description'] ?? '').toString(),
      secondaryText: (formatting['secondary_text'] ?? '').toString(),
    );
  }
}

class PlaceDetails {
  const PlaceDetails({
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
