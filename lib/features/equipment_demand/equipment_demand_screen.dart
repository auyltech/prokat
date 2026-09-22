import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';
import 'package:prokat/features/equipment_demand/widgets/demand_city_multi_sheet.dart';
import 'package:prokat/features/equipment_demand/widgets/demand_intent_card.dart';
import 'package:prokat/features/equipment_demand/widgets/demand_other_intent_card.dart';
import 'package:prokat/features/equipment_demand/widgets/demand_survey_app_bar.dart';
import 'package:prokat/l10n/app_localizations.dart';
import 'package:uuid/uuid.dart';

import 'equipment_demand_models.dart';
import 'equipment_demand_provider.dart';

class EquipmentDemandScreen extends ConsumerStatefulWidget {
  final String campaignId;

  const EquipmentDemandScreen({super.key, required this.campaignId});

  @override
  ConsumerState<EquipmentDemandScreen> createState() =>
      _EquipmentDemandScreenState();
}

class _EquipmentDemandScreenState extends ConsumerState<EquipmentDemandScreen> {
  /// Matches [AppElevatedButton] horizontal inset of «Готово».
  static const double _edgeInset = AppDimens.s20$lg;
  static const double _pageGap = AppDimens.s12$md;
  static const double _dotSize = 16;
  static const double _dotPaddingH = 3;

  PageController? _pageController;
  double _appliedViewportFraction = 0;
  final _dotsScrollController = ScrollController();
  final _otherProvideController = TextEditingController();
  final _otherRentController = TextEditingController();
  final _submissionId = const Uuid().v4();
  final Map<String, DemandOptionIntent> _intents = {};
  final Set<String> _selectedCityIds = {};

  bool _submitting = false;
  bool _guardHandled = false;
  String? _error;
  int _pageIndex = 0;
  int _dotsPageCount = 0;

  double get _dotStride => _dotSize + _dotPaddingH * 2;

  @override
  void initState() {
    super.initState();
    _otherProvideController.addListener(_onOtherTextChanged);
    _otherRentController.addListener(_onOtherTextChanged);
  }

  @override
  void dispose() {
    _pageController?.removeListener(_onPageScroll);
    _pageController?.dispose();
    _dotsScrollController.dispose();
    _otherProvideController
      ..removeListener(_onOtherTextChanged)
      ..dispose();
    _otherRentController
      ..removeListener(_onOtherTextChanged)
      ..dispose();
    super.dispose();
  }

  void _onOtherTextChanged() {
    if (mounted) setState(() {});
  }

  void _unfocusInputs() {
    final focus = FocusManager.instance.primaryFocus;
    if (focus != null && focus.hasFocus) {
      focus.unfocus();
    }
  }

  void _onPageScroll() {
    final page = _pageController?.page;
    if (page == null || _dotsPageCount <= 1) return;
    _scrollDotsTo(page);
  }

  /// Keep the active (or in-between) dot near the center of the dots viewport.
  void _scrollDotsTo(double page) {
    if (!_dotsScrollController.hasClients) return;
    final position = _dotsScrollController.position;
    final maxScroll = position.maxScrollExtent;
    if (maxScroll <= 0) return;

    final viewport = position.viewportDimension;
    final targetCenter =
        page.clamp(0, _dotsPageCount - 1) * _dotStride + _dotStride / 2;
    final target = (targetCenter - viewport / 2).clamp(0.0, maxScroll);
    if ((position.pixels - target).abs() < 0.5) return;
    _dotsScrollController.jumpTo(target);
  }

