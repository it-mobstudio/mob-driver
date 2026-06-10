import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:m_o_b_demand_side/core/di/injection.dart';
import 'package:m_o_b_demand_side/features/address/domain/entities/address_entity.dart';
import 'package:m_o_b_demand_side/features/address/presentation/bloc/address_bloc.dart';

class AddressDetailsPage extends StatefulWidget {
  const AddressDetailsPage({super.key, required this.place});

  static const routeName = 'AddressDetails';
  static const routePath = '/address_details';

  final PlaceDetails place;

  @override
  State<AddressDetailsPage> createState() => _AddressDetailsPageState();
}

class _AddressDetailsPageState extends State<AddressDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _addressLine1 = TextEditingController();
  final _addressLine2 = TextEditingController();
  final _sitePerson = TextEditingController();
  final _siteMobile = TextEditingController();
  final _phone = TextEditingController();
  String _tag = 'Home';

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _addressLine1.dispose();
    _addressLine2.dispose();
    _sitePerson.dispose();
    _siteMobile.dispose();
    _phone.dispose();
    super.dispose();
  }

  String? _required(String? value) =>
      (value ?? '').trim().isEmpty ? 'This field is required' : null;

  String? _mobile(String? value) {
    final mobile = (value ?? '').replaceAll(RegExp(r'\D'), '');
    return mobile.length == 10 ? null : 'Enter a valid 10 digit mobile number';
  }

  void _save(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;
    final place = widget.place;
    context.read<AddressBloc>().add(AddressSaveRequested(AddressEntity(
          latitude: place.latitude,
          longitude: place.longitude,
          googleMapLink:
              'https://www.google.com/maps?q=${place.latitude},${place.longitude}',
          formattedAddress: place.formattedAddress,
          city: place.city,
          state: place.state,
          pincode: place.pincode,
          sublocality: place.sublocality,
          locationName: place.locationName,
          isLocationServiceable: true,
          name: _name.text.trim(),
          email: _email.text.trim(),
          addressLine1: _addressLine1.text.trim(),
          sitePerson: _sitePerson.text.trim(),
          sitePersonMobile: _siteMobile.text.trim(),
          addressTag: _tag,
          phoneNumber: _phone.text.trim(),
          addressLine2: _addressLine2.text.trim(),
        )));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AddressBloc>(),
      child: BlocConsumer<AddressBloc, AddressState>(
        listener: (context, state) {
          if (state.error != null) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.error!)));
            context.read<AddressBloc>().add(AddressMessageCleared());
          }
          if (state.savedAddress != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Address saved successfully.')),
            );
            context.go('/address_selection');
          }
        },
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Add address details'),
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF0A243F),
              elevation: 0,
            ),
            body: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F6F8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(widget.place.formattedAddress),
                  ),
                  const SizedBox(height: 16),
                  _field(_name, 'Full name', validator: _required),
                  _field(
                    _email,
                    'Email',
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      final email = (value ?? '').trim();
                      if (email.isEmpty) return 'This field is required';
                      return email.contains('@') ? null : 'Enter a valid email';
                    },
                  ),
                  _field(_phone, 'Phone number',
                      keyboardType: TextInputType.phone, validator: _mobile),
                  _field(_addressLine1, 'Address line 1', validator: _required),
                  _field(_addressLine2, 'Address line 2'),
                  _field(_sitePerson, 'Site person', validator: _required),
                  _field(_siteMobile, 'Site person mobile',
                      keyboardType: TextInputType.phone, validator: _mobile),
                  DropdownButtonFormField<String>(
                    value: _tag,
                    decoration: const InputDecoration(
                      labelText: 'Address tag',
                      border: OutlineInputBorder(),
                    ),
                    items: const ['Home', 'Office', 'Site', 'Other']
                        .map((tag) => DropdownMenuItem(value: tag, child: Text(tag)))
                        .toList(),
                    onChanged: (value) => setState(() => _tag = value ?? 'Home'),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: state.isSaving ? null : () => _save(context),
                      child: state.isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save address'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
