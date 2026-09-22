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

  test('demand option parses optional image and description', () {
    final option = DemandOption.fromJson({
      'id': 'option-1',
      'name': 'Excavator',
      'description': 'Digs',
      'imageUrl': 'https://example.com/a.png',
    });
    expect(option.description, 'Digs');
    expect(option.imageUrl, 'https://example.com/a.png');
  });

  test('option intent hasAny requires at least one flag', () {
    expect(
      const DemandOptionIntent(provide: false, rent: false).hasAny,
      isFalse,
    );
    expect(const DemandOptionIntent(provide: true, rent: false).hasAny, isTrue);
    expect(const DemandOptionIntent(provide: false, rent: true).hasAny, isTrue);
  });

  test('demand other option parses optional description', () {
    final other = DemandOtherOption.fromJson({
      'name': 'Other',
      'description': 'Tell us more',
      'imageUrl': 'https://example.com/o.png',
    });
    expect(other.description, 'Tell us more');
    expect(other.imageUrl, 'https://example.com/o.png');
  });
}