  void _scheduleDotsSync([double? page]) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _scrollDotsTo(page ?? _pageIndex.toDouble());
    });
  }

  /// So first/last card outer edges align with «Готово» when centered via padEnds.
  static double _viewportFractionFor(double width) {
    const sidePad = _edgeInset - _pageGap / 2;
    if (width <= 0 || sidePad <= 0) return 0.86;
    return (1 - (2 * sidePad / width)).clamp(0.75, 0.95);
  }

  PageController _syncPageController(double width) {
    final fraction = _viewportFractionFor(width);
    final current = _pageController;
    if (current != null &&
        (fraction - _appliedViewportFraction).abs() < 0.0005) {
      return current;
    }

    final initialPage = current != null && current.hasClients
        ? (current.page?.round() ?? _pageIndex)
        : _pageIndex;
    current?.removeListener(_onPageScroll);
    final next = PageController(
      viewportFraction: fraction,
      initialPage: initialPage,
    );
    next.addListener(_onPageScroll);
    _appliedViewportFraction = fraction;
    _pageController = next;
    if (current != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => current.dispose());
    }
    _scheduleDotsSync(initialPage.toDouble());
    return next;
  }

  DemandOptionIntent _intentFor(String optionId) {
    return _intents[optionId] ??
        const DemandOptionIntent(provide: false, rent: false);
  }

  bool get _hasMeaningfulIntent {
    if (_intents.values.any((intent) => intent.hasAny)) return true;
    if (_otherProvideController.text.trim().isNotEmpty) return true;
    if (_otherRentController.text.trim().isNotEmpty) return true;
    return false;
  }

  bool _isPageCompleted(DemandForm data, int index) {
    if (index < data.options.length) {
      return _intentFor(data.options[index].id).hasAny;
    }
    return _otherProvideController.text.trim().isNotEmpty ||
        _otherRentController.text.trim().isNotEmpty;
  }

  Future<void> _rejectAccess(AppLocalizations l10n) async {
    if (_guardHandled) return;
    _guardHandled = true;
    AppToast.show(
      message: l10n.demandSurveyLoadError,
      type: AppToastType.error,
    );
    if (mounted && context.canPop()) {
      context.pop();
    }
  }

  Future<void> _onDone(DemandForm data) async {
    if (!_hasMeaningfulIntent || _submitting) return;
    final cityIds = await DemandCityMultiSheet.show(
      context: context,
      initialSelectedIds: _selectedCityIds,
    );
    if (!mounted || cityIds == null || cityIds.isEmpty) return;
    setState(() {
      _selectedCityIds
        ..clear()
        ..addAll(cityIds);
    });
    await _submit(data, cityIds);
  }

  Future<void> _submit(DemandForm data, List<String> cityIds) async {
    final l10n = AppLocalizations.of(context)!;
    final selections = _intents.entries
        .where((entry) => entry.value.hasAny)
        .map(
          (entry) => <String, Object>{
            'optionId': entry.key,
            'provide': entry.value.provide,
            'rent': entry.value.rent,
          },
        )
        .toList(growable: false);

    final otherProvide = _otherProvideController.text.trim();
    final otherRent = _otherRentController.text.trim();

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await ref
          .read(equipmentDemandServiceProvider)
          .submit(
            clientSubmissionId: _submissionId,
            campaignId: widget.campaignId,
            selections: selections,
            cityIds: cityIds,
            otherProvideText: otherProvide.isEmpty ? null : otherProvide,
            otherRentText: otherRent.isEmpty ? null : otherRent,
          );
      ref.read(demandConfigProvider.notifier).markResponded(widget.campaignId);
      if (!mounted) return;
      AppToast.show(
        message: l10n.demandSurveyThankYou,
        type: AppToastType.success,
      );
      context.pop();
    } on DemandApiException catch (error) {
      if (error.code == 'DEMAND_RESPONSE_ALREADY_EXISTS') {
        ref
            .read(demandConfigProvider.notifier)
            .markResponded(widget.campaignId);
        if (mounted) context.pop();
        return;
      }
      if (error.code == 'DEMAND_CAMPAIGN_INACTIVE') {
        await ref.read(demandConfigProvider.notifier).refresh();
        if (mounted) context.pop();
        return;
      }
      if (mounted) setState(() => _error = l10n.demandSurveySubmitError);
    } catch (_) {
      if (mounted) setState(() => _error = l10n.demandSurveySubmitError);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final configAsync = ref.watch(demandConfigProvider);

    return Scaffold(
      appBar: DemandSurveyAppBar(title: l10n.demandSurveyCardTitle),
      body: configAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            unawaited(_rejectAccess(l10n));
          });
          return const SizedBox.shrink();
        },
        data: (config) {
          final allowed =
              config.enabled &&
              config.campaignId == widget.campaignId &&
              !config.hasResponded;
          if (!allowed) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              unawaited(_rejectAccess(l10n));
            });
            return const SizedBox.shrink();
          }

          final form = ref.watch(demandFormProvider(widget.campaignId));
          return form.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(AppDimens.s24$xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.demandSurveyLoadError,
                      style: AppFonts.body14(context),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppDimens.s12$md),
                    AppIconButton(
                      icon: Icons.refresh,
                      onTap: () =>
                          ref.invalidate(demandFormProvider(widget.campaignId)),
                      variant: AppIconButtonVariant.filled,
                      tone: AppIconButtonTone.primary,
                    ),
                  ],
                ),
              ),
            ),
            data: (data) => _buildForm(context, l10n, data),
          );
        },
      ),
    );
  }

  Widget _buildForm(
    BuildContext context,
    AppLocalizations l10n,
    DemandForm data,
  ) {
    final colors = context.colors;
    final pageCount = data.options.length + (data.allowOther ? 1 : 0);
    if (pageCount == 0) {
      return Center(
        child: Text(
          l10n.demandSurveyLoadError,
          style: AppFonts.body14(context),
        ),
      );
    }

    if (_dotsPageCount != pageCount) {
      _dotsPageCount = pageCount;
      _scheduleDotsSync();
    }

    return GestureDetector(
      onTap: _unfocusInputs,
      behavior: HitTestBehavior.translucent,
      child: Column(
        children: [
          Expanded(
            child: pageCount == 1
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(
                      _edgeInset,
                      AppDimens.s16$base,
                      _edgeInset,
                      AppDimens.s08$sm,
                    ),
                    child: _cardAt(context, l10n, data, 0),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final controller = _syncPageController(
                        constraints.maxWidth,
                      );
                      return NotificationListener<ScrollNotification>(
                        onNotification: (notification) {
                          if (notification is ScrollStartNotification &&
                              notification.dragDetails != null) {
                            _unfocusInputs();
                          }
                          return false;
                        },
                        child: PageView.builder(
                          controller: controller,
                          padEnds: true,
                          itemCount: pageCount,
                          onPageChanged: (index) {
                            _unfocusInputs();
                            setState(() => _pageIndex = index);
                            _scheduleDotsSync(index.toDouble());
                          },
                          itemBuilder: (context, index) =>
                              _cardAt(context, l10n, data, index),
                        ),
                      );
                    },
                  ),
          ),
          if (pageCount > 1)
            Padding(
              padding: const EdgeInsets.only(
                top: AppDimens.s12$md,
                bottom: AppDimens.s20$lg,
              ),
              child: SizedBox(
                height: _dotSize,
                width: double.infinity,
                child: Builder(
                  builder: (context) {
                    final viewportWidth =
                        MediaQuery.sizeOf(context).width - 2 * _edgeInset;
                    final contentWidth = pageCount * _dotStride;
                    final dots = Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(pageCount, (index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: _dotPaddingH,
                          ),
                          child: _PageDot(
                            size: _dotSize,
                            active: index == _pageIndex,
                            completed: _isPageCompleted(data, index),
                            activeFill: colors.text.main,
                            inactiveFill: colors.text.secondary.withValues(
                              alpha: 0.22,
                            ),
                            activeCheck:
                                ThemeData.estimateBrightnessForColor(
                                      colors.text.main,
                                    ) ==
                                    Brightness.dark
                                ? const Color(0xFFC8E6C9)
                                : AppColors.success,
                            inactiveCheck: colors.text.success,
                          ),
                        );
                      }),
                    );

                    if (contentWidth <= viewportWidth) {
                      return Center(child: dots);
                    }

                    return SingleChildScrollView(
                      controller: _dotsScrollController,
                      scrollDirection: Axis.horizontal,
                      physics: const ClampingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: _edgeInset,
                      ),
                      child: dots,
                    );
                  },
                ),
              ),
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              _edgeInset,
              AppDimens.s08$sm,
              _edgeInset,
              AppDimens.s20$lg + MediaQuery.paddingOf(context).bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_error != null) ...[
                  Text(
                    _error!,
                    style: AppFonts.caption(context).copyWith(
                      color: colors.text.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: AppDimens.s12$md),
                ],
                AppElevatedButton(
                  title: l10n.demandSurveyDone,
                  onTap: (!_hasMeaningfulIntent || _submitting)
                      ? null
                      : () => _onDone(data),
                  isLoading: _submitting,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardAt(
    BuildContext context,
    AppLocalizations l10n,
    DemandForm data,
    int index,
  ) {
    final Widget card;
    if (index < data.options.length) {
      final option = data.options[index];
      card = DemandIntentCard(
        option: option,
        intent: _intentFor(option.id),
        onChanged: (next) => setState(() {
          if (next.hasAny) {
            _intents[option.id] = next;
          } else {
            _intents.remove(option.id);
          }
        }),
      );
    } else {
      card = DemandOtherIntentCard(
        title: data.other?.name ?? l10n.demandSurveyOtherOption,
        description: data.other?.description,
        imageUrl: data.other?.imageUrl,
        provideController: _otherProvideController,
        rentController: _otherRentController,
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        _pageGap / 2,
        AppDimens.s16$base,
        _pageGap / 2,
        AppDimens.s08$sm,
      ),
      child: card,
    );
  }
}

class _PageDot extends StatelessWidget {
  final double size;
  final bool active;
  final bool completed;
  final Color activeFill;
  final Color inactiveFill;
  final Color activeCheck;
  final Color inactiveCheck;

  const _PageDot({
    required this.size,
    required this.active,
    required this.completed,
    required this.activeFill,
    required this.inactiveFill,
    required this.activeCheck,
    required this.inactiveCheck,
  });

  @override
  Widget build(BuildContext context) {
    final fill = active ? activeFill : inactiveFill;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: size,
      height: size,
      decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: completed
          ? Icon(
              Icons.check_rounded,
              size: size,
              color: active ? activeCheck : inactiveCheck,
            )
          : null,
    );
  }
}
