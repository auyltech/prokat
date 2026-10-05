import 'package:flutter_test/flutter_test.dart';
import 'package:prokat/dev/equipment_identity/identity_fixtures.dart';
import 'package:prokat/dev/equipment_identity/identity_observation.dart';
import 'package:prokat/dev/equipment_identity/ocr_observation.dart';

void main() {
  test('latin plate, model and VIN are candidates, not a verification', () {
    final candidates = extractCandidates(
      OcrFrameResult.lines(['123 ABC 06', 'XCMG XE215C', 'XCMG12345ABC67890']),
    );

    expect(confirmedPlateOf(candidates), '123ABC06');
    expect(candidates.modelTokens, contains('XE215C'));
    expect(candidates.manufacturerTokens, contains('XCMG'));
    expect(candidates.acceptedVins, contains('XCMG12345ABC67890'));
  });

  test('cyrillic homoglyphs transliterate, other cyrillic letters do not', () {
    expect(transliterateHomoglyphs('123 АВС 06'), '123 ABC 06');
    expect(transliterateHomoglyphs('Госномер'), isNot(contains('G')));
  });

  test('digit-slot O stays observed and is not confirmed', () {
    final candidates = extractCandidates(OcrFrameResult.lines(['123 ABC O6']));
    final plate = candidates.plates.single;

    expect(plate.observedCompact, '123ABCO6');
    expect(plate.possibleNormalized, '123ABC06');
    expect(plate.ambiguous, isTrue);
    expect(plate.confirmed, isFalse);

    final consensus = consensusOf([
      OcrFrameResult.lines(['123 ABC O6']),
      OcrFrameResult.lines(['123 ABC O6']),
    ]);
    expect(consensus.stable, isFalse);
    expect(
      decideVerification(VerificationInput(consensus: consensus)),
      VerificationDecision.retry,
    );
  });

  test('letter-slot 8 is not confirmed as another plate', () {
    final plate = extractCandidates(OcrFrameResult.lines(['123 8BC 06']))
        .plates
        .single;

    expect(plate.ambiguous, isTrue);
    expect(plate.confirmed, isFalse);
    expect(plate.possibleNormalized, '123BBC06');
    expect(
      confirmedPlateOf(extractCandidates(OcrFrameResult.lines(['123 8BC 06']))),
      isNull,
    );
  });

  test('unclassified plate text is kept', () {
    final plates = extractCandidates(OcrFrameResult.lines(['1234AB12'])).plates;

    expect(plates.single.format, PlateFormat.unknown);
    expect(plates.single.observedCompact, '1234AB12');
    expect(plates.single.confirmed, isFalse);
  });

  test('VIN with O stays ambiguous', () {
    final candidates = extractCandidates(
      OcrFrameResult.lines(['XCMG12345ABO67890']),
    );

    expect(candidates.acceptedVins, isEmpty);
    expect(candidates.ambiguousVins, ['XCMG12345ABO67890']);
  });

  test(
    'AUTO_PASS needs a stable document plate and the same machine-photo plate',
    () {
      final consensus = consensusOf([
        OcrFrameResult.lines(['123 ABC 06']),
        OcrFrameResult.lines(['123 ABC 06']),
      ]);

      expect(
        decideVerification(VerificationInput(consensus: consensus)),
        VerificationDecision.insufficientEvidence,
      );
      expect(
        decideVerification(
          VerificationInput(
            consensus: consensus,
            machinePhotoPlate: '124ABC06',
            modelResolved: true,
          ),
        ),
        VerificationDecision.review,
      );
      expect(
        decideVerification(
          VerificationInput(
            consensus: consensus,
            machinePhotoPlate: '123ABC06',
            modelResolved: true,
          ),
        ),
        VerificationDecision.autoPass,
      );
    },
  );

  test('fixture report measures the parser, and no fixture auto-passes', () {
    final report = evaluateFixtures();
    final byId = {for (final score in report.scores) score.fixture.id: score};

    expect(byId['clean-latin']!.exactPlate, isTrue);
    expect(byId['clean-latin']!.modelHit, isTrue);
    expect(byId['clean-latin']!.vinHit, isTrue);
    expect(byId['cyrillic-homoglyphs']!.exactPlate, isFalse);
    expect(byId['cyrillic-homoglyphs']!.normalizedPlate, isTrue);
    expect(byId['digit-slot-o']!.normalizedPlate, isTrue);
    expect(byId['digit-slot-o']!.exactPlate, isFalse);
    expect(byId['letter-slot-8']!.falseAccept, isFalse);
    expect(byId['letter-slot-8']!.normalizedPlate, isFalse);
    expect(byId['frames-disagree']!.decision, VerificationDecision.retry);
    expect(byId['single-frame']!.decision, VerificationDecision.retry);
    expect(byId['vin-contains-o']!.vinHit, isFalse);

    expect(
      report.scores.every(
        (score) => score.decision != VerificationDecision.autoPass,
      ),
      isTrue,
    );
    expect(report.count((score) => score.falseAccept), 0);
  });
}
