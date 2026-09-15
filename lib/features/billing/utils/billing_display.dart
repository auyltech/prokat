import 'package:prokat/core/utils/format.dart';
import 'package:prokat/features/billing/models/pricing_tier_model.dart';
import 'package:prokat/l10n/app_localizations.dart';

const _minutesPerDay = 1440;
const _trialMinutesThreshold = 60;

bool isTrialPackage(PricingTierModel tier) =>
    tier.minutes < _trialMinutesThreshold;

String packageTitle(PricingTierModel tier, AppLocalizations l10n) {
  if (isTrialPackage(tier)) return l10n.trialPackage;
  if (tier.minutes > 0 && tier.minutes % _minutesPerDay == 0) {
    return l10n.durationDays(tier.minutes ~/ _minutesPerDay);
  }
  return '${formatPriceNumber(tier.minutes)} ${l10n.minutesUnit}';
}

String packageMinutesLabel(PricingTierModel tier, AppLocalizations l10n) {
  return '${formatPriceNumber(tier.minutes)} ${l10n.minutesUnit}';
}

List<PricingTierModel> sortedTopUpPackages(List<PricingTierModel> tiers) {
  final copy = [...tiers];
  copy.sort((a, b) {
    final aTrial = isTrialPackage(a);
    final bTrial = isTrialPackage(b);
    if (aTrial != bTrial) return aTrial ? 1 : -1;
    return a.minutes.compareTo(b.minutes);
  });
  return copy;
}

int estimateOnlineCount(int onlineEquipment) =>
    onlineEquipment < 1 ? 1 : onlineEquipment;
