import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';
import 'package:prokat/features/catalog/catalog_provider.dart';

import 'company_profile_api.dart';

import 'package:prokat/core/widgets/profile_read_only_row.dart';
import 'package:prokat/core/utils/kz_phone_mask.dart';

class CompanyMemberScreen extends ConsumerWidget {
  final String companyId, companyName;
  const CompanyMemberScreen({
    super.key,
    required this.companyId,
    required this.companyName,
  });
  Future<void> edit(
    BuildContext context,
    WidgetRef ref, {
    Map<String, dynamic>? member,
    Map<String, dynamic>? invitation,
  }) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CompanyPersonForm(
          companyId: companyId,
          member: member,
          invitation: invitation,
        ),
      ),
    );
    if (context.mounted && saved == true) {
      ref.invalidate(companyMembersProvider(companyId));
    }
  }

  Future<void> remove(BuildContext context, WidgetRef ref, String path) async {
    final invitation = path.startsWith('invitations/');
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          invitation ? 'Отменить приглашение?' : 'Удалить участника?',
        ),
        content: Text(
          invitation
              ? 'По этому коду больше нельзя будет вступить в компанию.'
              : 'Доступ к компании будет закрыт. Личный аккаунт останется.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (yes != true) return;
    try {
      await ref
          .read(companyProfileApiProvider)
          .request('/$companyId/$path', method: 'DELETE');
      ref.invalidate(companyMembersProvider(companyId));
    } catch (e) {
      if (context.mounted) {
        AppToast.show(
          message: companyProfileError(e),
          type: AppToastType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: const Text('Ваш профиль')),
    body: ref
        .watch(companyMembersProvider(companyId))
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(companyProfileError(e)),
              TextButton(
                onPressed: () =>
                    ref.invalidate(companyMembersProvider(companyId)),
                child: const Text('Повторить'),
              ),
            ],
          ),
          data: (data) {
            final self = data['self'] as Map<String, dynamic>,
                owner = self['role'] == 'OWNER';
            Widget value(String title, String value, {String? helper}) =>
                Padding(
                  padding: const EdgeInsets.only(bottom: AppDimens.s12$md),
                  child: ProfileReadOnlyRow(
                    label: title,
                    value: value,
                    helperText: helper,
                  ),
                );
            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(companyMembersProvider(companyId));
                await ref.read(companyMembersProvider(companyId).future);
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
                children: [
                  Text(
                    companyName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 24),
                  if (self['profileStatus'] == 'CHANGES_PENDING_REVIEW')
                    const AppCard(child: Text('Изменения данных на проверке')),
                  if (self['profileStatus'] == 'CHANGES_REJECTED')
                    AppCard(
                      child: Text(
                        'Изменения отклонены: ${self['adminComment'] ?? ''}',
                      ),
                    ),
                  value('Имя', self['firstName']),
                  value('Фамилия', self['lastName']),
                  value(
                    'Номер телефона',
                    maskedKzPhone(self['user']['phoneNumber'] ?? ''),
                    helper: 'Номер закреплён за аккаунтом и не меняется.',
                  ),
                  value('Город', _cityName(context, ref, self['city'])),
                  value('Должность', owner ? 'Руководитель' : 'Диспетчер'),
                  if (owner) ...[
                    const SizedBox(height: AppDimens.s32$xxl),
                    AppElevatedButton(
                      title: 'Изменить данные',
                      onTap: self['profileStatus'] == 'CHANGES_PENDING_REVIEW'
                          ? null
                          : () => edit(context, ref, member: self),
                    ),
                    const SizedBox(height: 20),
                    AppElevatedButton(
                      title: 'Добавить участника',
                      onTap: () => edit(context, ref),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Участники',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    for (final m in (data['members'] as List).where(
                      (m) => m['role'] != 'OWNER',
                    ))
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Диспетчер · Активен'),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${m['firstName']} ${m['lastName']}\n${m['user']['phoneNumber'] ?? ''}',
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(LucideIcons.pencil),
                                  onPressed: () => edit(
                                    context,
                                    ref,
                                    member: Map<String, dynamic>.from(m),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(LucideIcons.trash2),
                                  onPressed: () => remove(
                                    context,
                                    ref,
                                    'members/${m['id']}',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    for (final i in data['invitations'] as List)
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (i['attempts'] as int? ?? 0) >= 5
                                  ? 'Диспетчер · Код заблокирован'
                                  : 'Диспетчер · Ожидаем вступления (${i['code']})',
                            ),
                            if ((i['attempts'] as int? ?? 0) >= 5)
                              const Text(
                                'Отмените приглашение и добавьте участника заново.',
                              ),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${i['firstName']} ${i['lastName']}\n${i['phoneNumber']}',
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Изменить имя участника',
                                  icon: const Icon(LucideIcons.pencil),
                                  onPressed: () => edit(
                                    context,
                                    ref,
                                    invitation: Map<String, dynamic>.from(i),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(LucideIcons.trash2),
                                  onPressed: () => remove(
                                    context,
                                    ref,
                                    'invitations/${i['id']}',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                  ],
                ],
              ),
            );
          },
        ),
  );
}

