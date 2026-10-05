/// Engine-neutral OCR output. Engines observe text. They do not verify a machine.
class OcrBoundingBox {
  final double left;
  final double top;
  final double width;
  final double height;

  const OcrBoundingBox({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });
}

class OcrObservation {
  final String text;
  final OcrBoundingBox? boundingBox;
  final double? confidence;
  final String engine;

  const OcrObservation({
    required this.text,
    required this.engine,
    this.boundingBox,
    this.confidence,
  });
}

class OcrFrameResult {
  final List<OcrObservation> observations;
  final int imageWidth;
  final int imageHeight;
  final int elapsedMs;
  final String engine;
  final List<String> supportedLanguages;
  final String? note;

  const OcrFrameResult({
    required this.observations,
    required this.imageWidth,
    required this.imageHeight,
    required this.elapsedMs,
    required this.engine,
    this.supportedLanguages = const [],
    this.note,
  });

  factory OcrFrameResult.lines(
    List<String> lines, {
    String engine = 'fixture',
  }) {
    return OcrFrameResult(
      observations: [
        for (final line in lines) OcrObservation(text: line, engine: engine),
      ],
      imageWidth: 0,
      imageHeight: 0,
      elapsedMs: 0,
      engine: engine,
    );
  }

  factory OcrFrameResult.fromChannel(Map<Object?, Object?> raw) {
    final observations = raw['observations'];
    final languages = raw['supportedLanguages'];
    return OcrFrameResult(
      engine: raw['engine'] as String? ?? 'unknown',
      imageWidth: (raw['imageWidth'] as num?)?.toInt() ?? 0,
      imageHeight: (raw['imageHeight'] as num?)?.toInt() ?? 0,
      elapsedMs: (raw['elapsedMs'] as num?)?.toInt() ?? 0,
      note: raw['note'] as String?,
      supportedLanguages: languages is List
          ? [for (final item in languages) item.toString()]
          : const [],
      observations: observations is List
          ? [
              for (final item in observations)
                if (item is Map) _observation(item, raw['engine'] as String?),
            ]
          : const [],
    );
  }
}

OcrObservation _observation(Map<Object?, Object?> raw, String? engine) {
  final left = raw['left'];
  final top = raw['top'];
  final width = raw['width'];
  final height = raw['height'];
  OcrBoundingBox? box;
  if (left is num && top is num && width is num && height is num) {
    box = OcrBoundingBox(
      left: left.toDouble(),
      top: top.toDouble(),
      width: width.toDouble(),
      height: height.toDouble(),
    );
  }
  final confidence = raw['confidence'];
  return OcrObservation(
    text: raw['text'] as String? ?? '',
    engine: engine ?? 'unknown',
    confidence: confidence is num ? confidence.toDouble() : null,
    boundingBox: box,
  );
}
