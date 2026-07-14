import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:m_o_b_demand_side/core/di/injection.dart';
import 'package:m_o_b_demand_side/core/styles/app_fonts.dart';
import 'package:m_o_b_demand_side/features/profile/domain/entities/profile_entity.dart';
import 'package:m_o_b_demand_side/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:m_o_b_demand_side/shared/error_state_view.dart';
import 'package:m_o_b_demand_side/shared/pull_to_refresh.dart';
import 'package:m_o_b_demand_side/shared/widgets/app_back_icon.dart';

class MyProjectsPage extends StatelessWidget {
  const MyProjectsPage({super.key});

  static const routeName = 'MyProjects';
  static const routePath = '/profile/projects';

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ProfileBloc>()..add(ProjectsLoadRequested()),
      child: const _MyProjectsView(),
    );
  }
}

class _MyProjectsView extends StatefulWidget {
  const _MyProjectsView();

  @override
  State<_MyProjectsView> createState() => _MyProjectsViewState();
}

class _MyProjectsViewState extends State<_MyProjectsView> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _selectedCity = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _onSearchChanged() => setState(() {});

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.extentAfter > 360) return;

    final state = context.read<ProfileBloc>().state;
    if (state is! ProjectsLoaded ||
        state.isLoadingMore ||
        state.hasReachedEnd) {
      return;
    }
    context
        .read<ProfileBloc>()
        .add(ProjectsLoadRequested(page: state.projects.page + 1));
  }

  Future<void> _refresh() async {
    context.read<ProfileBloc>().add(ProjectsLoadRequested());
    await context.read<ProfileBloc>().stream.firstWhere(
          (state) => state is ProjectsLoaded || state is ProjectsError,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _ProjectColors.background,
      body: Column(
        children: [
          const _ProjectsHeader(),
          Expanded(
            child: BlocBuilder<ProfileBloc, ProfileState>(
              builder: (context, state) {
                final list = state is ProjectsLoaded
                    ? state.projects
                    : ProjectListEntity.empty;
                final projects = list.projects.where(_matchesFilters).toList();
                final cities = _citiesFrom(list.projects);

                return PullToRefresh(
                  onRefresh: _refresh,
                  child: CustomScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      if (state is! ProjectsLoaded || list.projects.isNotEmpty)
                        SliverToBoxAdapter(
                          child: _ProjectControls(
                            controller: _searchController,
                            selectedCity: _selectedCity,
                            cities: cities,
                            onCitySelected: (city) {
                              setState(() => _selectedCity = city);
                            },
                          ),
                        )
                      else
                        const SliverToBoxAdapter(child: SizedBox(height: 12)),
                      if (state is ProfileLoading || state is ProfileInitial)
                        const SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: _ProjectColors.blue,
                            ),
                          ),
                        )
                      else if (state is ProjectsError)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: ErrorStateView(
                            message: state.message,
                            onRetry: () => context
                                .read<ProfileBloc>()
                                .add(ProjectsLoadRequested()),
                          ),
                        )
                      else if (list.projects.isEmpty)
                        const SliverFillRemaining(
                          hasScrollBody: false,
                          child: _ProjectsEmptyState(),
                        )
                      else if (projects.isEmpty)
                        const SliverFillRemaining(
                          hasScrollBody: false,
                          child: _ProjectsNoSearchResults(),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                if (index < projects.length) {
                                  return Padding(
                                    padding: EdgeInsets.only(
                                      bottom:
                                          index == projects.length - 1 ? 0 : 12,
                                    ),
                                    child: _ProjectCard(
                                      project: projects[index],
                                    ),
                                  );
                                }
                                return _ProjectsPaginationFooter(
                                  isLoading: state is ProjectsLoaded &&
                                      state.isLoadingMore,
                                  errorMessage: state is ProjectsLoaded
                                      ? state.loadMoreError
                                      : null,
                                  onRetry: state is ProjectsLoaded
                                      ? () => context.read<ProfileBloc>().add(
                                            ProjectsLoadRequested(
                                              page: state.projects.page + 1,
                                            ),
                                          )
                                      : null,
                                );
                              },
                              childCount: projects.length +
                                  (state is ProjectsLoaded &&
                                          (state.isLoadingMore ||
                                              state.loadMoreError != null)
                                      ? 1
                                      : 0),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  bool _matchesFilters(ProjectEntity project) {
    final matchesCity =
        _selectedCity.isEmpty || project.city.trim() == _selectedCity;
    return matchesCity && project.matches(_searchController.text);
  }

  List<String> _citiesFrom(List<ProjectEntity> projects) {
    final cities = projects
        .map((project) => project.city.trim())
        .where((city) => city.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return cities;
  }
}

class _ProjectsPaginationFooter extends StatelessWidget {
  const _ProjectsPaginationFooter({
    required this.isLoading,
    required this.errorMessage,
    required this.onRetry,
  });

  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: _ProjectColors.blue,
            ),
          ),
        ),
      );
    }

    if (errorMessage == null || errorMessage!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Text(
            errorMessage!,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: _ProjectColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 18 / 12,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _ProjectsHeader extends StatelessWidget {
  const _ProjectsHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 56,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: context.pop,
                    icon: const AppBackIcon(),
                  ),
                ),
                Text(
                  'Projects',
                  style: GoogleFonts.inter(
                    color: _ProjectColors.navy,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    height: 22 / 15,
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    onPressed: () => _showProjectsInfoSheet(context),
                    icon: const Icon(
                      Icons.info_outline,
                      color: Color(0xFFB8BDC5),
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void _showProjectsInfoSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    builder: (_) => const _ProjectsInfoSheet(),
  );
}

class _ProjectsInfoSheet extends StatelessWidget {
  const _ProjectsInfoSheet();

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final sheetHeight = math.min(
      504.0 + media.padding.bottom,
      media.size.height - media.padding.top - 88,
    );

    return SizedBox(
      height: sheetHeight,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            top: -61,
            child: Material(
              color: Colors.white,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => Navigator.of(context).pop(),
                child: const SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(
                    Icons.close,
                    color: _ProjectColors.navy,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              child: Material(
                color: Colors.white,
                child: Column(
                  children: [
                    SizedBox(
                      height: 200,
                      width: double.infinity,
                      child: Stack(
                        children: [
                          Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [
                                  Color(0xFF441F0D),
                                  Color(0xFF893E1A),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            left: 16,
                            top: 26,
                            child: SizedBox(
                              width: 220,
                              child: Text(
                                'Organize procurement\nwith projects',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  height: 30 / 20,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            right: -20,
                            bottom: 1,
                            child: Image.asset(
                              'assets/images/myprojectssheet.png',
                              width: 195,
                              height: 119,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                        child: Column(
                          children: [
                            const _ProjectsInfoBenefitRow(
                              iconAsset: 'assets/images/easyfilterforrfq.svg',
                              label: 'Easy filter for all your RFQ and Orders',
                            ),
                            const SizedBox(height: 12),
                            const _ProjectsInfoBenefitRow(
                              iconAsset:
                                  'assets/images/dedicatedsiteaddress.svg',
                              label: 'Dedicated site address for projects',
                            ),
                            const Spacer(),
                            SafeArea(
                              top: false,
                              child: SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  style: ElevatedButton.styleFrom(
                                    elevation: 0,
                                    backgroundColor: _ProjectColors.blue,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    'Add new project',
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      height: 21 / 14,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectsInfoBenefitRow extends StatelessWidget {
  const _ProjectsInfoBenefitRow({
    required this.iconAsset,
    required this.label,
  });

  final String iconAsset;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SvgPicture.asset(
          iconAsset,
          width: 40,
          height: 40,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.inter(
              color: _ProjectColors.navy,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 18 / 12,
            ),
          ),
        ),
      ],
    );
  }
}

class _ProjectControls extends StatelessWidget {
  const _ProjectControls({
    required this.controller,
    required this.selectedCity,
    required this.cities,
    required this.onCitySelected,
  });

  final TextEditingController controller;
  final String selectedCity;
  final List<String> cities;
  final ValueChanged<String> onCitySelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: controller,
              style: GoogleFonts.inter(
                color: _ProjectColors.navy,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 20 / 14,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                prefixIcon: const Icon(
                  Icons.search,
                  color: _ProjectColors.navy,
                  size: 18,
                ),
                hintText: 'Search for project name/ city/ address',
                hintStyle: GoogleFonts.inter(
                  color: _ProjectColors.muted,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 20 / 14,
                ),
                contentPadding: const EdgeInsets.only(top: 13),
              ),
            ),
          ),
          const SizedBox(height: 10),
          PopupMenuButton<String>(
            enabled: cities.isNotEmpty,
            onSelected: onCitySelected,
            itemBuilder: (context) => [
              const PopupMenuItem(value: '', child: Text('All cities')),
              ...cities.map(
                (city) => PopupMenuItem(value: city, child: Text(city)),
              ),
            ],
            child: Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFDEDEDE)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    selectedCity.isEmpty ? 'City' : selectedCity,
                    style: GoogleFonts.inter(
                      color: _ProjectColors.navy,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      height: 18 / 12,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    color: _ProjectColors.navy,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({required this.project});

  final ProjectEntity project;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 14),
              child: Row(
                children: [
                  _ProjectAvatar(project: project),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          project.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: _ProjectColors.navy,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            height: 24 / 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Project ID: ${project.projectId}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: const Color(0xFF767C8F),
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            height: 20 / 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE4E7EC)),
                    ),
                    child: const Icon(
                      Icons.more_horiz,
                      color: _ProjectColors.navy,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE9E9E9)),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _LabeledText(
                      label: 'Delivery Address:', value: project.address),
                  if (project.sitePersonName.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    _LabeledText(
                      label: 'Site person name:',
                      value: project.sitePersonName,
                    ),
                  ],
                  if (project.phone.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    _LabeledText(label: 'Ph no:', value: project.phone),
                  ],
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE9E9E9)),
            SizedBox(
              height: 44,
              child: Row(
                children: [
                  Expanded(child: _ProjectMetric('${project.rfqCount} RFQ\'s')),
                  const VerticalDivider(width: 1, color: Color(0xFFE9E9E9)),
                  Expanded(
                    child: _ProjectMetric('${project.orderCount} Orders'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProjectAvatar extends StatelessWidget {
  const _ProjectAvatar({required this.project});

  final ProjectEntity project;

  @override
  Widget build(BuildContext context) {
    final imageUrl = project.imageUrl.trim();
    if (imageUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          imageUrl,
          width: 38,
          height: 38,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _InitialsAvatar(project: project),
        ),
      );
    }
    return _InitialsAvatar(project: project);
  }
}

class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar({required this.project});

  final ProjectEntity project;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFCEFBE3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        project.initials,
        style: GoogleFonts.inter(
          color: const Color(0xFF418A63),
          fontSize: 14,
          fontWeight: FontWeight.w700,
          height: 20 / 14,
        ),
      ),
    );
  }
}

class _LabeledText extends StatelessWidget {
  const _LabeledText({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final display = value.trim().isEmpty ? '-' : value.trim();
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label ',
            style: GoogleFonts.inter(
              color: _ProjectColors.navy,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 18 / 12,
            ),
          ),
          TextSpan(
            text: display,
            style: GoogleFonts.inter(
              color: _ProjectColors.body,
              fontSize: 12,
              fontWeight: FontWeight.w400,
              height: 18 / 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectMetric extends StatelessWidget {
  const _ProjectMetric(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        text,
        style: GoogleFonts.inter(
          color: _ProjectColors.blue,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          height: 18 / 12,
        ),
      ),
    );
  }
}

class _ProjectsEmptyState extends StatelessWidget {
  const _ProjectsEmptyState();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 72, 16, 24),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 400),
          padding: const EdgeInsets.fromLTRB(16, 48, 16, 28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/No projects.webp',
                width: 136,
                height: 136,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 16),
              Text(
                'No projects yet',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: _ProjectColors.navy,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 20 / 14,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: 252,
                child: Text(
                  'Group your procurement activity by creating a project',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: _ProjectColors.navy,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    height: 18 / 12,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              const _ProjectEmptyBenefit(
                iconAsset: 'assets/images/easyfilterforrfq.svg',
                text: 'Easy filter for all your RFQ and Orders',
              ),
              const SizedBox(height: 12),
              const _ProjectEmptyBenefit(
                iconAsset: 'assets/images/dedicatedsiteaddress.svg',
                text: 'Dedicated site address for projects',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProjectEmptyBenefit extends StatelessWidget {
  const _ProjectEmptyBenefit({
    required this.iconAsset,
    required this.text,
  });

  final String iconAsset;
  final String text;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 270,
      child: Row(
        children: [
          SvgPicture.asset(
            iconAsset,
            width: 40,
            height: 40,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                color: _ProjectColors.navy,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                height: 18 / 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectsNoSearchResults extends StatelessWidget {
  const _ProjectsNoSearchResults();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'No projects found',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: _ProjectColors.muted,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            height: 20 / 14,
          ),
        ),
      ),
    );
  }
}

abstract final class _ProjectColors {
  static const background = Color(0xFFF0F0F0);
  static const navy = Color(0xFF0A243F);
  static const muted = Color(0xFF596378);
  static const body = Color(0xFF6C7C8C);
  static const blue = Color(0xFF0360E5);
}
