import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:prokat/core/config/env.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';

import 'company_stat_grid.dart';

import 'package:prokat/features/catalog/catalog_provider.dart';
import 'package:prokat/features/equipment/models/equipment_image_model.dart';
import 'package:prokat/features/equipment/models/price_entry_model.dart';
import 'package:prokat/features/equipment/state/owner_equipment_editor_state.dart';
import 'package:prokat/features/equipment/utils/vacuum_tariffs.dart';
import 'package:prokat/features/equipment/widgets/owner/equipment_editor_section.dart';
import 'package:prokat/features/equipment/widgets/owner/owner_equipment_image_header.dart';
import 'package:prokat/features/equipment/widgets/owner/owner_tariff_card.dart';
import 'package:prokat/features/equipment_share/equipment_share_renderer.dart';
import 'package:prokat/features/user/widgets/city_picker_sheet.dart';
import 'package:prokat/l10n/app_localizations.dart';
import 'package:prokat/features/notifications/widgets/notification_badge.dart';

import 'company_profile_api.dart';

import 'package:prokat/features/user/widgets/profile_image_picker.dart';
import 'package:prokat/features/appstartup/app_mode_storage.dart';

class CompanyInformationScreen extends ConsumerStatefulWidget {
  final String companyId;
  final Map<String, dynamic> dashboard;
  const CompanyInformationScreen({
    super.key,
    required this.companyId,
    required this.dashboard,
  });
  @override
  ConsumerState<CompanyInformationScreen> createState() =>
      _CompanyInformationScreenState();
}

