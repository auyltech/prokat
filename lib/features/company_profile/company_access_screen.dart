import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:prokat/core/widgets/prokat_list_tile.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';
import 'package:prokat/features/catalog/catalog_provider.dart';

import 'company_profile_api.dart';
import 'company_profile_screen.dart';
import 'company_workspace.dart';

import 'package:prokat/core/widgets/moderation_status_card.dart';

Map? activeCompanyMembership(Map<String, dynamic>? data) {
  for (final member in data?['memberships'] as List? ?? []) {
    if (member['company']['status'] == 'APPROVED') return member as Map;
  }
  return null;
}

class CompanyEntryTile extends ConsumerWidget {
  const CompanyEntryTile({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(companyAccessProvider).valueOrNull;
    final invited = (data?['invitations'] as List?)?.isNotEmpty ?? false;
    final membership = activeCompanyMembership(data);
    final approved = membership != null;
    final tile = ProkatListTile(
      icon: LucideIcons.building2,
      iconColor: approved ? Colors.white : const Color(0xff702d45),
      iconBgColor: approved
          ? Colors.white.withValues(alpha: .12)
          : const Color(0xff702d45).withValues(alpha: .15),
      title: approved
          ? 'Перейти в профиль компании'
          : 'Открыть профиль компании',
      subtitle: approved
          ? membership['company']['name'] as String
          : invited
          ? 'Вас приглашают в компанию'
          : 'Разместите услуги вашей компании здесь',
      statusLine: invited ? 'Новое приглашение' : null,
      statusIcon: invited ? LucideIcons.circleAlert : null,
      statusColor: Colors.amber.shade700,
      onTap: () async {
        if (membership != null) {
          await context.push('/company/${membership['companyId']}');
        } else {
          await context.push('/company-profile');
        }
      },
    );
    final theme = Theme.of(context);
    return approved
        ? _CompanyGlow(
            child: Theme(
              data: theme.copyWith(
                textTheme: theme.textTheme.apply(
                  bodyColor: Colors.white,
                  displayColor: Colors.white,
                ),
                colorScheme: theme.colorScheme.copyWith(
                  onSurface: Colors.white,
                  onSurfaceVariant: Colors.white70,
                ),
              ),
              child: tile,
            ),
          )
        : tile;
  }
}

/// Paints only a small background. The content stays cached, without blur or
/// offscreen effects; route TickerMode and reduced-motion settings stop it.
class _CompanyGlow extends StatefulWidget {
  final Widget child;
  const _CompanyGlow({required this.child});
  @override
  State<_CompanyGlow> createState() => _CompanyGlowState();
}

class _CompanyGlowState extends State<_CompanyGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController animation = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 25),
  );
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      animation.stop();
    } else if (!animation.isAnimating) {
      animation.repeat();
    }
  }

  @override
  void dispose() {
    animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: CustomPaint(
        painter: _CompanyGlowPainter(animation),
        child: Padding(padding: const EdgeInsets.all(16), child: widget.child),
      ),
    ),
  );
}

class _CompanyGlowPainter extends CustomPainter {
  final Animation<double> animation;
  _CompanyGlowPainter(this.animation) : super(repaint: animation);
  @override
  void paint(Canvas canvas, Size size) {
    final value = (1 + math.sin(animation.value * math.pi * 2)) / 2;
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment(-1 + value, -1),
        end: Alignment(1, 1 - value),
        colors: const [Color(0xFF381727), Color(0xFF762E47), Color(0xFF472035)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, paint);
    for (var i = 0; i < 7; i++) {
      final x = size.width * ((i * .137 + value * .04) % 1);
      final y =
          size.height *
          (.2 + .6 * (1 + math.sin(i * 2.1 + value * math.pi)) / 2);
      canvas.drawCircle(
        Offset(x, y),
        i.isEven ? 1.5 : 1,
        Paint()..color = const Color(0xFFFFD3DC).withValues(alpha: .20),
      );
    }
  }

