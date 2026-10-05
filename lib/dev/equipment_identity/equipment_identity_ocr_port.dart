import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:prokat/dev/equipment_identity/ocr_observation.dart';

class EquipmentIdentityOcrException implements Exception {
  final String message;

  const EquipmentIdentityOcrException(this.message);

  @override
  String toString() => message;
}

/// File OCR only. The engine returns observations and does not verify a unit.
class EquipmentIdentityOcrPort {
  static const _channel = MethodChannel(
    'com.auyltech.prokat/equipment_identity_ocr',
  );

  const EquipmentIdentityOcrPort();

  bool get isDeviceEngine {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  Future<OcrFrameResult> recognizeFile(String path) async {
    if (!isDeviceEngine) {
      throw const EquipmentIdentityOcrException(
        'OCR файла доступен на Android и iOS. На этом устройстве движка нет.',
      );
    }
    try {
      final raw = await _channel.invokeMapMethod<Object?, Object?>(
        'recognizeFile',
        {'path': path},
      );
      if (raw == null) {
        throw const EquipmentIdentityOcrException('Пустой ответ OCR.');
      }
      return OcrFrameResult.fromChannel(raw);
    } on PlatformException catch (error) {
      throw EquipmentIdentityOcrException(error.message ?? error.code);
    }
  }
}