class _CompanyInformationScreenState
    extends ConsumerState<CompanyInformationScreen> {
  late final TextEditingController name, description;
  late String city;
  late List<TariffDraft> tariffs;
  bool expanded = true, dataExpanded = false, busy = false, queued = false;
  String? savedFingerprint;
  late Map<String, dynamic> dashboard;
  @override
  void initState() {
    super.initState();
    dashboard = widget.dashboard;
    final company = dashboard['company'] as Map;
    name = TextEditingController(
      text: (company['advertisingName'] as String).isEmpty
          ? company['name']
          : company['advertisingName'],
    );
    description = TextEditingController(text: company['description']);
    city = company['city'];
    tariffs = (company['tariffs'] as List)
        .map(
          (t) => TariffDraft.fromEntry(
            PriceEntry.fromJson(Map<String, dynamic>.from(t)),
          ),
        )
        .toList();
    savedFingerprint = fingerprint;
  }

  @override
  void dispose() {
    name.dispose();
    description.dispose();
    super.dispose();
  }

  bool get canEdit =>
      ref
          .read(companyMembersProvider(widget.companyId))
          .valueOrNull?['self']?['role'] ==
      'OWNER';
  String get fingerprint => jsonEncode({
    'city': city,
    'name': name.text.trim(),
    'description': description.text.trim(),
    'tariffs': [
      for (final t in tariffs.where((t) => t.isSavable))
        {
          'label': t.persistedLabel(),
          'price': t.price,
          'rate': t.priceRate.value,
          'starting': t.isStartingFrom,
        },
    ],
  });
  Future<void> save() async {
    if (!mounted || !canEdit) return;
    if (name.text.trim().isEmpty ||
        city.isEmpty ||
        tariffs.any((t) => t.id != null && !t.isSavable)) {
      AppToast.show(
        message: AppLocalizations.of(context)!.pleaseCompleteRequiredFields,
        type: AppToastType.error,
      );
      return;
    }
    if (busy) {
      queued = true;
      return;
    }
    final submittedFingerprint = fingerprint;
    if (submittedFingerprint == savedFingerprint) return;
    setState(() => busy = true);
    try {
      final result = await ref
          .read(companyProfileApiProvider)
          .request(
            '/${widget.companyId}/info',
            method: 'PATCH',
            body: {
              'city': city,
              'advertisingName': name.text.trim(),
              'description': description.text.trim(),
              'tariffs': [
                for (final t in tariffs.where((t) => t.isSavable))
                  {
                    'label': t.persistedLabel(),
                    'price': t.price,
                    'priceRate': t.priceRate.value,
                    'isStartingFrom': t.isStartingFrom,
                  },
              ],
            },
          );
      if (!mounted) return;
      savedFingerprint = submittedFingerprint;
      if (mounted) {
        setState(() => dashboard = Map<String, dynamic>.from(result));
      }
      if (mounted) {
        final saved = ((result['company'] as Map)['tariffs'] as List)
            .map(
              (t) => TariffDraft.fromEntry(
                PriceEntry.fromJson(Map<String, dynamic>.from(t)),
              ),
            )
            .toList();
        setState(
          () => tariffs = adoptServerTariffs(server: saved, local: tariffs),
        );
      }
      if (mounted) ref.invalidate(companyDashboardProvider(widget.companyId));
    } catch (e) {
      queued = false;
      if (mounted) {
        AppToast.show(
          message: companyProfileError(e),
          type: AppToastType.error,
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
      if (queued && mounted) {
        queued = false;
        await save();
      }
    }
  }

  Future<bool> photo(
    String suffix, {
    String method = 'PATCH',
    File? file,
  }) async {
    if (!mounted || busy) return false;
    setState(() => busy = true);
    try {
      final api = ref.read(companyProfileApiProvider);
      if (file != null) {
        await api.dio.post(
          '/company-profile/${widget.companyId}/images',
          data: FormData.fromMap({
            'equipmentImage': await MultipartFile.fromFile(file.path),
          }),
        );
      } else {
        await api.request('/${widget.companyId}/images$suffix', method: method);
      }
      final result = await api.request('/${widget.companyId}/dashboard');
      if (mounted) {
        setState(() => dashboard = Map<String, dynamic>.from(result));
      }
      if (mounted) ref.invalidate(companyDashboardProvider(widget.companyId));
      return true;
    } catch (e) {
      if (mounted) {
        AppToast.show(
          message: companyProfileError(e),
          type: AppToastType.error,
        );
      }
      return false;
    } finally {
      if (mounted) setState(() => busy = false);
      if (queued && mounted) {
        queued = false;
        await save();
      }
    }
  }

  Future<void> deleteAvatar() async {
    final result = await ref
        .read(companyProfileApiProvider)
        .request('/${widget.companyId}/avatar', method: 'DELETE');
    if (!mounted) return;
    setState(() => dashboard = Map<String, dynamic>.from(result));
    ref.invalidate(companyDashboardProvider(widget.companyId));
  }

  Future<void> uploadAvatar(File file) async {
    if (!mounted) return;
    final api = ref.read(companyProfileApiProvider);
    final response = await api.dio.post(
      '/company-profile/${widget.companyId}/avatar',
      data: FormData.fromMap({
        'equipmentImage': await MultipartFile.fromFile(file.path),
      }),
    );
    if (!mounted) return;
    setState(
      () => dashboard = Map<String, dynamic>.from(response.data['data']),
    );
    ref.invalidate(companyDashboardProvider(widget.companyId));
  }

  @override
  Widget build(BuildContext context) {
    final company = dashboard['company'] as Map;
    final l10n = AppLocalizations.of(context)!;
    final editable =
        ref
            .watch(companyMembersProvider(widget.companyId))
            .valueOrNull?['self']?['role'] ==
        'OWNER';
    return Scaffold(
      appBar: ProkatAppBar(
        title: const Text('Информация компании'),
        onBack: () => Navigator.of(context).pop(),
        actions: const [NotificationBadge()],
      ),
      body: ListView(
        children: [
          OwnerEquipmentImageHeader(
            equipmentId: widget.companyId,
            images: (company['images'] as List)
                .map(
                  (i) => EquipmentImage.fromJson(Map<String, dynamic>.from(i)),
                )
                .toList(),
            legacyImageUrl: null,
            emptyText: "Фотографии компании",
            canEditImages: editable && !busy,
            onUpload: (file) => photo('', file: file),
            onDelete: (id) => photo('/$id', method: 'DELETE'),
            onPrimary: (id) => photo('/$id/primary'),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                EquipmentEditorSection(
                  title: 'Для клиентов',
                  indicator: name.text.trim().isEmpty
                      ? BlockIndicator.empty
                      : BlockIndicator.valid,
                  expanded: expanded,
                  onToggleExpanded: () {
                    setState(() => expanded = !expanded);
                    if (!expanded) unawaited(save());
                  },
                  saveLabel: l10n.save,
                  showSave: editable,
                  saveEnabled: editable && !busy,
                  saveLoading: busy,
                  onSave: save,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Аватарка компании',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          SizedBox(
                            width: 64,
                            height: 64,
                            child: AbsorbPointer(
                              absorbing: !editable,
                              child: ProfileImagePicker(
                                mode: AppMode.ownerMode,
                                radius: 32,
                                showEditIcon: false,
                                initialImageUrl: company['avatarUrl'],
                                onUpload: uploadAvatar,
                                onDelete: deleteAvatar,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  company['name'],
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.star,
                                      size: 14,
                                      color: Colors.amber,
                                    ),
                                    const SizedBox(width: 2),
                                    Flexible(
                                      child: Text(
                                        '${(company['ratingAverage'] as num).toStringAsFixed(1)} • ${l10n.ordersCount(company['orderCount'] ?? 0)}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Divider(height: 1),
                      const SizedBox(height: 24),
                      AppDropdownField<String>(
                        title: 'Город работы',
                        value: city,
                        selectedLabel: catalogCityLabelOf(ref, context, city),
                        hint: l10n.selectCity,
                        sheetTitle: l10n.selectCity,
                        enabled: editable,
                        openCustomSheet: () => CityPickerSheet.show(
                          context: context,
                          service: CitySelectorService.createequipment,
                          highlightedCity: city,
                        ),
                        onChanged: (value) {
                          setState(() => city = value);
                          unawaited(save());
                        },
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        title: 'Рекламное название',
                        controller: name,
                        maxLength: 50,
                        isRequired: true,
                        readOnly: !editable,
                        onFocusLost: save,
                      ),
                      const SizedBox(height: 16),
                      AppTextArea(
                        title: l10n.shortDescription,
                        controller: description,
                        maxLength: 200,
                        minLines: 3,
                        maxLines: 4,
                        readOnly: !editable,
                        onFocusLost: save,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.tariffs,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      for (var i = 0; i < tariffs.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: OwnerTariffCard(
                            draft: tariffs[i],
                            canEdit: editable && !busy,
                            onChanged: (value) =>
                                setState(() => tariffs[i] = value),
                            onCommit: save,
                            onDelete: () {
                              setState(() => tariffs.removeAt(i));
                              unawaited(save());
                            },
                          ),
                        ),
                      if (editable && tariffs.length < 20)
                        AppLabelButton(
                          title: l10n.addTariff,
                          prefix: const Icon(Icons.add),
                          onTap: () =>
                              setState(() => tariffs.add(TariffDraft.custom())),
                        ),
                    ],
                  ),
                ),
                EquipmentEditorSection(
                  title: 'Данные компании',
                  indicator: BlockIndicator.valid,
                  expanded: dataExpanded,
                  onToggleExpanded: () =>
                      setState(() => dataExpanded = !dataExpanded),
                  saveLabel: l10n.save,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),
                      for (final group in [
                        ('Техника', 'machinery'),
                        ('Оборудование', 'equipment'),
                      ]) ...[
                        Text(
                          group.$1,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 12),
                        CompanyStatGrid(
                          items: [
                            for (final field in [
                              ('Категорий', 'categories'),
                              ('Всего', 'total'),
                              ('Показывается', 'showing'),
                              ('Свободно', 'available'),
                            ])
                              (
                                label: field.$1,
                                value: '${dashboard[group.$2][field.$2]}',
                              ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],
                      Text(
                        'Диспетчеры',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 12),
                      CompanyStatGrid(
                        items: [
                          (
                            label: 'Онлайн',
                            value: '${dashboard['dispatchers']['online']}',
                          ),
                          (
                            label: 'Офлайн',
                            value: '${dashboard['dispatchers']['offline']}',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                AppCard(
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          company['isVisible'] == true
                              ? 'Объявление показывается'
                              : 'Объявление скрыто',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      Switch(
                        value: company['isVisible'] == true,
                        onChanged: editable && !busy
                            ? (value) async {
                                setState(() => busy = true);
                                try {
                                  await ref
                                      .read(companyProfileApiProvider)
                                      .request(
                                        '/${widget.companyId}/visibility',
                                        method: 'PATCH',
                                        body: {'isVisible': value},
                                      );
                                  if (mounted) {
                                    setState(
                                      () => company['isVisible'] = value,
                                    );
                                  }
                                  if (mounted) {
                                    ref.invalidate(
                                      companyDashboardProvider(
                                        widget.companyId,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  AppToast.show(
                                    message: companyProfileError(e),
                                    type: AppToastType.error,
                                  );
                                } finally {
                                  if (mounted) setState(() => busy = false);
                                  if (queued && mounted) {
                                    queued = false;
                                    await save();
                                  }
                                }
                              }
                            : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> shareCompany(
  BuildContext context,
  WidgetRef ref,
  Map<String, dynamic> dashboard,
) async {
  File? file;
  ui.Image? image;
  try {
    final company = dashboard['company'] as Map;
    if (company['isVisible'] != true) {
      await AppAlertBottomSheet.show(
        context,
        title: 'Поделиться компанией',
        description: 'Сначала включите показ объявления компании.',
        primaryLabel: AppLocalizations.of(context)!.close,
      );
      return;
    }
    final name = (company['advertisingName'] as String).isEmpty
        ? company['name'] as String
        : company['advertisingName'] as String;
    image = await EquipmentShareRenderer.renderCard(
      context: context,
      ref: ref,
      name: name,
      description: company['description'],
      coverUrl: (company['images'] as List).firstOrNull?['imageUrl'],
      priceLine: dashboard['machinery'] != null
          ? 'Техника: ${dashboard['machinery']['total']} · Оборудование: ${dashboard['equipment']['total']}'
          : company['name'],
      cta: company['name'],
    );
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null || !context.mounted) return;
    final directory = await getTemporaryDirectory();
    file = File(
      '${directory.path}/company-share-${company['id']}-${DateTime.now().microsecondsSinceEpoch}.png',
    );
    await file.writeAsBytes(bytes.buffer.asUint8List());
    if (!context.mounted) return;
    final box = context.findRenderObject();
    if (!context.mounted) return;
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'image/png')],
        text: '$name\n${Env.shareBaseUrl}/c/${company['id']}',
        subject: name,
        sharePositionOrigin:
            box is RenderBox && box.hasSize && !box.size.isEmpty
            ? box.localToGlobal(Offset.zero) & box.size
            : null,
      ),
    );
  } catch (e, stack) {
    debugPrint('Company share failed: $e\n$stack');
    if (context.mounted) {
      AppToast.show(
        message: AppLocalizations.of(context)!.somethingWentWrongTryAgain,
        type: AppToastType.error,
      );
    }
  } finally {
    image?.dispose();
    if (file != null && await file.exists()) await file.delete();
  }
}
