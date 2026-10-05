import 'package:prokat/dev/equipment_identity/ocr_observation.dart';

/// Turns OCR observations into identity candidates.
///
/// A lookalike rewrite is kept as [PlateCandidate.possibleNormalized] and
/// stays ambiguous. It is never a confirmed plate.

const _digitLookalikes = {'O': '0', 'I': '1', 'S': '5', 'B': '8'};
const _letterLookalikes = {'0': 'O', '1': 'I', '5': 'S', '8': 'B'};

const _cyrillicHomoglyphs = {
  'А': 'A',
  'а': 'A',
  'В': 'B',
  'в': 'B',
  'Е': 'E',
  'е': 'E',
  'К': 'K',
  'к': 'K',
  'М': 'M',
  'м': 'M',
  'Н': 'H',
  'н': 'H',
  'О': 'O',
  'о': 'O',
  'Р': 'P',
  'р': 'P',
  'С': 'C',
  'с': 'C',
  'Т': 'T',
  'т': 'T',
  'Х': 'X',
  'х': 'X',
};

final _kz2012 = RegExp(r'^\d{3}[A-Z]{3}\d{2}$');
final _modelToken = RegExp(
  r'^(?:[A-Z]{1,8}\d{2,4}[A-Z0-9]{0,6}|\d{2,4}[A-Z]{1,4})$',
);
final _brandToken = RegExp(r'^[A-Z]{2,12}$');
final _vinClean = RegExp(r'^[A-HJ-NPR-Z0-9]{17}$');

enum PlateFormat { unknown, kz2012Private }

enum VerificationDecision { insufficientEvidence, autoPass, retry, review }

class PlateCandidate {
  final String observedCompact;
  final String? possibleNormalized;
  final PlateFormat format;
  final bool ambiguous;
  final List<String> warnings;

  const PlateCandidate({
    required this.observedCompact,
    required this.possibleNormalized,
    required this.format,
    required this.ambiguous,
    required this.warnings,
  });

  bool get confirmed =>
      !ambiguous &&
      warnings.isEmpty &&
      format == PlateFormat.kz2012Private &&
      possibleNormalized != null &&
      possibleNormalized == observedCompact;
}

class IdentityCandidates {
  final List<PlateCandidate> plates;
  final bool plateConflict;
  final List<String> acceptedVins;
  final List<String> ambiguousVins;
  final List<String> manufacturerTokens;
  final List<String> modelTokens;

  const IdentityCandidates({
    required this.plates,
    required this.plateConflict,
    required this.acceptedVins,
    required this.ambiguousVins,
    required this.manufacturerTokens,
    required this.modelTokens,
  });

  List<String> get warnings => [for (final plate in plates) ...plate.warnings];
}

class FrameConsensus {
  final int frames;
  final String? plate;
  final bool stable;
  final bool ambiguous;

  const FrameConsensus({
    required this.frames,
    required this.plate,
    required this.stable,
    required this.ambiguous,
  });
}

class VerificationInput {
  final FrameConsensus consensus;
  final String? machinePhotoPlate;
  final bool modelResolved;
  final bool duplicateRisk;
  final bool sourceConflict;

  const VerificationInput({
    required this.consensus,
    this.machinePhotoPlate,
    this.modelResolved = false,
    this.duplicateRisk = false,
    this.sourceConflict = false,
  });
}

class _PreparedLine {
  final String text;
  final bool homoglyph;

  const _PreparedLine(this.text, this.homoglyph);
}

_PreparedLine _prepareLine(String raw) {
  final buffer = StringBuffer();
  var homoglyph = false;
  for (final rune in raw.runes) {
    final ch = String.fromCharCode(rune);
    final mapped = _cyrillicHomoglyphs[ch];
    if (mapped != null) {
      homoglyph = true;
      buffer.write(mapped);
      continue;
    }
    final upper = ch.toUpperCase();
    if (RegExp(r'[A-Z0-9]').hasMatch(upper)) {
      buffer.write(upper);
      continue;
    }
    buffer.write(' ');
  }
  return _PreparedLine(
    buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim(),
    homoglyph,
  );
}

String transliterateHomoglyphs(String raw) => _prepareLine(raw).text;

PlateCandidate? interpretPlate(String compact, {bool homoglyph = false}) {
  if (compact.isEmpty) return null;
  final warnings = <String>[if (homoglyph) 'cyrillic-homoglyph'];

  if (_kz2012.hasMatch(compact)) {
    return PlateCandidate(
      observedCompact: compact,
      possibleNormalized: compact,
      format: PlateFormat.kz2012Private,
      ambiguous: warnings.isNotEmpty,
      warnings: warnings,
    );
  }

  if (compact.length == 8) {
    final chars = compact.split('');
    final out = List<String>.from(chars);
    var rewrites = 0;
    var convertible = true;
    for (var i = 0; i < 8; i++) {
      final char = chars[i];
      final digitSlot = i < 3 || i >= 6;
      if (digitSlot) {
        if (RegExp(r'\d').hasMatch(char)) continue;
        final mapped = _digitLookalikes[char];
        if (mapped == null) {
          convertible = false;
          break;
        }
        out[i] = mapped;
        rewrites++;
      } else if (RegExp(r'[A-Z]').hasMatch(char)) {
        continue;
      } else {
        final mapped = _letterLookalikes[char];
        if (mapped == null) {
          convertible = false;
          break;
        }
        out[i] = mapped;
        rewrites++;
      }
    }
    final possible = out.join();
    if (convertible && rewrites > 0 && _kz2012.hasMatch(possible)) {
      return PlateCandidate(
        observedCompact: compact,
        possibleNormalized: possible,
        format: PlateFormat.kz2012Private,
        ambiguous: true,
        warnings: [...warnings, 'lookalike'],
      );
    }
  }

  final digits = RegExp(r'\d').allMatches(compact).length;
  final letters = RegExp(r'[A-Z]').allMatches(compact).length;
  if (compact.length >= 4 &&
      compact.length <= 12 &&
      digits >= 2 &&
      letters >= 1 &&
      !_modelToken.hasMatch(compact)) {
    return PlateCandidate(
      observedCompact: compact,
      possibleNormalized: null,
      format: PlateFormat.unknown,
      ambiguous: false,
      warnings: [...warnings, 'unclassified-format'],
    );
  }
  return null;
}