class CompanyPersonForm extends ConsumerStatefulWidget {
  final String companyId;
  final Map<String, dynamic>? member;
  final Map<String, dynamic>? invitation;
  const CompanyPersonForm({
    super.key,
    required this.companyId,
    this.member,
    this.invitation,
  });
  @override
  ConsumerState<CompanyPersonForm> createState() => _PersonState();
}

class _PersonState extends ConsumerState<CompanyPersonForm> {
  final form = GlobalKey<FormState>();
  final first = TextEditingController(),
      last = TextEditingController(),
      phone = TextEditingController();
  bool saving = false;
  @override
  void initState() {
    super.initState();
    first.text = (widget.member ?? widget.invitation)?['firstName'] ?? '';
    last.text = (widget.member ?? widget.invitation)?['lastName'] ?? '';
    if (widget.member?['profileStatus'] == 'CHANGES_REJECTED') {
      for (final change in (widget.member?['pendingChanges'] as List? ?? [])) {
        if (change['field'] == 'firstName') first.text = change['to'];
        if (change['field'] == 'lastName') last.text = change['to'];
      }
    }
  }

  @override
  void dispose() {
    first.dispose();
    last.dispose();
    phone.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (saving || !(form.currentState?.validate() ?? false)) return;
    if (widget.member?['role'] == 'OWNER') {
      final confirmed = await showModalBottomSheet<bool>(
        context: context,
        builder: (context) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Данные будут переданы на модерацию',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: AppElevatedButton(
                        title: 'Нет',
                        onTap: () => Navigator.pop(context, false),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppElevatedButton(
                        title: 'Да',
                        onTap: () => Navigator.pop(context, true),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
      if (confirmed != true || !mounted) return;
    }
    setState(() => saving = true);
    try {
      final editing = widget.member != null || widget.invitation != null;
      final path = widget.member != null
          ? 'members/${widget.member!['id']}'
          : widget.invitation != null
          ? 'invitations/${widget.invitation!['id']}'
          : 'invitations';
      await ref
          .read(companyProfileApiProvider)
          .request(
            '/${widget.companyId}/$path',
            method: editing ? 'PATCH' : 'POST',
            body: {
              'firstName': first.text.trim(),
              'lastName': last.text.trim(),
              if (!editing) 'phoneNumber': phone.text.trim(),
            },
          );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        AppToast.show(
          message: companyProfileError(e),
          type: AppToastType.error,
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.member == null && widget.invitation == null
            ? 'Добавить участника'
            : 'Изменить данные',
      ),
    ),
    body: Form(
      key: form,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final p in [(first, 'Имя'), (last, 'Фамилия')])
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: AppTextField(
                controller: p.$1,
                title: p.$2,
                isRequired: true,
                enabled: !saving,
                maxLength: 100,
                validator: (v) =>
                    v?.trim().isNotEmpty == true ? null : 'Заполните поле',
              ),
            ),
          if (widget.member == null && widget.invitation == null) ...[
            AppTextField(
              controller: phone,
              title: 'Номер телефона',
              hint: '+77001234567',
              keyboardType: TextInputType.phone,
              maxLength: 12,
              validator: (v) => RegExp(r'^\+7\d{10}$').hasMatch(v ?? '')
                  ? null
                  : 'Введите номер +7 и 10 цифр',
            ),
            const SizedBox(height: 20),
            const Text('Должность: Диспетчер'),
            const SizedBox(height: 24),
          ],
          AppElevatedButton(
            title: widget.member == null && widget.invitation == null
                ? 'Добавить'
                : 'Сохранить',
            isLoading: saving,
            onTap: saving ? null : save,
          ),
        ],
      ),
    ),
  );
}

String _cityName(BuildContext context, WidgetRef ref, String slug) {
  for (final city in ref.watch(catalogProvider).valueOrNull?.cities ?? []) {
    if (city.slug == slug) {
      return city.label(Localizations.localeOf(context).languageCode);
    }
  }
  return slug;
}
