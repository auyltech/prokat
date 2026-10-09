import 'package:prokat/features/equipment_share/equipment_share_link.dart';
import 'package:prokat/features/equipment_share/equipment_share_open.dart';
import 'package:prokat/features/equipment_share/equipment_share_resolver.dart';
import 'package:prokat/features/equipment_share/equipment_share_storage.dart';

class EquipmentShareIngress {
  EquipmentShareIngress({
    required this.storage,
    required this.resolve,
    required this.isReady,
    required this.onAccepted,
    required this.onFailure,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final EquipmentShareStorage storage;
  final Future<ShareResolution> Function(String) resolve;
  final bool Function() isReady;
  final Future<void> Function(EquipmentShareOpen) onAccepted;
  final void Function(ShareResolutionStatus) onFailure;
  final DateTime Function() _now;
  int _generation = 0;
  int? _processing;
  int? _failedGeneration;
  String? _lastIdentity;
  DateTime? _lastAt;
  String? _receiptNotified;
  bool _disposed = false;
  bool hasPendingIntent = false;

  int get generation => _generation;

  bool _current(int generation) => !_disposed && generation == _generation;

  Future<bool> acceptUri(
    Uri uri, {
    required ShareOpenVia via,
    required bool firstShareBootstrapRun,
  }) async {
    final link = EquipmentShareLink.tryParse(uri);
    if (link == null) return false;
    await accept(
      EquipmentShareOpen(
        link: link,
        via: via,
        firstShareBootstrapRun: firstShareBootstrapRun,
      ),
    );
    return true;
  }

  Future<void> acceptShareId(String shareId, {required ShareOpenVia via}) =>
      accept(
        EquipmentShareOpen(
          link: EquipmentShareLink.fromShareId(shareId),
          via: via,
          firstShareBootstrapRun: false,
        ),
      );

  Future<void> accept(EquipmentShareOpen open) async {
    if (_disposed) return;
    final identity = open.link.uri.toString();
    final now = _now();
    if (_lastIdentity == identity &&
        _lastAt != null &&
        (_processing != null ||
            (now.difference(_lastAt!) >= Duration.zero &&
                now.difference(_lastAt!) < const Duration(seconds: 2)))) {
      return;
    }
    _lastIdentity = identity;
    _lastAt = now;
    final generation = ++_generation;
    hasPendingIntent = true;
    _processing = generation;
    try {
      await storage.savePendingOpen(open, receivedAt: now);
      if (!_current(generation)) return;
      if (!_current(generation) || !isReady()) return;
      final snapshot = await storage.readPendingSnapshot();
      if (!_current(generation)) return;
      if (snapshot.open == null) {
        hasPendingIntent = false;
        return;
      }
      await _process(snapshot.open!, snapshot.token, generation);
    } catch (_) {
      if (_current(generation)) {
        _fail(generation, ShareResolutionStatus.temporary);
      }
    } finally {
      if (_processing == generation) _processing = null;
    }
  }

  Future<void> flushPendingUriIfAny({bool retry = false}) async {
    final generation = _generation;
    if (_disposed || _processing == generation) return;
    _processing = generation;
    try {
      final snapshot = await storage.readPendingSnapshot();
      if (!_current(generation)) return;
      hasPendingIntent = snapshot.open != null;
      if (!isReady() || (!retry && _failedGeneration == generation)) {
        return;
      }
      if (snapshot.open == null) {
        final receipt = await storage.readOpenReceipt();
        if (_current(generation) &&
            receipt != null &&
            (retry || _receiptNotified != receipt.clientEventId)) {
          _receiptNotified = receipt.clientEventId;
          await onAccepted(receipt);
        }
        return;
      }
      await _process(snapshot.open!, snapshot.token, generation);
    } catch (_) {
      if (_current(generation)) {
        _fail(generation, ShareResolutionStatus.temporary);
      }
    } finally {
      if (_processing == generation) _processing = null;
    }
  }

  Future<void> _process(
    EquipmentShareOpen open,
    int token,
    int generation,
  ) async {
    _lastIdentity = open.link.uri.toString();
    _lastAt = _now();
    var resolved = open;
    if (open.link.equipmentId == null) {
      final result = await resolve(open.link.shareId!);
      if (!_current(generation)) return;
      if (result.status != ShareResolutionStatus.resolved ||
          !EquipmentShareLink.isValidEquipmentId(result.equipmentId)) {
        if (result.status == ShareResolutionStatus.unavailable ||
            result.status == ShareResolutionStatus.invalid) {
          if (!await storage.clearPendingIfUnchanged(token) ||
              !_current(generation)) {
            return;
          }
          hasPendingIntent = false;
        } else {
          final snapshot = await storage.readPendingSnapshot();
          if (snapshot.token != token || !_current(generation)) return;
        }
        _fail(
          generation,
          result.status == ShareResolutionStatus.resolved
              ? ShareResolutionStatus.temporary
              : result.status,
        );
        return;
      }
      resolved = open.resolved(result.equipmentId!);
    }
    if (!_current(generation) || !isReady()) return;
    if (!await storage.completePendingIfUnchanged(token, resolved) ||
        !_current(generation)) {
      return;
    }
    hasPendingIntent = false;
    _failedGeneration = null;
    final receipt = await storage.readOpenReceipt();
    if (!_current(generation) ||
        receipt == null ||
        receipt.link.uri != resolved.link.uri) {
      return;
    }
    _receiptNotified = receipt.clientEventId;
    await onAccepted(receipt);
  }

  void _fail(int generation, ShareResolutionStatus status) {
    if (_failedGeneration == generation) return;
    _failedGeneration = generation;
    onFailure(status);
  }

  void dispose() {
    _disposed = true;
    _generation++;
  }
}
