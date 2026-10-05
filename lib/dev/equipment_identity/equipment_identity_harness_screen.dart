import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:prokat/core/widgets/ui_kit/ui_kit.dart';
import 'package:prokat/dev/equipment_identity/equipment_identity_ocr_port.dart';
import 'package:prokat/dev/equipment_identity/identity_fixtures.dart';
import 'package:prokat/dev/equipment_identity/identity_observation.dart';
import 'package:prokat/dev/equipment_identity/ocr_observation.dart';

class EquipmentIdentityHarnessScreen extends StatefulWidget {
  const EquipmentIdentityHarnessScreen({super.key});

  @override
  State<EquipmentIdentityHarnessScreen> createState() =>
      _EquipmentIdentityHarnessScreenState();
}

class _EquipmentIdentityHarnessScreenState
    extends State<EquipmentIdentityHarnessScreen> {
  final _picker = ImagePicker();
  final _ocr = const EquipmentIdentityOcrPort();
  final _paste = TextEditingController(text: '123 ABC 06\nXCMG XE215C');

  String? _imagePath;
  OcrFrameResult? _frame;
  IdentityCandidates? _parsed;
  String? _error;
  bool _busy = false;
  FixtureReport? _report;
  String _probe = '';
  final List<_OcrRun> _runs = [];

  @override
  void dispose() {
    _paste.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    setState(() {
      _error = null;
      _busy = true;
    });
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 2000,
        maxHeight: 2000,
        imageQuality: 95,
      );
      if (picked == null) return;
      await _recognize(
        picked.path,
        source: source == ImageSource.camera ? 'camera' : 'gallery',
        framing: 'full',
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _crop() async {
    final path = _imagePath;
    if (path == null) return;
    final cropped = await ImageCropper().cropImage(
      sourcePath: path,
      compressQuality: 95,
      uiSettings: [
        AndroidUiSettings(toolbarTitle: 'OCR crop'),
        IOSUiSettings(title: 'OCR crop'),
      ],
    );
    if (cropped == null) return;
    setState(() => _busy = true);
    try {
      await _recognize(cropped.path, source: 'crop', framing: 'crop');
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _recognize(
    String path, {
    required String source,
    required String framing,
  }) async {
    final frame = await _ocr.recognizeFile(path);
    if (!mounted) return;
    setState(() {
      _imagePath = path;
      _frame = frame;
      _parsed = extractCandidates(frame);
      _error = null;
      _runs.add(
        _OcrRun(
          source: source,
          framing: framing,
          frame: frame,
          parsed: _parsed!,
        ),
      );
    });
  }

  void _probeLines() {
    final lines = _paste.text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    final frame = OcrFrameResult.lines(lines);
    final candidates = extractCandidates(frame);
    final decision = decideVerification(
      VerificationInput(consensus: consensusOf([frame, frame])),
    );
    setState(() {
      _probe = [
        'engine: fixture (не фото)',
        for (final plate in candidates.plates)
          'plate observed=${plate.observedCompact} '
              'possible=${plate.possibleNormalized ?? '—'} '
              'format=${plate.format.name} '
              'ambiguous=${plate.ambiguous} '
              'confirmed=${plate.confirmed} '
              'warnings=${plate.warnings.join(',')}',
        'manufacturer: ${candidates.manufacturerTokens.join(', ')}',
        'model: ${candidates.modelTokens.join(', ')}',
        'vin: ${candidates.acceptedVins.join(', ')}',
        'vin ambiguous: ${candidates.ambiguousVins.join(', ')}',
        'decision: ${decision.name}',
      ].join('\n');
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final frame = _frame;
    final parsed = _parsed;

    return Scaffold(
      backgroundColor: colors.background.main,
      appBar: ProkatAppBar(
        title: Text('OCR spike', style: AppFonts.body16(context)),
        onBack: () => context.pop(),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppDimens.s16$base),
        children: [
          Text(
            'Снимок остаётся на устройстве. Сеть, аналитика и git его не получают. '
            'Сейчас подключён только ML Kit Latin. Для марки и модели он не основной: '
            'кириллицу он может подменить похожей латиницей. В журнал копируйте raw как есть, '
            'обратно в исходный алфавит не переводите.',
            style: AppFonts.body14(context),
          ),
          const SizedBox(height: AppDimens.s12$md),
          AppElevatedButton(
            title: 'Камера',
            isLoading: _busy,
            onTap: _busy ? null : () => _pick(ImageSource.camera),
          ),
          const SizedBox(height: AppDimens.s08$sm),
          AppOutlinedButton(
            title: 'Галерея',
            onTap: _busy ? null : () => _pick(ImageSource.gallery),
          ),
          if (_imagePath != null) ...[
            const SizedBox(height: AppDimens.s08$sm),
            AppOutlinedButton(
              title: 'Обрезать фрагмент. Прошлый кадр останется в журнале',
              onTap: _busy ? null : _crop,
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: AppDimens.s12$md),
            Text(_error!, style: AppFonts.body14(context)),
          ],
          if (_imagePath != null && frame != null) ...[
            const SizedBox(height: AppDimens.s16$base),
            Text(
              '${frame.engine} · ${frame.elapsedMs} ms · '
              '${frame.imageWidth}×${frame.imageHeight}',
              style: AppFonts.body14(context),
            ),
            if (frame.supportedLanguages.isNotEmpty)
              Text(
                'languages: ${frame.supportedLanguages.join(', ')}',
                style: AppFonts.caption(context),
              ),
            if (frame.note != null)
              Text(frame.note!, style: AppFonts.caption(context)),
            const SizedBox(height: AppDimens.s08$sm),
            _OcrPreview(path: _imagePath!, frame: frame),
            const SizedBox(height: AppDimens.s12$md),
            Text('Raw', style: AppFonts.body16(context)),
            for (final line in frame.observations)
              Text(
                '${line.text}'
                '${line.confidence == null ? '' : '  conf=${line.confidence!.toStringAsFixed(2)}'}',
                style: AppFonts.caption(context),
              ),
            if (parsed != null) ...[
              const SizedBox(height: AppDimens.s12$md),
              Text('Parsed', style: AppFonts.body16(context)),
              if (parsed.plates.isEmpty)
                Text('plate: —', style: AppFonts.caption(context)),
              for (final plate in parsed.plates)
                Text(
                  'plate observed=${plate.observedCompact} '
                  'possible=${plate.possibleNormalized ?? '—'} '
                  'format=${plate.format.name} '
                  'ambiguous=${plate.ambiguous} '
                  'confirmed=${plate.confirmed}\n'
                  'warnings: ${plate.warnings.join(', ')}',
                  style: AppFonts.caption(context),
                ),
              Text(
                'manufacturer: ${parsed.manufacturerTokens.join(', ')}',
                style: AppFonts.caption(context),
              ),
              Text(
                'model: ${parsed.modelTokens.join(', ')}',
                style: AppFonts.caption(context),
              ),
              Text(
                'vin: ${parsed.acceptedVins.join(', ')}',
                style: AppFonts.caption(context),
              ),
              Text(
                'vin ambiguous: ${parsed.ambiguousVins.join(', ')}',
                style: AppFonts.caption(context),
              ),
            ],
          ],
          if (_runs.isNotEmpty) ...[
            const SizedBox(height: AppDimens.s16$base),
            Text(
              'Журнал прогонов. В метрику копируйте блок raw, не parsed. '
              'Полный кадр не стирается после crop.',
              style: AppFonts.body14(context),
            ),
            const SizedBox(height: AppDimens.s08$sm),
            SelectableText(
              _runs.map((run) => run.evidence()).join('\n---\n'),
              style: AppFonts.caption(context),
            ),
          ],
          const SizedBox(height: AppDimens.s24$xl),
          AppElevatedButton(
            title: 'Прогнать текстовые фикстуры',
            onTap: () => setState(() => _report = evaluateFixtures()),
          ),
          if (_report != null)
            Padding(
              padding: const EdgeInsets.only(top: AppDimens.s08$sm),
              child: Text(
                'Ложных подтверждённых номеров: '
                '${_report!.count((score) => score.falseAccept)} из ${_report!.total}. '
                'Это парсер строк, не OCR.',
                style: AppFonts.caption(context),
              ),
            ),
          const SizedBox(height: AppDimens.s12$md),
          AppTextArea(
            controller: _paste,
            title: 'Сырые строки',
            minLines: 3,
            maxLines: 6,
          ),
          const SizedBox(height: AppDimens.s08$sm),
          AppOutlinedButton(title: 'Разобрать вставку', onTap: _probeLines),
          if (_probe.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppDimens.s08$sm),
              child: Text(_probe, style: AppFonts.caption(context)),
            ),
        ],
      ),
    );
  }
}

class _OcrRun {
  final String source;
  final String framing;
  final OcrFrameResult frame;
  final IdentityCandidates parsed;

  const _OcrRun({
    required this.source,
    required this.framing,
    required this.frame,
    required this.parsed,
  });

  String evidence() {
    final lines = [
      'device: заполнить, первый прогон Samsung A125F',
      'os: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}',
      'image source: $source',
      'framing: $framing',
      'engine: ${frame.engine}',
      'elapsedMs: ${frame.elapsedMs}',
      'image: ${frame.imageWidth}x${frame.imageHeight}',
      if (frame.note != null) 'note: ${frame.note}',
      'raw:',
      if (frame.observations.isEmpty) '(пусто)',
      for (final line in frame.observations)
        '- ${line.text}'
            '${line.confidence == null ? '' : ' conf=${line.confidence!.toStringAsFixed(2)}'}'
            '${line.boundingBox == null ? '' : ' box=${line.boundingBox!.left.toStringAsFixed(0)},${line.boundingBox!.top.toStringAsFixed(0)},${line.boundingBox!.width.toStringAsFixed(0)}x${line.boundingBox!.height.toStringAsFixed(0)}'}',
      'parsed (не метрика):',
      if (parsed.plates.isEmpty) 'plate: —',
      for (final plate in parsed.plates)
        'plate observed=${plate.observedCompact} possible=${plate.possibleNormalized ?? '—'} '
            'format=${plate.format.name} ambiguous=${plate.ambiguous} '
            'warnings=${plate.warnings.join(',')}',
      'manufacturer tokens: ${parsed.manufacturerTokens.join(', ')}',
      'model tokens: ${parsed.modelTokens.join(', ')}',
      'vin: ${parsed.acceptedVins.join(', ')}',
      'vin ambiguous: ${parsed.ambiguousVins.join(', ')}',
      'warnings: ${parsed.warnings.join(', ')}',
    ];
    return lines.join('\n');
  }
}

class _OcrPreview extends StatelessWidget {
  final String path;
  final OcrFrameResult frame;

  const _OcrPreview({required this.path, required this.frame});

  @override
  Widget build(BuildContext context) {
    final width = frame.imageWidth.toDouble();
    final height = frame.imageHeight.toDouble();
    if (width <= 0 || height <= 0) {
      return Image.file(File(path), fit: BoxFit.contain);
    }
    return FittedBox(
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          children: [
            Image.file(
              File(path),
              width: width,
              height: height,
              fit: BoxFit.fill,
            ),
            CustomPaint(
              size: Size(width, height),
              painter: _BoxPainter(frame.observations, context.colors.primary),
            ),
          ],
        ),
      ),
    );
  }
}

class _BoxPainter extends CustomPainter {
  final List<OcrObservation> observations;
  final Color color;

  _BoxPainter(this.observations, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = color;
    for (final observation in observations) {
      final box = observation.boundingBox;
      if (box == null) continue;
      canvas.drawRect(
        Rect.fromLTWH(box.left, box.top, box.width, box.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BoxPainter oldDelegate) => true;
}
