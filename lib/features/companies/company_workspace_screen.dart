import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:prokat/core/router/app_routes.dart';
import 'package:prokat/core/widgets/optimized_network_image.dart';
import 'package:prokat/core/widgets/ui_kit/controls/buttons/app_elevated_button.dart';
import 'package:prokat/core/widgets/ui_kit/inputs/app_text_field.dart';
import 'package:prokat/features/catalog/catalog_provider.dart';
import 'package:prokat/l10n/app_localizations.dart';

import 'company_equipment_screen.dart';
import 'company_models.dart';
import 'company_service.dart';
import 'company_category_screen.dart';
import 'company_widgets.dart';

class CompanyWorkspaceScreen extends ConsumerStatefulWidget {
  final String companyId;
  final bool showCatalogLink;
  const CompanyWorkspaceScreen({
    super.key,
    required this.companyId,
    this.showCatalogLink = false,
  });
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

  Future<void> _uploadLogo({bool additional = false}) async {
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
      if (additional) {
        await ref
            .read(companyServiceProvider)
            .addPhoto(widget.companyId, image.path);
      } else {
        await ref
            .read(companyServiceProvider)
            .uploadLogo(widget.companyId, image.path);
      }
      ref.invalidate(companyPhotosProvider(widget.companyId));
      ref.invalidate(companyLogoProvider(widget.companyId));
      ref.invalidate(companyContextProvider);
      if (mounted) {
        companySnack(
          context,
          AppLocalizations.of(context)!.companyProfileSaved,
        );
      }
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
    final photos =
        ref.watch(companyPhotosProvider(widget.companyId)).valueOrNull ?? [];
    final locale = Localizations.localeOf(context).languageCode;
    final catalog = ref.watch(catalogProvider).valueOrNull;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          membership?.organization.name ?? l10n.companyWorkspace,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        actions: [
          if (widget.showCatalogLink)
            TextButton(
              onPressed: () => context.go(AppRoutes.searchList),
              child: Text(l10n.companyCatalog),
            ),
        ],
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
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: SizedBox(
                        height: 200,
                        width: double.infinity,
                        child: logo == null && photos.isEmpty
                            ? ColoredBox(
                                color: Theme.of(context).colorScheme.primary
                                    .withValues(alpha: 0.08),
                                child: const Icon(
                                  LucideIcons.building2,
                                  size: 64,
                                ),
                              )
                            : PageView(
                                children: [
                                  if (logo != null)
                                    Image.memory(logo, fit: BoxFit.cover),
                                  for (final photo in photos)
                                    Image.memory(
                                      photo.bytes,
                                      fit: BoxFit.cover,
                                    ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      membership.organization.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 6),
                    Text('${l10n.companyBin}: ${membership.organization.bin}'),
                    if (photos.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          '${photos.length + (logo == null ? 0 : 1)} фото',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    if (membership.canManageProfile && photos.isNotEmpty)
                      Wrap(
                        children: [
                          for (final photo in photos)
                            IconButton(
                              tooltip: l10n.delete,
                              onPressed: () async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text(l10n.delete),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: Text(l10n.cancel),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: Text(l10n.delete),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirmed != true) return;
                                try {
                                  await ref
                                      .read(companyServiceProvider)
                                      .removePhoto(widget.companyId, photo.id);
                                  ref.invalidate(
                                    companyPhotosProvider(widget.companyId),
                                  );
                                } catch (error) {
                                  if (context.mounted) {
                                    companySnack(
                                      context,
                                      companyErrorText(context, error),
                                    );
                                  }
                                }
                              },
                              icon: SizedBox(
                                width: 48,
                                height: 48,
                                child: Stack(
                                  children: [
                                    Image.memory(
                                      photo.bytes,
                                      width: 48,
                                      height: 48,
                                      fit: BoxFit.cover,
                                    ),
                                    const Align(
                                      alignment: Alignment.bottomRight,
                                      child: Icon(LucideIcons.trash2, size: 18),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    if (membership.organization.description.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(membership.organization.description),
                    ],
                    Material(
                      type: MaterialType.transparency,
                      child: SwitchListTile.adaptive(
                        title: Text(l10n.companyListing),
                        subtitle: Text(
                          membership.organization.catalogVisible
                              ? l10n.equipmentShown
                              : l10n.equipmentHidden,
                        ),
                        value: membership.organization.catalogVisible,
                        onChanged: (visible) async {
                          try {
                            await ref
                                .read(companyServiceProvider)
                                .visibility(widget.companyId, visible);
                            ref.invalidate(
                              companyBillingProvider(widget.companyId),
                            );
                            await _refresh();
                          } catch (e) {
                            if (context.mounted) {
                              companySnack(
                                context,
                                companyErrorText(context, e),
                              );
                            }
                          }
                        },
                      ),
                    ),
                    if (membership.canManageProfile) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: [
                          TextButton.icon(
                            onPressed: () =>
                                _editProfile(membership.organization),
                            icon: const Icon(LucideIcons.pencil),
                            label: Text(l10n.companyEditProfile),
                          ),
                          TextButton.icon(
                            onPressed: _uploading
                                ? null
                                : () => _uploadLogo(additional: true),
                            icon: const Icon(LucideIcons.imagePlus),
                            label: Text(l10n.companyAddPhoto),
                          ),
                          TextButton.icon(
                            onPressed: _uploading ? null : () => _uploadLogo(),
                            icon: _uploading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(LucideIcons.camera),
                            label: Text(l10n.companyPhoto),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.companyFleet,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              AppElevatedButton(
                title: l10n.companyAddEquipment,
                onTap: () => _editEquipment(),
                prefix: const Icon(LucideIcons.plus),
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
                    if (park.total == 0)
                      CompanyNotice(
                        l10n.companyFleetEmpty,
                        icon: LucideIcons.truck400,
                      ),
                    for (final group in park.groups.where(
                      (group) => group.categories.isNotEmpty,
                    )) ...[
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
                          child: InkWell(
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => CompanyCategoryScreen(
                                  companyId: widget.companyId,
                                  categoryId: category.id,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: OptimizedNetworkImage(
                                    imageUrl: catalog?.categories
                                        .where(
                                          (entry) => entry.id == category.id,
                                        )
                                        .firstOrNull
                                        ?.imageUrl,
                                    width: 56,
                                    height: 48,
                                    fallbackIcon: LucideIcons.wrench,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        category.label(locale),
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        l10n.companyAvailability(
                                          category.total,
                                          category.busy,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(LucideIcons.chevronRight),
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
              maxLength: 2000,
              maxLines: 6,
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