  @override
  bool shouldRepaint(_CompanyGlowPainter oldDelegate) =>
      oldDelegate.animation != animation;
}

class CompanyAccessScreen extends ConsumerStatefulWidget {
  const CompanyAccessScreen({super.key});
  @override
  ConsumerState<CompanyAccessScreen> createState() => _CompanyAccessState();
}

class _CompanyAccessState extends ConsumerState<CompanyAccessScreen> {
  final form = GlobalKey<FormState>();
  final first = TextEditingController(),
      last = TextEditingController(),
      name = TextEditingController(),
      bin = TextEditingController();
  final invitationCodes = <String, TextEditingController>{};
  String? city;
  bool saving = false;
  String? seededRejectedCompany;
  @override
  void dispose() {
    for (final c in [first, last, name, bin, ...invitationCodes.values]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> perform(Future<void> Function() action) async {
    if (saving) return;
    setState(() => saving = true);
    try {
      await action();
      ref.invalidate(companyAccessProvider);
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

  Widget field(TextEditingController c, String title, {bool numeric = false}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: AppTextField(
          controller: c,
          title: title,
          isRequired: true,
          enabled: !saving,
          maxLength: numeric ? 12 : 100,
          keyboardType: numeric ? TextInputType.number : TextInputType.text,
          inputFormatters: numeric
              ? [FilteringTextInputFormatter.digitsOnly]
              : null,
          validator: (v) => numeric
              ? (RegExp(r'^\d{12}$').hasMatch(v ?? '')
                    ? null
                    : 'Введите 12 цифр БИН')
              : (v?.trim().isEmpty ?? true)
              ? 'Заполните поле'
              : identical(c, name) && v!.trim().length < 2
              ? 'Введите название не короче двух символов'
              : null,
        ),
      );
  @override
  Widget build(BuildContext context) {
    final data = ref.watch(companyAccessProvider),
        catalog = ref.watch(catalogProvider).valueOrNull;
    final active = activeCompanyMembership(data.valueOrNull);
    if (active != null) {
      return CompanyWorkspace(companyId: active['companyId']);
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Профиль компании')),
      body: data.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(companyProfileError(e)),
            const SizedBox(height: 20),
            AppElevatedButton(
              title: 'Повторить',
              onTap: () => ref.invalidate(companyAccessProvider),
            ),
          ],
        ),
        data: (data) {
          final allMemberships = List<dynamic>.from(data['memberships'] as List)
            ..sort(
              (a, b) => (b['company']['updatedAt'] as String).compareTo(
                a['company']['updatedAt'] as String,
              ),
            );
          final memberships = allMemberships.take(1).toList(),
              invitations = data['invitations'] as List;
          final rejected =
              memberships.isNotEmpty &&
              memberships.first['company']['status'] == 'REJECTED';
          if (rejected &&
              seededRejectedCompany != memberships.first['companyId']) {
            final m = memberships.first;
            first.text = m['firstName'] ?? '';
            last.text = m['lastName'] ?? '';
            name.text = m['company']['name'] ?? '';
            bin.text = m['company']['bin'] ?? '';
            city = m['company']['city'];
            seededRejectedCompany = m['companyId'];
          }
          final pending = memberships.any(
            (m) => m['company']['status'] == 'PENDING_REVIEW',
          );
          final approved = memberships
              .where((m) => m['company']['status'] == 'APPROVED')
              .toList();
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(companyAccessProvider);
              await ref.read(companyAccessProvider.future);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
              children: [
                for (final m in approved)
                  AppCard(
                    child: ListTile(
                      title: Text(m['company']['name']),
                      subtitle: Text(
                        m['role'] == 'OWNER' ? 'Руководитель' : 'Диспетчер',
                      ),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => CompanyProfileScreen(
                            companyId: m['companyId'],
                            companyName: m['company']['name'],
                          ),
                        ),
                      ),
                    ),
                  ),
                for (final m in memberships.where(
                  (m) => m['company']['status'] != 'APPROVED',
                ))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: ModerationStatusCard(
                      title: m['company']['status'] == 'PENDING_REVIEW'
                          ? 'Заявка на проверке'
                          : m['company']['status'] == 'SUSPENDED'
                          ? 'Профиль компании приостановлен'
                          : 'Заявка отклонена',
                      subtitle: m['company']['status'] == 'REJECTED'
                          ? 'Ознакомьтесь с комментарием администратора и исправьте замечания.'
                          : m['company']['name'],
                      detail: m['company']['adminComment'],
                      icon: m['company']['status'] == 'PENDING_REVIEW'
                          ? Icons.hourglass_top_rounded
                          : Icons.error_outline_rounded,
                      color: m['company']['status'] == 'PENDING_REVIEW'
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.error,
                    ),
                  ),
                for (final i in invitations)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 32),
                    child: AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Вас приглашают в компанию «${i['company']['name']}»',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 20),
                          AppTextField(
                            controller: invitationCodes.putIfAbsent(
                              i['id'] as String,
                              TextEditingController.new,
                            ),
                            title: 'Код приглашения',
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            maxLength: 6,
                          ),
                          const SizedBox(height: 20),
                          AppElevatedButton(
                            title: 'Присоединиться',
                            isLoading: saving,
                            onTap: saving
                                ? null
                                : () => perform(() async {
                                    final code = invitationCodes[i['id']]!;
                                    if (!RegExp(r'^\d{6}$')
                                        .hasMatch(code.text)) {
                                      throw Exception(
                                        'Введите шестизначный код',
                                      );
                                    }
                                    await ref
                                        .read(companyProfileApiProvider)
                                        .request(
                                          '/invitations/${i['id']}/accept',
                                          method: 'POST',
                                          body: {'code': code.text},
                                        );
                                    code.clear();
                                  }),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (!pending &&
                    approved.isEmpty &&
                    invitations.isEmpty &&
                    !memberships.any(
                      (m) => m['company']['status'] == 'SUSPENDED',
                    ))
                  Form(
                    key: form,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Заполните короткую форму. Администратор проверит данные и откроет профиль компании.',
                        ),
                        const SizedBox(height: 24),
                        field(first, 'Имя'),
                        field(last, 'Фамилия'),
                        field(name, 'Название компании'),
                        field(bin, 'БИН', numeric: true),
                        FormField<String>(
                          validator: (_) =>
                              city == null ? 'Выберите город' : null,
                          builder: (f) => AppDropdownField<String>(
                            title: 'Город',
                            sheetTitle: 'Выберите город',
                            isRequired: true,
                            value: city,
                            errorText: f.errorText,
                            options: [
                              for (final c in catalog?.cities ?? [])
                                if (c.isVisible)
                                  DropdownOption(
                                    label: c.label(
                                      Localizations.localeOf(context)
                                          .languageCode,
                                    ),
                                    value: c.slug,
                                  ),
                            ],
                            onChanged: (v) {
                              setState(() => city = v);
                              f.didChange(v);
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                        AppElevatedButton(
                          title: rejected
                              ? 'Повторно отправить заявку'
                              : 'Отправить заявку',
                          isLoading: saving,
                          onTap: saving
                              ? null
                              : () async {
                                  if (!(form.currentState?.validate() ??
                                      false)) {
                                    return;
                                  }
                                  await perform(() async {
                                    await ref
                                        .read(companyProfileApiProvider)
                                        .request(
                                          '/applications',
                                          method: 'POST',
                                          body: {
                                            'firstName': first.text.trim(),
                                            'lastName': last.text.trim(),
                                            'name': name.text.trim(),
                                            'bin': bin.text,
                                            'city': city,
                                          },
                                        );
                                  });
                                },
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