IdentityCandidates extractCandidates(OcrFrameResult frame) {
  final plates = <PlateCandidate>[];
  final vins = <String>{};
  final ambiguousVins = <String>{};
  final manufacturers = <String>{};
  final models = <String>{};

  for (final observation in frame.observations) {
    final prepared = _prepareLine(observation.text);
    if (prepared.text.isEmpty) continue;
    final tokens = prepared.text.split(' ');
    final plateHit = _consumePlate(tokens, homoglyph: prepared.homoglyph);
    if (plateHit.reading != null) plates.add(plateHit.reading!);

    final used = plateHit.used;
    for (var i = 0; i < tokens.length; i++) {
      if (used.contains(i)) continue;
      final token = tokens[i];
      if (token.length == 17) {
        if (_vinClean.hasMatch(token)) {
          vins.add(token);
        } else if (RegExp(r'^[A-Z0-9]{17}$').hasMatch(token)) {
          ambiguousVins.add(token);
        }
      }
      if (_modelToken.hasMatch(token)) models.add(token);
      final unknown = interpretPlate(token, homoglyph: prepared.homoglyph);
      if (unknown != null && unknown.format == PlateFormat.unknown) {
        plates.add(unknown);
      }
    }

    for (var i = 0; i < tokens.length; i++) {
      if (used.contains(i)) continue;
      final token = tokens[i];
      if (models.contains(token)) continue;
      if (_brandToken.hasMatch(token)) manufacturers.add(token);
    }
  }

  final confirmed = plates
      .where((plate) => plate.confirmed)
      .map((plate) => plate.possibleNormalized)
      .toSet();
  return IdentityCandidates(
    plates: plates,
    plateConflict: confirmed.length > 1,
    acceptedVins: vins.toList(),
    ambiguousVins: ambiguousVins.toList(),
    manufacturerTokens: manufacturers.toList(),
    modelTokens: models.toList(),
  );
}

class _PlateHit {
  final PlateCandidate? reading;
  final Set<int> used;

  const _PlateHit(this.reading, this.used);
}

_PlateHit _consumePlate(List<String> tokens, {required bool homoglyph}) {
  for (final width in const [3, 2, 1]) {
    for (var start = 0; start + width <= tokens.length; start++) {
      final compact = tokens.skip(start).take(width).join();
      final reading = interpretPlate(compact, homoglyph: homoglyph);
      if (reading == null || reading.format == PlateFormat.unknown) continue;
      return _PlateHit(reading, {for (var i = 0; i < width; i++) start + i});
    }
  }
  return const _PlateHit(null, {});
}

String? confirmedPlateOf(IdentityCandidates candidates) {
  if (candidates.plateConflict) return null;
  final confirmed = candidates.plates.where((plate) => plate.confirmed);
  final values = confirmed.map((plate) => plate.possibleNormalized).toSet();
  if (values.length != 1) return null;
  return values.single;
}

FrameConsensus consensusOf(List<OcrFrameResult> frames) {
  if (frames.isEmpty) {
    return const FrameConsensus(
      frames: 0,
      plate: null,
      stable: false,
      ambiguous: false,
    );
  }

  final readings = [for (final frame in frames) extractCandidates(frame)];
  final ambiguous = readings.any(
    (item) => item.plateConflict || item.plates.any((plate) => plate.ambiguous),
  );
  final confirmed = [for (final item in readings) confirmedPlateOf(item)];
  final stable =
      !ambiguous &&
      frames.length >= 2 &&
      confirmed.every((plate) => plate != null) &&
      confirmed.toSet().length == 1;

  return FrameConsensus(
    frames: frames.length,
    plate: stable ? confirmed.first : null,
    stable: stable,
    ambiguous: ambiguous,
  );
}

VerificationDecision decideVerification(VerificationInput input) {
  final consensus = input.consensus;
  if (!consensus.stable || consensus.ambiguous) {
    return VerificationDecision.retry;
  }
  if (input.duplicateRisk || input.sourceConflict) {
    return VerificationDecision.review;
  }
  final photo = input.machinePhotoPlate;
  if (photo == null) return VerificationDecision.insufficientEvidence;
  if (photo != consensus.plate) return VerificationDecision.review;
  if (!input.modelResolved) return VerificationDecision.review;
  return VerificationDecision.autoPass;
}
