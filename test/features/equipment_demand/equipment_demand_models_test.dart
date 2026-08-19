import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/features/equipment_demand/equipment_demand_models.dart';

void main() {
  test('demand config parsing is fail closed', () {
    expect(DemandConfig.fromJson(null).shouldShow, isFalse);
    expect(DemandConfig.fromJson({'enabled': true}).shouldShow, isFalse);
    expect(
      DemandConfig.fromJson({
        'enabled': true,
        'campaignId': 'campaign-1',
        'hasResponded': false,
      }).shouldShow,
      isTrue,
    );
  });

  test('markResponded hides only the matching campaign', () {
    const config = DemandConfig(
      enabled: true,
      campaignId: 'campaign-1',
      hasResponded: false,
    );

    expect(config.markResponded('other').shouldShow, isTrue);
    expect(config.markResponded('campaign-1').shouldShow, isFalse);
    expect(config.markResponded('campaign-1').campaignId, 'campaign-1');
  });

  test('demand option rejects malformed backend data', () {
    expect(
      () => DemandOption.fromJson({'id': 'option-1'}),
      throwsFormatException,
    );
  });
}
