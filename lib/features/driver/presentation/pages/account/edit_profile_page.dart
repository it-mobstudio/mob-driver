import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mob_driver/core/l10n/tr.dart';
import 'package:mob_driver/core/theme/app_colors.dart';
import 'package:mob_driver/core/widgets/list_skeleton.dart';
import 'package:mob_driver/core/widgets/top_snack_bar.dart';
import 'package:mob_driver/features/driver/presentation/bloc/driver_session_cubit.dart';
import 'package:mob_driver/features/driver/presentation/widgets/onboarding/personal_details_form.dart';

/// Editing the details given at sign-up.
class EditProfilePage extends StatelessWidget {
  const EditProfilePage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          backgroundColor: AppColors.card,
          elevation: 0,
          foregroundColor: AppColors.ink,
          title: Text(tr('Edit details'),
              style:
                  const TextStyle(fontWeight: FontWeight.w800, fontSize: 19)),
        ),
        body: BlocBuilder<DriverSessionCubit, DriverSessionState>(
          buildWhen: (a, b) => (a.profile == null) != (b.profile == null),
          builder: (context, state) {
            final profile = state.profile;
            if (profile == null) {
              return const ListSkeleton(itemCount: 4, itemHeight: 60);
            }
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
                children: [
                  PersonalDetailsForm(
                    profile: profile,
                    submitLabel: tr('Save changes'),
                    onSaved: () {
                      TopSnackBar.show(context,
                          message: tr('Details saved.'),
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
