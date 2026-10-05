import 'package:prokat/dev/equipment_identity/identity_observation.dart';
import 'package:prokat/dev/equipment_identity/ocr_observation.dart';

/// Synthetic OCR strings. These are not photographs and do not measure ML Kit.
class IdentityFixture {
  final String id;
  final String note;
  final List<List<String>> frames;
  final String? plate;
  final String? manufacturer;
  final String? model;
  final String? vin;

  const IdentityFixture({
    required this.id,
    required this.note,
    required this.frames,
    this.plate,
    this.manufacturer,
    this.model,
    this.vin,
  });
}

class FixtureScore {
  final IdentityFixture fixture;
  final bool exactPlate;
  final bool normalizedPlate;
  final bool falseAccept;
  final bool manufacturerHit;
  final bool modelHit;
  final bool vinHit;
  final bool confidentPlate;
  final VerificationDecision decision;

  const FixtureScore({
    required this.fixture,
    required this.exactPlate,
    required this.normalizedPlate,
    required this.falseAccept,
    required this.manufacturerHit,
    required this.modelHit,
    required this.vinHit,
    required this.confidentPlate,
    required this.decision,
  });
}

class FixtureReport {
  final List<FixtureScore> scores;

  const FixtureReport(this.scores);

  int get total => scores.length;

  int count(bool Function(FixtureScore score) test) =>
      scores.where(test).length;
}

const identityFixtures = <IdentityFixture>[
  IdentityFixture(
    id: 'clean-latin',
    note: 'Чистая строка, формат 3+3+2, два одинаковых кадра.',
    frames: [
      ['123 ABC 06', 'XCMG XE215C', 'XCMG12345ABC67890'],
      ['123 ABC 06', 'XCMG XE215C', 'XCMG12345ABC67890'],
    ],
    plate: '123ABC06',
    manufacturer: 'XCMG',
    model: 'XE215C',
    vin: 'XCMG12345ABC67890',
  ),
  IdentityFixture(
    id: 'cyrillic-homoglyphs',
    note: 'Кириллические двойники. Кандидат остаётся ambiguous, это не подтверждённый номер.',
    frames: [
      ['123 АВС 06', 'XCMG XE215C'],
      ['123 АВС 06', 'XCMG XE215C'],
    ],
    plate: '123ABC06',
    manufacturer: 'XCMG',
    model: 'XE215C',
  ),
  IdentityFixture(
    id: 'digit-slot-o',
    note: 'O в цифровой позиции остаётся observed. Возможный номер не подтверждается.',
    frames: [
      ['123 ABC O6'],
      ['123 ABC O6'],
    ],
    plate: '123ABC06',
  ),
  IdentityFixture(
    id: 'letter-slot-8',
    note: '8 в буквенной позиции даёт другой возможный номер и не подтверждается.',
    frames: [
      ['123 8BC 06'],
      ['123 8BC 06'],
    ],
    plate: '123ABC06',
  ),
  IdentityFixture(
    id: 'frames-disagree',
    note: 'Два кадра дали разные номера.',
    frames: [
      ['123 ABC 06'],
      ['124 ABC 06'],
    ],
    plate: '123ABC06',
  ),
  IdentityFixture(
    id: 'vin-contains-o',
    note: 'В VIN есть O. Это неоднозначность, не автоматическая замена на 0.',
    frames: [
      ['XCMG12345ABO67890'],
      ['XCMG12345ABO67890'],
    ],
    vin: 'XCMG12345ABC67890',
  ),
  IdentityFixture(
    id: 'single-frame',
    note: 'Один чистый кадр не считается стабильным.',
    frames: [
      ['123 ABC 06', 'CAT 320D'],
    ],
    plate: '123ABC06',
    manufacturer: 'CAT',
    model: '320D',
  ),
];

FixtureReport evaluateFixtures([
  List<IdentityFixture> fixtures = identityFixtures,
]) {
  return FixtureReport([for (final fixture in fixtures) scoreFixture(fixture)]);
}

FixtureScore scoreFixture(IdentityFixture fixture) {
  final observations = [
    for (final frame in fixture.frames) OcrFrameResult.lines(frame),
  ];
  final consensus = consensusOf(observations);
  final first = extractCandidates(observations.first);
  final accepted = confirmedPlateOf(first);
  final expectedPlate = fixture.plate;

  final exact = expectedPlate != null && accepted == expectedPlate;
  final normalized =
      expectedPlate != null &&
      first.plates.any(
        (plate) =>
            plate.possibleNormalized == expectedPlate ||
            plate.observedCompact == expectedPlate,
      );
  final falseAccept =
      accepted != null && expectedPlate != null && accepted != expectedPlate;

  return FixtureScore(
    fixture: fixture,
    exactPlate: exact,
    normalizedPlate: normalized,
    falseAccept: falseAccept,
    manufacturerHit:
        fixture.manufacturer != null &&
        first.manufacturerTokens.contains(fixture.manufacturer),
    modelHit:
        fixture.model != null && first.modelTokens.contains(fixture.model),
    vinHit: fixture.vin != null && first.acceptedVins.contains(fixture.vin),
    confidentPlate: accepted != null,
    decision: decideVerification(VerificationInput(consensus: consensus)),
  );
}
