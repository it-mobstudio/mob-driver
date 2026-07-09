import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:m_o_b_demand_side/core/di/injection.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:m_o_b_demand_side/shared/widgets/app_back_icon.dart';

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

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
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
              style: GoogleFonts.inter(
                color: const Color(0xFF0A243F),
                fontSize: 14,
                fontWeight: FontWeight.w700,
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
                            onEdit: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('Profile image upload coming soon'),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 29),
                          _ProfileField(
                            label: 'Name',
                            controller: _nameController,
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 12),
                          _ProfileField(
                            label: 'Business mobile',
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                            readOnly: true,
                          ),
                          const SizedBox(height: 12),
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
                  12,
                  10,
                  10 + MediaQuery.of(context).padding.bottom,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(12),
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
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
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

    setState(() => _submitting = true);
    context.read<ProfileBloc>().add(
          ProfileUpdateRequested({
            'full_name': _nameController.text.trim(),
            if (email.isNotEmpty) 'email': email,
          }),
        );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.onEdit,
  });

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
            child: Center(
              child: SvgPicture.asset(
                'assets/images/grayprofile.svg',
                width: 48,
                height: 48,
                fit: BoxFit.contain,
              ),
            ),
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

// class _ProfileAvatar extends StatelessWidget {
//   const _ProfileAvatar({required this.onEdit});

//   final VoidCallback onEdit;

//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       width: 84,
//       height: 84,
//       child: Stack(
//         clipBehavior: Clip.none,
//         children: [
//           const CircleAvatar(
//             radius: 41,
//             backgroundColor: Color(0xFFF0F0F0),
//             child: Icon(
//               Icons.person,
//               color: Color(0xFF969696),
//               size: 55,
//             ),
//           ),
//           Positioned(
//             right: -1,
//             bottom: 1,
//             child: InkWell(
//               onTap: onEdit,
//               customBorder: const CircleBorder(),
//               child: Container(
//                 width: 26,
//                 height: 26,
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   shape: BoxShape.circle,
//                   border: Border.all(color: const Color(0xFFCBD3DE)),
//                 ),
//                 child: const Icon(
//                   Icons.edit,
//                   size: 15,
//                   color: Color(0xFF0A243F),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
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
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      style: GoogleFonts.inter(
        color: readOnly ? const Color(0x7F0A243F) : const Color(0xFF0A243F),
        fontSize: readOnly ? 14 : 12,
        fontWeight: readOnly ? FontWeight.w500 : FontWeight.w400,
        height: readOnly ? 1.43 : null,
      ),
      decoration: InputDecoration(
        label: Text('$label *'),
        labelStyle: GoogleFonts.inter(
          color: readOnly ? const Color(0xFF767C8F) : const Color(0xFF6E7C8F),
          fontSize: readOnly ? 11 : 10,
          fontWeight: readOnly ? FontWeight.w500 : FontWeight.w400,
          height: readOnly ? 1.27 : null,
        ),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.fromLTRB(12, 13, 12, 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: Color(0xFFD7DFE8)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: Color(0xFFD7DFE8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: Color(0xFF0866E9)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
    );
  }
}
