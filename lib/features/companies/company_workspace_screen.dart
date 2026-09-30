import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:prokat/core/widgets/optimized_network_image.dart';
import 'package:prokat/core/widgets/ui_kit/controls/buttons/app_elevated_button.dart';
import 'package:prokat/core/widgets/ui_kit/inputs/app_text_field.dart';
import 'package:prokat/features/catalog/catalog_provider.dart';
import 'package:prokat/l10n/app_localizations.dart';

import 'company_equipment_screen.dart';
import 'company_models.dart';
import 'company_service.dart';
import 'company_widgets.dart';

class CompanyWorkspaceScreen extends ConsumerStatefulWidget {
  final String companyId;
  const CompanyWorkspaceScreen({super.key, required this.companyId});
  @override
  ConsumerState<CompanyWorkspaceScreen> createState() =>
      _CompanyWorkspaceScreenState();
}

class _CompanyWorkspaceScreenState
    extends ConsumerState<CompanyWorkspaceScreen> {
  bool _uploading = false;

  Future<void> _refresh() async {
    ref.invalidate(companyContextProvider);
    ref.invalidate(companyFleetProvider(widget.companyId));
    try {
      await Future.wait([
        ref.read(companyContextProvider.future),
        ref.read(companyFleetProvider(widget.companyId).future),
      ]);
    } catch (_) {
      /* AsyncValue renders the error and offers retry. */
    }
  }

  Future<void> _editProfile(CompanyProfile profile) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => _CompanyProfileEditor(profile: profile),
      ),
    );
    if (updated == true && mounted) await _refresh();
  }

  Future<void> _editEquipment([CompanyFleetItem? item]) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            CompanyEquipmentScreen(companyId: widget.companyId, item: item),
      ),
    );
    if (updated == true && mounted) {
      ref.invalidate(companyFleetProvider(widget.companyId));
    }
  }

  Future<void> _uploadLogo() async {
    if (_uploading) return;
    setState(() => _uploading = true);
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (image == null || !mounted) return;
      await ref
          .read(companyServiceProvider)
          .uploadLogo(widget.companyId, image.path);
      ref.invalidate(companyLogoProvider(widget.companyId));
      ref.invalidate(companyContextProvider);
      if (mounted)
        companySnack(
          context,
          AppLocalizations.of(context)!.companyProfileSaved,
        );
    } catch (error) {
      if (mounted) companySnack(context, companyErrorText(context, error));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final companies = ref.watch(companyContextProvider);
    final membership = companies.valueOrNull?.memberships
        .where((item) => item.organization.id == widget.companyId)
        .firstOrNull;
    final fleet = ref.watch(companyFleetProvider(widget.companyId));
    final logo = ref.watch(companyLogoProvider(widget.companyId)).valueOrNull;
    final locale = Localizations.localeOf(context).languageCode;
    final catalog = ref.watch(catalogProvider).valueOrNull;
    return Scaffold(
      appBar: AppBar(
        title: Text(membership?.organization.name ?? l10n.companyWorkspace),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
          children: [
            if (companies.isLoading && membership == null)
              const Center(child: CircularProgressIndicator())
            else if (membership == null) ...[
              CompanyNotice(
                companies.hasError
                    ? l10n.companyLoadFailed
                    : l10n.companyAccessDenied,
              ),
              const SizedBox(height: 16),
              AppElevatedButton(title: l10n.retry, onTap: _refresh),
            ] else ...[
              CompanySection(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: SizedBox(
                            width: 80,
                            height: 80,
                            child: logo == null
                                ? ColoredBox(
                                    color: Theme.of(context).colorScheme.primary
                                        .withValues(alpha: 0.08),
                                    child: Icon(
                                      Icons.apartment_rounded,
                                      size: 40,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary,
                                    ),
                                  )
                                : Image.memory(logo, fit: BoxFit.cover),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                membership.organization.name,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${l10n.companyBin}: ${membership.organization.bin}',
                              ),
                              const SizedBox(height: 6),
                              Text(
                                membership.canManageProfile
                                    ? l10n.companyManager
                                    : l10n.companyDispatcher,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (membership.organization.description.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(membership.organization.description),
                    ],
                    if (membership.canManageProfile) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: [
                          TextButton.icon(
                            onPressed: () =>
                                _editProfile(membership.organization),
                            icon: const Icon(Icons.edit_outlined),
                            label: Text(l10n.companyEditProfile),
                          ),
                          TextButton.icon(
                            onPressed: _uploading ? null : _uploadLogo,
                            icon: _uploading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.add_a_photo_outlined),
                            label: Text(l10n.companyPhoto),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              CompanyNotice(l10n.companyPilotNotice),
              const SizedBox(height: 24),
              Text(
                l10n.companyFleet,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              AppElevatedButton(
                title: l10n.companyAddEquipment,
                onTap: () => _editEquipment(),
                prefix: const Icon(Icons.add),
              ),
              const SizedBox(height: 16),
              fleet.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, stack) => Column(
                  children: [
                    CompanyNotice(l10n.companyLoadFailed),
                    TextButton(onPressed: _refresh, child: Text(l10n.retry)),
                  ],
                ),
                data: (park) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.companyFleetCounts(
                        park.total,
                        park.visible,
                        park.busy,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (park.total == 0)
                      CompanyNotice(
                        l10n.companyFleetEmpty,
                        icon: Icons.garage_outlined,
                      ),
                    for (final group in park.groups) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 12),
                        child: Text(
                          group.id == 'EQUIPMENT'
                              ? l10n.catalogGroupEquipment
                              : l10n.catalogGroupMachinery,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      for (final category in group.categories)
                        CompanySection(
                          child: Theme(
                            data: Theme.of(context)
                                .copyWith(dividerColor: Colors.transparent),
                            child: ExpansionTile(
                              tilePadding: EdgeInsets.zero,
                              childrenPadding: EdgeInsets.zero,
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: OptimizedNetworkImage(
                                  imageUrl: catalog?.categories
                                      .where((entry) => entry.id == category.id)
                                      .firstOrNull
                                      ?.imageUrl,
                                  width: 56,
                                  height: 48,
                                  fallbackIcon:
                                      Icons.precision_manufacturing_outlined,
                                ),
                              ),
                              title: Text(category.label(locale)),
                              subtitle: Text(
                                l10n.companyFleetCounts(
                                  category.total,
                                  category.visible,
                                  category.busy,
                                ),
                              ),
                              children: [
                                for (final item in category.items)
                                  ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: OptimizedNetworkImage(
                                        imageUrl: item.imageUrl,
                                        width: 56,
                                        height: 48,
                                        fallbackIcon:
                                            Icons.local_shipping_outlined,
                                      ),
                                    ),
                                    title: Text(item.name),
                                    subtitle: Text(
                                      '${item.model}\n${companyEquipmentStatus(l10n, item)}',
                                    ),
                                    trailing: const Icon(Icons.chevron_right),
                                    onTap: () => _editEquipment(item),
                                  ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String companyEquipmentStatus(AppLocalizations l10n, CompanyFleetItem item) =>
    switch (item.status) {
      'DRAFT' => l10n.companyDraft,
      'CREATED' => l10n.companyReview,
      'REJECTED' => l10n.companyRejectedEquipment,
      'BOOKED' => l10n.companyBusy,
      'MAINTENANCE' => l10n.companyMaintenance,
      'AVAILABLE' =>
        item.isVisible ? l10n.equipmentShown : l10n.equipmentHidden,
      _ => l10n.companyStatusUnknown,
    };

class _CompanyProfileEditor extends ConsumerStatefulWidget {
  final CompanyProfile profile;
  const _CompanyProfileEditor({required this.profile});
  @override
  ConsumerState<_CompanyProfileEditor> createState() =>
      _CompanyProfileEditorState();
}

class _CompanyProfileEditorState extends ConsumerState<_CompanyProfileEditor> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.profile.name);
  late final _description = TextEditingController(
    text: widget.profile.description,
  );
  bool _saving = false;
  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !(_form.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(companyServiceProvider)
          .updateProfile(
            widget.profile.id,
            name: _name.text,
            description: _description.text,
          );
      if (mounted) {
        companySnack(
          context,
          AppLocalizations.of(context)!.companyProfileSaved,
        );
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (mounted) companySnack(context, companyErrorText(context, error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.companyEditProfile)),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            AppTextField(
              controller: _name,
              title: l10n.companyName,
              enabled: !_saving,
              maxLength: 100,
              validator: (text) => (text?.trim().length ?? 0) < 2
                  ? l10n.companyNameInvalid
                  : null,
            ),
            const SizedBox(height: 20),
            AppTextField(
              controller: _description,
              title: l10n.companyDescription,
              maxLength: 50,
              maxLines: 3,
              enabled: !_saving,
            ),
            const SizedBox(height: 24),
            AppElevatedButton(
              title: l10n.save,
              onTap: _save,
              isLoading: _saving,
            ),
          ],
        ),
      ),
    );
  }
}
