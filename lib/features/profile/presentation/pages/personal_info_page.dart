import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:m_o_b_demand_side/core/auth/auth_session.dart';
import 'package:m_o_b_demand_side/core/config/app_config.dart';
import 'package:m_o_b_demand_side/core/di/injection.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:m_o_b_demand_side/shared/widgets/app_back_icon.dart';
import 'package:m_o_b_demand_side/shared/widgets/app_text_field.dart';

class PersonalInfoPage extends StatelessWidget {
  const PersonalInfoPage({super.key});

  static const String routeName = 'PersonalInfoPage';
  static const String routePath = '/personal-info';

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ProfileBloc>()..add(ProfileLoadRequested()),
      child: const _PersonalInfoView(),
    );
  }
}

class _PersonalInfoView extends StatefulWidget {
  const _PersonalInfoView();

  @override
  State<_PersonalInfoView> createState() => _PersonalInfoViewState();
}

class _PersonalInfoViewState extends State<_PersonalInfoView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  bool _initialized = false;
  bool _submitting = false;

  // Set only when the user picks a new photo this session — kept as bytes
  // (rather than a File/path) so it previews the same way on web and mobile,
  // and so we can tell "no change" apart from "picked, then re-picked the
  // same file" when deciding whether to send profile_picture at all.
  Uint8List? _pickedImageBytes;
  String? _pickedImageName;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (!mounted || picked == null) return;
    final bytes = await picked.readAsBytes();
    if (!mounted || bytes.isEmpty) return;
    setState(() {
      _pickedImageBytes = bytes;
      _pickedImageName = picked.name;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileBloc, ProfileState>(
      listener: (context, state) {
        if (state case ProfileLoaded(:final profile)) {
          if (!_initialized) {
            _nameController.text = profile.name;
            _phoneController.text = profile.phone;
            _emailController.text = profile.email;
            _initialized = true;
          } else if (_submitting) {
            _submitting = false;
            // The freshly-saved profile_picture URL (if any) now lives in
            // AuthSession — drop the local preview so the avatar switches
            // over to the authoritative server copy.
            _pickedImageBytes = null;
            _pickedImageName = null;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile updated successfully')),
            );
          }
        } else if (state case ProfileError(:final message)) {
          _submitting = false;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is ProfileLoading;

        return Scaffold(
          backgroundColor: const Color(0xFFF1F1F1),
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF0A243F),
            leading: IconButton(
              onPressed: () => context.pop(),
              icon: const AppBackIcon(),
            ),
            centerTitle: true,
            title: Text(
              'Personal info',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: const Color(0xFF0A243F),
                fontSize: 14,
                fontWeight: FontWeight.w700,
                height: 1.47,
              ),
            ),
            bottom: const PreferredSize(
              preferredSize: Size.fromHeight(1),
              child: Divider(height: 1, color: Color(0xFFE8E8E8)),
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(10, 12, 10, 24),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(13, 19, 13, 13),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _ProfileAvatar(
                            imageUrl: AppConfig.resolveMediaUrl(
                              AuthSession
                                  .instance.userDetails?['profile_picture']
                                  ?.toString(),
                            ),
                            pickedImageBytes: _pickedImageBytes,
                            onEdit: _pickImage,
                          ),
                          const SizedBox(height: 29),
                          _ProfileField(
                            label: 'Name',
                            controller: _nameController,
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 20),
                          _ProfileField(
                            label: 'Business mobile',
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                            readOnly: true,
                          ),
                          const SizedBox(height: 20),
                          _ProfileField(
                            label: 'Email',
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.done,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(
                  10,
                  16,
                  10,
                  10 + MediaQuery.of(context).padding.bottom,
                ),
                decoration: const ShapeDecoration(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _updateProfile,
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: const Color(0xFF0866E9),
                      disabledBackgroundColor: const Color(0xFF9BBFF1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Update profile',
                            style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                height: 1.5),
                          ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _updateProfile() {
    final email = _emailController.text.trim();
    final emailOrPhone = AuthSession.instance.emailOrPhone;
    final pickedBytes = _pickedImageBytes;

    setState(() => _submitting = true);
    context.read<ProfileBloc>().add(
          ProfileUpdateRequested({
            // update_user requires this on every call, independent of what
            // else is being changed.
            if (emailOrPhone != null) 'email_or_phone': emailOrPhone,
            'full_name': _nameController.text.trim(),
            if (email.isNotEmpty) 'email': email,
            // Only sent when the user actually picked a new photo this
            // session — omitted entirely otherwise, never re-sent as-is.
            if (pickedBytes != null)
              'profile_picture': MultipartFile.fromBytes(
                pickedBytes,
                filename: _pickedImageName ?? 'profile-picture.jpg',
              ),
          }),
        );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.imageUrl,
    required this.pickedImageBytes,
    required this.onEdit,
  });

  final String imageUrl;
  final Uint8List? pickedImageBytes;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 104,
      height: 104,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 104,
            height: 104,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFF0F0F0),
            ),
            child: ClipOval(child: _image()),
          ),
          Positioned(
            right: -1,
            bottom: 1,
            child: InkWell(
              onTap: onEdit,
              customBorder: const CircleBorder(),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFCBD3DE),
                  ),
                ),
                child: Center(
                  child: SvgPicture.asset(
                    'assets/images/editicon.svg',
                    width: 16,
                    height: 16,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fallback() {
    return Center(
      child: SvgPicture.asset(
        'assets/images/grayprofile.svg',
        width: 48,
        height: 48,
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _image() {
    final bytes = pickedImageBytes;
    if (bytes != null) {
      return Image.memory(bytes, width: 104, height: 104, fit: BoxFit.cover);
    }
    if (imageUrl.isEmpty) return _fallback();
    return Image.network(
      imageUrl,
      width: 104,
      height: 104,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _fallback(),
    );
  }
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({
    required this.label,
    required this.controller,
    this.keyboardType,
    this.textInputAction,
    this.readOnly = false,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      hintText: '$label*',
      controller: controller,
      enabled: !readOnly,
      readOnly: readOnly,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
    );
  }
}
