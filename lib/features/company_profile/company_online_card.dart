import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prokat/core/widgets/account_status_card.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';
import 'package:prokat/l10n/app_localizations.dart';

import 'company_profile_api.dart';

class CompanyOnlineCard extends ConsumerStatefulWidget {
  final String companyId;
  const CompanyOnlineCard({super.key, required this.companyId});
  @override
  ConsumerState<CompanyOnlineCard> createState() => _CompanyOnlineCardState();
}

class _CompanyOnlineCardState extends ConsumerState<CompanyOnlineCard> {
  bool busy = false;
  @override
  Widget build(BuildContext context) {
    final balance = ref
        .watch(companyBalanceProvider(widget.companyId))
        .valueOrNull;
    final online = balance?['onlineStatus'] == 'ONLINE';
    final l10n = AppLocalizations.of(context)!;
    return AccountStatusCard(
      isOnline: online,
      title: online ? 'Компания онлайн' : 'Компания офлайн',
      subtitle: online ? l10n.readyToAcceptOrders : l10n.notAcceptingOrders,
      explanation: 'Чтобы принимать заказы и откликаться на запросы, компания должна быть онлайн.',
      onChanged: busy || balance == null
          ? null
          : (value) async {
              setState(() => busy = true);
              try {
                await ref
                    .read(companyProfileApiProvider)
                    .request(
                      '/${widget.companyId}/online',
                      method: 'PATCH',
                      body: {'online': value},
                    );
                ref.invalidate(companyBalanceProvider(widget.companyId));
              } catch (e) {
                AppToast.show(
                  message: companyProfileError(e),
                  type: AppToastType.error,
                );
              } finally {
                if (mounted) setState(() => busy = false);
              }
            },
    );
  }
}
