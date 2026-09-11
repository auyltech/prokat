import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/features/user/widgets/city_picker_sheet.dart';

void main() {
  const cities = ['atyrau', 'almaty', 'astana'];

  test('guest and client pickers prepend all-cities', () {
    expect(
      cityPickerOptions(
        cityKeys: cities,
        service: CitySelectorService.guestcategory,
      ),
      ['', ...cities],
    );
    expect(
      cityPickerOptions(
        cityKeys: cities,
        service: CitySelectorService.clientcity,
      ),
      ['', ...cities],
    );
    expect(
      cityPickerIncludesAllCities(CitySelectorService.guestcategory),
      isTrue,
    );
  });

  test('owner application picker lists only concrete cities', () {
    expect(
      cityPickerOptions(
        cityKeys: cities,
        service: CitySelectorService.becomeowner,
      ),
      cities,
    );
    expect(
      cityPickerIncludesAllCities(CitySelectorService.becomeowner),
      isFalse,
    );
  });
}
