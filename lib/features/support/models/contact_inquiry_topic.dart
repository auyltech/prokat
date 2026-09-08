import 'package:prokat/l10n/app_localizations.dart';

enum ContactInquiryTopic {
  general,
  support,
  bugReport,
  featureRequest,
  sales,
  partnership,
  billing,
  callMe,
  accountDeletion,
  accountRecovery,
  accountIssue,
  other,
}

extension ContactInquiryTopicX on ContactInquiryTopic {
  /// Backend `ContactInquiryTopic` enum (`FEATURE_REQUEST`, not `featureRequest`).
  String get apiValue {
    return name
        .replaceAllMapped(RegExp(r'[A-Z]'), (m) => '_${m.group(0)}')
        .toUpperCase();
  }

  String localizedLabel(AppLocalizations l10n) {
    return switch (this) {
      ContactInquiryTopic.general => l10n.inquiryTopicGeneral,
      ContactInquiryTopic.support => l10n.inquiryTopicSupport,
      ContactInquiryTopic.bugReport => l10n.inquiryTopicBugReport,
      ContactInquiryTopic.featureRequest => l10n.inquiryTopicFeatureRequest,
      ContactInquiryTopic.sales => l10n.inquiryTopicSales,
      ContactInquiryTopic.partnership => l10n.inquiryTopicPartnership,
      ContactInquiryTopic.billing => l10n.inquiryTopicBilling,
      ContactInquiryTopic.callMe => l10n.inquiryTopicCallMe,
      ContactInquiryTopic.accountDeletion => l10n.inquiryTopicAccountDeletion,
      ContactInquiryTopic.accountRecovery => l10n.inquiryTopicAccountRecovery,
      ContactInquiryTopic.accountIssue => l10n.inquiryTopicAccountIssue,
      ContactInquiryTopic.other => l10n.inquiryTopicOther,
    };
  }
}
