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
