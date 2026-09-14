import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/features/equipment/equipment_status_error_message.dart';
import 'package:prokat/l10n/app_localizations_en.dart';
import 'package:prokat/l10n/app_localizations_kk.dart';
import 'package:prokat/l10n/app_localizations_ru.dart';

void main() {
  test('maps CONFLICT:EQUIPMENT:STATUS:PHOTO to the photo required locale', () {
    expect(
      equipmentStatusErrorMessage(
        l10n: AppLocalizationsRu(),
        errorCode: equipmentStatusPhotoRequiredCode,
      ),
      AppLocalizationsRu().equipmentSubmitPhotoRequired,
    );
    expect(
      equipmentStatusErrorMessage(
        l10n: AppLocalizationsEn(),
        errorCode: equipmentStatusPhotoRequiredCode,
      ),
      AppLocalizationsEn().equipmentSubmitPhotoRequired,
    );
    expect(
      equipmentStatusErrorMessage(
        l10n: AppLocalizationsKk(),
        errorCode: equipmentStatusPhotoRequiredCode,
      ),
      AppLocalizationsKk().equipmentSubmitPhotoRequired,
    );
  });

  test('falls back to failedToSubmit for unknown codes without message', () {
    expect(
      equipmentStatusErrorMessage(
        l10n: AppLocalizationsRu(),
        errorCode: 'CONFLICT:EQUIPMENT:STATUS:OTHER',
      ),
      AppLocalizationsRu().failedToSubmit,
    );
  });

  test('uses API fallback for unknown codes when provided', () {
    expect(
      equipmentStatusErrorMessage(
        l10n: AppLocalizationsRu(),
        errorCode: 'CONFLICT:EQUIPMENT:STATUS:OTHER',
        fallback: 'Custom failure',
      ),
      'Custom failure',
    );
  });
}
