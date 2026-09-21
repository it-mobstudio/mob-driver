import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/bloc/driver_session_cubit.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/driver_ui.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/personal_details_form.dart';
import 'package:m_o_b_demand_side/features/driver/presentation/widgets/trip_actions_ui.dart';
import 'package:m_o_b_demand_side/shared/widgets/top_snack_bar.dart';

/// Editing the details given at sign-up.
class EditProfilePage extends StatelessWidget {
  const EditProfilePage({super.key});

  static const routeName = 'DriverEditProfile';
  static const routePath = DriverRoutes.editProfile;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: DriverColors.surface,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: DriverColors.ink,
          title: const Text('Edit details',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 19)),
        ),
        body: BlocBuilder<DriverSessionCubit, DriverSessionState>(
          buildWhen: (a, b) => (a.profile == null) != (b.profile == null),
          builder: (context, state) {
            final profile = state.profile;
            if (profile == null) {
              return const DriverListSkeleton(itemCount: 4, itemHeight: 60);
            }
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
                children: [
                  PersonalDetailsForm(
                    profile: profile,
                    submitLabel: 'Save changes',
                    onSaved: () {
                      TopSnackBar.show(context,
                          message: 'Details saved.',
                          type: TopSnackBarType.success);
                      if (context.canPop()) context.pop();
                    },
                  ),
                ],
              ),
            );
          },
        ),
      );
}
